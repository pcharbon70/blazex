import { seal, encode } from "../../js/blazex_runtime/src/render-transaction.js";
const id = n => "bx-" + n.toString(16).padStart(24, "0");
const lid = n => "bl-" + n.toString(16).padStart(24, "0");
const tid = n => "tx-" + n.toString(16).padStart(24, "0");
const root = id(1), child = id(2);
const empty = { owner: "root-demo", generation: 1, revision: 0, root: null, disposed: false, nodes: [], listeners: [], seen: [], transaction: null };
const live = { ...empty, revision: 1, root, nodes: [{ id: root, parent: null }, { id: child, parent: root }] };
const clone = x => structuredClone(x);
function ops(values) { return values.map((op, i) => ({ op_id: i, depends: i ? [i - 1] : [], ...op })); }
async function tx(kind, operations, context = live, overrides = {}) {
  return seal({ record: "transaction", protocol: "blazex.dom-transaction/1", schema: "1.0.0", owner: context.owner, generation: context.generation, root, base_revision: context.revision, target_revision: context.revision + 1, transaction_id: tid(1), kind, features: ["atomic", "ordered"], operations: ops(operations), ...overrides });
}
const create = (target = root) => ({ type: "create", target, tag: "div", text: null });
const insert = (target = root, parent = null) => ({ type: "insert", target, parent, anchor: null, old_parent: null });
const text = (value = "hello 🌍") => ({ type: "text", target: root, old: null, new: value });
function correlation(source) {
  const { record, operations, features, ...header } = source;
  return { ...header, operation_count: operations.length };
}
export async function cases() {
  const rows = [];
  const add = (name, expected, record, context = live) => rows.push({ name, expected, record, context: clone(context) });
  const initial = await tx("initial", [create(), insert()], empty);
  const patch = await tx("patch", [
    create(id(3)), insert(id(3), root),
    { type: "move", target: child, parent: root, anchor: id(3), old_parent: root },
    text(), { type: "attribute", target: root, name: "aria-label", old: null, new: "Greeting" },
    { type: "property", target: child, name: "value", old: null, new: "hello" },
    { type: "listener", target: child, listener: lid(1), event: "change", old: false, new: true },
    { type: "focus", target: child, old: root, new: true },
    { type: "selection", target: child, old: null, new: { start: 0, end: 5, direction: "forward" } },
    { type: "effect_barrier", barrier: "post-commit", resources: ["resource-focus"] }
  ]);
  add("initial", "ok", initial, empty);
  add("patch-all-value-operations", "ok", patch);
  add("remove", "ok", await tx("patch", [{ type: "remove", target: child, old_parent: root }]));
  add("replace-child", "ok", await tx("replace", [create(id(3)), { type: "replace", target: child, value: id(3), parent: root, anchor: null }]));
  const dispose = await tx("dispose", []);
  add("dispose", "ok", dispose);
  for (const state of ["preflight", "accepted", "committed", "rejected", "rolled-back", "fallback", "disposed"]) {
    const source = state === "disposed" ? dispose : patch;
    const { kind, features, operations, ...header } = source;
    add("ack-" + state, "ok", { ...header, record: "ack", state, diagnostic: ["rejected", "rolled-back", "fallback"].includes(state) ? "apply" : null }, { ...live, transaction: correlation(source) });
  }
  for (const code of ["malformed", "incompatible", "stale", "duplicate", "missing-target", "ownership", "limit", "apply", "rollback", "disposed-root"]) {
    const { kind, features, operations, ...header } = patch;
    add("diagnostic-" + code, "ok", { ...header, record: "diagnostic", code, operation_id: 0 }, { ...live, transaction: correlation(patch) });
  }
  const simple = await tx("patch", [text()]);
  for (const [name, expected, mutate] of [
    ["version", "incompatible", r => r.protocol = "unknown/2"],
    ["schema-version", "incompatible", r => r.schema = "2.0.0"],
    ["extra-field", "malformed", r => r.secret = "forbidden"],
    ["owner", "ownership", r => r.owner = "root-other"],
    ["owner-newline", "malformed", r => r.owner = "root-demo\n"],
    ["generation", "ownership", r => r.generation = 2],
    ["stale-base", "stale", r => r.base_revision = 0],
    ["target-gap", "stale", r => r.target_revision = 3],
    ["capability", "incompatible", r => r.features.reverse()],
    ["digest", "malformed", r => r.digest = "0".repeat(64)],
    ["operation-id", "malformed", r => r.operations[0].op_id = 2],
    ["forward-dependency", "malformed", r => r.operations[0].depends = [0]],
    ["missing-target", "missing-target", r => r.operations[0].target = id(99)],
    ["extra-operation-field", "malformed", r => r.operations[0].execute = "evil"],
    ["unknown-operation", "malformed", r => r.operations[0].type = "html"]
  ]) {
    const record = clone(simple); mutate(record);
    add(name, expected, record);
  }
  add("duplicate-transaction", "duplicate", simple, { ...live, seen: [tid(1)] });
  add("disposed-root", "disposed-root", simple, { ...live, disposed: true });
  add("duplicate-node", "duplicate", simple, { ...live, nodes: [...live.nodes, live.nodes[0]] });
  add("cycle", "malformed", await tx("patch", [{ type: "move", target: root, old_parent: null, parent: child, anchor: null }]));
  add("wrong-old-parent", "stale", await tx("patch", [{ type: "move", target: child, old_parent: null, parent: root, anchor: null }]));
  add("remove-parent-first", "malformed", await tx("patch", [{ type: "remove", target: root, old_parent: null }]));
  add("insert-before-create", "missing-target", await tx("patch", [insert(id(3), root), create(id(3))]));
  add("detached-final-node", "malformed", await tx("patch", [create(id(3))]));
  add("wrong-property-type", "malformed", await tx("patch", [{ type: "property", target: child, name: "checked", old: null, new: "true" }]));
  add("selection-reversed", "malformed", await tx("patch", [{ type: "selection", target: child, old: null, new: { start: 2, end: 1, direction: "forward" } }]));
  add("barrier-not-last", "malformed", await tx("patch", [{ type: "effect_barrier", barrier: "post-commit", resources: [] }, text()]));
  const ack = clone(rows.find(r => r.name === "ack-committed"));
  ack.record.owner = "root-other"; ack.name = "ack-cross-root"; ack.expected = "ownership"; rows.push(ack);
  const badAck = clone(rows.find(r => r.name === "ack-committed"));
  badAck.record.diagnostic = "apply"; badAck.name = "ack-partial-success"; badAck.expected = "malformed"; rows.push(badAck);
  const staleAck = clone(rows.find(r => r.name === "ack-rejected"));
  staleAck.name = "ack-rejected-stale"; staleAck.record.base_revision = 0;
  staleAck.record.diagnostic = "stale"; staleAck.context.transaction.base_revision = 0;
  rows.push(staleAck);
  const incompatibleAck = clone(rows.find(r => r.name === "ack-rejected"));
  incompatibleAck.name = "ack-rejected-incompatible";
  incompatibleAck.record.diagnostic = "incompatible";
  incompatibleAck.context.transaction.protocol = "unknown/2";
  rows.push(incompatibleAck);

  add("text-byte-boundary", "ok", await tx("patch", [text("é".repeat(2048))]));
  add("value-byte-boundary", "ok", await tx("patch", [{ type: "property", target: child, name: "value", old: null, new: "é".repeat(1024) }]));
  add("attribute-byte-boundary", "ok", await tx("patch", [{ type: "attribute", target: child, name: "aria-label", old: null, new: "x".repeat(2048) }]));
  add("operations-boundary", "ok", await tx("patch", Array.from({ length: 512 }, () => text(""))));
  const nodes = Array.from({ length: 128 }, (_, n) => ({ id: id(n + 1), parent: n ? root : null }));
  add("nodes-boundary", "ok", simple, { ...live, nodes });
  add("nodes-overflow", "limit", await tx("patch", [create(id(129)), insert(id(129), root)]), { ...live, nodes });
  const chain = Array.from({ length: 33 }, (_, n) => ({ id: id(n + 1), parent: n ? id(n) : null }));
  add("depth-boundary", "ok", simple, { ...live, nodes: chain });
  add("depth-overflow", "limit", simple, { ...live, nodes: [...chain, { id: id(34), parent: id(33) }] });
  const listeners = Array.from({ length: 256 }, (_, n) => lid(n + 1));
  add("listeners-boundary", "ok", simple, { ...live, listeners });
  add("listeners-overflow", "limit", await tx("patch", [{ type: "listener", target: root, listener: lid(257), event: "activate", old: false, new: true }]), { ...live, listeners });
  add("queue-window-boundary", "ok", simple, { ...live, seen: Array.from({ length: 64 }, (_, n) => tid(n + 2)) });
  add("safe-integer-boundary", "ok", await tx("patch", [text()], { ...live, revision: Number.MAX_SAFE_INTEGER - 1 }), { ...live, revision: Number.MAX_SAFE_INTEGER - 1 });
  const message = await tx("patch", Array.from({ length: 32 }, () => text("")));
  let remaining = 131072 - encode(message).length - 128;
  for (const op of message.operations) { const size = Math.min(4096, remaining); op.new = "x".repeat(size); remaining -= size; }
  if (remaining !== 0) throw new Error("message-boundary construction");
  const padding = message.operations.find(op => op.new.length > 100 && op.new.length < 4000);
  while (encode(message).length < 131072) padding.new += "x";
  add("message-byte-boundary", "ok", await seal(message));
  for (const [name, raw, expected] of [
    ["trailing-byte", "nX", "malformed"], ["nonminimal-integer", "i01;", "malformed"],
    ["negative-integer", "i-1;", "malformed"], ["float", "i1.0;", "malformed"],
    ["integer-newline", "i1\n;", "malformed"],
    ["duplicate-map-key", "m2:s1:ans1:an", "malformed"],
    ["map-order", "m2:s1:bns1:an", "malformed"],
    ["text-byte-overflow", "s4097:" + "x".repeat(4097), "limit"],
    ["message-byte-overflow", "x".repeat(131073), "limit"]
  ]) rows.push({ name, expected, raw_base64: Buffer.from(raw).toString("base64"), context: live });
  rows.push({ name: "invalid-utf8", expected: "malformed", raw_base64: Buffer.from([115,49,58,255]).toString("base64"), context: live });
  return rows;
}
