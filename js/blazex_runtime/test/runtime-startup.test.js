import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { webcrypto } from "node:crypto";
import test from "node:test";

import { BH03_RUNTIME_STARTUP, BlazeXHostError, BrowserRuntimeStartup, validateHostManifest } from "../src/index.js";

const fixtureUrl = new URL("../../../integration/bh-03/phase-03/startup-fixtures-v0.1.0.json", import.meta.url);
const fixtures = JSON.parse(await readFile(fixtureUrl, "utf8"));
const payloads = Object.fromEntries(fixtures.artifact_payloads.map((item) => [item.role, new Uint8Array(Buffer.from(item.base64, "base64"))]));

function gate() {
  const mime = {
    "runtime-module": "text/javascript",
    "runtime-wasm": "application/wasm",
    "application-bundle": "application/vnd.atomvm.avm",
  };
  const raw = {
    schema_version: "1.0.0",
    manifest_id: "BX-BH03-PHASE-03-STARTUP-TEST",
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
    artifacts: fixtures.artifact_payloads.map((artifact, index) => ({
      id: `startup-${index}`,
      role: artifact.role,
      path: `./artifact-${index}`,
      mime: mime[artifact.role],
      bytes: artifact.bytes,
      sha256: artifact.sha256,
    })),
  };
  return {
    protocol: "blazex.pre-acquisition-gate/1",
    decision: "eligible-for-artifact-acquisition",
    manifest: validateHostManifest(raw, "https://example.test/bh03/manifest.json"),
  };
}

function fetchFor(accepted) {
  return async (url) => {
    const declaration = accepted.manifest.artifacts.find((item) => item.url === url.href);
    const bytes = payloads[declaration.role];
    const response = new Response(bytes, { status: 200, headers: { "content-type": declaration.mime, "content-length": String(bytes.byteLength) } });
    Object.defineProperties(response, { url: { value: declaration.url }, redirected: { value: false } });
    return response;
  };
}

function frameFactory(behavior, record = {}) {
  return ({ onEvent }) => ({
    async attach(signal) {
      record.signal = signal;
      if (behavior === "attach-failure") throw new Error("fixture attach failure");
    },
    start(message) {
      record.message = message;
      record.emit = onEvent;
      record.onStart?.();
      const base = {
        protocol: "blazex.runtime.frame/1",
        generation: message.generation,
        manifest_generation: message.manifest.generation,
      };
      if (behavior === "ready") queueMicrotask(() => {
        onEvent({ ...base, type: "runtime-memory", memory_pages: 256 });
        onEvent({ ...base, type: "application-ready", name: "popcorn_app_ready" });
      });
      if (behavior === "stale-then-ready") {
        queueMicrotask(() => onEvent({ ...base, generation: message.generation + 1, type: "application-ready", name: "popcorn_app_ready" }));
        queueMicrotask(() => onEvent({ ...base, type: "application-ready", name: "popcorn_app_ready" }));
      }
      if (behavior === "duplicate-ready") queueMicrotask(() => {
        onEvent({ ...base, type: "application-ready", name: "popcorn_app_ready" });
        onEvent({ ...base, type: "application-ready", name: "popcorn_app_ready" });
      });
      if (behavior === "runtime-failure") queueMicrotask(() => onEvent({ ...base, type: "runtime-failed", code: "engine-abort" }));
      if (behavior === "bundle-failure") queueMicrotask(() => onEvent({ ...base, type: "runtime-failed", code: "bundle-load-failed" }));
    },
    stop(reason) {
      record.stops = (record.stops ?? 0) + 1;
      record.stopReason = reason;
    },
  });
}

test("starts one isolated attempt, loads the bundle contract, and waits for correlated readiness", async () => {
  const accepted = gate();
  const record = {};
  const events = [];
  const startup = new BrowserRuntimeStartup({ frameFactory: frameFactory("ready", record), onEvent: (event) => events.push(event) });
  const ready = await startup.start({ gate: accepted, frameUrl: "https://example.test/bh03/frame.html", fetchImpl: fetchFor(accepted), cryptoImpl: webcrypto, timeoutMs: 100 });
  assert.equal(ready.protocol, "blazex.runtime-ready/1");
  assert.equal(ready.attempt_generation, 1);
  assert.equal(ready.manifest_generation, 3);
  assert.equal(ready.runtime_memory_pages, 256);
  assert.deepEqual(ready.startup, fixtures.startup_descriptor);
  assert.equal(record.message.manifest.startup.bundle_virtual_path, "/bundle.avm");
  assert.deepEqual(Object.keys(record.message.artifacts), ["runtime-module", "runtime-wasm", "application-bundle"]);
  assert.equal(startup.snapshot().state, "ready");
  assert.ok(events.some((event) => event.stage === "acquiring"));
  assert.ok(events.some((event) => event.stage === "ready"));
  assert.ok(events.some((event) => event.details?.memory_pages === 256));
  assert.equal(ready.release().state, "stopped");
  assert.equal(record.stops, 1);
  assert.equal(startup.snapshot().owns_transport, false);
});

test("rejects stale readiness but accepts the correlated event", async () => {
  const accepted = gate();
  const events = [];
  const startup = new BrowserRuntimeStartup({ frameFactory: frameFactory("stale-then-ready"), onEvent: (event) => events.push(event) });
  const ready = await startup.start({ gate: accepted, frameUrl: "https://example.test/frame", fetchImpl: fetchFor(accepted), cryptoImpl: webcrypto, timeoutMs: 100 });
  assert.ok(events.some((event) => event.stage === "stale-event-rejected"));
  ready.release();
});

test("contains duplicate readiness after success and releases the transport", async () => {
  const accepted = gate();
  const record = {};
  const startup = new BrowserRuntimeStartup({ frameFactory: frameFactory("ready", record) });
  const ready = await startup.start({ gate: accepted, frameUrl: "https://example.test/frame", fetchImpl: fetchFor(accepted), cryptoImpl: webcrypto, timeoutMs: 100 });
  record.emit({ protocol: "blazex.runtime.frame/1", generation: 1, manifest_generation: 3, type: "application-ready", name: "popcorn_app_ready" });
  assert.equal(startup.snapshot().state, "failed");
  assert.equal(startup.snapshot().failure.code, "runtime-startup");
  assert.equal(record.stops, 1);
  assert.equal(ready.release().state, "stopped");
});

test("classifies transport, runtime, bundle, timeout, and cancellation failures and cleans up", async () => {
  for (const scenario of [
    { behavior: "attach-failure", code: "runtime-startup", reason: "transport-attach" },
    { behavior: "runtime-failure", code: "runtime-startup", reason: "runtime-failed" },
    { behavior: "bundle-failure", code: "bundle-load", reason: "bundle-load-failed" },
    { behavior: "duplicate-ready", code: "runtime-startup", reason: "protocol-mismatch" },
    { behavior: "silent", code: "readiness-timeout", reason: "readiness-timeout" },
  ]) {
    const accepted = gate();
    const record = {};
    const startup = new BrowserRuntimeStartup({ frameFactory: frameFactory(scenario.behavior, record) });
    await assert.rejects(
      startup.start({ gate: accepted, frameUrl: "https://example.test/frame", fetchImpl: fetchFor(accepted), cryptoImpl: webcrypto, timeoutMs: scenario.behavior === "silent" ? 100 : 1_000 }),
      failure(scenario.code, scenario.reason),
      scenario.behavior,
    );
    assert.equal(startup.snapshot().state, "failed");
    assert.equal(startup.snapshot().owns_transport, false);
    if (scenario.behavior !== "attach-failure") assert.equal(record.stops, 1);
  }

  const accepted = gate();
  const record = {};
  let markStarted;
  const started = new Promise((resolve) => { markStarted = resolve; });
  record.onStart = markStarted;
  const controller = new AbortController();
  const startup = new BrowserRuntimeStartup({ frameFactory: frameFactory("silent", record) });
  const pending = startup.start({ gate: accepted, frameUrl: "https://example.test/frame", fetchImpl: fetchFor(accepted), cryptoImpl: webcrypto, signal: controller.signal, timeoutMs: 1_000 });
  await started;
  controller.abort();
  await assert.rejects(pending, failure("runtime-startup", "startup-cancelled"));
  assert.equal(record.stops, 1);
});

function failure(code, reason) {
  return (error) => error instanceof BlazeXHostError && error.code === code && error.details.reason === reason;
}
