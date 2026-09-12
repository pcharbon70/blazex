"""Validate BH-06 Phase 6 license and provenance inventory evidence."""
import hashlib, json, sys
from pathlib import Path
from jsonschema import Draft202012Validator
from research_paths import REPO_ROOT

AUTHORITY="docs/research/assets/bh-06-baseline/phase-06-authorization-v0.1.0.json"
POLICY="integration/bh-06/license-policy-v0.1.0.json"
REPORT="integration/bh-06/license-inventory-v0.1.0.json"
AUDIT="integration/bh-06/phase-06-secret-audit-v0.1.0.json"
MANIFEST="integration/bh-06/phase-06-build-manifest-v0.1.0.json"
BROWSER="integration/bh-06/phase-06-browser-replay-v0.1.0.json"
INDEX="integration/bh-06/index-v0.1.0.json"
COMPLETION="docs/research/assets/bh-06-baseline/phase-06-completion-v0.1.0.json"
PLAN="docs/research/60-planning/01-browser-host/bh-06-build-compatibility-and-client-safety-pipeline/phase-06-license-and-provenance-inventory.md"
CLOSURE="packages/blazex_build/lib/blazex/build/client_closure.ex"
TASK="integration/bh-06/vertical_slice/lib/mix/tasks/bh06.package.ex"
MUTABLE={CLOSURE:"8f5027ca7c6ebbf553c7136b840109583b2cf126fe9c3044ea9499edd95fadc7"}
ROLES={"document","runtime-module","runtime-wasm","application-bundle","browser-host","reachability-report","client-safety-report","compatibility-report","secret-audit-report","license-inventory-report"}

def digest(path): return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def load(root, rel): return json.loads((Path(root)/rel).read_text())
def canonical(value): return hashlib.sha256((json.dumps(value,sort_keys=True,separators=(",",":"))+"\n").encode()).hexdigest()
def normalized_policy(policy):
    value=json.loads(json.dumps(policy))
    value["license_records"]=sorted(value.get("license_records",[]),key=lambda x:x.get("id",""))
    value["components"]=sorted(value.get("components",[]),key=lambda x:x.get("id",""))
    for row in value["components"]: row["license_record_ids"]=sorted(row.get("license_record_ids",[]))
    return canonical(value)

def validate(root=REPO_ROOT):
    root=Path(root); errors=[]
    authority=load(root,AUTHORITY); policy=load(root,POLICY); report=load(root,REPORT); audit=load(root,AUDIT); manifest=load(root,MANIFEST); browser=load(root,BROWSER); index=load(root,INDEX); completion=load(root,COMPLETION)
    if authority.get("authorized") is not True or authority.get("phase")!=6: errors.append("Phase 6 authority is invalid")
    for rel,expected in authority.get("bound_inputs",{}).items():
        if rel in MUTABLE:
            if expected!=MUTABLE[rel]: errors.append(f"mutable baseline identity drift: {rel}")
        elif not (root/rel).is_file() or digest(root/rel)!=expected: errors.append(f"bound input drift: {rel}")
    for data,schema in [(POLICY,"integration/bh-06/license-policy.schema.json"),(REPORT,"integration/bh-06/license-inventory.schema.json")]:
        found=list(Draft202012Validator(load(root,schema)).iter_errors(load(root,data)))
        if found: errors.append(f"schema failure for {data}: {found[0].message}")
    if report.get("phase")!=6 or report.get("status")!="complete" or report.get("complete") is not True: errors.append("license inventory is not a complete Phase 6 result")
    if report.get("policy_id")!=policy.get("policy_id") or report.get("policy_sha256")!=normalized_policy(policy): errors.append("license inventory does not bind normalized policy")
    inputs=report.get("inputs",[]); labels=[row.get("label") for row in inputs]
    expected_keys={"label","bytes","sha256","component_id","license_record_ids"}
    if labels!=sorted(labels) or len(labels)!=len(set(labels)) or any("path" in row or set(row)!=expected_keys for row in inputs): errors.append("license input accounting is unordered, duplicate, or path-bearing")
    audit_identity=[(x.get("label"),x.get("bytes"),x.get("sha256")) for x in audit.get("inputs",[])]
    inventory_identity=[(x.get("label"),x.get("bytes"),x.get("sha256")) for x in inputs]
    if inventory_identity!=audit_identity: errors.append("license inventory does not exactly match the Phase 6 secret audit")
    component_ids={x.get("id") for x in report.get("components",[])}
    if any(x.get("component_id") not in component_ids or not x.get("license_record_ids") for x in inputs): errors.append("shipped input lacks component or license ownership")
    policy_records={x.get("id"):x for x in policy.get("license_records",[])}
    for record in policy_records.values():
        path=record.get("notice_path")
        if path and (not (root/path).is_file() or digest(root/path)!=record.get("notice_sha256")): errors.append(f"required notice drift: {path}")
    lineage=report.get("build_lineage",[])
    if {x.get("id") for x in lineage}!={"gperf","ninja"} or any(x.get("scope")!="build-only" for x in lineage): errors.append("build-only lineage is incomplete or misclassified")
    summary=report.get("summary",{})
    expected_summary={"inputs":len(inputs),"input_bytes":sum(x.get("bytes",0) for x in inputs),"shipped_components":len(report.get("components",[])),"build_only_components":len(lineage),"license_records":len(policy_records),"verified_notices":len(report.get("notices",[]))}
    if summary!=expected_summary or labels[:2]!=["browser/host.js","browser/index.html"] or "runtime/AtomVM.wasm" not in labels: errors.append("license inventory summary or required input coverage drifted")
    artifacts=manifest.get("artifacts",[])
    if {x.get("role") for x in artifacts}!=ROLES or len(artifacts)!=len(ROLES): errors.append("Phase 6 manifest roles are incomplete or duplicate")
    bound={x.get("role"):x.get("sha256") for x in artifacts}
    if bound.get("license-inventory-report")!=canonical(report) or bound.get("secret-audit-report")!=canonical(audit): errors.append("manifest does not bind canonical Phase 6 audit and inventory")
    if browser.get("phase")!=6 or [x.get("browser") for x in browser.get("results",[])]!=["chrome","firefox"] or browser.get("comparison",{}).get("state")!="exact-match": errors.append("Phase 6 active-browser replay is incomplete or divergent")
    if any(x.get("result")!="passed" or x.get("page_errors")!=[] for x in browser.get("results",[])) or browser.get("negative_integrity",{}).get("result")!="failed": errors.append("Phase 6 browser or integrity replay failed")
    closure=(root/CLOSURE).read_text(); task=(root/TASK).read_text(); order=["ClientSafety.analyze!","Compatibility.evaluate!","SecretAudit.analyze!","LicenseInventory.analyze!","assemble.(authorization)"]
    if any(x not in closure for x in order) or any(closure.rindex(a)>=closure.rindex(b) for a,b in zip(order,order[1:])): errors.append("license inventory no longer precedes assembly in the required order")
    if "license_inputs!(secret_inputs)" not in task or "license_inventory: license_inventory" not in task: errors.append("candidate package bypasses license input accounting or manifest binding")
    required={Path(x).name for x in [POLICY,REPORT,AUDIT,MANIFEST,BROWSER]}
    if index.get("phase",0)<6 or not required.issubset(index.get("evidence",[])): errors.append("BH-06 Phase 6 evidence index is incomplete")
    expected={"decision":"accept","policy_evidence_sha256":digest(root/POLICY),"inventory_evidence_sha256":digest(root/REPORT),"audit_evidence_sha256":digest(root/AUDIT),"manifest_sha256":digest(root/MANIFEST),"browser_evidence_sha256":digest(root/BROWSER),"normalized_policy_sha256":normalized_policy(policy),"canonical_inventory_sha256":canonical(report)}
    if any(completion.get(k)!=v for k,v in expected.items()): errors.append("Phase 6 completion identities are stale")
    if "- [ ]" in (root/PLAN).read_text(): errors.append("Phase 6 checklist is incomplete")
    return errors

if __name__=="__main__":
    failures=validate(); print("\n".join(failures) if failures else "BH-06 Phase 6 license provenance: PASS"); sys.exit(bool(failures))

