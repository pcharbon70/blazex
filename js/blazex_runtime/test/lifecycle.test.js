import assert from "node:assert/strict";
import test from "node:test";

import { BlazeXHostError, BrowserRuntimeLifecycle, classifyLifecycleFailure } from "../src/index.js";

test("follows the monotonic activation state machine", () => {
  const transitions = [];
  const lifecycle = new BrowserRuntimeLifecycle({ onTransition: (event) => transitions.push(event), clock: () => 42 });
  assert.equal(lifecycle.begin(), 1);
  for (const state of ["fetching", "instantiating", "loading", "starting", "ready"]) lifecycle.transition(state);
  assert.equal(lifecycle.snapshot().state, "ready");
  assert.deepEqual(transitions.map((event) => event.to), ["checking", "fetching", "instantiating", "loading", "starting", "ready"]);
  assert.throws(() => lifecycle.transition("fetching"), (error) => error instanceof BlazeXHostError && error.code === "lifecycle-transition-illegal");
});

test("releases owned resources in reverse order and makes stop idempotent", () => {
  const released = [];
  const lifecycle = new BrowserRuntimeLifecycle();
  lifecycle.begin();
  lifecycle.own("listener", () => released.push("listener"));
  lifecycle.own("worker", () => released.push("worker"));
  lifecycle.stop("test");
  lifecycle.stop("duplicate");
  assert.deepEqual(released, ["worker", "listener"]);
  assert.equal(lifecycle.snapshot().state, "stopped");
  assert.deepEqual(lifecycle.snapshot().resources, {});
});

test("classifies retry, integrity, attempt limits, and stale generations", () => {
  assert.equal(classifyLifecycleFailure(Object.assign(new Error("network"), { code: "fetch-failed" }), 1).retryable, true);
  assert.equal(classifyLifecycleFailure(Object.assign(new Error("digest"), { code: "artifact-integrity-mismatch" }), 1).retryable, false);
  assert.equal(classifyLifecycleFailure(Object.assign(new Error("network"), { code: "fetch-failed" }), 2).retryable, false);
  const lifecycle = new BrowserRuntimeLifecycle();
  const generation = lifecycle.begin();
  assert.equal(lifecycle.acceptGeneration(generation), true);
  assert.equal(lifecycle.acceptGeneration(generation + 1), false);
  lifecycle.transition("fetching");
  lifecycle.fail(Object.assign(new Error("network"), { code: "fetch-failed" }));
  assert.equal(lifecycle.canRetry(), true);
  assert.equal(lifecycle.retryDelayMs(), 250);
  lifecycle.stop();
  assert.equal(lifecycle.begin(), 2);
});
