import { SCHEMA } from "./render-transaction-schema.js";
import { encode, decode, digest, fail, ProtocolError } from "./render-transaction-codec.js";
export { encode, decode, digest, ProtocolError };

function shape(value, schema) {
  if (schema.oneOf) return schema.oneOf.filter(s => shape(value, s)).length === 1;
  if (schema.enum) return schema.enum.includes(value);
  switch (schema.type) {
    case "null": return value === null;
    case "boolean": return typeof value === "boolean";
    case "integer": return Number.isSafeInteger(value) && value >= schema.minimum && value <= schema.maximum;
    case "string": return typeof value === "string" && new TextEncoder().encode(value).length <= schema.maxBytes && (!schema.pattern || new RegExp(schema.pattern).test(value));
    case "array": return Array.isArray(value) && value.length >= (schema.minItems ?? 0) && value.length <= schema.maxItems && value.every(x => shape(x, schema.items));
    case "object": return value !== null && Object.getPrototypeOf(value) === Object.prototype && Object.keys(value).length === schema.required.length && schema.required.every(k => Object.hasOwn(value, k) && shape(value[k], schema.properties[k]));
    default: return false;
  }
}
function require(ok, code = "malformed") { if (!ok) fail(code); }
function unique(values) { return new Set(values).size === values.length; }
function topology(nodes) {
  require(nodes.size <= 128, "limit");
  for (const [id] of nodes) {
    let cursor = id, depth = 0;
    const seen = new Set();
    while (cursor !== null) {
      require(nodes.has(cursor), "missing-target");
      require(!seen.has(cursor), "malformed");
      seen.add(cursor);
      require(depth++ <= 32, "limit");
      cursor = nodes.get(cursor);
    }
  }
}
function preflight(tx, context) {
  require(tx.features.join(",") === "atomic,ordered", "incompatible");
  require(tx.owner === context.owner && tx.generation === context.generation, "ownership");
  require(!context.disposed, "disposed-root");
  require(tx.base_revision === context.revision && tx.target_revision === context.revision + 1, "stale");
  require(!context.seen.includes(tx.transaction_id), "duplicate");
  require(unique(context.nodes.map(n => n.id)) && unique(context.listeners) && unique(context.seen), "duplicate");
  const nodes = new Map(context.nodes.map(n => [n.id, n.parent]));
  topology(nodes);
  require(context.root === null ? nodes.size === 0 : nodes.has(context.root) && nodes.get(context.root) === null && [...nodes.values()].filter(x => x === null).length === 1);
  if (tx.kind === "initial") require(context.root === null && context.revision === 0 && nodes.size === 0, "stale");
  else require(context.root !== null, "missing-target");
  if (tx.kind === "patch" || tx.kind === "dispose") require(tx.root === context.root, "ownership");
  if (tx.kind === "dispose") { require(tx.operations.length === 0); return; }
  require(tx.operations.length > 0);
  const detached = new Set(), listeners = new Set(context.listeners);
  function target(id) { require(nodes.has(id), "missing-target"); }
  function leaf(id) { require(![...nodes.values()].includes(id)); }
  function location(op) {
    if (op.parent !== null) target(op.parent);
    require(op.target !== op.parent && op.anchor !== op.target);
    if (op.anchor !== null) { target(op.anchor); require(nodes.get(op.anchor) === op.parent); }
  }
  tx.operations.forEach((op, index) => {
    require(op.op_id === index && unique(op.depends) && op.depends.every((n, i) => n < index && (i === 0 || n > op.depends[i - 1])));
    if (op.type === "create") {
      require(!nodes.has(op.target), "duplicate"); nodes.set(op.target, null); detached.add(op.target);
    } else if (op.type === "effect_barrier") {
      require(index === tx.operations.length - 1 && unique(op.resources));
    } else {
      target(op.target);
      if (op.type === "insert" || op.type === "move") {
        location(op);
        require(op.type === "insert" ? detached.has(op.target) : !detached.has(op.target));
        require(nodes.get(op.target) === op.old_parent, "stale");
        nodes.set(op.target, op.parent); detached.delete(op.target);
      } else if (op.type === "remove") {
        leaf(op.target); require(nodes.get(op.target) === op.old_parent, "stale");
        nodes.delete(op.target); detached.delete(op.target);
      } else if (op.type === "replace") {
        leaf(op.target); target(op.value); location(op);
        require(detached.has(op.value) && op.target !== op.value && nodes.get(op.target) === op.parent);
        require(op.anchor !== op.value && op.parent !== op.value);
        nodes.delete(op.target); detached.delete(op.target); nodes.set(op.value, op.parent); detached.delete(op.value);
      } else if (op.type === "listener") {
        require(op.old !== op.new && listeners.has(op.listener) === op.old, "stale");
        if (op.new) listeners.add(op.listener); else listeners.delete(op.listener);
        require(listeners.size <= 256, "limit");
      } else if (op.type === "property") {
        require([op.old, op.new].every(x => x === null || typeof x === (op.name === "value" ? "string" : "boolean")));
      } else if (op.type === "focus" && op.old !== null) target(op.old);
      else if (op.type === "selection") require([op.old, op.new].every(x => x === null || x.start <= x.end));
    }
    topology(nodes);
  });
  require(nodes.has(tx.root) && nodes.get(tx.root) === null, "missing-target");
  require([...nodes.values()].filter(x => x === null).length === 1 && detached.size === 0);
}
export async function seal(transaction) {
  const { digest: ignored, ...payload } = transaction;
  return { ...payload, digest: await digest(payload) };
}
export async function validate(record, context) {
  // Clone through the bounded codec: callers retain no mutable references.
  const value = decode(encode(record)), scope = decode(encode(context));
  require(value !== null && value.protocol === "blazex.dom-transaction/1" && value.schema === "1.0.0", "incompatible");
  require(shape(value, SCHEMA[value.record] ?? {}));
  require(shape(scope, SCHEMA.context));
  if (value.record === "transaction") {
    preflight(value, scope);
    const { digest: claimed, ...payload } = value;
    require(claimed === await digest(payload), "malformed");
  } else {
    require(scope.transaction !== null);
    require(scope.transaction.owner === scope.owner && scope.transaction.generation === scope.generation, "ownership");
    for (const key of ["owner", "generation", "root", "base_revision", "target_revision", "transaction_id", "digest"])
      require(value[key] === scope.transaction[key], "ownership");
    if (value.record === "ack") {
      const failed = ["rejected", "rolled-back", "fallback"].includes(value.state);
      require(failed === (value.diagnostic !== null));
      if (!failed) {
        require(scope.transaction.protocol === value.protocol && scope.transaction.schema === value.schema, "incompatible");
        require(value.base_revision === scope.revision && value.target_revision === scope.revision + 1, "stale");
      }
      require(value.state !== "disposed" || scope.transaction.kind === "dispose");
      require(value.state !== "committed" || scope.transaction.kind !== "dispose");
    } else require(value.operation_id === null || value.operation_id < scope.transaction.operation_count);
  }
  function freeze(v) { if (v && typeof v === "object") { Object.values(v).forEach(freeze); Object.freeze(v); } return v; }
  return freeze(value);
}
