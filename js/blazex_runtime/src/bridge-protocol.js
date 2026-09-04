import { BlazeXHostError } from "./internal/errors.js";

export const BRIDGE_PROTOCOL = "blazex.host-bridge/1";
export const BRIDGE_LIMITS = Object.freeze({
  max_bytes: 8_192,
  max_depth: 6,
  max_items: 64,
  max_string_bytes: 2_048,
  max_timeout_ms: 10_000,
  max_concurrency: 16,
  max_abs_number: 1_000_000_000,
});
export const BRIDGE_OPERATIONS = Object.freeze(["runtime.echo", "runtime.shutdown", "fixture.command", "fixture.event", "fixture.snapshot"]);
export const BRIDGE_SIGNAL_TYPES = Object.freeze(["event", "error", "readiness", "shutdown", "diagnostic"]);

const ID = /^[A-Za-z0-9][A-Za-z0-9._:-]{0,95}$/;
const FORBIDDEN_KEY = /authorization|cookie|credential|password|secret|token/i;
const PROTOTYPE_KEYS = new Set(["__proto__", "constructor", "prototype"]);

export function createBridgeRequest({ scenarioId, generation, correlationId, sequence, operation, payload, timeoutMs }) {
  const envelope = {
    protocol: BRIDGE_PROTOCOL,
    type: "request",
    scenario_id: scenarioId,
    generation,
    correlation_id: correlationId,
    sequence,
    operation,
    payload,
    timeout_ms: timeoutMs,
    retry: 0,
  };
  validateBridgeRequest(envelope);
  return Object.freeze(envelope);
}

export function createBridgeCancel(request, reason) {
  const envelope = {
    protocol: BRIDGE_PROTOCOL,
    type: "cancel",
    scenario_id: request.scenario_id,
    generation: request.generation,
    correlation_id: request.correlation_id,
    sequence: request.sequence,
    reason: boundedReason(reason),
  };
  assertEnvelopeSize(envelope);
  return Object.freeze(envelope);
}

export function createBridgeSignal({ type, scenarioId, generation, sequence, payload }) {
  if (!BRIDGE_SIGNAL_TYPES.includes(type)) throw new BlazeXHostError("bridge-signal-type-invalid", "The bridge signal type is unknown");
  const envelope = {
    protocol: BRIDGE_PROTOCOL,
    type,
    scenario_id: scenarioId,
    generation,
    correlation_id: `signal-${sequence}`,
    sequence,
    payload,
  };
  assertEnvelopeBase(envelope, type);
  assertBoundedValue(payload);
  assertEnvelopeSize(envelope);
  return Object.freeze(envelope);
}

export function validateBridgeRequest(value) {
  assertEnvelopeBase(value, "request");
  if (!BRIDGE_OPERATIONS.includes(value.operation)) {
    throw new BlazeXHostError("bridge-operation-forbidden", "The bridge operation is not allowlisted", { operation: value.operation });
  }
  if (!Number.isSafeInteger(value.timeout_ms) || value.timeout_ms < 1 || value.timeout_ms > BRIDGE_LIMITS.max_timeout_ms) {
    throw new BlazeXHostError("bridge-timeout-invalid", "The bridge timeout is outside the governed range");
  }
  if (value.retry !== 0) throw new BlazeXHostError("bridge-retry-forbidden", "BH-01 bridge requests are not retried");
  assertBoundedValue(value.payload);
  assertEnvelopeSize(value);
  return value;
}

export function validateBridgeResponse(value, request) {
  assertEnvelopeBase(value, "response");
  if (value.scenario_id !== request.scenario_id || value.generation !== request.generation || value.correlation_id !== request.correlation_id || value.sequence !== request.sequence) {
    throw new BlazeXHostError("bridge-response-identity-mismatch", "The bridge response identity does not match its request");
  }
  if (value.status !== "ok" && value.status !== "error") {
    throw new BlazeXHostError("bridge-response-status-invalid", "The bridge response status is invalid");
  }
  assertBoundedValue(value.status === "ok" ? value.result : value.error);
  assertEnvelopeSize(value);
  return value;
}

export function assertBoundedValue(value, depth = 0, budget = { items: 0 }) {
  if (depth > BRIDGE_LIMITS.max_depth) throw new BlazeXHostError("bridge-payload-depth-exceeded", "Bridge payload nesting is too deep");
  if (value === null || typeof value === "boolean" || typeof value === "number") {
    if (typeof value === "number" && (!Number.isFinite(value) || Math.abs(value) > BRIDGE_LIMITS.max_abs_number)) throw new BlazeXHostError("bridge-payload-number-invalid", "Bridge numbers must be finite and bounded");
    return;
  }
  if (typeof value === "string") {
    if (new TextEncoder().encode(value).byteLength > BRIDGE_LIMITS.max_string_bytes) throw new BlazeXHostError("bridge-payload-string-exceeded", "A bridge string is too large");
    return;
  }
  if (["function", "bigint", "symbol", "undefined"].includes(typeof value)) {
    throw new BlazeXHostError("bridge-payload-type-forbidden", "Bridge payloads contain JSON values only");
  }
  if (Array.isArray(value)) {
    addItems(budget, value.length);
    value.forEach((item) => assertBoundedValue(item, depth + 1, budget));
    return;
  }
  if (!isPlainObject(value)) throw new BlazeXHostError("bridge-object-handle-forbidden", "Browser and JavaScript object handles cannot cross the bridge");
  const entries = Object.entries(value);
  addItems(budget, entries.length);
  for (const [key, item] of entries) {
    if (!ID.test(key) || FORBIDDEN_KEY.test(key) || PROTOTYPE_KEYS.has(key)) throw new BlazeXHostError("bridge-payload-key-forbidden", "A bridge payload key is invalid or sensitive");
    assertBoundedValue(item, depth + 1, budget);
  }
}

function assertEnvelopeBase(value, type) {
  if (!isPlainObject(value) || value.protocol !== BRIDGE_PROTOCOL || value.type !== type) {
    throw new BlazeXHostError("bridge-envelope-invalid", `Expected a ${type} bridge envelope`);
  }
  if (!ID.test(value.scenario_id) || !ID.test(value.correlation_id) || !Number.isSafeInteger(value.generation) || value.generation < 1 || !Number.isSafeInteger(value.sequence) || value.sequence < 1) {
    throw new BlazeXHostError("bridge-identity-invalid", "Bridge scenario, generation, correlation, or sequence identity is invalid");
  }
}

function assertEnvelopeSize(value) {
  const bytes = new TextEncoder().encode(JSON.stringify(value)).byteLength;
  if (bytes > BRIDGE_LIMITS.max_bytes) throw new BlazeXHostError("bridge-envelope-size-exceeded", "The bridge envelope is too large", { bytes });
}

function addItems(budget, count) {
  budget.items += count;
  if (budget.items > BRIDGE_LIMITS.max_items) throw new BlazeXHostError("bridge-payload-items-exceeded", "The bridge payload has too many items");
}

function boundedReason(reason) {
  return String(reason ?? "cancelled").slice(0, 96);
}

function isPlainObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value) && Object.getPrototypeOf(value) === Object.prototype;
}
