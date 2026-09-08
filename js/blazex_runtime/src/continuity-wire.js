import { encode, decode, digest } from "./render-transaction-codec.js";
import { requireDOM } from "./dom-transaction-plan.js";
const keys = (v, names) => v && Object.getPrototypeOf(v) === Object.prototype && Object.keys(v).sort().join(" ") === names.split(" ").sort().join(" ");
const id = v => typeof v === "string" && /^bx-[0-9a-f]{24}$/.exec(v)?.[0] === v;
const string = (v, max) => typeof v === "string" && v.isWellFormed() && new TextEncoder().encode(v).length <= max;
export function validateControls(controls) {
  requireDOM(Array.isArray(controls) && controls.length <= 32, "limit");
  const claims = new Set();
  for (const c of controls) {
    requireDOM(keys(c, "owner kind value choices edit_sequence disabled readonly required invalid indeterminate"));
    requireDOM(id(c.owner) && !claims.has(c.owner), "ownership"); claims.add(c.owner);
    requireDOM(["text", "check", "single", "multiple"].includes(c.kind));
    requireDOM(Number.isSafeInteger(c.edit_sequence) && c.edit_sequence >= 0);
    requireDOM([c.disabled, c.readonly, c.required, c.invalid, c.indeterminate].every(v => typeof v === "boolean") && (!c.indeterminate || c.kind === "check"));
    requireDOM(Array.isArray(c.choices) && c.choices.length <= 32, "limit");
    const values = new Set();
    for (const choice of c.choices) {
      requireDOM(keys(choice, "owner value") && id(choice.owner) && !claims.has(choice.owner) && string(choice.value, 128) && choice.value !== "" && !values.has(choice.value), "ownership");
      claims.add(choice.owner); values.add(choice.value);
    }
    if (c.kind === "text") requireDOM(c.choices.length === 0 && string(c.value, 2048));
    if (c.kind === "check") requireDOM(c.choices.length === 0 && typeof c.value === "boolean");
    if (c.kind === "single") requireDOM(c.value === null || values.has(c.value), "missing-target");
    if (c.kind === "multiple") requireDOM(Array.isArray(c.value) && c.value.length <= 32 && new Set(c.value).size === c.value.length && c.value.every(v => values.has(v)), "missing-target");
  }
  return controls;
}
export function copyContinuity(raw) {
  const value = decode(encode(raw));
  requireDOM(keys(value, "protocol transaction controls base_control_digest control_digest digest") && value.protocol === "blazex.dom-continuity/1", "incompatible");
  validateControls(value.controls);
  requireDOM(value.base_control_digest === null || /^[0-9a-f]{64}$/.test(value.base_control_digest));
  return value;
}
export async function verifyContinuity(value) {
  const { digest: claimed, ...payload } = value;
  requireDOM(claimed === await digest(payload) && value.control_digest === await digest(value.controls), "malformed");
}
