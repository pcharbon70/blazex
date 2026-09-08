import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import {summarize,statistics,sha} from "./acceptance-report.mjs";
const prefix="docs/research/assets/bh-04-baseline/blazex-bh-04-phase-10-";
const raw=JSON.parse(fs.readFileSync(prefix+"measurements-v0.1.0.json"));
const auth=JSON.parse(fs.readFileSync(prefix+"authorization-v0.1.0.json"));
test("nearest-rank statistics retain tail and reject invalid input",()=>{
  assert.equal(statistics(Array.from({length:100},(_,i)=>i+1)).p95,95);
  assert.equal(statistics([1,1,1,100]).max,100);
  for(const values of [[],[NaN],[-1],[Infinity]])assert.throws(()=>statistics(values));
});
test("candidate is not a paint or acceptance claim",()=>{
  const result=summarize(raw,auth);assert.equal(result.paint_budget_state,"unverified-compositor-paint");assert.equal(result.support_state,"unsupported");
});
const mutations={
  "missing browser":d=>d.results.pop(),
  "missing sample":d=>d.results[0].keyed.pop(),
  "failed sample":d=>d.results[0].keyed[1].correct=false,
  "raw hash drift":d=>d.results[0].keyed[1].marks.receipt++,
  "missing queue run":d=>d.results[0].queues.pop(),
  "missing effects":d=>d.results[0].stale.pop(),
  "forged cleanup":d=>d.results[0].cleanup.resources.active++,
  "page failure":d=>d.results[0].page_errors.push("failure"),
  "duplicate transaction":d=>{const row=d.results[0].stale[1];row.transaction_id=d.results[0].stale[0].transaction_id;const {trace_sha256,...body}=row;row.trace_sha256=sha(JSON.stringify(body));},
  "forged ordering with refreshed hash":d=>{const row=d.results[0].keyed[1];row.marks.apply=row.marks.receipt-1;const {trace_sha256,...body}=row;row.trace_sha256=sha(JSON.stringify(body));}
};
for(const [name,mutate]of Object.entries(mutations))test("reject "+name,()=>{const d=structuredClone(raw);mutate(d);assert.throws(()=>summarize(d,auth));});
