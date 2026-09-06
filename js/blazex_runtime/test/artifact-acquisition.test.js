import assert from "node:assert/strict";
import { createHash, webcrypto } from "node:crypto";
import test from "node:test";

import { acquireHostArtifacts, BH03_ARTIFACT_LIMITS, BlazeXHostError, validateHostManifest } from "../src/index.js";

const bytesByRole = Object.freeze({
  "runtime-module": new TextEncoder().encode("export default () => ({})"),
  "runtime-wasm": new Uint8Array([0, 97, 115, 109, 1, 0, 0, 0]),
  "application-bundle": new TextEncoder().encode("AVM-phase-3"),
});

function gate() {
  const raw = {
    schema_version: "1.0.0",
    manifest_id: "BX-BH03-PHASE-03-TEST",
    generation: 3,
    profile_id: "phase-three-test",
    compatibility: {
      browser_host: "blazex.browser-host/1",
      runtime_adapter: "blazex.popcorn-runtime-adapter/1",
      runtime_loader: "blazex.browser-runtime-loader/1",
      profile_manifest: "blazex.browser-profile-manifest/1",
      root_lifecycle: "blazex.browser-root-lifecycle/1",
      semantic_tree: "blazex.ui-tree/1",
      renderer: "blazex.renderer/1",
      dom_projection: "blazex.dom-projection/1",
    },
    prerequisites: {
      browser_required: ["webassembly", "workers", "module-scripts", "fetch", "abort-controller", "subtle-crypto"],
      deployment_required: ["secure-context", "cross-origin-isolation", "same-origin-artifacts"],
      optional: ["wasm-streaming"],
    },
    artifacts: Object.entries(bytesByRole).map(([role, bytes], index) => ({
      id: `phase-three-${index}`,
      role,
      path: `./artifact-${index}`,
      mime: role === "runtime-module" ? "text/javascript" : role === "runtime-wasm" ? "application/wasm" : "application/vnd.atomvm.avm",
      bytes: bytes.byteLength,
      sha256: createHash("sha256").update(bytes).digest("hex"),
    })),
  };
  return {
    protocol: "blazex.pre-acquisition-gate/1",
    decision: "eligible-for-artifact-acquisition",
    manifest: validateHostManifest(raw, "https://example.test/bh03/manifest.json"),
  };
}

function response(body, declaration, overrides = {}) {
  const value = new Response(body, {
    status: overrides.status ?? 200,
    headers: {
      "content-type": overrides.mime ?? declaration.mime,
      "content-length": String(overrides.length ?? body.byteLength),
      ...(overrides.encoding ? { "content-encoding": overrides.encoding } : {}),
    },
  });
  Object.defineProperties(value, {
    url: { value: overrides.url ?? declaration.url },
    redirected: { value: overrides.redirected ?? false },
  });
  return value;
}

test("acquires the three accepted artifacts in order and publishes only after verification", async () => {
  const accepted = structuredClone(gate());
  const requests = [];
  const fetchImpl = async (url, init) => {
    const declaration = accepted.manifest.artifacts.find((item) => item.url === url.href);
    requests.push({ role: declaration.role, cache: init.cache, credentials: init.credentials, redirect: init.redirect });
    return response(bytesByRole[declaration.role], declaration);
  };
  const result = await acquireHostArtifacts(accepted, { fetchImpl, cryptoImpl: webcrypto });
  assert.deepEqual(requests.map((item) => item.role), ["runtime-module", "runtime-wasm", "application-bundle"]);
  assert.ok(requests.every((item) => item.cache === "no-store" && item.credentials === "same-origin" && item.redirect === "error"));
  assert.equal(result.protocol, "blazex.artifact-acquisition/1");
  assert.deepEqual(Object.keys(result.artifacts), ["runtime-module", "runtime-wasm", "application-bundle"]);
  assert.equal(result.total_bytes, Object.values(bytesByRole).reduce((total, bytes) => total + bytes.byteLength, 0));
  assert.deepEqual(result.artifacts["runtime-wasm"].webassembly, { imports: 0, exports: 0 });
});

test("rejects missing gates and declaration limits before any fetch", async () => {
  let fetches = 0;
  const fetchImpl = async () => { fetches += 1; };
  await assert.rejects(acquireHostArtifacts({}, { fetchImpl }), failure("artifact-unavailable", "pre-acquisition-gate"));
  const accepted = structuredClone(gate());
  accepted.manifest.artifacts[0].bytes = BH03_ARTIFACT_LIMITS["runtime-module"] + 1;
  await assert.rejects(acquireHostArtifacts(accepted, { fetchImpl }), failure("artifact-integrity", "declaration-limit"));
  assert.equal(fetches, 0);
});

test("rejects response metadata, truncation, corruption, and invalid WebAssembly atomically", async () => {
  for (const scenario of ["mime", "encoding", "redirect", "truncated", "corrupt", "wasm"]) {
    const accepted = structuredClone(gate());
    const fetchImpl = async (url) => {
      const declaration = accepted.manifest.artifacts.find((item) => item.url === url.href);
      let body = bytesByRole[declaration.role];
      const overrides = {};
      if (declaration.role === "runtime-module" && scenario === "mime") overrides.mime = "text/plain";
      if (declaration.role === "runtime-module" && scenario === "encoding") overrides.encoding = "gzip";
      if (declaration.role === "runtime-module" && scenario === "redirect") overrides.redirected = true;
      if (declaration.role === "application-bundle" && scenario === "truncated") {
        body = body.slice(0, -1);
        overrides.length = declaration.bytes;
      }
      if (declaration.role === "application-bundle" && scenario === "corrupt") body = new Uint8Array(declaration.bytes);
      if (declaration.role === "runtime-wasm" && scenario === "wasm") {
        body = new Uint8Array(declaration.bytes);
        declaration.sha256 = createHash("sha256").update(body).digest("hex");
      }
      return response(body, declaration, overrides);
    };
    await assert.rejects(acquireHostArtifacts(accepted, { fetchImpl, cryptoImpl: webcrypto }), (error) => error instanceof BlazeXHostError && error.code === "artifact-integrity", scenario);
  }
});

test("rejects unavailable, timed-out, cancelled, and oversize-stream artifacts", async () => {
  const accepted = gate();
  const unavailableFetch = async (url) => {
    const declaration = accepted.manifest.artifacts.find((item) => item.url === url.href);
    return response(new Uint8Array(), declaration, { status: 503, length: 0 });
  };
  await assert.rejects(acquireHostArtifacts(accepted, { fetchImpl: unavailableFetch, cryptoImpl: webcrypto }), failure("artifact-unavailable", "fetch-status"));

  const pendingFetch = (_url, init) => new Promise((_resolve, reject) => init.signal.addEventListener("abort", () => reject(new DOMException("stopped", "AbortError")), { once: true }));
  await assert.rejects(acquireHostArtifacts(accepted, { fetchImpl: pendingFetch, timeoutMs: 1, cryptoImpl: webcrypto }), failure("artifact-unavailable", "fetch-timeout"));

  const controller = new AbortController();
  const cancelled = acquireHostArtifacts(accepted, { fetchImpl: pendingFetch, signal: controller.signal, cryptoImpl: webcrypto });
  controller.abort();
  await assert.rejects(cancelled, failure("artifact-unavailable", "fetch-cancelled"));

  const streamFetch = async (url) => {
    const declaration = accepted.manifest.artifacts.find((item) => item.url === url.href);
    const stream = new ReadableStream({ start(streamController) { streamController.enqueue(new Uint8Array(declaration.bytes + 1)); streamController.close(); } });
    const value = new Response(stream, { status: 200, headers: { "content-type": declaration.mime } });
    Object.defineProperties(value, { url: { value: declaration.url }, redirected: { value: false } });
    return value;
  };
  await assert.rejects(acquireHostArtifacts(accepted, { fetchImpl: streamFetch, cryptoImpl: webcrypto }), failure("artifact-integrity", "stream-oversize"));
});

function failure(code, reason) {
  return (error) => error instanceof BlazeXHostError && error.code === code && error.details.reason === reason;
}
