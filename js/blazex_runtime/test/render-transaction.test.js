import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import { cases } from "../../../integration/bh-04/protocol-cases.mjs";
import { encode, decode, validate, ProtocolError } from "../src/render-transaction.js";
import { SCHEMA } from "../src/render-transaction-schema.js";

test("schema constants equal the versioned source", () => {
  const schema = JSON.parse(fs.readFileSync(new URL("../../../integration/bh-04/render-transaction.schema.json", import.meta.url)));
  assert.deepEqual(SCHEMA, schema.$defs);
});
for (const row of await cases()) {
  test("protocol: " + row.name, async () => {
    const context = structuredClone(row.context);
    const record = row.record && structuredClone(row.record);
    if (row.expected === "ok") {
      const result = await validate(decode(encode(record)), context);
      assert.deepEqual(result, record);
      assert.ok(Object.isFrozen(result));
    } else {
      await assert.rejects(async () => {
        const value = row.raw_base64 ? decode(Buffer.from(row.raw_base64, "base64")) : decode(encode(record));
        await validate(value, context);
      }, error => error instanceof ProtocolError && error.code === row.expected);
    }
    assert.deepEqual(context, row.context);
    if (record) assert.deepEqual(record, row.record);
  });
}
test("canonical map order, unicode and malformed local inputs", () => {
  assert.deepEqual(encode({ b: "🌍", a: 1 }), encode({ a: 1, b: "🌍" }));
  for (const value of [NaN, Infinity, -0, -1, 1.5, undefined, new Date(), { a: "\uD800" }])
    assert.throws(() => encode(value), ProtocolError);
  assert.throws(() => encode({ get a() { throw new Error("must not execute getter"); } }), ProtocolError);
});
test("no browser or runtime surface is referenced by pure validation", () => {
  for (const file of ["render-transaction.js", "render-transaction-codec.js"]) {
    const source = fs.readFileSync(new URL("../src/" + file, import.meta.url), "utf8");
    assert.doesNotMatch(source, /document\.|window\.|fetch\(|dispatchEvent|postMessage|Phoenix|LiveView/);
  }
});
