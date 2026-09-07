import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { webcrypto } from "node:crypto";
import {
  BrowserRuntimeStartup, REQUIRED_COMPATIBILITY, SharedRuntimeRegistry,
  validateHostManifest,
} from "../src/index.js";

const fixtures = JSON.parse(await readFile(new URL("../../../integration/bh-03/phase-03/startup-fixtures-v0.1.0.json", import.meta.url)));
const mime = ["text/javascript", "application/wasm", "application/vnd.atomvm.avm"];
const manifest = validateHostManifest({
  schema_version: "1.0.0", manifest_id: "BX-BH03-PHASE-09-LOSS-PROBE",
  generation: 9, profile_id: "acceptance-probe",
  compatibility: REQUIRED_COMPATIBILITY,
  prerequisites: {
    browser_required: ["webassembly", "workers", "module-scripts", "fetch", "abort-controller", "subtle-crypto"],
    deployment_required: ["secure-context", "cross-origin-isolation", "same-origin-artifacts"],
    optional: ["wasm-streaming"],
  },
  artifacts: fixtures.artifact_payloads.map((item, index) => ({
    id: `probe-${index}`, role: item.role, path: `./artifact-${index}`,
    mime: mime[index], bytes: item.bytes, sha256: item.sha256,
  })),
}, "https://example.test/bh03/manifest.json");
const gate = { protocol: "blazex.pre-acquisition-gate/1", decision: "eligible-for-artifact-acquisition", manifest };
import test from "node:test";

function fixture({ lossBeforeReturn = 0, lossDuringReplay = false, exitOnStop = false } = {}) {
  const runtimes = [];
  const registry = new SharedRuntimeRegistry({
    wait: async () => {},
    startRuntime: async (options) => {
      const record = { stops: 0, operations: [], emit: null };
      runtimes.push(record);
      const startup = record.startup = new BrowserRuntimeStartup({
        frameFactory: ({ onEvent }) => ({
          async attach() {},
          start(message) {
            record.emit = (type, overrides = {}) => onEvent({
              protocol: "blazex.runtime.frame/1", generation: message.generation,
              manifest_generation: message.manifest.generation, type, ...overrides,
            });
            queueMicrotask(() => record.emit("application-ready", { name: "popcorn_app_ready" }));
          },
          request(request) {
            record.operations.push(request);
            if (lossDuringReplay && runtimes.length === 2 && request.operation === "root.mount") {
              record.emit("runtime-failed", { code: "runtime-abort" });
            }
            return {
              protocol: request.protocol, type: "response", status: "ok",
              scenario_id: request.scenario_id, generation: request.generation,
              correlation_id: request.correlation_id, sequence: request.sequence,
              result: request.payload,
            };
          },
          cancel() {},
          stop() {
            record.stops += 1;
            if (exitOnStop) record.emit("runtime-exited", { status: 0 });
          },
        }),
      });
      const ready = await startup.start(options);
      record.ready = ready;
      if (runtimes.length === lossBeforeReturn) record.emit("runtime-exited", { status: 1 });
      return ready;
    },
  });
  const open = {
    scopeId: "page-runtime", compatibility: REQUIRED_COMPATIBILITY,
    startupOptions: {
      gate, frameUrl: "https://example.test/frame.html", cryptoImpl: webcrypto,
      fetchImpl: async (url) => {
        const index = manifest.artifacts.findIndex((item) => item.url === url.href);
        return new Response(Buffer.from(fixtures.artifact_payloads[index].base64, "base64"), {
          headers: { "content-type": mime[index] },
        });
      },
    },
  };
  return { registry, open, runtimes };
}

async function settle(f) {
  // Observe the registry's existing recovery promise through its public open API.
  return f.registry.openOrFallback(f.open);
}

for (const type of ["runtime-exited", "runtime-failed"]) {
  test(type + " automatically recovers real startup and replays the same root handle", async () => {
    const f = fixture();
    const scope = await f.registry.open(f.open);
    const root = await scope.roots().register("root");
    await root.mount({ targetId: "target", tree: { text: "retained" } });
    f.runtimes[0].emit(type, { status: 1, code: "runtime-abort" });
    assert.equal(scope.snapshot().state, "recovering");
    assert.throws(() => scope.roots());
    assert.strictEqual(await settle(f), scope);
    assert.equal(root.snapshot().state, "ready");
    assert.equal(f.runtimes.length, 2);
    assert.equal(f.runtimes[0].stops, 1);
    assert.deepEqual(f.runtimes[1].operations.map(x => x.operation), ["root.register", "root.mount"]);
    assert.deepEqual(f.runtimes[1].operations[1].payload.tree, { text: "retained" });
    const before = f.registry.snapshot();
    f.runtimes[0].emit(type, { status: 1 });
    f.runtimes[1].emit(type, { generation: 999 });
    f.runtimes[1].emit(type, { manifest_generation: 999 });
    assert.deepEqual(f.registry.snapshot(), before);
    f.runtimes[1].emit(type, { status: 1 });
    const fallback = await settle(f);
    assert.equal(fallback.decision, "fallback");
    assert.equal(fallback.partial_activation, false);
    assert.equal(f.registry.snapshot().scopes[0].state, "fallback");
    assert.equal(f.registry.snapshot().metrics.losses, 2);
    assert.equal(f.runtimes.length, 2);
    assert.deepEqual(f.runtimes.map(r => r.stops), [1, 1]);
    assert.equal(scope.rootsSnapshot().accepting, false);
    await assert.rejects(root.update({ text: "forbidden" }));
  });
}

test("loss latched before first subscription never publishes ready", async () => {
  const f = fixture({ lossBeforeReturn: 1 });
  await assert.rejects(f.registry.open(f.open), error => error.code === "runtime-loss");
  assert.equal(f.registry.snapshot().scopes[0].state, "failed");
  assert.equal(f.runtimes[0].stops, 1);
});

test("loss before replacement subscription converges to fallback", async () => {
  const f = fixture({ lossBeforeReturn: 2 });
  await f.registry.open(f.open);
  f.runtimes[0].emit("runtime-exited");
  assert.equal((await settle(f)).decision, "fallback");
  assert.deepEqual(f.runtimes.map(r => r.stops), [1, 1]);
});

test("loss during replay cannot publish a ready replacement", async () => {
  const f = fixture({ lossDuringReplay: true });
  const scope = await f.registry.open(f.open);
  const root = await scope.roots().register("root");
  await root.mount({ targetId: "target", tree: {} });
  f.runtimes[0].emit("runtime-exited");
  assert.equal((await settle(f)).decision, "fallback");
  assert.notEqual(root.snapshot().state, "ready");
  assert.equal(scope.rootsSnapshot().accepting, false);
  assert.deepEqual(f.runtimes.map(r => r.stops), [1, 1]);
});

test("intentional stop ignores synchronous exit and later callbacks", async () => {
  const f = fixture({ exitOnStop: true });
  await f.registry.open(f.open);
  await f.registry.close(f.open.scopeId);
  f.runtimes[0].emit("runtime-exited");
  assert.equal(f.registry.snapshot().scopes[0].state, "stopped");
  assert.equal(f.registry.snapshot().metrics.losses, 0);
  assert.equal(f.runtimes.length, 1);
});

test("close during automatic recovery prevents subsequent opens and converges", async () => {
  const f = fixture();
  await f.registry.open(f.open);
  f.runtimes[0].emit("runtime-exited");
  const closed = f.registry.close(f.open.scopeId);
  await assert.rejects(f.registry.open(f.open), error => error.code === "runtime-shutdown");
  await closed;
  assert.equal(f.registry.snapshot().scopes[0].state, "stopped");
  assert.deepEqual(f.runtimes.map(r => r.stops), [1, 1]);
});
