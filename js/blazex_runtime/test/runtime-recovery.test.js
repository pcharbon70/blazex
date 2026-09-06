import assert from "node:assert/strict";
import test from "node:test";

import { BlazeXHostError, REQUIRED_COMPATIBILITY, SharedRuntimeRegistry } from "../src/index.js";

function response(request, result = {}, status = "ok") {
  return {
    protocol: request.protocol,
    type: "response",
    scenario_id: request.scenario_id,
    generation: request.generation,
    correlation_id: request.correlation_id,
    sequence: request.sequence,
    status,
    ...(status === "ok" ? { result } : { error: result }),
  };
}

function runtime(handle, records, handler = null) {
  const transport = {
    cancel(envelope) { records.cancels.push({ handle, reason: envelope.reason }); },
    request(request) {
      records.operations.push({ handle, operation: request.operation, root: request.payload.root_id ?? null, payload: request.payload });
      if (handler) return handler(request);
      if (request.operation === "runtime.shutdown") {
        return response(request, { scope_id: request.payload.scope_id, runtime_generation: request.payload.runtime_generation });
      }
      return response(request, { root_id: request.payload.root_id, root_generation: request.payload.root_generation });
    },
  };
  return {
    protocol: "blazex.runtime-ready/1",
    state: "ready",
    attempt_generation: handle,
    manifest_id: `BX-BH03-RECOVERY-${handle}`,
    manifest_generation: 5,
    transport,
    release(reason) { records.releases.push({ handle, reason }); },
  };
}

async function mountedFixture({ replacementHandler = null } = {}) {
  const records = { cancels: [], delays: [], operations: [], releases: [] };
  let starts = 0;
  const registry = new SharedRuntimeRegistry({
    startRuntime: async () => runtime(++starts, records, starts === 2 ? replacementHandler : null),
    wait: async (delay) => { records.delays.push(delay); },
  });
  const scope = await registry.open({ scopeId: "browser-page", compatibility: REQUIRED_COMPATIBILITY, startupOptions: { fixture: "retained" } });
  const roots = scope.roots();
  const [registered, ready, disposed] = await Promise.all([
    roots.register("registered-root"), roots.register("ready-root"), roots.register("disposed-root"),
  ]);
  await ready.mount({ targetId: "first-target", tree: { value: "first" } });
  await ready.update({ value: "retained" });
  await ready.move("second-target");
  await disposed.dispose();
  return { disposed, ready, records, registered, registry, roots, scope, starts: () => starts };
}

test("replaces one lost generation and atomically replays roots through the same handles", async () => {
  const fixture = await mountedFixture();
  const before = fixture.registry.snapshot();
  const recovered = await fixture.registry.reportRuntimeLoss({
    scopeId: "browser-page",
    runtimeGeneration: before.scopes[0].generation,
    reason: "worker-exited",
  });

  assert.strictEqual(recovered, fixture.scope);
  assert.strictEqual(fixture.scope.roots(), fixture.roots);
  assert.equal(fixture.starts(), 2);
  assert.deepEqual(fixture.records.delays, [100]);
  assert.deepEqual(fixture.records.releases, [{ handle: 1, reason: "worker-exited" }]);
  assert.deepEqual(fixture.roots.snapshot().states, {
    "disposed-root": "disposed",
    "ready-root": "ready",
    "registered-root": "registered",
  });
  const replacementOperations = fixture.records.operations.filter(({ handle }) => handle === 2);
  assert.deepEqual(replacementOperations.map(({ root, operation }) => `${root}:${operation}`).sort(), [
    "disposed-root:root.dispose",
    "disposed-root:root.register",
    "ready-root:root.mount",
    "ready-root:root.register",
    "registered-root:root.register",
  ].sort());
  const mount = replacementOperations.find(({ operation }) => operation === "root.mount");
  assert.equal(mount.root, "ready-root");
  assert.equal(mount.payload.target_id, "second-target");
  assert.deepEqual(mount.payload.tree, { value: "retained" });
  assert.equal(fixture.registry.snapshot().scopes[0].generation, 2);
  assert.equal(fixture.registry.snapshot().metrics.recoveries, 1);
});

test("rejects stale loss reports without changing state or starting a replacement", async () => {
  const fixture = await mountedFixture();
  const before = fixture.registry.snapshot();
  await assert.rejects(
    fixture.registry.reportRuntimeLoss({ scopeId: "browser-page", runtimeGeneration: before.scopes[0].generation + 1 }),
    failure("stale-generation", "stale-runtime-loss-report"),
  );
  assert.deepEqual(fixture.registry.snapshot(), before);
  assert.equal(fixture.starts(), 1);
  assert.deepEqual(fixture.records.releases, []);
});

test("releases a replacement and exposes no partial ready state when one root replay fails", async () => {
  const fixture = await mountedFixture({
    replacementHandler(request) {
      if (request.operation === "root.mount" && request.payload.root_id === "ready-root") {
        return response(request, { code: "fixture-replay-failed", message: "replay rejected" }, "error");
      }
      return response(request, { root_id: request.payload.root_id, root_generation: request.payload.root_generation });
    },
  });
  const generation = fixture.registry.snapshot().scopes[0].generation;
  const decision = await fixture.registry.reportRuntimeLoss({ scopeId: "browser-page", runtimeGeneration: generation });

  assert.equal(decision.protocol, "blazex.runtime-fallback/1");
  assert.equal(decision.failure_class, "recovery-exhausted");
  assert.equal(decision.diagnostic.details.reason, "replacement-or-root-replay-failed");
  assert.equal(decision.partial_activation, false);
  assert.deepEqual(fixture.records.releases.map(({ handle }) => handle), [1, 2]);
  assert.equal(fixture.registry.snapshot().scopes[0].state, "fallback");
  assert.notEqual(fixture.roots.snapshot().states["ready-root"], "ready");
  assert.equal(fixture.roots.snapshot().accepting, false);
});

test("allows one replacement only and converges a second active loss to fallback", async () => {
  const fixture = await mountedFixture();
  await fixture.registry.reportRuntimeLoss({ scopeId: "browser-page", runtimeGeneration: 1 });
  const decision = await fixture.registry.reportRuntimeLoss({ scopeId: "browser-page", runtimeGeneration: 2 });
  assert.equal(decision.failure_class, "recovery-exhausted");
  assert.equal(decision.diagnostic.details.reason, "replacement-limit");
  assert.equal(fixture.starts(), 2);
  assert.deepEqual(fixture.records.releases.map(({ handle }) => handle), [1, 2]);
});

test("converges non-retryable loss without replacement", async () => {
  const fixture = await mountedFixture();
  const decision = await fixture.registry.reportRuntimeLoss({
    scopeId: "browser-page",
    runtimeGeneration: 1,
    retryable: false,
  });
  assert.equal(decision.failure_class, "recovery-exhausted");
  assert.equal(decision.diagnostic.details.reason, "non-retryable-loss");
  assert.equal(fixture.starts(), 1);
  assert.deepEqual(fixture.records.releases.map(({ handle }) => handle), [1]);
});

test("isolates recovery to the reported scope", async () => {
  const records = { cancels: [], operations: [], releases: [] };
  let starts = 0;
  const registry = new SharedRuntimeRegistry({
    startRuntime: async () => runtime(++starts, records),
    wait: async () => {},
  });
  const [left, right] = await Promise.all([
    registry.open({ scopeId: "left-page", compatibility: REQUIRED_COMPATIBILITY }),
    registry.open({ scopeId: "right-page", compatibility: REQUIRED_COMPATIBILITY }),
  ]);
  const rightRoot = await right.roots().register("right-root");
  await registry.reportRuntimeLoss({ scopeId: "left-page", runtimeGeneration: left.snapshot().runtime_generation });

  assert.equal(starts, 3);
  assert.equal(right.snapshot().state, "ready");
  assert.equal(rightRoot.snapshot().state, "registered");
  assert.deepEqual(records.releases, [{ handle: 1, reason: "active-generation-runtime-exited" }]);
});

test("converges replacement startup failure without publishing ready", async () => {
  const records = { cancels: [], operations: [], releases: [] };
  let starts = 0;
  const registry = new SharedRuntimeRegistry({
    startRuntime: async () => {
      starts += 1;
      if (starts === 2) throw new Error("replacement fixture failed");
      return runtime(starts, records);
    },
    wait: async () => {},
  });
  const scope = await registry.open({ scopeId: "browser-page", compatibility: REQUIRED_COMPATIBILITY });
  await scope.roots().register("retained-root");
  const decision = await registry.reportRuntimeLoss({ scopeId: "browser-page", runtimeGeneration: 1 });
  assert.equal(decision.failure_class, "recovery-exhausted");
  assert.equal(decision.diagnostic.details.reason, "replacement-or-root-replay-failed");
  assert.equal(registry.snapshot().scopes[0].state, "fallback");
  assert.equal(scope.rootsSnapshot().accepting, false);
});

test("maps closed mismatch, prerequisite, startup, loss, and exhaustion fallback actions", async () => {
  const registry = new SharedRuntimeRegistry();
  const cases = [
    [new BlazeXHostError("identity-mismatch", "bad identity", { token: "secret" }), "deployment-action"],
    [new BlazeXHostError("unsupported-prerequisite", "missing workers"), "static-content"],
    [new BlazeXHostError("runtime-startup", "startup failed"), "user-action"],
    [new BlazeXHostError("runtime-loss", "runtime exited"), "user-action"],
    [new BlazeXHostError("recovery-exhausted", "retry spent"), "user-action"],
  ];
  for (const [error, action] of cases) {
    const decision = registry.fallbackFor({ scopeId: "browser-page", runtimeGeneration: 3, error });
    assert.equal(decision.action, action);
    assert.equal(decision.partial_activation, false);
    assert.equal(decision.presentation, "non-dom-decision-only");
    assert.ok(JSON.stringify(decision).length < 2_048);
    assert.doesNotMatch(JSON.stringify(decision), /secret/);
  }
});

test("openOrFallback returns a bounded decision for mismatch and sticky startup failure", async () => {
  const mismatch = await new SharedRuntimeRegistry().openOrFallback({
    scopeId: "browser-page",
    compatibility: { ...REQUIRED_COMPATIBILITY, renderer: "blazex.renderer/2" },
  });
  assert.equal(mismatch.failure_class, "identity-mismatch");

  const registry = new SharedRuntimeRegistry({ startRuntime: async () => { throw new Error("Authorization: Bearer top-secret /home/person/private.js"); } });
  const startup = await registry.openOrFallback({ scopeId: "browser-page", compatibility: REQUIRED_COMPATIBILITY });
  assert.equal(startup.failure_class, "runtime-startup");
  assert.equal(startup.partial_activation, false);
  assert.doesNotMatch(JSON.stringify(startup), /top-secret|\/home\/person/);
  assert.equal(registry.snapshot().scopes[0].state, "fallback");
});

function failure(code, reason) {
  return (error) => error instanceof BlazeXHostError && error.code === code && error.details.reason === reason;
}
