import fs from "node:fs";
import assert from "node:assert/strict";
import { encode, decode, digest, seal, validate } from "../../js/blazex_runtime/src/render-transaction-v2.js";

const directory = new URL("./", import.meta.url);
const b64 = value => Buffer.from(encode(value)).toString("base64");
const rows = fs.readFileSync(new URL("reconciliation-fixtures-v0.1.0.txt", directory), "utf8").trimEnd().split("\n").map(line => {
  const [name, bytes, hash] = line.split("|");
  return { name, row: decode(Buffer.from(bytes, "base64")), hash };
});
const header = tx => ({ ...Object.fromEntries("protocol schema owner generation root base_revision target_revision transaction_id digest kind".split(" ").map(k => [k, tx[k]])), operation_count: tx.operations.length });

// Independent ordered data replay: this is a test oracle, not a DOM applicator.
async function replay(row) {
  const { transaction: tx, context, before, after } = row;
  await validate(tx, context);
  await validate(row.ack, { ...context, transaction: header(tx) });
  if (tx.kind === "dispose") { assert.equal(after, null); return; }
  const nodes = new Map((before?.nodes ?? []).map(n => [n.id, structuredClone(n)]));
  let root = before?.root ?? null;
  if (before) assert.equal(before.fingerprint, await digest({ root, nodes: before.nodes }));
  const detach = id => {
    const node = nodes.get(id);
    if (node.parent !== null) {
      const parent = nodes.get(node.parent);
      parent.children = parent.children.filter(x => x !== id);
    } else if (root === id) root = null;
  };
  for (const op of tx.operations) {
    if (op.type === "effect_barrier") { assert.deepEqual(op.resources, []); continue; }
    if (op.type === "create") {
      assert.ok(!nodes.has(op.target));
      nodes.set(op.target, { id: op.target, parent: null, children: [], tag: op.tag, text: op.text, attributes: [], properties: [], focus: null, selection: null, listeners: null });
      continue;
    }
    const node = nodes.get(op.target);
    assert.ok(node);
    if (["insert", "move"].includes(op.type)) {
      assert.equal(node.parent, op.old_parent);
      detach(op.target);
      node.parent = op.parent;
      if (op.parent === null) { assert.equal(root, null); assert.equal(op.anchor, null); root = op.target; }
      else {
        const siblings = nodes.get(op.parent).children;
        const index = op.anchor === null ? siblings.length : siblings.indexOf(op.anchor);
        assert.ok(index >= 0);
        siblings.splice(index, 0, op.target);
      }
    } else if (op.type === "remove") {
      assert.deepEqual(node.children, []); assert.equal(node.listeners, null); assert.equal(node.parent, op.old_parent);
      detach(op.target); nodes.delete(op.target);
    } else if (op.type === "text") {
      assert.equal(node.text, op.old); node.text = op.new;
    } else if (["attribute", "property"].includes(op.type)) {
      const field = op.type === "attribute" ? "attributes" : "properties";
      const values = new Map(node[field].map(c => [c.name, c.value]));
      assert.equal(values.get(op.name) ?? null, op.old);
      if (op.new === null) values.delete(op.name); else values.set(op.name, op.new);
      node[field] = [...values].sort(([a], [b]) => a < b ? -1 : a > b ? 1 : 0).map(([name, value]) => ({ name, value }));
    } else if (op.type === "intent") {
      assert.equal(node[op.name], op.old); node[op.name] = op.new;
    } else assert.fail("unexpected emitted operation " + op.type);
  }
  const ordered = [], visited = new Set();
  const visit = id => { assert.ok(!visited.has(id)); visited.add(id); const n = nodes.get(id); assert.ok(n); ordered.push(n); n.children.forEach(visit); };
  visit(root);
  assert.equal(visited.size, nodes.size);
  assert.deepEqual({ root, nodes: ordered, fingerprint: await digest({ root, nodes: ordered }) }, after);
}
const cases = [];
for (const { name, row, hash } of rows) {
  assert.equal(name, row.name); assert.equal(await digest(row), hash);
  await replay(row);
  cases.push({ name: name + "/transaction", expected: "ok", context: row.context, record: row.transaction });
  cases.push({ name: name + "/ack", expected: "ok", context: { ...row.context, transaction: header(row.transaction) }, record: row.ack });
}
const source = rows[0].row;
async function negative(name, expected, mutate, reseal = true, ack = false) {
  const record = structuredClone(ack ? source.ack : source.transaction);
  const context = structuredClone(ack ? { ...source.context, transaction: header(source.transaction) } : source.context);
  mutate(record, context);
  cases.push({ name: "negative/" + name, expected, context, record: !ack && reseal ? await seal(record) : record });
}
await negative("v1", "incompatible", t => { t.protocol = "blazex.dom-transaction/1"; });
await negative("schema", "incompatible", t => { t.schema = "1.0.0"; });
await negative("owner", "ownership", t => { t.owner = "root-other"; });
await negative("generation", "ownership", t => { t.generation++; });
await negative("stale", "stale", t => { t.base_revision++; t.target_revision++; });
await negative("digest", "malformed", t => { t.digest = "0".repeat(64); }, false);
await negative("duplicate", "duplicate", (t, c) => { c.seen = [t.transaction_id]; }, false);
await negative("disposed", "disposed-root", (_t, c) => { c.disposed = true; });
await negative("unsafe-attribute", "malformed", t => { t.operations.find(o => o.type === "attribute").name = "onclick"; });
await negative("invalid-intent", "malformed", t => { t.operations.find(o => o.type === "intent").new = b64({ invalid: true }); });
await negative("intent-integer-negative-zero", "malformed", t => {
  const op = t.operations.find(o => o.type === "intent"); op.name = "selection"; op.new = b64({ kind: "single", value: { type: "integer", value: "-0" } });
});
await negative("forward-dependency", "malformed", t => { t.operations[0].depends = [1]; });
await negative("empty-initial", "malformed", t => { t.operations = []; });
await negative("ack-owner", "ownership", t => { t.owner = "root-other"; }, false, true);
await negative("ack-digest", "ownership", t => { t.digest = "0".repeat(64); }, false, true);
await negative("ack-v1", "incompatible", t => { t.protocol = "blazex.dom-transaction/1"; }, false, true);

const fixtures = [], results = [];
for (const row of cases) {
  let actual = "ok", canonical = "", hash = "";
  try { const value = await validate(row.record, row.context); canonical = b64(value); hash = await digest(value); }
  catch (error) { actual = error.code ?? error.name; }
  assert.equal(actual, row.expected, row.name);
  fixtures.push([row.name, row.expected, b64(row.context), b64(row.record)].join("|"));
  results.push([row.name, actual, canonical, hash].join("|"));
}
for (const [name, value] of Object.entries({ "reconciliation-protocol-fixtures-v0.1.0.txt": fixtures.join("\n") + "\n", "reconciliation-protocol-results-v0.1.0.txt": results.join("\n") + "\n" })) {
  if (process.argv.includes("--write")) fs.writeFileSync(new URL(name, directory), value);
  else assert.equal(fs.readFileSync(new URL(name, directory), "utf8"), value, name + " freshness");
}
if (process.argv.includes("--compare")) assert.equal(fs.readFileSync(process.argv[process.argv.indexOf("--compare") + 1], "utf8"), results.join("\n") + "\n", "Elixir/Node exact bytes, hashes and codes");
console.log(JSON.stringify({ traces: rows.length, cases: cases.length, positive: cases.filter(r => r.expected === "ok").length, negative: cases.filter(r => r.expected !== "ok").length, independent_replay: "exact", result: "passed" }));
