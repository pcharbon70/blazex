"""Validate BH-06 Phase 8 payload-budget and public/private evidence."""
import hashlib,json,sys
from pathlib import Path
from jsonschema import Draft202012Validator
from research_paths import REPO_ROOT

AUTHORITY="docs/research/assets/bh-06-baseline/phase-08-authorization-v0.1.0.json"
POLICY="integration/bh-06/payload-policy-v0.1.0.json"
REPORT="integration/bh-06/phase-08-payload-report-v0.1.0.json"
MANIFEST="integration/bh-06/phase-08-build-manifest-v0.1.0.json"
BROWSER="integration/bh-06/phase-08-browser-replay-v0.1.0.json"
INDEX="integration/bh-06/index-v0.1.0.json"
COMPLETION="docs/research/assets/bh-06-baseline/phase-08-completion-v0.1.0.json"
PLAN="docs/research/60-planning/01-browser-host/bh-06-build-compatibility-and-client-safety-pipeline/phase-08-payload-budgets-and-public-artifact-accounting.md"
PIPELINE="packages/blazex_build/lib/blazex/build/pipeline.ex"
TASK="integration/bh-06/vertical_slice/lib/mix/tasks/bh06.package.ex"
RUNNER="integration/bh-06/vertical_slice/run-browser.mjs"
HOST="integration/bh-06/vertical_slice/assets/host.js"
PRIVATE={
 "reachability-report":"integration/bh-06/phase-08-reachability-v0.1.0.json",
 "client-safety-report":"integration/bh-06/phase-08-client-safety-v0.1.0.json",
 "compatibility-report":"integration/bh-06/phase-08-compatibility-v0.1.0.json",
 "secret-audit-report":"integration/bh-06/phase-08-secret-audit-v0.1.0.json",
 "license-inventory-report":"integration/bh-06/phase-08-license-inventory-v0.1.0.json",
 "bundle-plan-report":"integration/bh-06/phase-08-bundle-plan-v0.1.0.json"}
MUTABLE={PIPELINE:"9fe3158d5b12b2c5e8e8b1552bbb605e0263a087220c8eedc3119dcc18ca773b"}

def digest(path): return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def load(root,rel): return json.loads((Path(root)/rel).read_text())
def canonical(value): return hashlib.sha256((json.dumps(value,sort_keys=True,separators=(",",":"))+"\n").encode()).hexdigest()

def validate(root=REPO_ROOT):
 root=Path(root); errors=[]
 authority=load(root,AUTHORITY); policy=load(root,POLICY); report=load(root,REPORT); manifest=load(root,MANIFEST); browser=load(root,BROWSER); index=load(root,INDEX); completion=load(root,COMPLETION)
 if authority.get("authorized") is not True or authority.get("phase")!=8: errors.append("Phase 8 authority is invalid")
 for rel,expected in authority.get("bound_inputs",{}).items():
  if rel in MUTABLE:
   if expected!=MUTABLE[rel]: errors.append(f"mutable baseline identity drift: {rel}")
  elif not (root/rel).is_file() or digest(root/rel)!=expected: errors.append(f"bound input drift: {rel}")
 for data,schema in [(POLICY,"integration/bh-06/payload-policy.schema.json"),(REPORT,"integration/bh-06/payload-report.schema.json")]:
  found=list(Draft202012Validator(load(root,schema)).iter_errors(load(root,data)))
  if found: errors.append(f"schema failure for {data}: {found[0].message}")
 if report.get("policy_id")!=policy.get("policy_id") or report.get("policy_sha256")!=canonical(policy): errors.append("payload report does not bind normalized policy")
 artifacts=manifest.get("artifacts",[]); by_role={x.get("role"):x for x in artifacts}
 if len(artifacts)!=12 or len(by_role)!=12: errors.append("Phase 8 manifest roles are incomplete or duplicate")
 for row in artifacts:
  declaration=policy.get("roles",{}).get(row.get("role"),{})
  expected=declaration.get("exposure")
  if row.get("exposure")!=expected: errors.append(f"manifest exposure drift: {row.get('role')}")
  if expected=="public" and not (row.get("path")=="index.html" or str(row.get("path","")).startswith("assets/")): errors.append("public artifact escaped public assets")
  if expected=="private-build-evidence" and not str(row.get("path","")).startswith("evidence/"): errors.append("private evidence escaped evidence directory")
 for role,rel in PRIVATE.items():
  row=by_role.get(role,{})
  if not (root/rel).is_file() or row.get("sha256")!=digest(root/rel) or row.get("bytes")!=(root/rel).stat().st_size: errors.append(f"private evidence binding drift: {role}")
 measured=report.get("artifacts",[]); paths=[x.get("path") for x in measured]
 if paths!=sorted(paths) or len(paths)!=len(set(paths)): errors.append("payload artifacts are unordered or duplicate")
 expected_public={x.get("path"):x for x in artifacts if x.get("exposure")=="public"}
 expected_public["build-manifest.json"]={"role":"build-manifest","sha256":digest(root/MANIFEST),"bytes":(root/MANIFEST).stat().st_size}
 if set(paths)!=set(expected_public): errors.append("payload report does not cover every public artifact exactly")
 for row in measured:
  source=expected_public.get(row.get("path"),{})
  declaration=policy.get("roles",{}).get(row.get("role"),{})
  if row.get("source_sha256")!=source.get("sha256") or row.get("decoded_bytes")!=source.get("bytes") or row.get("owner")!=declaration.get("owner") or row.get("exposure")!="public": errors.append(f"payload artifact identity or ownership drift: {row.get('path')}")
 totals={}
 for row in measured:
  value=totals.setdefault(row.get("owner"),{"artifacts":0,"decoded_bytes":0,"brotli_bytes":0}); value["artifacts"]+=1; value["decoded_bytes"]+=row.get("decoded_bytes",0); value["brotli_bytes"]+=row.get("brotli_bytes",0)
 if report.get("totals")!=totals: errors.append("payload owner totals drifted")
 source_map_bytes=sum(x.get("decoded_bytes",0) for x in measured if str(x.get("path","")).endswith(".map"))
 decisions=[]
 for budget in policy.get("budgets",[]):
  observed=source_map_bytes if budget.get("metric")=="source_map_bytes" else totals.get(budget.get("owner"),{}).get(budget.get("metric"),0)
  passed=observed<=budget.get("threshold",-1) if budget.get("direction")=="at-most" else observed==budget.get("threshold")
  decisions.append({**budget,"observed":observed,"result":"passed" if passed else "failed"})
 if report.get("budgets")!=decisions: errors.append("payload budget decisions were not recomputed truthfully")
 failures=[x.get("id") for x in decisions if x.get("result")=="failed"]
 if failures!=["runtime-brotli"] or report.get("decision")!="reject" or report.get("summary",{}).get("failed_budgets")!=1: errors.append("runtime payload rejection is missing or concealed")
 if source_map_bytes!=0 or report.get("summary",{}).get("public_source_maps")!=0: errors.append("public source-map exclusion failed")
 required={"brotli-negotiation","feature-dynamic-load","duplicate-load-rejection","mount","browser-interaction","dispose"}
 results=browser.get("results",[])
 if browser.get("phase")!=8 or browser.get("payload_decision")!="reject" or [x.get("browser") for x in results]!=["chrome","firefox"] or browser.get("comparison",{}).get("state")!="exact-match": errors.append("Phase 8 browser replay is incomplete or divergent")
 if any(x.get("result")!="passed" or x.get("page_errors")!=[] or not required.issubset(x.get("checks",[])) or set(x.get("content_encodings",{}).values())!={"br"} for x in results): errors.append("Phase 8 Brotli browser proof failed")
 if browser.get("negative_private_evidence",{}).get("status")!=404 or browser.get("negative_integrity",{}).get("result")!="failed" or browser.get("negative_feature_integrity",{}).get("result")!="failed": errors.append("Phase 8 denial or integrity negative proof failed")
 pipeline=(root/PIPELINE).read_text(); task=(root/TASK).read_text(); runner=(root/RUNNER).read_text(); host=(root/HOST).read_text()
 if '"private-build-evidence"' not in pipeline or '"evidence/#{role}' not in pipeline: errors.append("pipeline no longer isolates private build evidence")
 if "payload gate rejected candidate; no output was promoted" not in task or "retain_rejected" not in task or "PayloadBudget.measure!" not in task: errors.append("package promotion no longer obeys payload decision")
 if 'relative.startsWith("evidence/")' not in runner or 'Content-Encoding", "br"' not in runner or 'brotli-negotiation' not in host: errors.append("browser negotiation or private denial implementation is missing")
 required_files={Path(x).name for x in [POLICY,REPORT,MANIFEST,BROWSER,*PRIVATE.values()]}
 if index.get("phase",0)<8 or not required_files.issubset(index.get("evidence",[])): errors.append("BH-06 Phase 8 evidence index is incomplete")
 expected_completion={"decision":"revision-required","policy_evidence_sha256":digest(root/POLICY),"payload_evidence_sha256":digest(root/REPORT),"manifest_sha256":digest(root/MANIFEST),"browser_evidence_sha256":digest(root/BROWSER),"canonical_policy_sha256":canonical(policy)}
 if any(completion.get(k)!=v for k,v in expected_completion.items()): errors.append("Phase 8 completion identities are stale")
 if "- [ ]" in (root/PLAN).read_text(): errors.append("Phase 8 checklist is incomplete")
 return errors

if __name__=="__main__":
 failures=validate(); print("\n".join(failures) if failures else "BH-06 Phase 8 payload budgets: REVISION REQUIRED (validated)"); sys.exit(bool(failures))
