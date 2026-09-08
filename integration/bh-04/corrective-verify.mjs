import fs from "node:fs";
import assert from "node:assert/strict";
import { gunzipSync } from "node:zlib";
import { sha } from "./acceptance-report.mjs";
import { presentationReport } from "./presentation-trace.mjs";
import { validateCorrectiveMeasurements } from "./corrective-report.mjs";
import { decode } from "../../js/blazex_runtime/src/render-transaction-v2.js";
const prefix = "docs/research/assets/bh-04-correction/";
const report = JSON.parse(fs.readFileSync(prefix + "presentation.json"));
assert.equal(report.platform, "linux"); assert.equal(report.error, undefined);
assert.deepEqual(report.results.map(b => b.browser), ["chrome", "firefox"]);
for (const [file, hash] of Object.entries(report.source_hashes)) assert.equal(sha(fs.readFileSync(file)), hash, file);
const fixture = fs.readFileSync("integration/bh-04/atomic-dom-fixtures-v0.1.0.txt", "utf8").trim().split("\n").map(l => decode(Buffer.from(l.split("|")[1], "base64"))).find(r => r.name === "keyed-reorder");
for (const b of report.results) {
  assert.equal(b.error, undefined); assert.deepEqual(b.page_errors, []);
  const bytes = fs.readFileSync(prefix + b.browser + "-native.json.gz"); assert.equal(sha(bytes), b.trace.sha256);
  assert.deepEqual(presentationReport(b.browser, JSON.parse(gunzipSync(bytes)), b.samples), b.presentation);
  assert.equal(b.presentation.result, "measurements-within-budget-not-acceptance");
  assert.equal(b.samples.length, 101);
  for (const sample of b.samples) for (const key of ["owner", "root", "generation", "transaction_id", "digest", "base_revision", "target_revision"]) assert.equal(sample.ack[key], fixture.transaction[key]);
  assert.deepEqual(b.regression, ["text", "check"].flatMap(kind => ["activate", "move", "reorder"].map(semantic => ({ kind, semantic, result: "passed" }))));
  assert.equal(b.retention_probe.length, 2); assert.equal(b.retention_probe[0].error, null); assert.match(b.retention_probe[1].error, /injected late cleanup failure/);
}
const raw = JSON.parse(gunzipSync(fs.readFileSync(prefix + "stale-queue.json.gz")));
for (const [file, hash] of Object.entries(raw.source_hashes)) assert.equal(sha(fs.readFileSync(file)), hash, file);
validateCorrectiveMeasurements(raw, JSON.parse(fs.readFileSync("docs/research/assets/bh-04-baseline/blazex-bh-04-phase-10-authorization-v0.1.0.json")));
console.log("Both native traces, 200 measured presentations, draft/retention regressions and 4000 seeded stale rejections verified.");
