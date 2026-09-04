import assert from "node:assert/strict";
import { createHash, webcrypto } from "node:crypto";
import test from "node:test";

import { BRIDGE_LIMITS, assertBoundedValue, fetchDeclaredArtifact, validateRuntimeManifest } from "../src/index.js";

const bytes = new TextEncoder().encode("bounded-artifact");
const digest = createHash("sha256").update(bytes).digest("hex");

function manifest() {
  return validateRuntimeManifest({
    schema_version: "1.0.0",
    manifest_id: "BX-BH01-PHASE7-SECURITY",
    generation: 1,
    startup: { entrypoint: "Elixir.BlazeX.BH01.BrowserHost.Boot", memory_pages: 256, readiness_event: "popcorn_app_ready", allowed_import_modules: [], required_exports: [], required_features: [] },
    artifacts: [
      { id: "runtime-module", role: "runtime-module", path: "runtime.mjs", mime: "text/javascript", bytes: bytes.byteLength, sha256: digest },
      { id: "runtime-wasm", role: "runtime-wasm", path: "runtime.wasm", mime: "application/wasm", bytes: 8, sha256: createHash("sha256").update(new Uint8Array([0,97,115,109,1,0,0,0])).digest("hex") },
      { id: "bundle", role: "application-bundle", path: "bundle.avm", mime: "application/vnd.atomvm.avm", bytes: bytes.byteLength, sha256: digest },
    ],
  }, "https://example.test/bh01/runtime-manifest.json");
}

test("rejects deterministic hostile bridge families without executing values", () => {
  const hostile = [
    { value: Infinity, code: "bridge-payload-number-invalid" },
    { value: BRIDGE_LIMITS.max_abs_number + 1, code: "bridge-payload-number-invalid" },
    { value: 1n, code: "bridge-payload-type-forbidden" },
    { value: () => "executed", code: "bridge-payload-type-forbidden" },
    { value: { token: "secret" }, code: "bridge-payload-key-forbidden" },
    { value: { constructor: "pollution" }, code: "bridge-payload-key-forbidden" },
    { value: { "ключ": "unicode-key" }, code: "bridge-payload-key-forbidden" },
    { value: "x".repeat(BRIDGE_LIMITS.max_string_bytes + 1), code: "bridge-payload-string-exceeded" },
    { value: Array.from({ length: BRIDGE_LIMITS.max_items + 1 }, () => 0), code: "bridge-payload-items-exceeded" },
    { value: { a: { b: { c: { d: { e: { f: { g: true } } } } } } }, code: "bridge-payload-depth-exceeded" },
  ];
  for (let repeat = 0; repeat < 64; repeat += 1) {
    const entry = hostile[repeat % hostile.length];
    assert.throws(() => assertBoundedValue(entry.value), (error) => error.code === entry.code);
  }
});

test("retains script and HTML payloads only as inert bounded text", () => {
  const text = "<img src=x onerror=globalThis.compromised=true><script>throw 1</script>";
  assert.doesNotThrow(() => assertBoundedValue({ text }));
  assert.equal(globalThis.compromised, undefined);
});

test("rejects traversal, credentials, downgrade, and missing integrity declarations", () => {
  const raw = {
    schema_version: "1.0.0",
    manifest_id: "BX-BH01-SECURITY",
    generation: 1,
    startup: { entrypoint: "Elixir.BlazeX.BH01.BrowserHost.Boot", memory_pages: 256, readiness_event: "popcorn_app_ready", allowed_import_modules: [], required_exports: [], required_features: [] },
    artifacts: [
      { id: "m", role: "runtime-module", path: "https://attacker.invalid/m.js", mime: "text/javascript", bytes: 1, sha256: "0".repeat(64) },
      { id: "w", role: "runtime-wasm", path: "w.wasm", mime: "application/wasm", bytes: 1, sha256: "0".repeat(64) },
      { id: "a", role: "application-bundle", path: "a.avm", mime: "application/vnd.atomvm.avm", bytes: 1, sha256: "0".repeat(64) },
    ],
  };
  assert.throws(() => validateRuntimeManifest(raw, "https://example.test/bh01/m.json"), { code: "artifact-url-forbidden" });
  raw.artifacts[0].path = "https://user:pass@example.test/bh01/m.js";
  assert.throws(() => validateRuntimeManifest(raw, "https://example.test/bh01/m.json"), { code: "artifact-url-forbidden" });
  raw.artifacts[0].path = "http://example.test/bh01/m.js";
  assert.throws(() => validateRuntimeManifest(raw, "https://example.test/bh01/m.json"), { code: "artifact-url-forbidden" });
  raw.artifacts[0].path = "../escaped.js";
  assert.throws(() => validateRuntimeManifest(raw, "https://example.test/bh01/m.json"), { code: "artifact-url-forbidden" });
  raw.artifacts[0].path = "m.js";
  delete raw.artifacts[0].sha256;
  assert.throws(() => validateRuntimeManifest(raw, "https://example.test/bh01/m.json"), { code: "artifact-integrity-declaration-invalid" });
});

test("fails artifact MIME, compression, size, and integrity before returning bytes", async () => {
  const value = manifest();
  const declaration = value.artifacts.find(({ role }) => role === "runtime-module");
  const response = (body, headers = {}, url = declaration.url) => {
    const result = new Response(body, { status: 200, headers });
    Object.defineProperties(result, { url: { value: url }, redirected: { value: false } });
    return result;
  };
  await assert.rejects(fetchDeclaredArtifact(value, "runtime-module", { fetchImpl: async () => response(bytes, { "content-type": "text/html" }), cryptoImpl: webcrypto }), { code: "fetch-mime-invalid" });
  await assert.rejects(fetchDeclaredArtifact(value, "runtime-module", { fetchImpl: async () => response(bytes, { "content-type": "text/javascript", "content-encoding": "gzip" }), cryptoImpl: webcrypto }), { code: "fetch-encoding-forbidden" });
  await assert.rejects(fetchDeclaredArtifact(value, "runtime-module", { fetchImpl: async () => response(new Uint8Array([1]), { "content-type": "text/javascript" }), cryptoImpl: webcrypto }), { code: "artifact-size-mismatch" });
  const modified = new TextEncoder().encode("bounded-artifacx");
  await assert.rejects(fetchDeclaredArtifact(value, "runtime-module", { fetchImpl: async () => response(modified, { "content-type": "text/javascript" }), cryptoImpl: webcrypto }), { code: "artifact-integrity-mismatch" });
});
