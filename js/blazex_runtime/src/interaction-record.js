export const INTERACTION_PROTOCOL = "blazex.interaction/1";
export const INTERACTION_LIMITS = Object.freeze({ bytes: 8192, string: 2048, items: 64, depth: 6, queue: 64, coordinate: 1000000 });
export const EVENT_MAPPINGS = Object.freeze({ activate: "click", change: "input", submit: "submit", select: "change", expand: "click", dismiss: "click", move: "pointermove", reorder: "drop", increment: "click", decrement: "click", request_open: "click", request_close: "click", request_page: "click" });
export class InteractionError extends Error { constructor(code) { super(code); this.code = code; } }
export const INTERACTION_DIAGNOSTICS = Object.freeze(["malformed", "incompatible", "ownership", "listener", "limit", "privacy", "composition", "clock", "disposed-root", "stale", "duplicate", "cancelled", "timeout", "transport", "unmounted", "render", "stale-or-unbound", "mount"]);
export const interactionDiagnostic = error => INTERACTION_DIAGNOSTICS.includes(error?.code) ? error.code : "malformed";
export const requireInteraction = (value, code = "malformed") => { if (!value) throw new InteractionError(code); };
const utf8 = value => new TextEncoder().encode(value).length;
export function copyInteractionData(value) {
  let items = 0;
  function copy(v, depth) {
    requireInteraction(depth <= 6, "limit");
    if (v === null || typeof v === "boolean") return v;
    if (typeof v === "string") { requireInteraction(v.isWellFormed(), "malformed"); requireInteraction(utf8(v) <= 2048, "limit"); return v; }
    if (typeof v === "number") { requireInteraction(Number.isFinite(v) && Math.abs(v) <= Number.MAX_SAFE_INTEGER); return Object.is(v, -0) ? 0 : v; }
    requireInteraction(v !== null && typeof v === "object" && (Array.isArray(v) || Object.getPrototypeOf(v) === Object.prototype));
    const descriptors = Object.getOwnPropertyDescriptors(v), names = Reflect.ownKeys(v).filter(k => !(Array.isArray(v) && k === "length"));
    items += names.length; requireInteraction(items <= 64, "limit");
    requireInteraction(names.every(k => typeof k === "string" && Object.hasOwn(descriptors[k], "value") && descriptors[k].enumerable && !["__proto__", "constructor", "prototype"].includes(k)));
    if (Array.isArray(v)) { requireInteraction(names.length === v.length && names.every((k, i) => k === String(i))); return Object.freeze(names.map(k => copy(descriptors[k].value, depth + 1))); }
    return Object.freeze(Object.fromEntries(names.sort().map(k => [k, copy(descriptors[k].value, depth + 1)])));
  }
  const result = copy(value, 0); requireInteraction(utf8(JSON.stringify(result)) <= 8192, "limit"); return result;
}
export const listenerIdentity = (source, semantic) => "li-" + source + "-" + semantic;
const exact = (v, keys) => v !== null && !Array.isArray(v) && typeof v === "object" && Object.keys(v).sort().join(" ") === keys.split(" ").sort().join(" ");
const integer = (v, min = 1) => Number.isSafeInteger(v) && v >= min;
const matches = (pattern, value) => typeof value === "string" && pattern.exec(value)?.[0] === value;
export function validateInteraction(raw) {
  const v = copyInteractionData(raw);
  requireInteraction(exact(v, "protocol provenance root_id lifecycle_generation owner source listener_id generation revision transaction_id digest sequence timestamp semantic payload"));
  requireInteraction(v.protocol === INTERACTION_PROTOCOL, "incompatible");
  requireInteraction(v.provenance === "local-event" && matches(/^[a-z][a-z0-9-]{0,63}$/, v.root_id) && matches(/^root-[a-z0-9_-]{1,59}$/, v.owner), "ownership");
  requireInteraction(matches(/^bx-[0-9a-f]{24}$/, v.source) && matches(/^tx-[0-9a-f]{24}$/, v.transaction_id) && matches(/^[0-9a-f]{64}$/, v.digest));
  requireInteraction([v.lifecycle_generation, v.generation, v.revision, v.sequence].every(n => integer(n)) && integer(v.timestamp, 0));
  requireInteraction(Object.hasOwn(EVENT_MAPPINGS, v.semantic) && v.listener_id === listenerIdentity(v.source, v.semantic), "listener");
  const p = v.payload;
  if (["change", "select"].includes(v.semantic)) requireInteraction(exact(p, "value checked") && typeof p.value === "string" && (p.checked === null || typeof p.checked === "boolean"));
  else if (v.semantic === "move") requireInteraction(exact(p, "x y dx dy buttons") && [p.x, p.y, p.dx, p.dy].every(n => typeof n === "number" && Number.isFinite(n) && Math.abs(n) <= 1000000) && Number.isInteger(p.buttons) && p.buttons >= 0 && p.buttons <= 31);
  else if (v.semantic === "reorder") requireInteraction(exact(p, "source") && p.source === v.source, "ownership");
  else requireInteraction(exact(p, ""));
  return v;
}

/** Reads only declared native fields; never enumerates an Event or control. */
export function normalizeNative(semantic, source, element, event) {
  requireInteraction(Object.hasOwn(EVENT_MAPPINGS, semantic) && event?.type === EVENT_MAPPINGS[semantic], "listener");
  requireInteraction(event.target === element && event.currentTarget === element, "ownership");
  const type = String(element.type ?? "").toLowerCase();
  const designation = [element.name, element.autocomplete, element.getAttribute?.("autocomplete")].filter(v => typeof v === "string").join(" ");
  requireInteraction(!["password", "file", "hidden"].includes(type) && !/password|credential|secret|token|credit.card|cc-number|cc-csc/i.test(designation), "privacy");
  if (["change", "select"].includes(semantic)) {
    requireInteraction(!event.isComposing, "composition");
    requireInteraction(typeof element.value === "string" && utf8(element.value) <= 2048, "limit");
    return { value: element.value, checked: typeof element.checked === "boolean" ? element.checked : null };
  }
  if (semantic === "move") return { x: event.clientX, y: event.clientY, dx: event.movementX, dy: event.movementY, buttons: event.buttons };
  if (semantic === "reorder") return { source };
  return {};
}
