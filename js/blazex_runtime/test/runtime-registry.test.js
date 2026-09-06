import assert from "node:assert/strict";
import test from "node:test";

import { BlazeXHostError, REQUIRED_COMPATIBILITY, SharedRuntimeRegistry } from "../src/index.js";

function ready(attempt = 1) {
  return {
    protocol: "blazex.runtime-ready/1",
    state: "ready",
    attempt_generation: attempt,
    manifest_id: `BX-BH03-REGISTRY-${attempt}`,
    manifest_generation: 4,
    transport: { request() {}, cancel() {} },
    release() { throw new Error("roots and scopes must not release the runtime"); },
  };
}

test("coalesces concurrent startup and reuses one ready scope", async () => {
  let starts = 0;
  let resolveStart;
  const pendingStart = new Promise((resolve) => { resolveStart = resolve; });
  const events = [];
  const registry = new SharedRuntimeRegistry({
    startRuntime: async () => { starts += 1; return pendingStart; },
    onEvent: (event) => events.push(event),
  });
  const first = registry.open({ scopeId: "browser-page", compatibility: REQUIRED_COMPATIBILITY });
  const second = registry.open({ scopeId: "browser-page", compatibility: REQUIRED_COMPATIBILITY });
  await new Promise((resolve) => setTimeout(resolve, 0));
  assert.equal(starts, 1);
  resolveStart(ready());
  const [left, right] = await Promise.all([first, second]);
  assert.strictEqual(left, right);
  assert.strictEqual(await registry.open({ scopeId: "browser-page", compatibility: REQUIRED_COMPATIBILITY }), left);
  assert.deepEqual(registry.snapshot().metrics, { starts: 1, shares: 2, failures: 0, mismatches: 0, shutdowns: 0, shutdown_failures: 0, losses: 0, recoveries: 0, recovery_failures: 0, fallbacks: 0, scope_count: 1 });
  assert.ok(events.some((event) => event.stage === "scope-starting"));
  assert.ok(events.some((event) => event.stage === "scope-ready"));
  assert.equal(left.snapshot().owns_runtime_release, false);
});

test("starts different compatible host scopes independently", async () => {
  let starts = 0;
  const registry = new SharedRuntimeRegistry({ startRuntime: async () => ready(++starts) });
  const [left, right] = await Promise.all([
    registry.open({ scopeId: "primary-page", compatibility: REQUIRED_COMPATIBILITY }),
    registry.open({ scopeId: "preview-page", compatibility: REQUIRED_COMPATIBILITY }),
  ]);
  assert.notStrictEqual(left, right);
  assert.equal(starts, 2);
  assert.deepEqual(registry.snapshot().scopes.map((scope) => scope.scope_id), ["preview-page", "primary-page"]);
});

test("rejects incompatible reuse before another startup", async () => {
  let starts = 0;
  const registry = new SharedRuntimeRegistry({ startRuntime: async () => ready(++starts) });
  await registry.open({ scopeId: "browser-page", compatibility: REQUIRED_COMPATIBILITY });
  const incompatible = { ...REQUIRED_COMPATIBILITY, renderer: "blazex.renderer/2" };
  await assert.rejects(
    registry.open({ scopeId: "browser-page", compatibility: incompatible }),
    (error) => error instanceof BlazeXHostError && error.code === "identity-mismatch",
  );
  assert.equal(starts, 1);
  assert.equal(registry.snapshot().metrics.mismatches, 1);
});

test("retains a failed scope tombstone without retry", async () => {
  let starts = 0;
  const registry = new SharedRuntimeRegistry({ startRuntime: async () => { starts += 1; throw new Error("fixture failure"); } });
  await assert.rejects(registry.open({ scopeId: "failed-page", compatibility: REQUIRED_COMPATIBILITY }), failure("runtime-startup", "startup-failed"));
  await assert.rejects(registry.open({ scopeId: "failed-page", compatibility: REQUIRED_COMPATIBILITY }), failure("runtime-startup", "startup-failed"));
  assert.equal(starts, 1);
  assert.equal(registry.snapshot().scopes[0].state, "failed");
  assert.deepEqual(registry.snapshot().metrics, { starts: 1, shares: 1, failures: 1, mismatches: 0, shutdowns: 0, shutdown_failures: 0, losses: 0, recoveries: 0, recovery_failures: 0, fallbacks: 0, scope_count: 1 });
});

test("bounds scope identifiers and registry size", async () => {
  const registry = new SharedRuntimeRegistry({ startRuntime: async () => ready() });
  await assert.rejects(registry.open({ scopeId: "Invalid Scope", compatibility: REQUIRED_COMPATIBILITY }), failure("identity-mismatch", "scope-id-invalid"));
  for (let index = 0; index < 16; index += 1) {
    await registry.open({ scopeId: `scope-${index}`, compatibility: REQUIRED_COMPATIBILITY });
  }
  await assert.rejects(registry.open({ scopeId: "scope-overflow", compatibility: REQUIRED_COMPATIBILITY }), failure("identity-mismatch", "scope-limit"));
});

function failure(code, reason) {
  return (error) => error instanceof BlazeXHostError && error.code === code && error.details.reason === reason;
}
