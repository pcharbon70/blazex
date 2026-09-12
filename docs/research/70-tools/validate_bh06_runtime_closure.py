"""Validate BH-06 Phase 9 runtime-closure reduction and browser acceptance."""
import hashlib,json,sys
from pathlib import Path
from jsonschema import Draft202012Validator
from research_paths import REPO_ROOT

AUTHORITY="docs/research/assets/bh-06-baseline/phase-09-authorization-v0.1.0.json"
POLICY="integration/bh-06/runtime-closure-policy-v0.1.0.json"
CLOSURE="integration/bh-06/phase-09-runtime-closure-v0.1.0.json"
PAYLOAD_POLICY="integration/bh-06/payload-policy-v0.1.1.json"
PHASE8_POLICY="integration/bh-06/payload-policy-v0.1.0.json"
PAYLOAD="integration/bh-06/phase-09-payload-report-v0.1.0.json"
MANIFEST="integration/bh-06/phase-09-build-manifest-v0.1.0.json"
BROWSER="integration/bh-06/phase-09-browser-replay-v0.1.0.json"
INDEX="integration/bh-06/index-v0.1.0.json"
COMPLETION="docs/research/assets/bh-06-baseline/phase-09-completion-v0.1.0.json"
PLAN="docs/research/60-planning/01-browser-host/bh-06-build-compatibility-and-client-safety-pipeline/phase-09-audited-runtime-closure-reduction.md"
REDUCER="packages/blazex_build/lib/blazex/build/runtime_closure.ex"
TASK="integration/bh-06/vertical_slice/lib/mix/tasks/bh06.package.ex"
RUNNER="integration/bh-06/vertical_slice/run-browser.mjs"
PRIVATE={
 "reachability-report":"integration/bh-06/phase-09-reachability-v0.1.0.json",
 "client-safety-report":"integration/bh-06/phase-09-client-safety-v0.1.0.json",
 "compatibility-report":"integration/bh-06/phase-09-compatibility-v0.1.0.json",
 "secret-audit-report":"integration/bh-06/phase-09-secret-audit-v0.1.0.json",
 "license-inventory-report":"integration/bh-06/phase-09-license-inventory-v0.1.0.json",
 "bundle-plan-report":"integration/bh-06/phase-09-bundle-plan-v0.1.0.json",
 "runtime-closure-report":CLOSURE}

def digest(path): return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def load(root,rel): return json.loads((Path(root)/rel).read_text())
def canonical(value): return hashlib.sha256((json.dumps(value,sort_keys=True,separators=(",",":"))+"\n").encode()).hexdigest()
def closure_policy_digest(value):
 normalized=dict(value)
 for key in ["keep_modules","leave_modules","ignore_modules","drop_modules"]: normalized[key]=sorted(value[key])
 normalized["keep_functions"]=sorted(value["keep_functions"],key=lambda x:(x["module"],x["function"],x["arity"]))
 return canonical(normalized)

def validate(root=REPO_ROOT):
 root=Path(root); errors=[]
 authority=load(root,AUTHORITY); policy=load(root,POLICY); closure=load(root,CLOSURE)
 payload_policy=load(root,PAYLOAD_POLICY); old_policy=load(root,PHASE8_POLICY)
 payload=load(root,PAYLOAD); manifest=load(root,MANIFEST); browser=load(root,BROWSER)
 index=load(root,INDEX); completion=load(root,COMPLETION)
 if authority.get("authorized") is not True or authority.get("phase")!=9: errors.append("Phase 9 authority is invalid")
 for rel,expected in authority.get("bound_inputs",{}).items():
  if not (root/rel).is_file() or digest(root/rel)!=expected: errors.append(f"bound input drift: {rel}")
 for data,schema in [(POLICY,"integration/bh-06/runtime-closure-policy.schema.json"),(CLOSURE,"integration/bh-06/runtime-closure-report.schema.json"),(PAYLOAD_POLICY,"integration/bh-06/payload-policy.schema.json"),(PAYLOAD,"integration/bh-06/payload-report.schema.json")]:
  found=list(Draft202012Validator(load(root,schema)).iter_errors(load(root,data)))
  if found: errors.append(f"schema failure for {data}: {found[0].message}")
 if closure.get("policy_id")!=policy.get("policy_id") or closure.get("policy_sha256")!=closure_policy_digest(policy): errors.append("closure report does not bind normalized policy")
 expected=policy.get("expected_input",{})
 if closure.get("input_set_sha256")!=expected.get("set_sha256") or len(closure.get("inputs",[]))!=expected.get("modules"): errors.append("authorized closure input identity drift")
 inputs=closure.get("inputs",[]); outputs=closure.get("outputs",[])
 names=lambda rows:[x.get("module") for x in rows]
 if names(inputs)!=sorted(names(inputs)) or len(names(inputs))!=len(set(names(inputs))): errors.append("closure inputs are unordered or duplicate")
 if names(outputs)!=sorted(names(outputs)) or len(names(outputs))!=len(set(names(outputs))): errors.append("closure outputs are unordered or duplicate")
 before={x.get("module"):x for x in inputs}; after={x.get("module"):x for x in outputs}
 if not after or not set(after).issubset(before): errors.append("closure output is empty or contains additions")
 removed=sorted(set(before)-set(after))
 if closure.get("removed_modules")!=removed: errors.append("removed-module evidence is incomplete")
 opaque=closure.get("opaque_modules",[]); bridges=closure.get("opaque_dependency_modules",[])
 if opaque!=sorted(set(opaque)) or any(before.get(x)!=after.get(x) for x in opaque): errors.append("opaque modules are not sorted or byte-identical")
 if bridges!=sorted(set(bridges)) or not set(bridges).issubset(after): errors.append("opaque bridge roots are incomplete")
 roots=policy.get("keep_modules",[])+policy.get("leave_modules",[])+[x.get("module") for x in policy.get("keep_functions",[])]
 if not set(roots).issubset(after): errors.append("declared reduction root was removed")
 functions=closure.get("removed_functions",[]); function_keys=[(x.get("module"),x.get("function"),x.get("arity")) for x in functions]
 if function_keys!=sorted(set(function_keys)) or any(x[0] not in after for x in function_keys): errors.append("removed-function evidence is unordered, duplicate, or invalid")
 summary=closure.get("summary",{}); recomputed={"before_modules":len(before),"after_modules":len(after),"removed_modules":len(removed),"before_bytes":sum(x.get("bytes",0) for x in inputs),"after_bytes":sum(x.get("bytes",0) for x in outputs),"removed_functions":len(functions),"opaque_modules":len(opaque),"opaque_dependency_modules":len(bridges)}; recomputed["removed_bytes"]=recomputed["before_bytes"]-recomputed["after_bytes"]
 if summary!=recomputed or recomputed["removed_bytes"]<=0: errors.append("runtime closure summary drifted")
 old_public={k:v for k,v in old_policy.get("roles",{}).items() if v.get("exposure")=="public"}
 new_public={k:v for k,v in payload_policy.get("roles",{}).items() if v.get("exposure")=="public"}
 if payload_policy.get("compression")!=old_policy.get("compression") or payload_policy.get("budgets")!=old_policy.get("budgets") or new_public!=old_public or payload_policy.get("roles",{}).get("runtime-closure-report")!={"owner":"build-evidence","exposure":"private-build-evidence"}: errors.append("Phase 8 public payload authority or thresholds drifted")
 artifacts=manifest.get("artifacts",[]); roles=[x.get("role") for x in artifacts]
 if len(artifacts)!=13 or len(roles)!=len(set(roles)): errors.append("Phase 9 manifest roles are incomplete or duplicate")
 by_role={x.get("role"):x for x in artifacts}
 for role,rel in PRIVATE.items():
  row=by_role.get(role,{})
  if row.get("exposure")!="private-build-evidence" or row.get("sha256")!=digest(root/rel) or row.get("bytes")!=(root/rel).stat().st_size: errors.append(f"private evidence binding drift: {role}")
 totals={}
 for row in payload.get("artifacts",[]):
  value=totals.setdefault(row.get("owner"),{"artifacts":0,"decoded_bytes":0,"brotli_bytes":0}); value["artifacts"]+=1; value["decoded_bytes"]+=row.get("decoded_bytes",0); value["brotli_bytes"]+=row.get("brotli_bytes",0)
 if payload.get("totals")!=totals: errors.append("payload owner totals drifted")
 source_map_bytes=sum(x.get("decoded_bytes",0) for x in payload.get("artifacts",[]) if str(x.get("path","")).endswith(".map"))
 decisions=[]
 for budget in payload_policy.get("budgets",[]):
  observed=source_map_bytes if budget.get("metric")=="source_map_bytes" else totals.get(budget.get("owner"),{}).get(budget.get("metric"),0)
  passed=observed<=budget.get("threshold",-1) if budget.get("direction")=="at-most" else observed==budget.get("threshold")
  decisions.append({**budget,"observed":observed,"result":"passed" if passed else "failed"})
 if payload.get("policy_sha256")!=canonical(payload_policy) or payload.get("budgets")!=decisions or payload.get("decision")!="accept" or any(x["result"]!="passed" for x in decisions): errors.append("payload acceptance is missing, stale, or untruthful")
 required={"atomvm-ready","brotli-negotiation","feature-absent-before-load","feature-dynamic-load","duplicate-load-rejection","mount","browser-interaction","dispose"}
 results=browser.get("results",[])
 if browser.get("phase")!=9 or browser.get("payload_decision")!="accept" or [x.get("browser") for x in results]!=["chrome","firefox"] or browser.get("comparison",{}).get("state")!="exact-match": errors.append("Phase 9 browser replay is incomplete or divergent")
 if any(x.get("result")!="passed" or x.get("page_errors")!=[] or not required.issubset(x.get("checks",[])) for x in results): errors.append("reduced runtime browser proof failed")
 if browser.get("negative_private_evidence",{}).get("status")!=404 or browser.get("negative_integrity",{}).get("result")!="failed" or browser.get("negative_feature_integrity",{}).get("result")!="failed": errors.append("Phase 9 denial or integrity negative proof failed")
 reducer=(root/REDUCER).read_text(); task=(root/TASK).read_text(); runner=(root/RUNNER).read_text()
 if "opaque_dependencies" not in reducer or "RuntimeClosure.reduce!" not in task or "runtime_closure:" not in task: errors.append("audited runtime reduction is not wired into packaging")
 if 'relative.startsWith("evidence/")' not in runner or 'Content-Encoding", "br"' not in runner: errors.append("browser transport or private-evidence denial is missing")
 required_files={Path(x).name for x in [POLICY,CLOSURE,PAYLOAD_POLICY,PAYLOAD,MANIFEST,BROWSER,*PRIVATE.values()]}
 if index.get("phase",0)<9 or not required_files.issubset(index.get("evidence",[])): errors.append("BH-06 Phase 9 evidence index is incomplete")
 expected_completion={"decision":"accept","closure_evidence_sha256":digest(root/CLOSURE),"payload_evidence_sha256":digest(root/PAYLOAD),"manifest_sha256":digest(root/MANIFEST),"browser_evidence_sha256":digest(root/BROWSER),"canonical_closure_policy_sha256":closure_policy_digest(policy),"canonical_payload_policy_sha256":canonical(payload_policy)}
 if any(completion.get(k)!=v for k,v in expected_completion.items()): errors.append("Phase 9 completion identities are stale")
 if "- [ ]" in (root/PLAN).read_text(): errors.append("Phase 9 checklist is incomplete")
 return errors

if __name__=="__main__":
 failures=validate(); print("\n".join(failures) if failures else "BH-06 Phase 9 runtime closure: ACCEPT (validated)"); sys.exit(bool(failures))
