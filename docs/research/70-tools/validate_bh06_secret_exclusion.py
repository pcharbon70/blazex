"""Validate BH-06 Phase 5 secret-bearing input exclusion evidence."""
import hashlib, json, sys
from pathlib import Path
from jsonschema import Draft202012Validator
from research_paths import REPO_ROOT

AUTHORITY="docs/research/assets/bh-06-baseline/phase-05-authorization-v0.1.0.json"
POLICY="integration/bh-06/secret-policy-v0.1.0.json"
REPORT="integration/bh-06/secret-audit-v0.1.0.json"
MANIFEST="integration/bh-06/phase-05-build-manifest-v0.1.0.json"
BROWSER="integration/bh-06/phase-05-browser-replay-v0.1.0.json"
INDEX="integration/bh-06/index-v0.1.0.json"
COMPLETION="docs/research/assets/bh-06-baseline/phase-05-completion-v0.1.0.json"
PLAN="docs/research/60-planning/01-browser-host/bh-06-build-compatibility-and-client-safety-pipeline/phase-05-secret-bearing-input-exclusion.md"
CLOSURE="packages/blazex_build/lib/blazex/build/client_closure.ex"
TASK="integration/bh-06/vertical_slice/lib/mix/tasks/bh06.package.ex"
MUTABLE={CLOSURE:"617a79ef469b0415e59deddf872c0f0209f200c04b74f6bfe80ee426e6a5ac26"}
ROLES={"document","runtime-module","runtime-wasm","application-bundle","browser-host","reachability-report","client-safety-report","compatibility-report","secret-audit-report"}

def digest(path): return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def load(root, rel): return json.loads((Path(root)/rel).read_text())
def canonical(value): return hashlib.sha256((json.dumps(value,sort_keys=True,separators=(",",":"))+"\n").encode()).hexdigest()

def validate(root=REPO_ROOT):
    root=Path(root); errors=[]
    authority=load(root,AUTHORITY); policy=load(root,POLICY); report=load(root,REPORT); manifest=load(root,MANIFEST); browser=load(root,BROWSER); index=load(root,INDEX); completion=load(root,COMPLETION)
    if authority.get("authorized") is not True or authority.get("phase")!=5: errors.append("Phase 5 authority is invalid")
    for rel,expected in authority.get("bound_inputs",{}).items():
        if rel in MUTABLE:
            if expected!=MUTABLE[rel]: errors.append(f"mutable baseline identity drift: {rel}")
        elif not (root/rel).is_file() or digest(root/rel)!=expected: errors.append(f"bound input drift: {rel}")
    for data,schema in [(POLICY,"integration/bh-06/secret-policy.schema.json"),(REPORT,"integration/bh-06/secret-audit.schema.json")]:
        found=list(Draft202012Validator(load(root,schema)).iter_errors(load(root,data)))
        if found: errors.append(f"schema failure for {data}: {found[0].message}")
    if report.get("phase")!=5 or report.get("status")!="complete" or report.get("clean") is not True or report.get("findings")!=[]: errors.append("secret audit is not a clean Phase 5 result")
    if report.get("policy_id")!=policy.get("policy_id") or report.get("policy_sha256")!=canonical(policy): errors.append("secret audit does not bind normalized policy")
    inputs=report.get("inputs",[]); labels=[row.get("label") for row in inputs]
    if labels!=sorted(labels) or len(labels)!=len(set(labels)) or any("path" in row or set(row)!={"label","bytes","sha256"} for row in inputs): errors.append("secret input accounting is unordered, duplicate, or path-bearing")
    summary=report.get("summary",{})
    expected_summary={"inputs":len(inputs),"input_bytes":sum(row.get("bytes",0) for row in inputs),"literal_rules":len(policy.get("literal_rules",[])),"key_fragments":len(policy.get("key_fragments",[])),"findings":0}
    if summary!=expected_summary or labels[:2]!=["browser/host.js","browser/index.html"] or "runtime/AtomVM.wasm" not in labels: errors.append("secret audit summary or required input coverage drifted")
    artifacts=manifest.get("artifacts",[])
    if {x.get("role") for x in artifacts}!=ROLES or len(artifacts)!=len(ROLES): errors.append("Phase 5 manifest roles are incomplete or duplicate")
    assets=[x for x in artifacts if x.get("role")=="secret-audit-report"]
    if len(assets)!=1 or assets[0].get("sha256")!=canonical(report): errors.append("manifest does not bind canonical secret audit")
    if [x.get("browser") for x in browser.get("results",[])]!=["chrome","firefox"] or browser.get("comparison",{}).get("state")!="exact-match": errors.append("Phase 5 active-browser replay is incomplete or divergent")
    if any(x.get("result")!="passed" or x.get("page_errors")!=[] for x in browser.get("results",[])) or browser.get("negative_integrity",{}).get("result")!="failed": errors.append("Phase 5 browser or integrity replay failed")
    closure=(root/CLOSURE).read_text(); task=(root/TASK).read_text(); order=["ClientSafety.analyze!","Compatibility.evaluate!","SecretAudit.analyze!","assemble.(authorization)"]
    if any(x not in closure for x in order) or any(closure.rindex(a)>=closure.rindex(b) for a,b in zip(order,order[1:])): errors.append("secret audit no longer precedes assembly in the required order")
    if "secret_inputs!(root, inputs)" not in task or "secret_audit: secret_audit" not in task: errors.append("candidate package bypasses complete secret input accounting or manifest binding")
    required={Path(x).name for x in [POLICY,REPORT,MANIFEST,BROWSER]}
    if index.get("phase",0)<5 or not required.issubset(index.get("evidence",[])): errors.append("BH-06 Phase 5 evidence index is incomplete")
    expected={"decision":"accept","policy_evidence_sha256":digest(root/POLICY),"audit_evidence_sha256":digest(root/REPORT),"manifest_sha256":digest(root/MANIFEST),"browser_evidence_sha256":digest(root/BROWSER),"canonical_policy_sha256":canonical(policy),"canonical_audit_sha256":canonical(report)}
    if any(completion.get(k)!=v for k,v in expected.items()): errors.append("Phase 5 completion identities are stale")
    if "- [ ]" in (root/PLAN).read_text(): errors.append("Phase 5 checklist is incomplete")
    return errors

if __name__=="__main__":
    failures=validate(); print("\n".join(failures) if failures else "BH-06 Phase 5 secret exclusion: PASS"); sys.exit(bool(failures))
