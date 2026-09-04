import assert from "node:assert/strict";
import test from "node:test";

import { BrowserRecoveryCoordinator } from "../src/index.js";

test("coordinates one authority-bearing retry under the browser owner", async () => {
  const trace = [];
  const coordinator = new BrowserRecoveryCoordinator({ scenarioId: "phase7", generation: 1, onTrace: (event) => trace.push(event) });
  const result = await coordinator.run({
    failureId: "transport-unavailable",
    correlationId: "command-1",
    retryable: true,
    authorityBearing: true,
    operation: async ({ attempt, delayMs }) => ({ attempt, delayMs, idempotencyKey: "original-key" }),
  });
  assert.equal(result.state, "stable");
  assert.equal(result.attempt, 1);
  assert.equal(result.value.idempotencyKey, "original-key");
  assert.deepEqual(trace.map((event) => event.kind), ["attempt", "stable"]);
  assert.equal(coordinator.snapshot().pending, 0);
});

test("prohibits a lower-layer authority retry", async () => {
  const coordinator = new BrowserRecoveryCoordinator({ scenarioId: "phase7", generation: 1 });
  await assert.rejects(coordinator.run({
    failureId: "transport-unavailable",
    correlationId: "command-2",
    retryable: true,
    authorityBearing: true,
    requester: "transport",
    operation: async () => null,
  }), { code: "recovery-owner-forbidden" });
});

test("bounds exhaustion without starting a third operation", async () => {
  const coordinator = new BrowserRecoveryCoordinator({ scenarioId: "phase7", generation: 1 });
  let executions = 0;
  const request = () => coordinator.run({
    failureId: "runtime-crashed",
    correlationId: "runtime-1",
    retryable: true,
    operation: async () => { executions += 1; throw new Error("controlled"); },
  });
  assert.equal((await request()).state, "failed");
  assert.equal((await request()).state, "exhausted");
  const final = await request();
  assert.equal(final.state, "exhausted");
  assert.equal(final.attempted, false);
  assert.equal(executions, 2);
  assert.equal(coordinator.snapshot().pending, 0);
});

test("drops stale generations and cancels replacement work", async () => {
  const coordinator = new BrowserRecoveryCoordinator({ scenarioId: "phase7", generation: 1 });
  const stale = await coordinator.run({ failureId: "bridge-failed", correlationId: "stale", generation: 0, retryable: true, operation: async () => null });
  assert.equal(stale.state, "stale-dropped");
  let aborted = false;
  const pending = coordinator.run({
    failureId: "loader-failed",
    correlationId: "loader-1",
    retryable: true,
    operation: ({ signal }) => new Promise((resolve) => signal.addEventListener("abort", () => { aborted = true; resolve("late"); }, { once: true })),
  });
  coordinator.replaceGeneration(2);
  assert.equal((await pending).state, "stale-dropped");
  assert.equal(aborted, true);
  assert.equal(coordinator.snapshot().pending, 0);
});

test("converges non-retryable and stopped recovery", async () => {
  const coordinator = new BrowserRecoveryCoordinator({ scenarioId: "phase7", generation: 1 });
  const terminal = await coordinator.run({ failureId: "artifact-integrity-mismatch", correlationId: "asset-1", retryable: false, operation: async () => null });
  assert.equal(terminal.state, "failed");
  assert.equal(terminal.attempted, false);
  assert.equal(coordinator.stop().state, "stopped");
  assert.equal(coordinator.stop().pending, 0);
  await assert.rejects(coordinator.run({ failureId: "loader-failed", correlationId: "stopped", retryable: true, operation: async () => null }), { code: "recovery-stopped" });
});
