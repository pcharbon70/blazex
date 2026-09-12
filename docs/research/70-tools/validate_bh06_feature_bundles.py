"""Validate BH-06 Phase 7 deterministic feature-bundle evidence."""
import hashlib,json,sys
from pathlib import Path
from jsonschema import Draft202012Validator
from research_paths import REPO_ROOT

AUTHORITY="docs/research/assets/bh-06-baseline/phase-07-authorization-v0.1.0.json"
POLICY="integration/bh-06/bundle-policy-v0.1.0.json"
PLAN="integration/bh-06/bundle-plan-v0.1.0.json"
AUDIT="integration/bh-06/phase-07-secret-audit-v0.1.0.json"
LICENSES="integration/bh-06/phase-07-license-inventory-v0.1.0.json"
MANIFEST="integration/bh-06/phase-07-build-manifest-v0.1.0.json"
BROWSER="integration/bh-06/phase-07-browser-replay-v0.1.0.json"
INDEX="integration/bh-06/index-v0.1.0.json"
COMPLETION="docs/research/assets/bh-06-baseline/phase-07-completion-v0.1.0.json"
PHASE_PLAN="docs/research/60-planning/01-browser-host/bh-06-build-compatibility-and-client-safety-pipeline/phase-07-deterministic-feature-bundles.md"
CLOSURE="packages/blazex_build/lib/blazex/build/client_closure.ex"
TASK="integration/bh-06/vertical_slice/lib/mix/tasks/bh06.package.ex"
BRIDGE="integration/bh-06/vertical_slice/lib/browser.ex"
HOST="integration/bh-06/vertical_slice/assets/host.js"
MUTABLE={CLOSURE:"6753181e316331d2d56d5fa4fbdca4c8e559f74fece38a2a2bd4603c1acd8062"}
ROLES={"document","runtime-module","runtime-wasm","application-bundle","browser-host","feature-bundle","reachability-report","client-safety-report","compatibility-report","secret-audit-report","license-inventory-report","bundle-plan-report"}

def digest(path): return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def load(root,rel): return json.loads((Path(root)/rel).read_text())
def canonical(value): return hashlib.sha256((json.dumps(value,sort_keys=True,separators=(",",":"))+"\n").encode()).hexdigest()

def validate(root=REPO_ROOT):
    root=Path(root); errors=[]
    authority=load(root,AUTHORITY); policy=load(root,POLICY); plan=load(root,PLAN); audit=load(root,AUDIT); licenses=load(root,LICENSES); manifest=load(root,MANIFEST); browser=load(root,BROWSER); index=load(root,INDEX); completion=load(root,COMPLETION)
    if authority.get("authorized") is not True or authority.get("phase")!=7: errors.append("Phase 7 authority is invalid")
    for rel,expected in authority.get("bound_inputs",{}).items():
        if rel in MUTABLE:
            if expected!=MUTABLE[rel]: errors.append(f"mutable baseline identity drift: {rel}")
        elif not (root/rel).is_file() or digest(root/rel)!=expected: errors.append(f"bound input drift: {rel}")
    for data,schema in [(POLICY,"integration/bh-06/bundle-policy.schema.json"),(PLAN,"integration/bh-06/bundle-plan.schema.json")]:
        found=list(Draft202012Validator(load(root,schema)).iter_errors(load(root,data)))
        if found: errors.append(f"schema failure for {data}: {found[0].message}")
    if plan.get("phase")!=7 or plan.get("status")!="complete" or plan.get("complete") is not True: errors.append("bundle plan is not a complete Phase 7 result")
    if plan.get("policy_id")!=policy.get("policy_id") or plan.get("policy_sha256")!=canonical(policy): errors.append("bundle plan does not bind normalized policy")
    inputs=plan.get("inputs",[]); labels=[x.get("label") for x in inputs]
    keys={"label","module","bundle_id","bytes","sha256"}
    if labels!=sorted(labels) or len(labels)!=len(set(labels)) or len({x.get("module") for x in inputs})!=len(inputs) or any(set(x)!=keys or "path" in x for x in inputs): errors.append("bundle inputs are unordered, duplicate, malformed, or path-bearing")
    audited=[(x.get("label"),x.get("bytes"),x.get("sha256")) for x in audit.get("inputs",[]) if str(x.get("label","")).startswith("bundle/")]
    planned=[(x.get("label"),x.get("bytes"),x.get("sha256")) for x in inputs]
    if planned!=audited: errors.append("bundle plan does not exactly cover audited BEAM inputs")
    bundles=plan.get("bundles",[]); by_id={x.get("id"):x for x in bundles}
    for bundle in bundles:
        owned=[x for x in inputs if x.get("bundle_id")==bundle.get("id")]
        if bundle.get("modules")!=[x.get("module") for x in owned] or bundle.get("input_count")!=len(owned) or bundle.get("input_bytes")!=sum(x.get("bytes",0) for x in owned):
            errors.append(f"bundle rows disagree with input ownership: {bundle.get('id')}")
    counter=by_id.get("counter",{}); base=by_id.get("base",{})
    if counter.get("kind")!="feature" or counter.get("modules")!=["Elixir.BlazeX.BH06.VerticalSlice.Counter"] or counter.get("input_count")!=1: errors.append("counter feature membership drifted")
    if base.get("kind")!="base" or not set(policy.get("startup_modules",[])).issubset(set(base.get("modules",[]))): errors.append("base startup ownership drifted")
    summary=plan.get("summary",{}); expected={"bundles":len(bundles),"features":sum(x.get("kind")=="feature" for x in bundles),"inputs":len(inputs),"input_bytes":sum(x.get("bytes",0) for x in inputs)}
    if summary!=expected: errors.append("bundle plan summary drifted")
    license_identity={(x.get("label"),x.get("bytes"),x.get("sha256")) for x in licenses.get("inputs",[]) if str(x.get("label","")).startswith("bundle/")}
    if set(planned)!=license_identity: errors.append("bundle plan and license inventory BEAM sets diverge")
    artifacts=manifest.get("artifacts",[])
    if {x.get("role") for x in artifacts}!=ROLES or len(artifacts)!=len(ROLES): errors.append("Phase 7 manifest roles are incomplete or duplicate")
    plan_assets=[x for x in artifacts if x.get("role")=="bundle-plan-report"]
    features=[x for x in artifacts if x.get("role")=="feature-bundle"]
    if len(plan_assets)!=1 or plan_assets[0].get("sha256")!=canonical(plan): errors.append("manifest does not bind canonical bundle plan")
    if len(features)!=1 or features[0].get("feature_id")!="counter" or features[0].get("bytes")!=2124: errors.append("manifest counter feature artifact drifted")
    required_checks={"feature-integrity","feature-absent-before-load","feature-dynamic-load","duplicate-load-rejection","mount","browser-interaction","dispose"}
    results=browser.get("results",[])
    if browser.get("phase")!=7 or [x.get("browser") for x in results]!=["chrome","firefox"] or browser.get("comparison",{}).get("state")!="exact-match": errors.append("Phase 7 active-browser replay is incomplete or divergent")
    if any(x.get("result")!="passed" or x.get("page_errors")!=[] or not required_checks.issubset(x.get("checks",[])) for x in results): errors.append("Phase 7 browser dynamic-load proof failed")
    if browser.get("negative_integrity",{}).get("result")!="failed" or browser.get("negative_feature_integrity",{}).get("result")!="failed": errors.append("base or feature integrity rejection is missing")
    closure=(root/CLOSURE).read_text(); order=["ClientSafety.analyze!","Compatibility.evaluate!","SecretAudit.analyze!","LicenseInventory.analyze!","BundlePlan.plan!","assemble.(authorization)"]
    if any(x not in closure for x in order) or any(closure.rindex(a)>=closure.rindex(b) for a,b in zip(order,order[1:])): errors.append("bundle planning no longer precedes assembly in required order")
    task=(root/TASK).read_text(); bridge=(root/BRIDGE).read_text(); host=(root/HOST).read_text()
    if "package_bundles!" not in task or "feature_bundles: archives.features" not in task: errors.append("candidate package bypasses feature archive assembly or binding")
    if ":atomvm.add_avm_pack_binary" not in bridge or "function_exported" not in bridge or "featureArtifact" not in host or "verifiedBytes(featureArtifact" not in host: errors.append("real verified dynamic feature load is missing")
    required={Path(x).name for x in [POLICY,PLAN,AUDIT,LICENSES,MANIFEST,BROWSER]}
    if index.get("phase",0)<7 or not required.issubset(index.get("evidence",[])): errors.append("BH-06 Phase 7 evidence index is incomplete")
    expected_completion={"decision":"accept","policy_evidence_sha256":digest(root/POLICY),"plan_evidence_sha256":digest(root/PLAN),"manifest_sha256":digest(root/MANIFEST),"browser_evidence_sha256":digest(root/BROWSER),"canonical_policy_sha256":canonical(policy),"canonical_plan_sha256":canonical(plan)}
    if any(completion.get(k)!=v for k,v in expected_completion.items()): errors.append("Phase 7 completion identities are stale")
    if "- [ ]" in (root/PHASE_PLAN).read_text(): errors.append("Phase 7 checklist is incomplete")
    return errors

if __name__=="__main__":
    failures=validate(); print("\n".join(failures) if failures else "BH-06 Phase 7 feature bundles: PASS"); sys.exit(bool(failures))
