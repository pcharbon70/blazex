"""Validate BH-07 Phase 1 attested static delivery and deferred boundaries."""
import hashlib,json,re,sys
from pathlib import Path
from research_paths import REPO_ROOT

AUTHORITY="docs/research/assets/bh-07-baseline/phase-01-authorization-v0.1.0.json"
EVIDENCE="integration/bh-07/phase-01-static-delivery-evidence-v0.1.0.json"
INDEX="integration/bh-07/index-v0.1.0.json"
COMPLETION="docs/research/assets/bh-07-baseline/phase-01-completion-v0.1.0.json"
PLAN="docs/research/60-planning/01-browser-host/bh-07-phoenix-integration-and-trusted-command-boundary/phase-01-attested-static-delivery-boundary.md"
CONTRACT="docs/research/60-planning/01-browser-host/bh-07-phoenix-integration-and-trusted-command-boundary/static-delivery-contract.md"
ENGINE="packages/blazex_phoenix/lib/blazex/phoenix/static_delivery.ex"
ASSET_PLUG="profiles/browser_phoenix/lib/blazex_browser_phoenix/asset_plug.ex"
CACHE="profiles/browser_phoenix/lib/blazex_browser_phoenix/static_delivery_cache.ex"
PROFILE_MIX="profiles/browser_phoenix/mix.exs"
PROFILE_LOCK="profiles/browser_phoenix/mix.lock"
BOUNDARY_TEST="profiles/browser_phoenix/test/boundary_test.exs"
MUTABLE_BASELINES={
 PROFILE_MIX:"325f4ff935747f81ffa9755f2078abd44ae45b77471732a4d26880469326b593",
 ASSET_PLUG:"2068e49af2a842d21f3df1092b4236e02cf3a98e9fbddccc0f22e35bd7a91e03"
}

def load(root,rel): return json.loads((Path(root)/rel).read_text())
def digest(path): return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def validate(root=REPO_ROOT):
 root=Path(root); errors=[]
 authority=load(root,AUTHORITY); evidence=load(root,EVIDENCE); index=load(root,INDEX); completion=load(root,COMPLETION)
 if authority.get("authorized") is not True or authority.get("milestone")!="BH-07" or authority.get("phase")!=1: errors.append("Phase 1 authority is invalid")
 for rel,expected in authority.get("bound_inputs",{}).items():
  if rel in MUTABLE_BASELINES:
   if expected!=MUTABLE_BASELINES[rel]: errors.append(f"mutable baseline identity drift: {rel}")
  elif not (root/rel).is_file() or digest(root/rel)!=expected: errors.append(f"bound input drift: {rel}")
 if evidence.get("decision")!="accept" or evidence.get("support_state")!="unsupported-development-evidence": errors.append("delivery evidence decision or support state drifted")
 for rel,expected in evidence.get("source_bindings",{}).items():
  if not (root/rel).is_file() or digest(root/rel)!=expected: errors.append(f"implementation source binding drift: {rel}")
 route=evidence.get("route",{}); required_route={"prefix":"/bh07/","methods":["GET","HEAD"],"public_only":True,"private_evidence_denied":True,"conditional_etag":True,"requested_artifact_reverified":True}
 if any(route.get(key)!=value for key,value in required_route.items()): errors.append("static delivery route contract drifted")
 scaling=evidence.get("scaling",{})
 if scaling.get("full_inventory_validations_per_identity")!=1 or scaling.get("retained_identity_results")!=1 or scaling.get("historical_identity_growth")!=0 or scaling.get("repeated_invalid_identity_full_rescans")!=0: errors.append("static delivery scaling bound drifted")
 gates={row.get("gate"):row for row in evidence.get("tests",[])}
 required_gates={"blazex-phoenix-package","browser-phoenix-profile","static-delivery-mutations","research-archive","patch-hygiene"}
 if set(gates)!=required_gates or any(row.get("result")!="passed" or row.get("failures",0)!=0 for row in gates.values()): errors.append("Phase 1 gate evidence is incomplete")
 engine=(root/ENGINE).read_text(); plug=(root/ASSET_PLUG).read_text(); cache=(root/CACHE).read_text(); mix=(root/PROFILE_MIX).read_text(); lock=(root/PROFILE_LOCK).read_text(); boundary=(root/BOUNDARY_TEST).read_text()
 engine_terms=["attested-inventory-mismatch","private-build-evidence","artifact-content-mismatch","method_not_allowed","manifest-not-canonical"]
 if any(term not in engine for term in engine_terms): errors.append("reusable fail-closed delivery checks drifted")
 if '"bh07"' not in plug or "StaticDelivery.resolve" not in plug or "StaticDeliveryCache.fetch" not in plug: errors.append("Phoenix /bh07/ composition drifted")
 if "validations: state.validations + 1" not in cache or "hits: state.hits + 1" not in cache or "result: reply" not in cache: errors.append("bounded identity cache drifted")
 forbidden=["blazex_renderer_dom_liveview","phoenix_live_view","local_live_view"]
 if any(re.search(r"\{:"+re.escape(name)+r"(?:,|\})",mix) for name in forbidden): errors.append("deferred dependency returned to active profile")
 if any(f'"{name}"' in lock for name in ["phoenix_live_view","local_live_view"]): errors.append("deferred dependency returned to active lock")
 active_sources="\n".join(path.read_text() for path in (root/"profiles/browser_phoenix/lib").rglob("*.ex"))
 if "BlazeX.Renderer.DOM.LiveView" in active_sources or "LocalLiveView" in active_sources: errors.append("deferred LiveView coupling returned to active source")
 if not all(name in boundary for name in forbidden): errors.append("deferred dependency regression assertions are incomplete")
 if authority.get("deferred")!=evidence.get("deferred"): errors.append("deferred scope drifted")
 if index.get("status")!="complete" or Path(EVIDENCE).name not in index.get("evidence",[]): errors.append("BH-07 evidence index is incomplete")
 if "- [ ]" in (root/PLAN).read_text(): errors.append("Phase 1 checklist is incomplete")
 if "historical identities" not in (root/CONTRACT).read_text(): errors.append("scaling contract is missing")
 expected={"decision":"accept","authorization_sha256":digest(root/AUTHORITY),"evidence_sha256":digest(root/EVIDENCE)}
 if any(completion.get(key)!=value for key,value in expected.items()): errors.append("Phase 1 completion identities are stale")
 return errors

if __name__=="__main__":
 failures=validate(); print("\n".join(failures) if failures else "BH-07 Phase 1 attested static delivery: ACCEPT (validated)"); sys.exit(bool(failures))
