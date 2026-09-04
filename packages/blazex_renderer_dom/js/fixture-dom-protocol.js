export const FIXTURE_DOM_PROTOCOL = "blazex.bh01.dom/0.1";
export const FIXTURE_EFFECT_PROTOCOL = "blazex.bh01.fixture-effect/0.1";
export const FIXTURE_EVENT_PROTOCOL = "blazex.bh01.fixture-event/0.1";

export const FIXTURE_DOM_LIMITS = Object.freeze({
  max_operations: 96,
  max_nodes: 48,
  max_text_bytes: 2_048,
  max_value_bytes: 2_048,
  max_id_bytes: 64,
});

export const FIXTURE_NODE_KINDS = Object.freeze({
  heading: "h2",
  status: "p",
  group: "section",
  list: "ul",
  item: "li",
  label: "label",
  field: "input",
  help: "p",
  error: "p",
  action: "button",
  text: "span",
});

export const FIXTURE_DOM_OPERATIONS = Object.freeze([
  "root.mount",
  "node.upsert",
  "node.move",
  "node.text",
  "node.property",
  "node.relationship",
  "listener.bind",
  "node.remove",
  "root.dispose",
]);

export const FIXTURE_EVENTS = Object.freeze(["input", "change", "focus", "blur", "action"]);

const ID = /^bx-[a-z0-9-]{1,60}$/;
const TEST_ID = /^bx-test-[a-z0-9-]{1,60}$/;
const PROPERTY_NAMES = new Set(["value", "disabled", "read_only", "hidden", "invalid"]);
const RELATIONSHIP_NAMES = new Set(["label_for", "described_by", "error_message", "controls"]);
const OP_KEYS = Object.freeze({
  "root.mount": new Set(["protocol", "op", "generation", "id", "test_id"]),
  "node.upsert": new Set(["protocol", "op", "generation", "id", "parent_id", "kind", "text", "test_id"]),
  "node.move": new Set(["protocol", "op", "generation", "id", "parent_id", "before_id"]),
  "node.text": new Set(["protocol", "op", "generation", "id", "text"]),
  "node.property": new Set(["protocol", "op", "generation", "id", "name", "value"]),
  "node.relationship": new Set(["protocol", "op", "generation", "id", "name", "target_ids"]),
  "listener.bind": new Set(["protocol", "op", "generation", "id", "event"]),
  "node.remove": new Set(["protocol", "op", "generation", "id"]),
  "root.dispose": new Set(["protocol", "op", "generation", "id"]),
});

export class FixtureDOMError extends Error {
  constructor(code, message, details = {}) {
    super(message);
    this.name = "FixtureDOMError";
    this.code = code;
    this.details = Object.freeze({ ...details });
  }
}

export function validateFixtureEffect(effect) {
  if (!plain(effect) || effect.protocol !== FIXTURE_EFFECT_PROTOCOL) fail("fixture-effect-invalid", "The fixture effect envelope is invalid");
  if (!Number.isSafeInteger(effect.generation) || effect.generation < 1 || !Number.isSafeInteger(effect.sequence) || effect.sequence < 1) {
    fail("fixture-effect-identity-invalid", "Fixture generation and sequence must be positive integers");
  }
  if (!Array.isArray(effect.operations) || effect.operations.length > FIXTURE_DOM_LIMITS.max_operations) {
    fail("fixture-operation-count-exceeded", "The fixture operation batch is invalid or too large");
  }
  effect.operations.forEach(validateFixtureOperation);
  return effect;
}

export function validateFixtureOperation(operation) {
  if (!plain(operation) || operation.protocol !== FIXTURE_DOM_PROTOCOL || !FIXTURE_DOM_OPERATIONS.includes(operation.op)) {
    fail("fixture-operation-unknown", "The DOM fixture operation is unknown");
  }
  if (!Number.isSafeInteger(operation.generation) || operation.generation < 1) fail("fixture-generation-invalid", "The operation generation is invalid");
  for (const key of Object.keys(operation)) {
    if (!OP_KEYS[operation.op].has(key)) fail("fixture-operation-key-forbidden", "The operation contains an undeclared field", { key });
  }
  id(operation.id);
  if (operation.parent_id !== undefined) id(operation.parent_id);
  if (operation.before_id !== undefined && operation.before_id !== null) id(operation.before_id);
  if (operation.test_id !== undefined && !TEST_ID.test(operation.test_id)) fail("fixture-test-identity-invalid", "The test identity is invalid");

  if (operation.op === "root.mount" && (!operation.test_id || operation.id !== "bx-fixture-root")) fail("fixture-root-invalid", "The one fixture root identity is fixed");
  if (operation.op === "node.upsert") {
    if (!operation.parent_id || !Object.hasOwn(FIXTURE_NODE_KINDS, operation.kind)) fail("fixture-node-kind-forbidden", "The fixture node kind or parent is invalid");
    if (operation.text !== undefined) boundedString(operation.text, FIXTURE_DOM_LIMITS.max_text_bytes, "fixture-text-exceeded");
  }
  if (operation.op === "node.text") boundedString(operation.text, FIXTURE_DOM_LIMITS.max_text_bytes, "fixture-text-exceeded");
  if (operation.op === "node.property") {
    if (!PROPERTY_NAMES.has(operation.name)) fail("fixture-property-forbidden", "The fixture property is not allowlisted");
    if (operation.name === "value") boundedString(operation.value, FIXTURE_DOM_LIMITS.max_value_bytes, "fixture-value-exceeded");
    else if (typeof operation.value !== "boolean") fail("fixture-property-value-invalid", "The fixture property value has the wrong type");
  }
  if (operation.op === "node.relationship") {
    if (!RELATIONSHIP_NAMES.has(operation.name) || !Array.isArray(operation.target_ids) || operation.target_ids.length > 4) fail("fixture-relationship-invalid", "The fixture relationship is not allowlisted");
    operation.target_ids.forEach(id);
  }
  if (operation.op === "listener.bind" && !FIXTURE_EVENTS.includes(operation.event)) fail("fixture-event-forbidden", "The fixture event is not allowlisted");
  return operation;
}

export function normalizeFixtureEvent(event, { generation, sequence, nodeId, eventName }) {
  if (!FIXTURE_EVENTS.includes(eventName)) fail("fixture-event-forbidden", "The fixture event is not allowlisted");
  id(nodeId);
  const payload = {};
  if (eventName === "input" || eventName === "change") {
    boundedString(event?.target?.value ?? "", FIXTURE_DOM_LIMITS.max_value_bytes, "fixture-event-value-exceeded");
    payload.value = event.target.value;
    payload.is_composing = Boolean(event.isComposing);
    payload.input_type = boundedToken(event.inputType ?? "unknown");
  } else if (eventName === "action") {
    payload.key = ["Enter", " ", ""].includes(event?.key ?? "") ? (event.key ?? "") : "other";
    payload.detail = Number.isSafeInteger(event?.detail) ? Math.max(0, Math.min(event.detail, 8)) : 0;
  } else {
    payload.related_target = event?.relatedTarget ? "present" : "none";
  }
  return Object.freeze({
    protocol: FIXTURE_EVENT_PROTOCOL,
    record_type: "event",
    scenario_id: "BX-BH01-SCENARIO-LOCAL-BROWSER",
    generation,
    sequence,
    node_id: nodeId,
    event: eventName,
    payload: Object.freeze(payload),
  });
}

function id(value) {
  if (typeof value !== "string" || !ID.test(value) || new TextEncoder().encode(value).byteLength > FIXTURE_DOM_LIMITS.max_id_bytes) {
    fail("fixture-node-identity-invalid", "The fixture node identity is invalid");
  }
}

function boundedString(value, maximum, code) {
  if (typeof value !== "string" || new TextEncoder().encode(value).byteLength > maximum) fail(code, "The fixture string is invalid or too large");
}

function boundedToken(value) {
  const token = String(value);
  return /^[A-Za-z0-9._-]{1,32}$/.test(token) ? token : "unknown";
}

function plain(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value) && Object.getPrototypeOf(value) === Object.prototype;
}

function fail(code, message, details) {
  throw new FixtureDOMError(code, message, details);
}
