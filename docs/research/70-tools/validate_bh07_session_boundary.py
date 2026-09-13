"""Validate BH-07 Phase 3 opaque sessions and authentication projection."""
import hashlib,json,re,sys
from pathlib import Path
from research_paths import REPO_ROOT

AUTHORITY="docs/research/assets/bh-07-baseline/phase-03-authorization-v0.1.0.json"; EVIDENCE="integration/bh-07/phase-03-session-boundary-evidence-v0.1.0.json"; INDEX="integration/bh-07/index-v0.1.0.json"; COMPLETION="docs/research/assets/bh-07-baseline/phase-03-completion-v0.1.0.json"
PLAN="docs/research/60-planning/01-browser-host/bh-07-phoenix-integration-and-trusted-command-boundary/phase-03-opaque-session-and-authentication-projection.md"; CONTRACT="docs/research/60-planning/01-browser-host/bh-07-phoenix-integration-and-trusted-command-boundary/session-boundary-contract.md"
REGISTRY="packages/blazex_phoenix/lib/blazex/phoenix/session_registry.ex"; BOOTSTRAP="packages/blazex_phoenix/lib/blazex/phoenix/public_bootstrap.ex"; PLUG="profiles/browser_phoenix/lib/blazex_browser_phoenix/session_plug.ex"; ENDPOINT="profiles/browser_phoenix/lib/blazex_browser_phoenix/endpoint.ex"; PROFILE_MIX="profiles/browser_phoenix/mix.exs"; PROFILE_LOCK="profiles/browser_phoenix/mix.lock"
MUTABLE={BOOTSTRAP:"1fd7e940ce1a4deab52ee6468940cc42f5403503ce5db381ed26996639baa9bc",ENDPOINT:"8514b8f1c8212f14294c4756e9490ebdb3834407150359f15fcfd19097f09927"}
def load(root,rel): return json.loads((Path(root)/rel).read_text())
def digest(path): return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def validate(root=REPO_ROOT):
 root=Path(root); errors=[]; authority=load(root,AUTHORITY); evidence=load(root,EVIDENCE); index=load(root,INDEX); completion=load(root,COMPLETION)
 if authority.get("authorized") is not True or authority.get("phase")!=3: errors.append("Phase 3 authority is invalid")
 for rel,expected in authority.get("bound_inputs",{}).items():
  if rel in MUTABLE:
   if expected!=MUTABLE[rel]: errors.append(f"mutable baseline identity drift: {rel}")
  elif not (root/rel).is_file() or digest(root/rel)!=expected: errors.append(f"bound input drift: {rel}")
 if evidence.get("decision")!="accept" or evidence.get("support_state")!="unsupported-development-evidence": errors.append("session evidence decision drifted")
 for rel,expected in evidence.get("source_bindings",{}).items():
  if not (root/rel).is_file() or digest(root/rel)!=expected: errors.append(f"implementation source binding drift: {rel}")
 registry=evidence.get("registry",{}); required={"opaque_random_bytes":32,"max_sessions":256,"default_ttl_ms":900000,"max_ttl_ms":3600000,"prune_before_capacity":True,"rotation_preserves_expiry":True,"revocation_idempotent":True,"restart_invalidates_all":True,"concurrent_capacity_exact":True,"snapshot_redacted":True}
 if registry!=required: errors.append("session registry bounds drifted")
 projection=evidence.get("projection",{}); expected_fields=["expires_at_ms","protocol","state","subject"]
 if projection.get("path")!="/bh07/session" or projection.get("authenticated_fields")!=expected_fields or projection.get("cache_control")!="no-store": errors.append("session projection contract drifted")
 forbidden={"session_id","credential","role","permission","allowed_action","csrf","mutation_authority"}
 if set(projection.get("forbidden_fields",[]))!=forbidden: errors.append("session projection redaction drifted")
 capabilities=evidence.get("capabilities",{})
 if capabilities!={"sessions":True,"authentication_projection":True,"remote_commands":False,"pushes":False,"server_mutation":False}: errors.append("session capability boundary drifted")
 gates={x.get("gate"):x for x in evidence.get("tests",[])}; required_gates={"blazex-phoenix-package","browser-phoenix-profile","session-validator-mutations","research-archive","dependency-boundary","patch-hygiene"}
 if set(gates)!=required_gates or any(x.get("result")!="passed" or x.get("failures",0)!=0 for x in gates.values()): errors.append("Phase 3 gate evidence is incomplete")
 registry_source=(root/REGISTRY).read_text(); plug=(root/PLUG).read_text(); endpoint=(root/ENDPOINT).read_text(); mix=(root/PROFILE_MIX).read_text(); lock=(root/PROFILE_LOCK).read_text()
 if any(term not in registry_source for term in ["@default_max_sessions 256","@max_ttl_ms 3_600_000","strong_rand_bytes(32)","session-capacity","expires_at_ms","Map.delete"]): errors.append("session registry implementation drifted")
 if any(term not in plug for term in ['@session_path "/bh07/session"',"SessionRegistry.lookup","SessionRegistry.revoke","same_origin?","test_control?","delete_session(:bh07_session_id)"]): errors.append("Phoenix session projection implementation drifted")
 if 'key: "_blazex_browser_phoenix"' not in endpoint or 'same_site: "Strict"' not in endpoint or "encryption_salt" not in endpoint or endpoint.find("Plug.Session")>endpoint.find("SessionPlug"): errors.append("encrypted session cookie composition drifted")
 forbidden_deps=["blazex_renderer_dom_liveview","phoenix_live_view","local_live_view"]
 if any(re.search(r"\{:"+re.escape(name)+r"(?:,|\})",mix) for name in forbidden_deps) or any(f'"{name}"' in lock for name in ["phoenix_live_view","local_live_view"]): errors.append("deferred dependency returned")
 if authority.get("deferred")!=evidence.get("deferred"): errors.append("deferred scope drifted")
 if index.get("status")!="complete" or Path(EVIDENCE).name not in index.get("evidence",[]): errors.append("Phase 3 evidence index incomplete")
 if "- [ ]" in (root/PLAN).read_text(): errors.append("Phase 3 checklist incomplete")
 if "[DEFERRED]" not in (root/CONTRACT).read_text(): errors.append("session deferral contract incomplete")
 expected={"decision":"accept","authorization_sha256":digest(root/AUTHORITY),"evidence_sha256":digest(root/EVIDENCE)}
 if any(completion.get(k)!=v for k,v in expected.items()): errors.append("Phase 3 completion identities stale")
 return errors
if __name__=="__main__":
 failures=validate(); print("\n".join(failures) if failures else "BH-07 Phase 3 session boundary: ACCEPT (validated)"); sys.exit(bool(failures))
