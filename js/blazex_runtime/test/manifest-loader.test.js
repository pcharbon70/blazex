import assert from "node:assert/strict";
import { createHash, webcrypto } from "node:crypto";
import test from "node:test";

import { BlazeXHostError, acquireDeclaredArtifacts, fetchDeclaredArtifact, fetchRuntimeManifest, validateRuntimeManifest } from "../src/index.js";

const bytesByRole = {
  "runtime-module": new TextEncoder().encode("export default () => ({})"),
  "runtime-wasm": new Uint8Array([0, 97, 115, 109, 1, 0, 0, 0]),
  "application-bundle": new TextEncoder().encode("AVM-test"),
};
const sha256 = (bytes) => createHash("sha256").update(bytes).digest("hex");

function manifest() {
  return {
    schema_version: "1.0.0",
    manifest_id: "BX-BH01-TEST-MANIFEST",
    generation: 1,
    startup: {
      entrypoint: "Elixir.BlazeX.BH01.BrowserHost.Boot",
      memory_pages: 256,
      readiness_event: "popcorn_app_ready",
      allowed_import_modules: [],
      required_exports: [],
      required_features: ["shared-memory", "threads"],
    },
    artifacts: Object.entries(bytesByRole).map(([role, bytes], index) => ({
      id: `artifact-${index}`,
      role,
      path: `./artifact-${index}`,
      mime: role === "runtime-module" ? "text/javascript" : role === "runtime-wasm" ? "application/wasm" : "application/vnd.atomvm.avm",
      bytes: bytes.byteLength,
      sha256: sha256(bytes),
    })),
  };
}

function withUrl(response, url, redirected = false) {
  Object.defineProperties(response, { url: { value: url }, redirected: { value: redirected } });
  return response;
}

test("validates the exact Phase 4 manifest and resolves same-origin assets", () => {
  const value = validateRuntimeManifest(manifest(), "https://example.test/bh01/runtime-manifest.json");
  assert.equal(value.artifacts[0].url, "https://example.test/bh01/artifact-0");
  assert.throws(() => validateRuntimeManifest({ ...manifest(), schema_version: "2.0.0" }, "https://example.test/m.json"), /Unsupported/);
  const duplicate = manifest();
  duplicate.artifacts[1].id = duplicate.artifacts[0].id;
  assert.throws(() => validateRuntimeManifest(duplicate, "https://example.test/m.json"), /unique/);
  const crossOrigin = manifest();
  crossOrigin.artifacts[0].path = "https://attacker.test/runtime.mjs";
  assert.throws(() => validateRuntimeManifest(crossOrigin, "https://example.test/m.json"), /same-origin/);
});

test("fetches a no-store manifest and rejects redirects", async () => {
  const value = manifest();
  const url = "https://example.test/runtime-manifest.json";
  const fetchImpl = async (_url, init) => {
    assert.equal(init.cache, "no-store");
    assert.equal(init.redirect, "error");
    return withUrl(new Response(JSON.stringify(value), { status: 200, headers: { "content-type": "application/json" } }), url);
  };
  assert.equal((await fetchRuntimeManifest(url, { fetchImpl })).manifest_id, value.manifest_id);
  const redirected = async () => withUrl(new Response(JSON.stringify(value), { status: 200, headers: { "content-type": "application/json" } }), "https://example.test/other", true);
  await assert.rejects(fetchRuntimeManifest(url, { fetchImpl: redirected }), (error) => error instanceof BlazeXHostError && error.code === "fetch-redirect-forbidden");
});

test("verifies artifact bytes, MIME, digest, Wasm, and cancellation", async () => {
  const value = validateRuntimeManifest(manifest(), "https://example.test/runtime-manifest.json");
  const fetchImpl = async (url) => {
    const declaration = value.artifacts.find((item) => item.url === url.href);
    const bytes = bytesByRole[declaration.role];
    return withUrl(new Response(bytes, { status: 200, headers: { "content-type": declaration.mime, "content-length": String(bytes.byteLength) } }), url.href);
  };
  const acquired = await acquireDeclaredArtifacts(value, { fetchImpl, cryptoImpl: webcrypto });
  assert.deepEqual(Object.keys(acquired), ["runtime-module", "runtime-wasm", "application-bundle"]);
  assert.deepEqual(acquired["runtime-wasm"].wasmContract.import_modules, []);
  const corruptFetch = async (url) => withUrl(new Response(new Uint8Array(8), { status: 200, headers: { "content-type": "application/wasm", "content-length": "8" } }), url.href);
  await assert.rejects(fetchDeclaredArtifact(value, "runtime-wasm", { fetchImpl: corruptFetch, cryptoImpl: webcrypto }), (error) => error.code === "artifact-integrity-mismatch");
  const controller = new AbortController();
  const pendingFetch = (_url, init) => new Promise((_resolve, reject) => init.signal.addEventListener("abort", () => reject(new DOMException("cancel", "AbortError")), { once: true }));
  const request = fetchDeclaredArtifact(value, "runtime-module", { fetchImpl: pendingFetch, cryptoImpl: webcrypto, signal: controller.signal });
  controller.abort();
  await assert.rejects(request, (error) => error.code === "fetch-cancelled");
});

test("rejects undeclared Wasm imports and missing required exports", async () => {
  const importedWasm = new Uint8Array([0, 97, 115, 109, 1, 0, 0, 0, 2, 8, 1, 1, 120, 1, 121, 2, 0, 0]);
  const value = manifest();
  value.artifacts.find((item) => item.role === "runtime-wasm").bytes = importedWasm.byteLength;
  value.artifacts.find((item) => item.role === "runtime-wasm").sha256 = sha256(importedWasm);
  const validated = validateRuntimeManifest(value, "https://example.test/runtime-manifest.json");
  const fetchImpl = async (url) => withUrl(new Response(importedWasm, {
    status: 200,
    headers: { "content-type": "application/wasm", "content-length": String(importedWasm.byteLength) },
  }), url.href);
  await assert.rejects(fetchDeclaredArtifact(validated, "runtime-wasm", { fetchImpl, cryptoImpl: webcrypto }), (error) => error.code === "wasm-import-contract-mismatch");

  const missing = manifest();
  missing.startup.required_exports = ["start"];
  const missingValidated = validateRuntimeManifest(missing, "https://example.test/runtime-manifest.json");
  const emptyFetch = async (url) => withUrl(new Response(bytesByRole["runtime-wasm"], {
    status: 200,
    headers: { "content-type": "application/wasm", "content-length": "8" },
  }), url.href);
  await assert.rejects(fetchDeclaredArtifact(missingValidated, "runtime-wasm", { fetchImpl: emptyFetch, cryptoImpl: webcrypto }), (error) => error.code === "wasm-export-contract-mismatch");
});
