import fs from "node:fs";
import assert from "node:assert/strict";
import {createHash} from "node:crypto";
import {fileURLToPath} from "node:url";
export const sha = bytes => createHash("sha256").update(bytes).digest("hex");
export function statistics(values) {
  assert.ok(values.length>0&&values.every(v=>Number.isFinite(v)&&v>=0));
  const sorted=[...values].sort((a,b)=>a-b),mean=values.reduce((a,b)=>a+b,0)/values.length;
  const rank=q=>sorted[Math.max(0,Math.ceil(sorted.length*q)-1)];
  return {samples:values.length,min:sorted[0],max:sorted.at(-1),median:rank(.5),p95:rank(.95),p99:rank(.99),mean,cv_percent:mean===0?0:Math.sqrt(values.reduce((a,b)=>a+(b-mean)**2,0)/values.length)/mean*100};
}
export function summarize(raw,auth) {
  assert.equal(raw.phase,10);assert.equal(raw.platform,"linux");assert.equal(raw.fatal_error,undefined);
  assert.deepEqual(raw.results.map(r=>r.browser),["chrome","firefox"]);
  const browsers=[];
  for(const b of raw.results) {
    assert.ok(b.version&&b.executable);assert.deepEqual(b.page_errors,[]);assert.deepEqual(b.errors,[]);assert.equal(b.result,"passed");
    assert.equal(b.partial_retention_probe.result,"failed");assert.equal(b.partial_retention_probe.keyed.length,2);assert.match(b.partial_retention_probe.errors[0],/injected partial-result/);
    for(const row of [...b.keyed,...b.queues,...b.stale]) {
      const {trace_sha256,...body}=row;assert.equal(trace_sha256,sha(JSON.stringify(body)),"raw trace hash");assert.equal(row.correct,true,"failed sample");
    }
    assert.equal(b.keyed.length,auth.metrics.keyed.samples_per_browser+1);assert.equal(b.keyed.filter(r=>r.warmup).length,1);assert.equal(b.keyed[0].warmup,true);
    for(const [i,row]of b.keyed.entries()) {
      assert.equal(row.sample,i);assert.equal(row.scenario,"keyed-reorder");assert.equal(row.ack.state,"committed");
      for(const key of ["owner","root","generation","transaction_id","digest","base_revision","target_revision"])assert.equal(row.ack[key],row[key]);
      const times=["receipt","pump","accepted","apply","committed","frame1","frame2"].map(k=>row.marks[k]);
      assert.ok(times.every((v,i)=>Number.isFinite(v)&&(i===0||v>=times[i-1])));assert.equal(row.receipt_to_frame_ms,row.marks.frame2-row.marks.receipt);
    }
    assert.equal(b.queues.length,auth.metrics.queue.runs_per_browser);
    for(const [i,q]of b.queues.entries()) {
      assert.equal(q.run,i);assert.equal(q.outcomes.length,65);assert.equal(q.offered.length,65);assert.ok(q.offered.every(n=>n<=64));assert.equal(q.snapshot.max_depth,64);assert.equal(q.coalesced,0);assert.equal(q.sibling.state,"committed");
      assert.equal(q.outcomes.filter(o=>o.ack.state==="committed").length,1);assert.equal(q.outcomes.filter(o=>o.ack.diagnostic==="limit").length,1);assert.equal(q.outcomes.filter(o=>o.ack.diagnostic==="stale").length,63);
      assert.equal(new Set(q.outcomes.map(o=>o.transaction_id)).size,65);
    }
    for(const kind of ["renderer","effects"]) {
      const samples=b.stale.filter(r=>r.path===kind);assert.equal(samples.length,auth.metrics.stale[kind+"_per_browser"]);
      assert.equal(new Set(samples.map(r=>r.transaction_id)).size,1000);
      for(const [i,row]of samples.entries()){assert.equal(row.sample,i);assert.equal(kind==="renderer"?row.ack.diagnostic:row.diagnostic,"stale");}
    }
    assert.equal(b.cleanup.resources.active,0);assert.equal(b.cleanup.inventory.nodes,0);assert.equal(b.cleanup.queued,0);
    const latency=statistics(b.keyed.filter(r=>!r.warmup).map(r=>r.receipt_to_frame_ms));
    browsers.push({browser:b.browser,version:b.version,frame_opportunity_ms:latency,proxy_within_50ms:latency.p95<=50,variance_investigation_required:latency.cv_percent>10,max_queue:64,stale_renderer:1000,stale_effects:1000,rejection_percent:100});
  }
  return {schema_version:"1.0.0",phase:10,browsers,paint_budget_state:"unverified-compositor-paint",result:"measurements-recorded-not-acceptance",support_state:"unsupported"};
}
if(process.argv[1]===fileURLToPath(import.meta.url)) {
  const prefix="docs/research/assets/bh-04-baseline/blazex-bh-04-phase-10-";
  const inputs=Object.fromEntries(["authorization","measurements"].map(k=>[k,fs.readFileSync(prefix+k+"-v0.1.0.json")]));
  const report={...summarize(JSON.parse(inputs.measurements),JSON.parse(inputs.authorization)),source_hashes:Object.fromEntries(Object.entries(inputs).map(([k,b])=>[prefix+k+"-v0.1.0.json",sha(b)]))};
  const output=JSON.stringify(report,null,2)+"\n",target=prefix+"statistics-v0.1.0.json";
  if(process.argv.includes("--write"))fs.writeFileSync(target,output);else assert.equal(fs.readFileSync(target,"utf8"),output,"stale report");
  console.log(JSON.stringify(report.browsers));
}
