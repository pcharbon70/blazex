"""Validate BH-06 Phase 10 delivery-integrity metadata and browser acceptance."""
import base64,hashlib,json,re,sys
from pathlib import Path
from jsonschema import Draft202012Validator
from research_paths import REPO_ROOT

AUTHORITY="docs/research/assets/bh-06-baseline/phase-10-authorization-v0.1.0.json"
POLICY="integration/bh-06/delivery-integrity-policy-v0.1.0.json"
MANIFEST="integration/bh-06/phase-10-build-manifest-v0.1.0.json"
BROWSER="integration/bh-06/phase-10-browser-replay-v0.1.0.json"
PAYLOAD="integration/bh-06/phase-10-payload-report-v0.1.0.json"
INDEX="integration/bh-06/index-v0.1.0.json"
COMPLETION="docs/research/assets/bh-06-baseline/phase-10-completion-v0.1.0.json"
PLAN="docs/research/60-planning/01-browser-host/bh-06-build-compatibility-and-client-safety-pipeline/phase-10-delivery-integrity-metadata.md"
ENGINE="packages/blazex_build/lib/blazex/build/delivery_integrity.ex"
TASK="integration/bh-06/vertical_slice/lib/mix/tasks/bh06.package.ex"
HOST="integration/bh-06/vertical_slice/assets/host.js"
RUNNER="integration/bh-06/vertical_slice/run-browser.mjs"
PRIVATE={role:f"integration/bh-06/phase-10-{name}-v0.1.0.json" for role,name in {
 "reachability-report":"reachability","client-safety-report":"client-safety",
 "compatibility-report":"compatibility","secret-audit-report":"secret-audit",
 "license-inventory-report":"license-inventory","bundle-plan-report":"bundle-plan",
 "runtime-closure-report":"runtime-closure"}.items()}
MUTABLE={
 "packages/blazex_build/lib/blazex/build/pipeline.ex":"f0e49e0774df2fc480127678089381cedbdd917bcb3663894c50ee1947d30267",
 "integration/bh-06/vertical_slice/lib/mix/tasks/bh06.package.ex":"69003bb86e68a537e76a0cd77037e3f4700d51a13fbe78953e1241c6ae506e7a"}

def digest(path): return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def sri(path): return "sha384-"+base64.b64encode(hashlib.sha384(Path(path).read_bytes()).digest()).decode()
def load(root,rel): return json.loads((Path(root)/rel).read_text())
def canonical(value): return hashlib.sha256((json.dumps(value,sort_keys=True,separators=(",",":"))+"\n").encode()).hexdigest()

def validate(root=REPO_ROOT):
 root=Path(root); errors=[]
 authority=load(root,AUTHORITY); policy=load(root,POLICY); manifest=load(root,MANIFEST)
 browser=load(root,BROWSER); payload=load(root,PAYLOAD); index=load(root,INDEX); completion=load(root,COMPLETION)
 if authority.get("authorized") is not True or authority.get("phase")!=10: errors.append("Phase 10 authority is invalid")
 for rel,expected in authority.get("bound_inputs",{}).items():
  if rel in MUTABLE:
   if expected!=MUTABLE[rel]: errors.append(f"mutable baseline identity drift: {rel}")
  elif not (root/rel).is_file() or digest(root/rel)!=expected: errors.append(f"bound input drift: {rel}")
 found=list(Draft202012Validator(load(root,"integration/bh-06/delivery-integrity-policy.schema.json")).iter_errors(policy))
 if found: errors.append(f"policy schema failure: {found[0].message}")
 binding=manifest.get("delivery_integrity",{})
 if binding!={"algorithm":"sha384","manifest_cache_control":"no-store","policy_id":policy.get("policy_id"),"policy_sha256":canonical(policy)}: errors.append("manifest delivery-policy binding drifted")
 artifacts=manifest.get("artifacts",[]); paths=[x.get("path") for x in artifacts]
 if not artifacts or len(artifacts)>policy["limits"]["max_artifacts"] or len(paths)!=len(set(paths)): errors.append("artifact count or path identity is invalid")
 if sum(x.get("bytes",0) for x in artifacts)>policy["limits"]["max_total_bytes"]: errors.append("artifact bytes exceed policy")
 counts={role:sum(x.get("role")==role for x in artifacts) for role in policy["roles"]}
 if set(x.get("role") for x in artifacts)!=set(policy["roles"]): errors.append("manifest roles do not match closed policy")
 for role,declaration in policy["roles"].items():
  if counts[role]<1 or (declaration["cardinality"]=="exactly-one" and counts[role]!=1): errors.append(f"role cardinality drift: {role}")
 for row in artifacts:
  declaration=policy["roles"].get(row.get("role"),{})
  if row.get("cache_control")!=declaration.get("cache_control"): errors.append(f"cache metadata drift: {row.get('role')}")
  if not re.fullmatch(r"sha384-[A-Za-z0-9+/]{64}",str(row.get("integrity",""))): errors.append(f"SRI encoding drift: {row.get('role')}")
 by_role={x["role"]:x for x in artifacts if x["role"]!="feature-bundle"}
 for role,rel in PRIVATE.items():
  row=by_role.get(role,{})
  if row.get("sha256")!=digest(root/rel) or row.get("integrity")!=sri(root/rel) or row.get("bytes")!=(root/rel).stat().st_size: errors.append(f"private evidence integrity drift: {role}")
 required={"delivery-policy-binding","sha384-sri","cache-control","atomvm-ready","brotli-negotiation","feature-dynamic-load","mount","browser-interaction","dispose"}
 results=browser.get("results",[])
 if browser.get("phase")!=10 or browser.get("payload_decision")!="accept" or [x.get("browser") for x in results]!=["chrome","firefox"] or browser.get("comparison",{}).get("state")!="exact-match": errors.append("Phase 10 browser replay is incomplete or divergent")
 immutable="public, max-age=31536000, immutable"
 if any(x.get("result")!="passed" or x.get("page_errors")!=[] or not required.issubset(x.get("checks",[])) or x.get("cache_controls",{}).get("build-manifest")!="no-store" or set(v for k,v in x.get("cache_controls",{}).items() if k!="build-manifest")!={immutable} for x in results): errors.append("delivery-integrity browser proof failed")
 for key,needle in [("negative_integrity","integrity mismatch"),("negative_feature_integrity","integrity mismatch"),("negative_sri","SRI mismatch"),("negative_cache_control","cache policy mismatch")]:
  value=browser.get(key,{})
  if value.get("result")!="failed" or needle not in value.get("error",""): errors.append(f"{key} did not fail closed")
 if browser.get("negative_private_evidence",{}).get("status")!=404: errors.append("private evidence became public")
 if payload.get("decision")!="accept" or payload.get("phase")!=10 or any(x.get("result")!="passed" for x in payload.get("budgets",[])): errors.append("Phase 10 payload acceptance is missing")
 source=(root/ENGINE).read_text(); task=(root/TASK).read_text(); host=(root/HOST).read_text(); runner=(root/RUNNER).read_text()
 if "sha384" not in source or "delivery_integrity:" not in task or 'crypto.subtle.digest("SHA-384"' not in host or 'Cache-Control' not in runner: errors.append("delivery integrity implementation is not wired")
 required_files={Path(x).name for x in [POLICY,MANIFEST,BROWSER,PAYLOAD,*PRIVATE.values()]}
 if index.get("phase",0)<10 or not required_files.issubset(index.get("evidence",[])): errors.append("BH-06 Phase 10 evidence index is incomplete")
 expected={"decision":"accept","policy_evidence_sha256":digest(root/POLICY),"manifest_sha256":digest(root/MANIFEST),"browser_evidence_sha256":digest(root/BROWSER),"payload_evidence_sha256":digest(root/PAYLOAD),"canonical_policy_sha256":canonical(policy)}
 if any(completion.get(k)!=v for k,v in expected.items()): errors.append("Phase 10 completion identities are stale")
 if "- [ ]" in (root/PLAN).read_text(): errors.append("Phase 10 checklist is incomplete")
 return errors

if __name__=="__main__":
 failures=validate(); print("\n".join(failures) if failures else "BH-06 Phase 10 delivery integrity: ACCEPT (validated)"); sys.exit(bool(failures))
