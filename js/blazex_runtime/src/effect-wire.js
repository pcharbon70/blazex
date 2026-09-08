import { encode, decode, digest } from "./render-transaction-codec.js";
import { copyContinuity, verifyContinuity } from "./continuity-wire.js";
import { requireDOM } from "./dom-transaction-plan.js";
const exact = (v, names) => v && Object.getPrototypeOf(v) === Object.prototype && Object.keys(v).sort().join(" ") === names.split(" ").sort().join(" ");
export async function copyEffects(raw, grants) {
  const value = decode(encode(raw));
  requireDOM(exact(value, "protocol continuity effects digest") && value.protocol === "blazex.dom-effects/1", "incompatible");
  const { digest: claimed, ...body } = value;
  requireDOM(claimed === await digest(body));
  const continuity = copyContinuity(value.continuity); await verifyContinuity(continuity);
  const tx = continuity.transaction, seen = new Set();
  requireDOM(Array.isArray(value.effects) && value.effects.length <= 16, "limit");
  for (const e of value.effects) {
    requireDOM(exact(e, "id owner generation revision capability operation payload timeout_ms fallback barrier depends"));
    requireDOM(typeof e.id === "string" && /^[A-Za-z0-9_-]{1,64}$/.exec(e.id)?.[0] === e.id && !seen.has(e.id), "duplicate");
    requireDOM(e.owner === tx.root && e.generation === tx.generation && e.revision === tx.target_revision, "ownership");
    requireDOM(e.capability === "time" && grants.includes("time") && e.operation === "schedule", "incompatible");
    requireDOM(exact(e.payload, "delay_ms") && Number.isInteger(e.payload.delay_ms) && e.payload.delay_ms >= 0 && e.payload.delay_ms <= 250, "limit");
    requireDOM(Number.isInteger(e.timeout_ms) && e.timeout_ms >= 1 && e.timeout_ms <= 500, "limit");
    requireDOM(["fail", "omit", "component"].includes(e.fallback) && e.barrier === "post-commit");
    requireDOM(Array.isArray(e.depends) && e.depends.length <= 16 && new Set(e.depends).size === e.depends.length && e.depends.every(id => seen.has(id)), "missing-target");
    seen.add(e.id);
  }
  requireDOM(tx.kind !== "dispose" || value.effects.length === 0, "disposed-root");
  return value;
}
