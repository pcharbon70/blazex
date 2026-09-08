import fs from "node:fs";
import assert from "node:assert/strict";
import {decode} from "../../js/blazex_runtime/src/render-transaction-v2.js";
import {compare,compareBindings} from "./conformance-scenarios.js";
import {sha} from "./acceptance-report.mjs";
const prefix=process.argv[2]??"docs/research/assets/bh-04-baseline/blazex-bh-04-phase-10-";
const expected={atomic:{scenarios:50,injected_boundaries:1204,stale_rejected:100,max_queue:64,terminal_acks:1254,cleanup:1263},interaction:{mappings:13,rejected:17,roots:3,dom_commits:18,cleanup:3,max_queue:64,trusted_clicks:1,no_render_events:2},continuity:{scenarios:16,roots:2,cleanup:2},effect:{scenarios:19,roots:24,cleanup:24}};
for(const [name,counters]of Object.entries(expected)){
  const raw=JSON.parse(fs.readFileSync(prefix+name+"-browser-v0.1.0.json"));
  assert.equal(raw.platform,"linux");assert.deepEqual(raw.results.map(r=>r.browser),["chrome","firefox"]);
  for(const row of raw.results){assert.equal(row.result,"passed");assert.equal(row.support_state,"unsupported");assert.deepEqual(row.counters,counters);assert.ok(row.version);}
  if(name==="effect")for(const row of raw.results){
    assert.equal(row.observation_window_ms,1000);
    for(const s of row.late)assert.ok(s.resources.active===0&&s.inventory.nodes===0&&s.inventory.interaction.queued===0&&s.queued===0);
    for(const c of row.cleanup)assert.ok(c.elapsed_ms<1000&&c.snapshot.resources.active===0&&c.snapshot.resources.failures===0);
  }
}
const rows=fs.readFileSync("integration/bh-04/conformance-fixtures-v0.1.0.txt","utf8").trim().split("\n").map(l=>decode(Buffer.from(l.split("|")[1],"base64")));
assert.equal(rows.length,51);
const semantic=JSON.parse(fs.readFileSync(prefix+"semantic-browser-v0.1.0.json"));
assert.deepEqual(semantic.results.map(r=>r.browser),["chrome","firefox"]);
for(const browser of semantic.results){
  assert.equal(browser.traces.length,102);assert.equal(browser.repetitions,2);
  for(let repeat=0;repeat<2;repeat++)for(let i=0;i<51;i++){
    const row=rows[i],trace=browser.traces[repeat*51+i];compareBindings(row);compare(row,trace.observed);
    assert.equal(trace.scenario,row.scenario_id);assert.equal(trace.repeat,repeat);assert.equal(trace.result,"passed");
    assert.deepEqual(trace.observed,semantic.results[0].traces[i].observed);
    for(const key of ["owner","generation","transaction_id","digest","base_revision","target_revision"])assert.equal(trace.ack[key],row.transaction[key]);
    assert.equal(trace.ack.state,row.after?"committed":"disposed");
    if(row.setup&&row.transaction.operations.length)assert.equal(trace.rollback.state,"rolled-back");
    if(row.after)assert.equal(trace.duplicate.state,"rejected");
    assert.ok(trace.cleanup.disposed&&trace.cleanup.nodes===0&&trace.cleanup.listeners===0&&trace.cleanup.queued===0);
  }
}
const isolation=JSON.parse(fs.readFileSync(prefix+"isolation-v0.1.0.json"));
assert.equal(isolation.result,"passed");assert.equal(isolation.framework_directories,"physically-absent");assert.equal(isolation.headless_tests,6);assert.equal(isolation.standalone_tests,116);
for(const [file,hash]of Object.entries(isolation.source_hashes))assert.equal(sha(fs.readFileSync(file)),hash);
console.log("Fresh Phase 10 corpora verified: both engines, 204 semantic observations, fault counts, cleanup and isolation.");
