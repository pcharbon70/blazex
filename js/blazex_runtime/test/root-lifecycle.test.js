import assert from "node:assert/strict";
import test from "node:test";

import { BlazeXHostError, REQUIRED_COMPATIBILITY, SharedRuntimeRegistry } from "../src/index.js";

function response(request, result = {}) {
  return {
    protocol: request.protocol,
    type: "response",
    scenario_id: request.scenario_id,
    generation: request.generation,
    correlation_id: request.correlation_id,
    sequence: request.sequence,
    status: "ok",
    result: {
      root_id: request.payload.root_id,
      root_generation: request.payload.root_generation,
      ...result,
    },
  };
}

function runtime(transport, attempt = 1) {
  return {
    protocol: "blazex.runtime-ready/1",
    state: "ready",
    attempt_generation: attempt,
    manifest_id: `BX-BH03-ROOTS-${attempt}`,
    manifest_generation: 4,
    transport,
    release() { throw new Error("root handles must not release the runtime"); },
  };
}

function transport(handler = (request) => response(request)) {
  return { request: handler, cancel() {} };
}

async function rootsFor(hostTransport = transport()) {
  const registry = new SharedRuntimeRegistry({ startRuntime: async () => runtime(hostTransport) });
  const scope = await registry.open({ scopeId: "browser-page", compatibility: REQUIRED_COMPATIBILITY });
  return { registry, roots: scope.roots(), scope };
}

test("registers, mounts, updates, moves, disposes, and remounts independent roots", async () => {
  const operations = [];
  let starts = 0;
  const registry = new SharedRuntimeRegistry({
    startRuntime: async () => {
      starts += 1;
      return runtime(transport((request) => {
        operations.push({ operation: request.operation, root: request.payload.root_id, generation: request.payload.root_generation });
        return response(request);
      }));
    },
  });
  const scope = await registry.open({ scopeId: "browser-page", compatibility: REQUIRED_COMPATIBILITY });
  const roots = scope.roots();
  assert.strictEqual(scope.roots(), roots);
  const [left, right] = await Promise.all([roots.register("left-root"), roots.register("right-root")]);
  await Promise.all([
    left.mount({ targetId: "left-target", tree: { kind: "text", value: "left" } }),
    right.mount({ targetId: "right-target", tree: { kind: "text", value: "right" } }),
  ]);
  await left.update({ kind: "text", value: "updated" });
  await left.move("left-target-next");
  await left.dispose();
  const disposedGeneration = left.snapshot().root_generation;
  await left.dispose();
  assert.equal(left.snapshot().root_generation, disposedGeneration);
  assert.equal(right.snapshot().state, "ready");
  await left.mount({ targetId: "left-target", tree: { kind: "text", value: "remounted" } });
  assert.equal(left.snapshot().state, "ready");
  assert.equal(right.snapshot().state, "ready");
  assert.equal(starts, 1);
  assert.deepEqual(operations.filter(({ root }) => root === "left-root").map(({ operation }) => operation), [
    "root.register", "root.mount", "root.update", "root.move", "root.dispose", "root.mount",
  ]);
  assert.deepEqual(roots.snapshot().states, { "left-root": "ready", "right-root": "ready" });
  assert.equal(roots.snapshot().owns_runtime_release, false);
});

test("serializes each root queue while another root continues", async () => {
  let releaseLeftMount;
  const leftMount = new Promise((resolve) => { releaseLeftMount = resolve; });
  const dispatched = [];
  const { roots } = await rootsFor(transport(async (request) => {
    dispatched.push(`${request.payload.root_id}:${request.operation}`);
    if (request.payload.root_id === "left-root" && request.operation === "root.mount") await leftMount;
    return response(request);
  }));
  const [left, right] = await Promise.all([roots.register("left-root"), roots.register("right-root")]);
  const blockedMount = left.mount({ targetId: "left-target", tree: { value: "left" } });
  const queuedUpdate = left.update({ value: "queued" });
  await new Promise((resolve) => setTimeout(resolve, 0));
  assert.ok(dispatched.includes("left-root:root.mount"));
  assert.ok(!dispatched.includes("left-root:root.update"));
  await right.mount({ targetId: "right-target", tree: { value: "right" } });
  assert.equal(right.snapshot().state, "ready");
  releaseLeftMount();
  await Promise.all([blockedMount, queuedUpdate]);
  assert.deepEqual(dispatched.filter((entry) => entry.startsWith("left-root:")), [
    "left-root:root.register", "left-root:root.mount", "left-root:root.update",
  ]);
});

test("rejects duplicates while registration is reserved and after disposal", async () => {
  let releaseRegistration;
  const registration = new Promise((resolve) => { releaseRegistration = resolve; });
  const { roots } = await rootsFor(transport(async (request) => {
    if (request.operation === "root.register") await registration;
    return response(request);
  }));
  const first = roots.register("reserved-root");
  await assert.rejects(roots.register("reserved-root"), failure("duplicate-root", "existing-or-reserved-root-id"));
  releaseRegistration();
  const handle = await first;
  await handle.dispose();
  await assert.rejects(roots.register("reserved-root"), failure("duplicate-root", "existing-or-reserved-root-id"));
});

test("rejects stale and foreign acknowledgements without mutating another root", async () => {
  const { roots } = await rootsFor(transport((request) => {
    if (request.payload.root_id === "stale-root" && request.operation === "root.mount") {
      return response(request, { root_generation: request.payload.root_generation - 1 });
    }
    if (request.payload.root_id === "foreign-root" && request.operation === "root.mount") {
      return response(request, { root_id: "other-root" });
    }
    return response(request);
  }));
  const [healthy, stale, foreign] = await Promise.all([
    roots.register("healthy-root"), roots.register("stale-root"), roots.register("foreign-root"),
  ]);
  await healthy.mount({ targetId: "healthy-target", tree: { value: "healthy" } });
  await assert.rejects(stale.mount({ targetId: "stale-target", tree: { value: "stale" } }), failure("stale-generation", "wrong-root-generation"));
  await assert.rejects(foreign.mount({ targetId: "foreign-target", tree: { value: "foreign" } }), failure("ownership-violation", "foreign-root-acknowledgement"));
  assert.equal(healthy.snapshot().state, "ready");
  assert.equal(healthy.snapshot().root_generation, 2);
  assert.equal(stale.snapshot().state, "failed");
  assert.equal(foreign.snapshot().state, "failed");
});

test("rejects illegal transitions without consuming a generation", async () => {
  const { roots } = await rootsFor();
  const root = await roots.register("lifecycle-root");
  const generation = root.snapshot().root_generation;
  await assert.rejects(root.update({ value: "not-mounted" }), failure("root-lifecycle", "illegal-transition"));
  assert.equal(root.snapshot().state, "registered");
  assert.equal(root.snapshot().root_generation, generation);
});

test("bounds root identities and root count", async () => {
  const { roots } = await rootsFor();
  assert.throws(() => roots.register("Invalid Root"), failure("root-lifecycle", "invalid-root-or-target-id"));
  for (let index = 0; index < 64; index += 1) await roots.register(`root-${index}`);
  await assert.rejects(roots.register("root-overflow"), failure("root-lifecycle", "root-limit"));
  assert.equal(roots.snapshot().root_count, 64);
});

function failure(code, reason) {
  return (error) => error instanceof BlazeXHostError && error.code === code && error.details.reason === reason;
}
