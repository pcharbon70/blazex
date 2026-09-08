import fs from "node:fs";
import assert from "node:assert/strict";
import {execFileSync} from "node:child_process";
import {sha} from "./acceptance-report.mjs";
const assets="docs/research/assets/bh-04-baseline/", prefix=assets+"blazex-bh-04-phase-10-";
const read=p=>JSON.parse(fs.readFileSync(p)),pathFor=k=>prefix+k+"-v0.1.0.json";
const write=(name,data)=>{const bytes=JSON.stringify(data,null,2)+"\n",path=pathFor(name);if(process.argv.includes("--write"))fs.writeFileSync(path,bytes);else assert.equal(fs.readFileSync(path,"utf8"),bytes,"stale "+name);return path;};
const review=read(pathFor("review")),auth=read(pathFor("authorization")),stats=read(pathFor("statistics"));
const entryPath=assets+"blazex-bh-04-entry-ledger-v0.1.0.json",entry=read(entryPath);
const files=execFileSync("git",["ls-files","--cached","--others","--exclude-standard"],{encoding:"utf8"}).trim().split("\n");
const bindings=paths=>Object.fromEntries([...new Set(paths)].sort().map(p=>[p,sha(fs.readFileSync(p))]));
const groups={
  protocol:files.filter(p=>/^(js\/blazex_runtime\/src\/render-transaction|integration\/bh-04\/.*(?:protocol|transaction))/.test(p)),
  reconciliation:files.filter(p=>p.startsWith("packages/blazex_renderer_dom/")&&/reconcil|retained/.test(p)),
  dom:files.filter(p=>/^js\/blazex_runtime\/src\/(atomic-dom|dom-root-queue|dom-transaction-plan)/.test(p)),
  interaction:files.filter(p=>/^js\/blazex_runtime\/src\/interaction/.test(p)),
  continuity:files.filter(p=>/^js\/blazex_runtime\/src\/(form-continuity|focus-continuity|continuity-wire)/.test(p)),
  effects:files.filter(p=>/^js\/blazex_runtime\/src\/(effect-|renderer-resources|renderer-failure)/.test(p)),
  conformance:[pathFor("atomic-browser"),pathFor("interaction-browser"),pathFor("continuity-browser"),pathFor("effect-browser"),pathFor("semantic-browser")],
  dependency:files.filter(p=>/(?:mix\.exs|mix\.lock|package-lock\.json|package\.json)$/.test(p)),
  measurement:[pathFor("measurements"),pathFor("statistics")],
  deferred_adapter:["docs/research/60-planning/liveview-integration-deferral.md"]
};
const inherited=entry.predecessor_handoff.carried_obligations;
assert.ok(Array.isArray(inherited)&&inherited.length>0);
const reconciliation={schema_version:"1.0.0",phase:10,source_hashes:bindings([entryPath,pathFor("review"),review.review_document]),outputs:Object.fromEntries(Object.entries(groups).map(([k,p])=>[k,{source_hashes:bindings(p),disposition:k==="deferred_adapter"?"deferred-no-pass-credit":"candidate-evidence-not-milestone-acceptance"}])),inherited_obligations:inherited,inherited_handoff:entry.predecessor_handoff,findings:review.findings,deferred:review.deferred,limits:review.limits};
const reconciliationPath=write("reconciliation",reconciliation);
// The current candidate deliberately cannot accept: the frozen paint method
// and review requirements are not satisfied. Do not infer acceptance from tests.
assert.equal(stats.paint_budget_state,"unverified-compositor-paint");
assert.equal(review.independent,false);
const conditions=entry.acceptance_records.map(r=>({id:r.id,subject:r.subject,owner:r.evidence_owner,
  state:r.id.includes("DOM-UPDATE")?"blocked-missing-paint-evidence":r.id.includes("ROADMAP")?"blocked-independent-review-and-measurement": "active-development-evidence-release-unqualified",
  release_pass_credit:false,source_registry_state:r.status,evidence:r.id.includes("RENDERER-QUEUE")||r.id.includes("STALE-REJECTION")||r.id.includes("DOM-UPDATE")?[pathFor("measurements"),pathFor("statistics")]:r.id.includes("FAILURE")?[pathFor("effect-browser"),pathFor("atomic-browser")]:[reconciliationPath]}));
assert.equal(conditions.length,5);
const overlayPath=write("acceptance-overlay",{schema_version:"1.0.0",phase:10,decision:"revise",conditions,open_blockers:review.findings.filter(f=>f.blocks_acceptance),source_hashes:bindings([pathFor("authorization"),pathFor("statistics"),pathFor("review"),reconciliationPath]),canonical_registry_modified:false,bh05_eligible:false,next_authorized_work:null,support_state:"unsupported"});
const candidate={schema_version:"1.0.0",phase:10,base_revision:auth.base_revision,decision:"revise",bh04_accepted:false,bh05_eligible:false,next_authorized_work:null,support_state:"unsupported",api_state:"experimental-not-stable",indexes:Object.fromEntries(Object.entries(groups).map(([k,p])=>[k,bindings(p)])),source_hashes:bindings([reconciliationPath,overlayPath,pathFor("review"),review.review_document,pathFor("authorization"),pathFor("statistics")]),findings:review.findings,deferred:review.deferred,limits:review.limits,
  handoff:{state:"blocked-no-entry-manifest",required:"Resolve active findings, freeze corrected measurement method, rerun affected gates and independent reviews; only a new accepted decision can make BH-05 eligible",prohibited:["BH-05 implementation","public API stability","product controls","server authority","Plug support","prerender activation","release qualification"],separate_authorization_required:true}};
write("release-index",candidate);
console.log("BH-04 release candidate regenerated: revise; BH-05 ineligible and unauthorized.");
