"""Validate BH-06 Phase 11 entrypoint accounting and milestone handoff."""
import hashlib,json,sys
from pathlib import Path
from jsonschema import Draft202012Validator
from research_paths import REPO_ROOT

AUTHORITY="docs/research/assets/bh-06-baseline/phase-11-authorization-v0.1.0.json"
POLICY="integration/bh-06/entrypoint-accounting-policy-v0.1.0.json"
ATTESTATION="integration/bh-06/phase-11-entrypoint-attestation-v0.1.0.json"
MANIFEST="integration/bh-06/phase-11-build-manifest-v0.1.0.json"
BROWSER="integration/bh-06/phase-11-browser-replay-v0.1.0.json"
PAYLOAD="integration/bh-06/phase-11-payload-report-v0.1.0.json"
INDEX="integration/bh-06/index-v0.1.0.json"
COMPLETION="docs/research/assets/bh-06-baseline/phase-11-completion-v0.1.0.json"
HANDOFF="docs/research/assets/bh-06-baseline/bh-07-entry-decision-v0.1.0.json"
PLAN="docs/research/60-planning/01-browser-host/bh-06-build-compatibility-and-client-safety-pipeline/phase-11-entrypoint-accounting-and-milestone-handoff.md"
ENGINE="packages/blazex_build/lib/blazex/build/entrypoint_attestation.ex"
TASK="integration/bh-06/vertical_slice/lib/mix/tasks/bh06.package.ex"
RUNNER="integration/bh-06/vertical_slice/run-browser.mjs"
REPORTS={name:f"integration/bh-06/phase-11-{name.replace('_','-')}-v0.1.0.json" for name in ["reachability","client_safety","compatibility","secret_audit","license_inventory","bundle_plan","runtime_closure","payload"]}
REPORTS["payload"]=PAYLOAD
REPORTS["delivery_integrity"]=MANIFEST
ROLE_BY_CATEGORY={"reachability":"reachability-report","client_safety":"client-safety-report","compatibility":"compatibility-report","secret_audit":"secret-audit-report","license_inventory":"license-inventory-report","bundle_plan":"bundle-plan-report","runtime_closure":"runtime-closure-report"}
MUTABLE={"packages/blazex_build/lib/blazex/build/pipeline.ex":"308ddd924f750cbe76b63ac54da94731faf73a3975ae5559f0c8c5fd7a06a9ed","integration/bh-06/vertical_slice/lib/mix/tasks/bh06.package.ex":"d5df4ea44ab45992e1c74e984a58e3347a450c54165dbe223a26d97f29420558"}

def load(root,rel): return json.loads((Path(root)/rel).read_text())
def digest(path): return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def canonical(value): return hashlib.sha256((json.dumps(value,sort_keys=True,separators=(",",":"))+"\n").encode()).hexdigest()

def validate(root=REPO_ROOT):
 root=Path(root); errors=[]
 authority=load(root,AUTHORITY); policy=load(root,POLICY); att=load(root,ATTESTATION); manifest=load(root,MANIFEST); browser=load(root,BROWSER); payload=load(root,PAYLOAD); index=load(root,INDEX); completion=load(root,COMPLETION); handoff=load(root,HANDOFF)
 if authority.get("authorized") is not True or authority.get("phase")!=11: errors.append("Phase 11 authority is invalid")
 for rel,expected in authority.get("bound_inputs",{}).items():
  if rel in MUTABLE:
   if expected!=MUTABLE[rel]: errors.append(f"mutable baseline identity drift: {rel}")
  elif not (root/rel).is_file() or digest(root/rel)!=expected: errors.append(f"bound input drift: {rel}")
 for data,schema in [(POLICY,"integration/bh-06/entrypoint-accounting-policy.schema.json"),(ATTESTATION,"integration/bh-06/entrypoint-attestation.schema.json")]:
  found=list(Draft202012Validator(load(root,schema)).iter_errors(load(root,data)))
  if found: errors.append(f"schema failure for {data}: {found[0].message}")
 declared=policy.get("entrypoints",[]); observed=[att.get("entrypoint")]
 if observed!=declared or att.get("attestation_id")!=f"{policy.get('policy_id')}/{declared[0].get('id')}" or att.get("policy_sha256")!=canonical(policy): errors.append("declared entrypoint set or policy binding drifted")
 if att.get("manifest")!={"id":manifest.get("manifest_id"),"sha256":canonical(manifest),"support_state":manifest.get("support_state")}: errors.append("attestation manifest binding drifted")
 expected_artifacts=[{k:v for k,v in row.items() if k in {"path","role","exposure","sha256","integrity","bytes","cache_control","feature_id"}} for row in manifest.get("artifacts",[])]
 expected_artifacts.sort(key=lambda x:x.get("path",""))
 if att.get("artifacts")!=expected_artifacts: errors.append("attested artifact inventory drifted")
 public={x.get("role") for x in expected_artifacts if x.get("exposure")=="public"}; private={x.get("role") for x in expected_artifacts if x.get("exposure")=="private-build-evidence"}
 if public!=set(policy.get("required_public_roles",[])) or private!=set(policy.get("required_private_roles",[])): errors.append("public/private artifact role coverage drifted")
 reports={name:(manifest.get("delivery_integrity") if name=="delivery_integrity" else load(root,rel)) for name,rel in REPORTS.items()}
 if set(att.get("evidence",{}))!=set(policy.get("required_evidence",[])): errors.append("attested evidence category coverage drifted")
 for name,report in reports.items():
  row=att.get("evidence",{}).get(name,{})
  if row.get("sha256")!=canonical(report) or row.get("decision")!="accept": errors.append(f"attested evidence identity or decision drift: {name}")
  role=ROLE_BY_CATEGORY.get(name)
  if role:
   artifact=next((x for x in expected_artifacts if x.get("role")==role),{})
   if artifact.get("sha256")!=canonical(report): errors.append(f"manifest evidence identity drift: {name}")
 summary={"artifacts":len(expected_artifacts),"public_artifacts":len([x for x in expected_artifacts if x.get("exposure")=="public"]),"private_artifacts":len([x for x in expected_artifacts if x.get("exposure")=="private-build-evidence"]),"shipped_components":reports["license_inventory"]["summary"]["shipped_components"],"license_records":reports["license_inventory"]["summary"]["license_records"],"public_decoded_bytes":payload["summary"]["public_decoded_bytes"],"public_brotli_bytes":payload["summary"]["public_brotli_bytes"],"failed_budgets":payload["summary"]["failed_budgets"]}
 if att.get("summary")!=summary or att.get("decision")!="accept" or summary["failed_budgets"]!=0: errors.append("attestation summary or decision drifted")
 required={"entrypoint-attestation","delivery-policy-binding","sha384-sri","atomvm-ready","feature-dynamic-load","mount","browser-interaction","dispose"}; results=browser.get("results",[])
 if browser.get("phase")!=11 or browser.get("attestation_id")!=att.get("attestation_id") or browser.get("attestation_sha256")!=digest(root/ATTESTATION) or [x.get("browser") for x in results]!=["chrome","firefox"] or browser.get("comparison",{}).get("state")!="exact-match": errors.append("browser attestation binding or parity drifted")
 if any(x.get("result")!="passed" or x.get("attestation_id")!=att.get("attestation_id") or not required.issubset(x.get("checks",[])) for x in results): errors.append("attested browser proof failed")
 negative=browser.get("negative_attestation_binding",{})
 if negative.get("result")!="failed" or "attestation binding mismatch" not in negative.get("error",""): errors.append("stale browser attestation did not fail closed")
 if payload.get("phase")!=11 or payload.get("decision")!="accept" or any(x.get("result")!="passed" for x in payload.get("budgets",[])): errors.append("Phase 11 payload acceptance is missing")
 if "assert_complete_set!" not in (root/ENGINE).read_text() or "EntryPointAttestation.build!" not in (root/TASK).read_text() or "negative_attestation_binding" not in (root/RUNNER).read_text(): errors.append("entrypoint attestation implementation is not wired")
 required_files={Path(x).name for x in [POLICY,ATTESTATION,MANIFEST,BROWSER,PAYLOAD,*[v for k,v in REPORTS.items() if k not in {"payload","delivery_integrity"}]]}
 if index.get("phase",0)<11 or not required_files.issubset(index.get("evidence",[])): errors.append("BH-06 Phase 11 evidence index is incomplete")
 expected={"decision":"accept","policy_evidence_sha256":digest(root/POLICY),"attestation_sha256":digest(root/ATTESTATION),"manifest_sha256":digest(root/MANIFEST),"browser_evidence_sha256":digest(root/BROWSER),"payload_evidence_sha256":digest(root/PAYLOAD),"canonical_policy_sha256":canonical(policy)}
 if any(completion.get(k)!=v for k,v in expected.items()): errors.append("Phase 11 completion identities are stale")
 if handoff.get("decision")!="ready-for-separate-authorization" or handoff.get("bh06_completion_sha256")!=digest(root/COMPLETION) or handoff.get("authorized") is not False: errors.append("BH-07 handoff boundary is stale or over-authorized")
 if "- [ ]" in (root/PLAN).read_text(): errors.append("Phase 11 checklist is incomplete")
 return errors

if __name__=="__main__":
 failures=validate(); print("\n".join(failures) if failures else "BH-06 Phase 11 entrypoint accounting: ACCEPT (validated)"); sys.exit(bool(failures))
