export const DOM_WIRE_VERSION = 1;

export const DOM_LIMITS = Object.freeze({
  max_depth: 32,
  max_nodes: 128,
  max_listeners: 256,
  max_text_bytes: 4_096,
  max_value_bytes: 2_048,
  max_attribute_bytes: 2_048,
});

export const DOM_TAGS = Object.freeze(["span", "div", "button", "input", "ul", "li", "section"]);
export const DOM_TRANSITIONS = Object.freeze(["mount", "update", "replace", "dispose"]);
export const SEMANTIC_EVENTS = Object.freeze([
  "activate", "change", "submit", "select", "expand", "dismiss", "move", "reorder",
  "increment", "decrement", "request_open", "request_close", "request_page",
]);
export const NATIVE_EVENTS = Object.freeze({
  activate: "click",
  change: "input",
  submit: "submit",
  select: "change",
  expand: "click",
  dismiss: "click",
  move: "pointermove",
  reorder: "drop",
  increment: "click",
  decrement: "click",
  request_open: "click",
  request_close: "click",
  request_page: "click",
});

const BATCH_KEYS = new Set(["version", "owner", "generation", "revision", "transition", "root", "digest"]);
const NODE_KEYS = new Set(["version", "id", "tag", "text", "attributes", "listeners", "focus", "selection", "children"]);
const LISTENER_KEYS = new Set(["semantic", "native", "owner", "source"]);
const FOCUS_KEYS = new Set(["behavior", "order", "auto_focus", "restore", "wrap"]);
const SELECTION_KEYS = new Set(["kind", "value"]);
const IDENTITY_KEYS = new Set(["root", "path", "generation"]);
const PORTABLE_KEYS = new Set(["type", "value"]);
const ID = /^bx-[0-9a-f]{24}$/;
const DIGEST = /^[0-9a-f]{64}$/;
const ATTRIBUTE_NAMES = new Set([
  "data-bx-kind", "type", "role", "aria-label", "aria-description", "aria-disabled",
  "aria-expanded", "aria-selected", "aria-checked", "aria-invalid", "aria-required",
  "aria-readonly", "aria-busy", "aria-labelledby", "aria-describedby", "aria-controls",
  "aria-owns", "aria-errormessage", "aria-live", "data-bx-layout-mode",
  "data-bx-layout-direction", "data-bx-layout-align", "data-bx-layout-gap",
  "data-bx-layout-padding", "data-bx-layout-width", "data-bx-layout-height",
  "data-bx-layout-min-width", "data-bx-layout-min-height", "data-bx-layout-max-width",
  "data-bx-layout-max-height", "data-bx-layout-grow", "data-bx-layout-overflow",
  "data-bx-layout-virtualization",
]);

export class DOMProtocolError extends Error {
  constructor(code, message, details = {}) {
    super(message);
    this.name = "DOMProtocolError";
    this.code = code;
    this.details = Object.freeze({ ...details });
  }
}

export function validateBatch(batch) {
  exactObject(batch, BATCH_KEYS, "dom-batch-invalid");
  if (batch.version !== DOM_WIRE_VERSION) fail("dom-version-unsupported", "The DOM batch version is unsupported");
  identity(batch.owner);
  positive(batch.generation, "dom-generation-invalid");
  nonNegative(batch.revision, "dom-revision-invalid");
  if (!DOM_TRANSITIONS.includes(batch.transition)) fail("dom-transition-unknown", "The DOM transition is unknown");
  if (!DIGEST.test(batch.digest)) fail("dom-digest-invalid", "The DOM batch digest is invalid");
  if (batch.transition === "dispose") {
    if (batch.root !== null) fail("dom-dispose-root-forbidden", "A disposal batch cannot carry a root");
    return batch;
  }
  if (batch.root === null) fail("dom-projection-root-missing", "A projection batch requires a root");

  const state = { ids: new Set(), nodes: 0, listeners: 0, generation: batch.generation, owner: JSON.stringify(batch.owner) };
  validateNode(batch.root, 0, state);
  validateRelationships(batch.root, state.ids);
  return batch;
}

export function normalizeEvent(event, listener, { generation, revision, sequence }) {
  const payload = {};
  if (listener.semantic === "change" || listener.semantic === "select") {
    const value = event?.target?.value ?? "";
    boundedString(value, DOM_LIMITS.max_value_bytes, "dom-event-value-invalid");
    payload.value = value;
  }
  return Object.freeze({
    version: DOM_WIRE_VERSION,
    generation,
    revision,
    sequence,
    name: listener.semantic,
    owner: listener.owner,
    source: listener.source,
    payload: Object.freeze(payload),
  });
}

function validateNode(node, depth, state) {
  exactObject(node, NODE_KEYS, "dom-node-invalid");
  if (node.version !== DOM_WIRE_VERSION) fail("dom-node-version-unsupported", "The DOM node version is unsupported");
  if (depth > DOM_LIMITS.max_depth) fail("dom-depth-exceeded", "The DOM projection depth is exceeded");
  state.nodes += 1;
  if (state.nodes > DOM_LIMITS.max_nodes) fail("dom-node-count-exceeded", "The DOM projection node count is exceeded");
  if (!ID.test(node.id) || state.ids.has(node.id)) fail("dom-node-id-invalid", "The DOM node ID is invalid or duplicated");
  state.ids.add(node.id);
  if (!DOM_TAGS.includes(node.tag)) fail("dom-tag-forbidden", "The DOM tag is not allowed");
  if (node.text !== null) boundedString(node.text, DOM_LIMITS.max_text_bytes, "dom-text-invalid");
  attributes(node.attributes);
  if (!Array.isArray(node.listeners)) fail("dom-listeners-invalid", "DOM listeners must be an array");
  for (const listener of node.listeners) {
    validateListener(listener, state);
    state.listeners += 1;
    if (state.listeners > DOM_LIMITS.max_listeners) fail("dom-listener-count-exceeded", "The listener count is exceeded");
  }
  if (node.focus !== null) validateFocus(node.focus);
  if (node.selection !== null) validateSelection(node.selection);
  if (!Array.isArray(node.children)) fail("dom-children-invalid", "DOM children must be an array");
  for (const child of node.children) validateNode(child, depth + 1, state);
}

function attributes(value) {
  if (!plain(value)) fail("dom-attributes-invalid", "DOM attributes must be a plain object");
  for (const [name, attribute] of Object.entries(value)) {
    if (!ATTRIBUTE_NAMES.has(name)) fail("dom-attribute-forbidden", "The DOM attribute is not allowed", { name });
    boundedString(attribute, DOM_LIMITS.max_attribute_bytes, "dom-attribute-value-invalid");
  }
}

function validateListener(listener, state) {
  exactObject(listener, LISTENER_KEYS, "dom-listener-invalid");
  if (!SEMANTIC_EVENTS.includes(listener.semantic) || NATIVE_EVENTS[listener.semantic] !== listener.native) {
    fail("dom-listener-mapping-invalid", "The semantic/native event mapping is invalid");
  }
  identity(listener.owner);
  identity(listener.source);
  if (JSON.stringify(listener.owner) !== state.owner || listener.source.generation !== state.generation) {
    fail("dom-listener-owner-invalid", "A listener must retain the batch owner and generation");
  }
}

function validateFocus(focus) {
  exactObject(focus, FOCUS_KEYS, "dom-focus-invalid");
  if (!["none", "target", "scope"].includes(focus.behavior) || !["none", "previous"].includes(focus.restore)) {
    fail("dom-focus-value-invalid", "The focus intent is invalid");
  }
  if (focus.order !== null) nonNegative(focus.order, "dom-focus-order-invalid");
  if (typeof focus.auto_focus !== "boolean" || typeof focus.wrap !== "boolean") fail("dom-focus-flag-invalid", "A focus flag is invalid");
  if (focus.behavior === "target" && focus.order === null) fail("dom-focus-shape-invalid", "A focus target requires order");
}

function validateSelection(selection) {
  exactObject(selection, SELECTION_KEYS, "dom-selection-invalid");
  if (!["none", "single", "multiple", "text_range"].includes(selection.kind)) fail("dom-selection-kind-invalid", "The selection kind is invalid");
  if (selection.kind === "none" && selection.value !== null) fail("dom-selection-value-invalid", "None selection must be null");
  if (selection.kind === "single") portable(selection.value);
  if (selection.kind === "multiple") {
    if (!Array.isArray(selection.value)) fail("dom-selection-value-invalid", "Multiple selection must be an array");
    selection.value.forEach(portable);
  }
  if (selection.kind === "text_range") {
    exactObject(selection.value, new Set(["anchor", "focus", "direction"]), "dom-selection-range-invalid");
    nonNegative(selection.value.anchor, "dom-selection-range-invalid");
    nonNegative(selection.value.focus, "dom-selection-range-invalid");
    if (!["forward", "backward"].includes(selection.value.direction)) fail("dom-selection-range-invalid", "The selection direction is invalid");
  }
}

function identity(value) {
  exactObject(value, IDENTITY_KEYS, "dom-identity-invalid");
  portable(value.root);
  if (!Array.isArray(value.path)) fail("dom-identity-path-invalid", "The identity path is invalid");
  value.path.forEach(portable);
  positive(value.generation, "dom-identity-generation-invalid");
}

function portable(value) {
  exactObject(value, PORTABLE_KEYS, "dom-portable-invalid");
  if (!["atom", "binary", "integer", "list", "tuple"].includes(value.type)) fail("dom-portable-type-invalid", "The portable value type is invalid");
  if (value.type === "atom" || value.type === "binary") boundedString(value.value, DOM_LIMITS.max_value_bytes, "dom-portable-value-invalid");
  else if (value.type === "integer" && !Number.isSafeInteger(value.value)) fail("dom-portable-value-invalid", "The portable integer is invalid");
  else if (value.type === "list" || value.type === "tuple") {
    if (!Array.isArray(value.value)) fail("dom-portable-value-invalid", "The portable collection is invalid");
    value.value.forEach(portable);
  }
}

function validateRelationships(node, ids) {
  for (const name of ["aria-labelledby", "aria-describedby", "aria-controls", "aria-owns", "aria-errormessage"]) {
    const value = node.attributes[name];
    if (value && value.split(" ").some((id) => !ids.has(id))) fail("dom-relationship-target-missing", "An accessibility relationship target is missing");
  }
  node.children.forEach((child) => validateRelationships(child, ids));
}

function exactObject(value, keys, code) {
  if (!plain(value) || Object.keys(value).length !== keys.size || Object.keys(value).some((key) => !keys.has(key))) {
    fail(code, "The wire object fields differ from the contract");
  }
}

function boundedString(value, maximum, code) {
  if (typeof value !== "string" || new TextEncoder().encode(value).byteLength > maximum) fail(code, "A bounded string is invalid");
}

function positive(value, code) {
  if (!Number.isSafeInteger(value) || value < 1) fail(code, "A positive integer is required");
}

function nonNegative(value, code) {
  if (!Number.isSafeInteger(value) || value < 0) fail(code, "A non-negative integer is required");
}

function plain(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value) && Object.getPrototypeOf(value) === Object.prototype;
}

function fail(code, message, details) {
  throw new DOMProtocolError(code, message, details);
}
