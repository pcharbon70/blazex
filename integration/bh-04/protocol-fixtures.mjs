import fs from "node:fs";
import assert from "node:assert/strict";
import { fileURLToPath } from "node:url";
import { cases } from "./protocol-cases.mjs";
import { encode, decode, validate, digest } from "../../js/blazex_runtime/src/render-transaction.js";
const directory = fileURLToPath(new URL("./", import.meta.url));
const rows = await cases();
const lines = [], results = [];
for (const row of rows) {
  const bytes = row.raw_base64 ? Buffer.from(row.raw_base64, "base64") : encode(row.record);
  let actual, canonical = "", hash = "";
  try {
    const record = await validate(decode(bytes), row.context);
    canonical = Buffer.from(encode(record)).toString("base64");
    hash = await digest(record); actual = "ok";
    assert.equal(Object.isFrozen(record), true);
  } catch (error) { actual = error.code ?? error.name; }
  assert.equal(actual, row.expected, row.name);
  lines.push([row.name, row.expected, Buffer.from(encode(row.context)).toString("base64"), Buffer.from(bytes).toString("base64")].join("|"));
  results.push([row.name, actual, canonical, hash].join("|"));
}
const artifacts = {
  "protocol-fixtures-v0.1.0.txt": lines.join("\n") + "\n",
  "protocol-results-v0.1.0.txt": results.join("\n") + "\n"
};
if (process.argv.includes("--write")) {
  for (const [name, content] of Object.entries(artifacts)) fs.writeFileSync(directory + name, content);
} else {
  for (const [name, content] of Object.entries(artifacts)) assert.equal(fs.readFileSync(directory + name, "utf8"), content, name + " generated freshness");
}
if (process.argv.includes("--compare")) {
  assert.equal(fs.readFileSync(process.argv[process.argv.indexOf("--compare") + 1], "utf8"), artifacts["protocol-results-v0.1.0.txt"], "Elixir/JavaScript exact bytes, digests and codes");
}
console.log(JSON.stringify({ cases: rows.length, positive: rows.filter(r => r.expected === "ok").length, negative: rows.filter(r => r.expected !== "ok").length, result: "passed" }));
