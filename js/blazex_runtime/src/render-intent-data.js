import { decode } from "./render-transaction-codec.js";

// Intent cells use only canonical data. No atom creation, executable payload or host access.
const events = { activate: "click", change: "input", submit: "submit", select: "change", expand: "click", dismiss: "click", move: "pointermove", reorder: "drop", increment: "click", decrement: "click", request_open: "click", request_close: "click", request_page: "click" };
const keys = (v, names) => v !== null && !Array.isArray(v) && typeof v === "object" && Object.keys(v).sort().join(",") === names.split(" ").sort().join(",");
const bounded = (v, max) => Number.isSafeInteger(v) && v >= 0 && v <= max;
const equal = (a, b) => JSON.stringify(a) === JSON.stringify(b);
function portable(v, depth = 0) {
  if (depth > 8 || !keys(v, "type value")) return false;
  if (v.type === "integer") return typeof v.value === "string" && /^(0|-?[1-9][0-9]*)$/.exec(v.value)?.[0] === v.value;
  if (v.type === "atom" || v.type === "binary") return typeof v.value === "string" && new TextEncoder().encode(v.value).length >= 1 && new TextEncoder().encode(v.value).length <= 256 && (v.type !== "atom" || v.value !== "nil");
  return ["list", "tuple"].includes(v.type) && Array.isArray(v.value) && v.value.length >= 1 && v.value.length <= 32 && v.value.every(x => portable(x, depth + 1));
}
const identity = v => keys(v, "root path generation") && portable(v.root) && Array.isArray(v.path) && v.path.length <= 32 && v.path.every(x => portable(x)) && bounded(v.generation, Number.MAX_SAFE_INTEGER) && v.generation > 0;
export function decodeIntent(value) {
  if (value === null) return null;
  if (typeof value !== "string" || value.length > 4096) throw new Error("intent cell limit");
  const bytes = Uint8Array.from(atob(value), c => c.charCodeAt(0));
  if (btoa(String.fromCharCode(...bytes)) !== value) throw new Error("noncanonical intent base64");
  return decode(bytes);
}
export const intentCount = value => value === null ? 0 : decodeIntent(value).length;
export function validIntent(name, cell) {
  if (!["focus", "selection", "listeners"].includes(name)) return false;
  if (cell === null) return true;
  try {
    const v = decodeIntent(cell);
    if (name === "focus") {
      if (!keys(v, "behavior order auto_focus restore wrap") || typeof v.auto_focus !== "boolean" || typeof v.wrap !== "boolean" || !["none", "previous"].includes(v.restore)) return false;
      if (v.behavior === "none") return v.order === null && !v.auto_focus && v.restore === "none" && !v.wrap;
      if (v.behavior === "target") return bounded(v.order, 1000000) && v.restore === "none" && !v.wrap;
      return v.behavior === "scope" && v.order === null && !v.auto_focus;
    }
    if (name === "selection") {
      if (!keys(v, "kind value")) return false;
      if (v.kind === "none") return v.value === null;
      if (v.kind === "single") return portable(v.value);
      if (v.kind === "multiple") return Array.isArray(v.value) && v.value.length <= 256 && new Set(v.value.map(x => JSON.stringify(x))).size === v.value.length && v.value.every(x => portable(x));
      return v.kind === "text_range" && keys(v.value, "anchor focus direction") && bounded(v.value.anchor, 1000000000) && bounded(v.value.focus, 1000000000) && ["forward", "backward"].includes(v.value.direction);
    }
    return Array.isArray(v) && v.length <= 256 && v.every(x => keys(x, "semantic native owner source") && Object.hasOwn(events, x.semantic) && events[x.semantic] === x.native && identity(x.owner) && identity(x.source) && equal(x.owner.root, x.source.root) && x.owner.generation === x.source.generation && x.owner.path.length <= x.source.path.length && x.owner.path.every((k, i) => equal(k, x.source.path[i]))) && equal(v.map(x => x.semantic), [...new Set(v.map(x => x.semantic))].sort());
  } catch { return false; }
}
