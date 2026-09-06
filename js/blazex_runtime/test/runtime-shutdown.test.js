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

function fixture({ handle, operations, releases, shutdownResult, shutdownPending = false }) {
  const transport = {
    cancel(envelope) { operations.push(`cancel:${envelope.reason}`); },
    request(request) {
      operations.push(request.operation);
      if (request.operation === "runtime.shutdown") {
        if (shutdownPending) return new Promise(() => {});
        const result = shutdownResult?.(request) ?? {
          scope_id: request.payload.scope_id,
          runtime_generation: request.payload.runtime_generation,
        };
        return response(request, result);
      }
      return response(request, {
        root_id: request.payload.root_id,
        root_generation: request.payload.root_generation,
      });
    },
  };
  return {
    protocol: "blazex.runtime-ready/1",
    state: "ready",
    attempt_generation: 1,
    manifest_id: "BX-BH03-SHUTDOWN",
    manifest_generation: 5,
    transport,
    release(reason) {
      releases.push({ handle, reason });
      operations.push("runtime.release");
    },
  };
}

async function opened(options = {}) {
  const operations = [];
  const releases = [];
  const runtime = fixture({ handle: "initial", operations, releases, ...options });
  const registry = new SharedRuntimeRegistry({ startRuntime: async () => runtime });
  const scope = await registry.open({ scopeId: "browser-page", compatibility: REQUIRED_COMPATIBILITY });
  return { operations, registry, releases, scope };
}

test("drains independent roots before an acknowledged registry-owned shutdown", async () => {
  const { operations, registry, releases, scope } = await opened();
  const roots = scope.roots();
  const [left, right] = await Promise.all([roots.register("left-root"), roots.register("right-root")]);
  await Promise.all([
    left.mount({ targetId: "left-target", tree: { value: "left" } }),
    right.mount({ targetId: "right-target", tree: { value: "right" } }),
  ]);

  const closing = registry.close("browser-page", { reason: "page-unload" });
  assert.strictEqual(registry.close("browser-page", { reason: "duplicate" }), closing);
  const stopped = await closing;

  assert.deepEqual(stopped, {
    protocol: "blazex.runtime-shutdown/1",
    scope_id: "browser-page",
    runtime_generation: 1,
    state: "stopped",
    acknowledged: true,
    root_failures: 0,
    released: true,
  });
  assert.equal(operations.filter((operation) => operation === "root.dispose").length, 2);
  assert.ok(operations.lastIndexOf("root.dispose") < operations.indexOf("runtime.shutdown"));
  assert.ok(operations.indexOf("runtime.shutdown") < operations.indexOf("runtime.release"));
  assert.equal(releases.length, 1);
  assert.strictEqual(await registry.close("browser-page"), stopped);
  assert.equal(releases.length, 1);
  assert.equal(registry.snapshot().scopes[0].state, "stopped");
  assert.equal(roots.snapshot().accepting, false);
  await assert.rejects(roots.register("late-root"), failure("root-lifecycle", "scope-not-ready"));
  await assert.rejects(left.mount({ targetId: "late-target", tree: {} }), failure("root-lifecycle", "scope-stopped"));
  assert.throws(() => scope.roots(), failure("root-lifecycle", "scope-not-ready"));
  assert.deepEqual(Object.getOwnPropertySymbols(Object.getPrototypeOf(scope)), []);
});

test("force releases and retains a stopped tombstone after shutdown timeout", async () => {
  const { registry, releases, scope } = await opened({ shutdownPending: true });
  const root = await scope.roots().register("timeout-root");
  await root.mount({ targetId: "timeout-target", tree: {} });
  await assert.rejects(registry.close("browser-page", { timeoutMs: 10 }), failure("shutdown-timeout", "root-drain-or-runtime-ack-timeout"));
  assert.equal(releases.length, 1);
  assert.equal(registry.snapshot().scopes[0].state, "stopped");
  assert.equal(registry.snapshot().metrics.shutdown_failures, 1);
  assert.equal(root.snapshot().state, "disposed");
  const tombstone = await registry.close("browser-page");
  assert.equal(tombstone.acknowledged, false);
  assert.equal(releases.length, 1);
});

test("classifies foreign and stale shutdown acknowledgements and still releases once", async () => {
  for (const scenario of [
    {
      result: (request) => ({ scope_id: "foreign-page", runtime_generation: request.payload.runtime_generation }),
      expected: failure("ownership-violation", "foreign-shutdown-acknowledgement"),
    },
    {
      result: (request) => ({ scope_id: request.payload.scope_id, runtime_generation: request.payload.runtime_generation - 1 }),
      expected: failure("stale-generation", "stale-shutdown-acknowledgement"),
    },
  ]) {
    const { registry, releases } = await opened({ shutdownResult: scenario.result });
    await assert.rejects(registry.close("browser-page"), scenario.expected);
    assert.equal(releases.length, 1);
    assert.equal(registry.snapshot().scopes[0].state, "stopped");
  }
});

test("rejects unknown scopes and shutdown timeouts outside the governed range", async () => {
  const registry = new SharedRuntimeRegistry();
  await assert.rejects(registry.close("missing-scope"), failure("runtime-shutdown", "scope-unknown"));
  assert.throws(() => registry.close("missing-scope", { timeoutMs: 0 }), failure("runtime-shutdown", "timeout-invalid"));
  assert.throws(() => registry.close("missing-scope", { timeoutMs: 10_001 }), failure("runtime-shutdown", "timeout-invalid"));
});

function failure(code, reason) {
  return (error) => error instanceof BlazeXHostError && error.code === code && error.details.reason === reason;
}
