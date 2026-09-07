import { encode, decode, digest, validate, ProtocolError } from "./render-transaction-v2.js";
import { SCHEMA } from "./render-transaction-v2-schema.js";
import { decodeIntent, validIntent, intentCount } from "./render-intent-data.js";

export const requireDOM = (ok, code = "malformed") => { if (!ok) throw new ProtocolError(code); };
export const equalData = (a, b) => JSON.stringify(a) === JSON.stringify(b);
export function shape(v, s) {
  if (s.oneOf) return s.oneOf.filter(x => shape(v, x)).length === 1;
  if (s.enum) return s.enum.includes(v);
  switch (s.type) {
    case "null": return v === null;
    case "boolean": return typeof v === "boolean";
    case "integer": return Number.isSafeInteger(v) && v >= s.minimum && v <= s.maximum;
    case "string": return typeof v === "string" && new TextEncoder().encode(v).length <= s.maxBytes && (!s.pattern || new RegExp(s.pattern).exec(v)?.[0] === v);
    case "array": return Array.isArray(v) && v.length >= (s.minItems ?? 0) && v.length <= s.maxItems && v.every(x => shape(x, s.items));
    case "object": return v !== null && Object.getPrototypeOf(v) === Object.prototype && Object.keys(v).length === s.required.length && s.required.every(k => Object.hasOwn(v, k) && shape(v[k], s.properties[k]));
    default: return false;
  }
}
export function copyTransaction(raw) {
  const tx = decode(encode(raw));
  requireDOM(shape(tx, SCHEMA.transaction));
  return tx;
}
export const attemptHeader = tx => ({ ...Object.fromEntries("protocol schema owner generation root base_revision target_revision transaction_id digest kind".split(" ").map(k => [k, tx[k]])), operation_count: tx.operations.length });
export const acknowledgement = (tx, state, diagnostic = null) => Object.freeze({ ...Object.fromEntries("protocol schema owner generation root base_revision target_revision transaction_id digest".split(" ").map(k => [k, tx[k]])), record: "ack", state, diagnostic });
export function transactionContext(state, tx) {
  return { owner: state.owner, generation: tx.generation, revision: state.revision, root: state.projection?.root ?? null, disposed: state.disposed,
    nodes: (state.projection?.nodes ?? []).map(({ id, parent }) => ({ id, parent })),
    listeners: Array.from({ length: (state.projection?.nodes ?? []).reduce((n, node) => n + intentCount(node.listeners), 0) }, (_, i) => "bl-" + i.toString(16).padStart(24, "0")), seen: state.seen, transaction: null };
}
export const values = cells => new Map(cells.map(c => [c.name, c.value]));
export const cells = map => [...map].sort(([a], [b]) => a < b ? -1 : a > b ? 1 : 0).map(([name, value]) => ({ name, value }));
export const emptyNode = op => ({ id: op.target, parent: null, children: [], tag: op.tag, text: op.text, attributes: [], properties: [], focus: null, selection: null, listeners: null });

export async function planTransaction(state, tx) {
  requireDOM(tx.owner === state.owner, "ownership");
  requireDOM(tx.kind === "replace" ? tx.generation === state.generation + 1 : tx.generation === state.generation, "stale");
  const context = transactionContext(state, tx);
  await validate(tx, context);
  if (tx.kind === "dispose") return { projection: null, context };
  const nodes = new Map((state.projection?.nodes ?? []).map(n => [n.id, decode(encode(n))]));
  let root = state.projection?.root ?? null;
  const detach = id => {
    const n = nodes.get(id);
    if (n.parent !== null) { const p = nodes.get(n.parent); p.children = p.children.filter(x => x !== id); }
    else if (root === id) root = null;
  };
  const insert = (id, parent, anchor) => {
    const n = nodes.get(id); n.parent = parent;
    if (parent === null) { requireDOM(root === null && anchor === null); root = id; }
    else { const list = nodes.get(parent).children; const i = anchor === null ? list.length : list.indexOf(anchor); requireDOM(i >= 0, "missing-target"); list.splice(i, 0, id); }
  };
  for (const op of tx.operations) {
    if (op.type === "effect_barrier") { requireDOM(op.resources.length === 0, "incompatible"); continue; }
    if (op.type === "create") { nodes.set(op.target, emptyNode(op)); continue; }
    const n = nodes.get(op.target); requireDOM(n, "missing-target");
    if (["insert", "move"].includes(op.type)) { requireDOM(n.parent === op.old_parent, "stale"); detach(op.target); insert(op.target, op.parent, op.anchor); }
    else if (op.type === "remove") { requireDOM(n.children.length === 0 && n.listeners === null && n.parent === op.old_parent, "stale"); detach(op.target); nodes.delete(op.target); }
    else if (op.type === "replace") {
      requireDOM(n.children.length === 0 && n.listeners === null && n.parent === op.parent, "stale");
      detach(op.target); nodes.delete(op.target); insert(op.value, op.parent, op.anchor);
    } else if (op.type === "text") { requireDOM(n.text === op.old, "stale"); n.text = op.new; }
    else if (["attribute", "property"].includes(op.type)) {
      const field = op.type === "attribute" ? "attributes" : "properties", map = values(n[field]);
      requireDOM((map.get(op.name) ?? null) === op.old, "stale");
      if (op.new === null) map.delete(op.name); else map.set(op.name, op.new);
      n[field] = cells(map);
    } else if (op.type === "intent") { requireDOM(n[op.name] === op.old, "stale"); n[op.name] = op.new; }
    else requireDOM(false);
  }
  requireDOM(root === tx.root, "ownership");
  const ordered = [], visited = new Set();
  function visit(id, parent, depth) {
    requireDOM(depth <= 32 && ordered.length < 128, "limit");
    requireDOM(!visited.has(id) && nodes.has(id), "missing-target");
    const n = nodes.get(id); requireDOM(n.parent === parent, "ownership"); visited.add(id); ordered.push(n);
    requireDOM(n.attributes.length <= 32 && n.properties.length <= 5, "limit");
    requireDOM(n.text === null || n.children.length === 0);
    requireDOM(values(n.attributes).has("data-bx-kind"));
    for (const c of n.attributes) if (["aria-labelledby", "aria-describedby", "aria-controls", "aria-owns", "aria-errormessage"].includes(c.name)) {
      const targets = c.value.split(" "); requireDOM(targets.length > 0 && new Set(targets).size === targets.length && targets.every(x => nodes.has(x)), "missing-target");
    }
    for (const name of ["focus", "selection", "listeners"]) requireDOM(validIntent(name, n[name]));
    for (const listener of decodeIntent(n.listeners) ?? []) requireDOM(listener.owner.generation === tx.generation && listener.source.generation === tx.generation, "ownership");
    n.children.forEach(child => visit(child, id, depth + 1));
  }
  visit(root, null, 0); requireDOM(visited.size === nodes.size);
  requireDOM(ordered.reduce((sum, n) => sum + intentCount(n.listeners), 0) <= 256, "limit");
  const projection = { root, nodes: ordered, fingerprint: await digest({ root, nodes: ordered }) };
  return { projection, context };
}
