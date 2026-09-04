import assert from "node:assert/strict";
import { createHash, webcrypto } from "node:crypto";
import test from "node:test";

import { BrowserRuntimeLoader } from "../src/index.js";

const bytesByRole = {
  "runtime-module": new TextEncoder().encode("export default () => ({})"),
  "runtime-wasm": new Uint8Array([0, 97, 115, 109, 1, 0, 0, 0]),
  "application-bundle": new TextEncoder().encode("AVM-loader"),
};

function fixtureManifest() {
  return {
    schema_version: "1.0.0",
    manifest_id: "BX-BH01-LOADER-TEST",
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
      id: `loader-${index}`,
      role,
      path: `./loader-${index}`,
      mime: role === "runtime-module" ? "text/javascript" : role === "runtime-wasm" ? "application/wasm" : "application/vnd.atomvm.avm",
      bytes: bytes.byteLength,
      sha256: createHash("sha256").update(bytes).digest("hex"),
    })),
  };
}

function response(body, url, mime) {
  const value = new Response(body, { status: 200, headers: { "content-type": mime, "content-length": String(body.byteLength ?? new TextEncoder().encode(body).byteLength) } });
  Object.defineProperties(value, { url: { value: url.href }, redirected: { value: false } });
  return value;
}

test("waits for application readiness and converges resources on stop", async () => {
  const manifest = fixtureManifest();
  const events = [];
  const eventTarget = new EventTarget();
  let stopped = 0;
  const fetchImpl = async (url) => {
    if (url.pathname.endsWith("manifest.json")) {
      const body = JSON.stringify(manifest);
      return response(body, url, "application/json");
    }
    const declaration = manifest.artifacts.find((item) => url.pathname.endsWith(item.path.slice(1)));
    return response(bytesByRole[declaration.role], url, declaration.mime);
  };
  const frameFactory = ({ onEvent }) => ({
    async attach() {},
    start({ generation }) { queueMicrotask(() => onEvent({ protocol: "blazex.runtime.frame/1", type: "application-ready", name: "popcorn_app_ready", generation })); },
    request(request) {
      return Promise.resolve({
        protocol: "blazex.host-bridge/1", type: "response", scenario_id: request.scenario_id,
        generation: request.generation, correlation_id: request.correlation_id, sequence: request.sequence,
        status: "ok", result: request.payload,
      });
    },
    cancel() {},
    stop() { stopped += 1; },
  });
  const loader = new BrowserRuntimeLoader({ onEvent: (event) => events.push(event), frameFactory, eventTarget });
  const activation = await loader.start({
    manifestUrl: "https://example.test/bh01/manifest.json",
    frameUrl: "https://example.test/bh01/runtime-frame.html",
    fetchImpl,
    cryptoImpl: webcrypto,
    timeoutMs: 100,
  });
  assert.equal(loader.lifecycle().state, "ready");
  assert.deepEqual(await activation.bridge.request("runtime.echo", { observed: true }), { observed: true });
  assert.ok(events.some((event) => event.stage === "root-ready"));
  eventTarget.dispatchEvent(new Event("pagehide"));
  loader.stop();
  assert.equal(stopped, 1);
  assert.equal(loader.lifecycle().state, "stopped");
  assert.deepEqual(loader.lifecycle().resources, {});

  const restarted = await loader.start({
    manifestUrl: "https://example.test/bh01/manifest.json",
    frameUrl: "https://example.test/bh01/runtime-frame.html",
    fetchImpl,
    cryptoImpl: webcrypto,
    timeoutMs: 100,
  });
  assert.equal(restarted.generation, 2);
  loader.stop("restart-test");
  assert.equal(stopped, 2);
});

test("contains runtime failure and startup cancellation", async () => {
  const manifest = fixtureManifest();
  const fetchImpl = async (url) => {
    if (url.pathname.endsWith("manifest.json")) return response(JSON.stringify(manifest), url, "application/json");
    const declaration = manifest.artifacts.find((item) => url.pathname.endsWith(item.path.slice(1)));
    return response(bytesByRole[declaration.role], url, declaration.mime);
  };
  const failedLoader = new BrowserRuntimeLoader({
    eventTarget: new EventTarget(),
    frameFactory: ({ onEvent }) => ({
      async attach() {},
      start({ generation }) { queueMicrotask(() => onEvent({ type: "runtime-failed", generation, code: "worker-crash", reason: "test" })); },
      request() {}, cancel() {}, stop() {},
    }),
  });
  await assert.rejects(failedLoader.start({ manifestUrl: "https://example.test/manifest.json", frameUrl: "https://example.test/frame", fetchImpl, cryptoImpl: webcrypto, timeoutMs: 100 }), /test/);
  assert.equal(failedLoader.lifecycle().state, "stopped");
  assert.equal(failedLoader.lifecycle().failure.code, "worker-crash");
  assert.equal(failedLoader.lifecycle().failure.retryable, true);

  const cancelledLoader = new BrowserRuntimeLoader({
    eventTarget: new EventTarget(),
    frameFactory: () => ({ async attach() {}, start() {}, request() {}, cancel() {}, stop() {} }),
  });
  const pending = cancelledLoader.start({ manifestUrl: "https://example.test/manifest.json", frameUrl: "https://example.test/frame", fetchImpl, cryptoImpl: webcrypto, timeoutMs: 100 });
  await new Promise((resolve) => setTimeout(resolve, 0));
  cancelledLoader.stop("test-cancel");
  await assert.rejects(pending, (error) => error.code === "startup-cancelled");
  assert.equal(cancelledLoader.lifecycle().state, "stopped");
});
