import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import { encode, decode, seal, validate } from "../src/render-transaction-v2.js";
import { validIntent, decodeIntent } from "../src/render-intent-data.js";
import { SCHEMA } from "../src/render-transaction-v2-schema.js";

const root = "bx-" + "1".repeat(24);
const context = { owner: "root-test", generation: 1, revision: 0, root: null, disposed: false, nodes: [], listeners: [], seen: [], transaction: null };
const cell = value => Buffer.from(encode(value)).toString("base64");
async function transaction(extra = []) {
  const ops = [{ type: "create", target: root, tag: "div", text: null }, { type: "insert", target: root, parent: null, anchor: null, old_parent: null }, ...extra];
  return seal({ record: "transaction", protocol: "blazex.dom-transaction/2", schema: "2.0.0", owner: "root-test", generation: 1, root, base_revision: 0, target_revision: 1, transaction_id: "tx-" + "2".repeat(24), kind: "initial", features: ["atomic", "ordered"], operations: ops.map((op, i) => ({ ...op, op_id: i, depends: i ? [i - 1] : [] })) });
}
test("V2 schema is exactly the versioned JSON source", () => {
  const source = JSON.parse(fs.readFileSync(new URL("../../../integration/bh-04/render-transaction-v2.schema.json", import.meta.url)));
  assert.deepEqual(SCHEMA, source.$defs);
});
test("every V2 attribute passes the shared strict protocol", async () => {
  const names = SCHEMA.transaction.properties.operations.items.oneOf.find(s => s.properties.type.enum[0] === "attribute").properties.name.enum;
  for (const name of names) {
    const tx = await transaction([{ type: "attribute", target: root, name, old: null, new: "value" }]);
    assert.deepEqual(await validate(decode(encode(tx)), context), tx);
  }
});
test("focus, selection and listener intent cells use closed canonical data", async () => {
  const focus = { behavior: "target", order: 1, auto_focus: true, restore: "none", wrap: false };
  const selection = { kind: "single", value: { type: "integer", value: "-9007199254741000" } };
  const identity = { root: { type: "atom", value: "root" }, path: [], generation: 1 };
  const listeners = [{ semantic: "activate", native: "click", owner: identity, source: identity }];
  for (const [name, data] of Object.entries({ focus, selection, listeners })) {
    assert.ok(validIntent(name, cell(data)));
    assert.deepEqual(decodeIntent(cell(data)), data);
    const tx = await transaction([{ type: "intent", target: root, name, old: null, new: cell(data) }]);
    assert.deepEqual(await validate(tx, context), tx);
    const invalid = Array.isArray(data) ? [{ ...data[0], unexpected: true }] : { ...data, unexpected: true };
    assert.equal(validIntent(name, cell(invalid)), false);
  }
  assert.equal(validIntent("selection", cell({ kind: "single", value: { type: "integer", value: "-0" } })), false);
  assert.equal(validIntent("focus", "not-base64"), false);
});
test("v1 identity, unknown intent and noncanonical intent are rejected", async () => {
  const tx = await transaction();
  await assert.rejects(validate({ ...tx, protocol: "blazex.dom-transaction/1" }, context), e => e.code === "incompatible");
  for (const [name, value] of [["onclick", null], ["focus", cell({ behavior: "target" })], ["listeners", cell([{ semantic: "activate", native: "eval" }])]]) {
    const invalid = await transaction([{ type: "intent", target: root, name, old: null, new: value }]);
    await assert.rejects(validate(invalid, context), e => e.code === "malformed");
  }
});
