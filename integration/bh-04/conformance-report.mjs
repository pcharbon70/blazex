import fs from "node:fs";
import assert from "node:assert/strict";
import {createHash} from "node:crypto";
import {decode,digest} from "../../js/blazex_runtime/src/render-transaction-v2.js";
import {compare,compareBindings} from "./conformance-scenarios.js";
const directory = new URL("../../docs/research/assets/bh-04-baseline/",import.meta.url);
const sha = bytes => createHash("sha256").update(bytes).digest("hex");
const prefix = "blazex-bh-04-phase-09-";
const hashes = {}, inputs = {};
for (const name of ["semantic","atomic","interaction","continuity","effect"]) {
  const filename = prefix+name+"-browser-v0.1.0.json", bytes=fs.readFileSync(new URL(filename,directory));
  hashes[filename]=sha(bytes); inputs[name]=JSON.parse(bytes);
  assert.equal(inputs[name].platform,"linux");
  assert.deepEqual(inputs[name].results.map(r=>r.browser),["chrome","firefox"]);
  for(const row of inputs[name].results) {
    assert.equal(row.result,"passed");assert.equal(row.support_state,"unsupported");
    assert.ok(row.version && row.executable);
    for(const request of row.network ?? []) {
      assert.equal(request.method,"GET");
      if(request.url) assert.equal(new URL(request.url).hostname,"127.0.0.1");
      assert.ok(!/liveview|local_live_view/i.test(request.path ?? request.url));
    }
  }
}
const fixtures=fs.readFileSync(new URL("conformance-fixtures-v0.1.0.txt",import.meta.url));
hashes["conformance-fixtures-v0.1.0.txt"]=sha(fixtures);
const rows=[];
for(const line of fixtures.toString().trim().split("\n")) {
  const [id,payload,hash]=line.split("|"), row=decode(Buffer.from(payload,"base64"));
  assert.equal(row.scenario_id,id);assert.equal(await digest(row),hash);compareBindings(row);rows.push(row);
}
assert.equal(rows.length,51);assert.equal(new Set(rows.map(r=>r.scenario_id)).size,51);
const ledger=[];
for(const row of rows) ledger.push({scenario:row.scenario_id,path:"headless",result:"passed",digest:row.headless_after?.digest ?? null,source:"conformance-fixtures-v0.1.0.txt"});
for(const browser of inputs.semantic.results) {
  assert.equal(browser.scenarios,51);assert.equal(browser.repetitions,2);assert.equal(browser.traces.length,102);
  for(let repeat=0;repeat<2;repeat++)for(let i=0;i<rows.length;i++) {
    const row=rows[i],trace=browser.traces[repeat*51+i];
    assert.equal(trace.scenario,row.scenario_id);assert.equal(trace.repeat,repeat);assert.equal(trace.result,"passed");
    compare(row,trace.observed);
    for(const key of ["owner","generation","transaction_id","digest","base_revision","target_revision"])assert.equal(trace.ack[key],row.transaction[key]);
    assert.equal(trace.ack.state,row.after?"committed":"disposed");
    if(row.setup && row.transaction.operations.length)assert.equal(trace.rollback.state,"rolled-back");
    if(row.after)assert.equal(trace.duplicate.state,"rejected");
    assert.ok(trace.cleanup.disposed && trace.cleanup.nodes===0 && trace.cleanup.listeners===0 && trace.cleanup.queued===0);
    assert.deepEqual(trace.observed,browser.traces[i].observed,"repeat drift");
    assert.deepEqual(trace.observed,inputs.semantic.results[0].traces[i].observed,"cross-engine semantic drift");
    ledger.push({scenario:row.scenario_id,path:browser.browser,repeat,result:"passed",observation_sha256:sha(JSON.stringify(trace.observed)),accessibility_sha256:sha(trace.accessibility)});
  }
}
const expected={atomic:{scenarios:50,injected_boundaries:1204,stale_rejected:100,max_queue:64,terminal_acks:1254,cleanup:1263},interaction:{mappings:13,rejected:17,roots:3,dom_commits:18,cleanup:3,max_queue:64,trusted_clicks:1,no_render_events:2},continuity:{scenarios:16,roots:2,cleanup:2},effect:{scenarios:19,roots:24,cleanup:24}};
for(const [name,counts]of Object.entries(expected))for(const browser of inputs[name].results){
  assert.deepEqual(browser.counters,counts);assert.ok(browser.traces.length>0);
  ledger.push({scenario:name+"-full-corpus",path:browser.browser,result:"passed",counts,source:prefix+name+"-browser-v0.1.0.json"});
}
const isolationBytes=fs.readFileSync(new URL(prefix+"isolation-v0.1.0.json",directory)),isolation=JSON.parse(isolationBytes);
hashes[prefix+"isolation-v0.1.0.json"]=sha(isolationBytes);
assert.equal(isolation.result,"passed");assert.equal(isolation.framework_directories,"physically-absent");
assert.equal(isolation.headless_tests,6);assert.equal(isolation.standalone_tests,116);
for(const [file,expectedHash]of Object.entries(isolation.source_hashes))assert.equal(sha(fs.readFileSync(new URL("../../"+file,import.meta.url))),expectedHash);
const report={schema_version:"1.0.0",phase:9,result:"passed",support_state:"unsupported",source_hashes:hashes,active_rows:ledger.length,ledger,
  browsers:inputs.semantic.results.map(r=>({browser:r.browser,version:r.version})),
  deferred:[{scope:"LiveView/LocalLiveView integration and equivalence",owner:"liveview-adapter-owner",reactivation:"separate owner-authorized work after BH-04"},{scope:"external platforms and manual assistive technology",owner:"platform/accessibility owners",reactivation:"BH-22"}],
  not_applicable:[{path:"headless",observations:"native focus, selection, Web API effects and browser accessibility tree; semantic intent remains active"}],
  accessibility_method:inputs.semantic.accessibility_method,next_eligible_phase:10,next_authorized_work:null};
const applications = ["interaction_counter.exs","continuity_component.exs","effect_component.exs"];
report.architecture_audit = {application_sources:{},headless_profile:"framework-free Mix dependency declarations",future_plug:"not activated; no build or support credit",profile_dependencies_unchanged:true};
for(const file of applications) {
  const bytes=fs.readFileSync(new URL("support/"+file,import.meta.url));
  assert.ok(!/BlazeX\.(Renderer|Runtime|Host)|Phoenix|LocalLiveView|LiveView/.test(bytes.toString()), "application boundary leakage");
  report.architecture_audit.application_sources[file]=sha(bytes);
}
const headlessMix=fs.readFileSync(new URL("../../profiles/headless/mix.exs",import.meta.url));
assert.ok(!/phoenix|local_live_view|renderer_dom_liveview|blazex_host_browser/.test(headlessMix.toString()));
report.architecture_audit.headless_mix_sha256=sha(headlessMix);
const bytes=JSON.stringify(report,null,2)+"\n", target=new URL(prefix+"conformance-ledger-v0.1.0.json",directory);
if(process.argv.includes("--write"))fs.writeFileSync(target,bytes);else assert.equal(fs.readFileSync(target,"utf8"),bytes,"stale conformance ledger");
console.log(JSON.stringify({result:"passed",active_rows:report.active_rows,semantic_cases:51,browser_observations:204,deferred:2,ledger_sha256:sha(bytes)}));
