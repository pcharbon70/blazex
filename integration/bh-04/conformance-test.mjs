import fs from "node:fs";
import assert from "node:assert/strict";
import { decode, digest } from "../../js/blazex_runtime/src/render-transaction-v2.js";
import { decodeIntent } from "../../js/blazex_runtime/src/render-intent-data.js";
import { compare, compareBindings } from "./conformance-scenarios.js";
const rows = [];
for (const line of fs.readFileSync(new URL("conformance-fixtures-v0.1.0.txt", import.meta.url), "utf8").trim().split("\n")) {
  const [name, payload, hash] = line.split("|"), row = decode(Buffer.from(payload, "base64"));
  assert.equal(row.scenario_id, name); assert.equal(await digest(row), hash); rows.push(row);
}
assert.equal(rows.length, 51);
let negatives = 0;
for (const row of rows) {
  compareBindings(row);
  const expected = (row.after?.nodes ?? []).map(n => ({...n, attributes: Object.fromEntries(n.attributes.map(c => [c.name,c.value]))}));
  for (const n of expected) { const focus = decodeIntent(n.focus); if (focus?.behavior === "target") n.attributes.tabindex = String(focus.order); }
  assert.ok(compare(row, expected));
  if (expected.length) for (const mutate of [a => a.pop(), a => a[0].text = "wrong", a => a[0].attributes["data-bx-kind"] = "wrong", a => a[0].tag = "wrong", a => a[0].children.push("missing"), a => a[0].attributes["aria-hidden"] = "true"]) {
    const copy = structuredClone(expected); mutate(copy); assert.throws(() => compare(row, copy)); negatives++;
  }
}
console.log(JSON.stringify({scenarios: rows.length, comparator_negatives: negatives, result: "passed"}));
