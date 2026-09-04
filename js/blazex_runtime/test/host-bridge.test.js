import assert from "node:assert/strict";
import test from "node:test";

import { BRIDGE_LIMITS, BrowserHostBridge, BlazeXHostError, assertBoundedValue, createBridgeSignal } from "../src/index.js";

function response(request, result, overrides = {}) {
  return {
    protocol: "blazex.host-bridge/1",
    type: "response",
    scenario_id: request.scenario_id,
    generation: request.generation,
    correlation_id: request.correlation_id,
    sequence: request.sequence,
    status: "ok",
    result,
    ...overrides,
  };
}

test("correlates a bounded allowlisted request and records metrics", async () => {
  const traces = [];
  const transport = { request: async (request) => response(request, request.payload), cancel() {} };
  const bridge = new BrowserHostBridge({ transport, generation: 7, scenarioId: "bridge-test", onTrace: (event) => traces.push(event) });
  assert.deepEqual(await bridge.request("runtime.echo", { message: "hello" }), { message: "hello" });
  assert.equal(bridge.metrics().requests, 1);
  assert.equal(bridge.metrics().responses, 1);
  assert.equal(bridge.metrics().pending, 0);
  assert.deepEqual(traces.map((event) => event.kind), ["request", "response"]);
});

test("accepts only the three bounded fixture operations added for Phase 5", async () => {
  const transport = { request: async (request) => response(request, request.payload), cancel() {} };
  const bridge = new BrowserHostBridge({ transport, generation: 1, scenarioId: "fixture" });
  for (const operation of ["fixture.command", "fixture.event", "fixture.snapshot"]) {
    assert.deepEqual(await bridge.request(operation, { command: "snapshot" }), { command: "snapshot" });
  }
  await assert.rejects(bridge.request("fixture.dom", {}), { code: "bridge-operation-forbidden" });
  bridge.stop();
});

test("rejects operations, executable values, handles, secrets, and oversized values", async () => {
  const transport = { request: async (request) => response(request, null), cancel() {} };
  const bridge = new BrowserHostBridge({ transport, generation: 1, scenarioId: "negative" });
  await assert.rejects(bridge.request("browser.fetch", {}), (error) => error.code === "bridge-operation-forbidden");
  await assert.rejects(bridge.request("runtime.echo", { callback() {} }), (error) => error.code === "bridge-payload-type-forbidden");
  await assert.rejects(bridge.request("runtime.echo", { node: new URL("https://example.test") }), (error) => error.code === "bridge-object-handle-forbidden");
  await assert.rejects(bridge.request("runtime.echo", { authToken: "value" }), (error) => error.code === "bridge-payload-key-forbidden");
  assert.throws(() => assertBoundedValue({ value: "x".repeat(BRIDGE_LIMITS.max_string_bytes + 1) }), /too large/);
});

test("times out, cancels transport, and drops a late result", async () => {
  let resolveTransport;
  const cancellations = [];
  const transport = {
    request: () => new Promise((resolve) => { resolveTransport = resolve; }),
    cancel: (envelope) => cancellations.push(envelope),
  };
  const bridge = new BrowserHostBridge({ transport, generation: 2, scenarioId: "timeout" });
  await assert.rejects(bridge.request("runtime.echo", {}, { timeoutMs: 5 }), (error) => error instanceof BlazeXHostError && error.code === "bridge-timeout");
  assert.equal(cancellations.length, 1);
  resolveTransport(response({ scenario_id: "timeout", generation: 2, correlation_id: cancellations[0].correlation_id, sequence: cancellations[0].sequence }, {}));
  await new Promise((resolve) => setTimeout(resolve, 0));
  assert.equal(bridge.metrics().stale_drops, 1);
});

test("rejects stale responses and makes stop idempotent", async () => {
  const transport = { request: async (request) => response(request, {}, { generation: request.generation + 1 }), cancel() {} };
  const bridge = new BrowserHostBridge({ transport, generation: 3, scenarioId: "stale" });
  await assert.rejects(bridge.request("runtime.echo", {}), (error) => error.code === "bridge-response-identity-mismatch");
  bridge.stop();
  bridge.stop();
  await assert.rejects(bridge.request("runtime.echo", {}), (error) => error.code === "bridge-stopped");
  assert.equal(bridge.metrics().generation, 4);
  assert.equal(bridge.metrics().timers, 0);
});

test("defines bounded event, error, readiness, shutdown, and diagnostic signals", () => {
  for (const type of ["event", "error", "readiness", "shutdown", "diagnostic"]) {
    assert.equal(createBridgeSignal({ type, scenarioId: "signals", generation: 1, sequence: 1, payload: { state: "observed" } }).type, type);
  }
  assert.throws(() => createBridgeSignal({ type: "script", scenarioId: "signals", generation: 1, sequence: 1, payload: {} }), /unknown/);
});
