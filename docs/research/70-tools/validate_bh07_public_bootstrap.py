"""Validate BH-07 Phase 2 public bootstrap and trust-boundary evidence."""
import hashlib,json,re,sys
from pathlib import Path
from research_paths import REPO_ROOT

AUTHORITY="docs/research/assets/bh-07-baseline/phase-02-authorization-v0.1.0.json"
EVIDENCE="integration/bh-07/phase-02-public-bootstrap-evidence-v0.1.0.json"
INDEX="integration/bh-07/index-v0.1.0.json"
COMPLETION="docs/research/assets/bh-07-baseline/phase-02-completion-v0.1.0.json"
PLAN="docs/research/60-planning/01-browser-host/bh-07-phoenix-integration-and-trusted-command-boundary/phase-02-public-bootstrap-envelope.md"
CONTRACT="docs/research/60-planning/01-browser-host/bh-07-phoenix-integration-and-trusted-command-boundary/public-bootstrap-contract.md"
ENGINE="packages/blazex_phoenix/lib/blazex/phoenix/public_bootstrap.ex"
STATIC="packages/blazex_phoenix/lib/blazex/phoenix/static_delivery.ex"
PLUG="profiles/browser_phoenix/lib/blazex_browser_phoenix/bootstrap_plug.ex"
CONFIG="profiles/browser_phoenix/lib/blazex_browser_phoenix/delivery_config.ex"
ENDPOINT="profiles/browser_phoenix/lib/blazex_browser_phoenix/endpoint.ex"
PROFILE_MIX="profiles/browser_phoenix/mix.exs"
PROFILE_LOCK="profiles/browser_phoenix/mix.lock"
MUTABLE_BASELINES={STATIC:"e9f4413b3540c3a550f2d00ed124fb0267b06f1da5faae6d3ea1e793ddf9ccc8", "profiles/browser_phoenix/lib/blazex_browser_phoenix/asset_plug.ex":"41a9263e89f68996157de4a7d820c8cd7ec8d9bd3946ee2a38fbd737be97e47c"}

def load(root,rel): return json.loads((Path(root)/rel).read_text())
def digest(path): return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def validate(root=REPO_ROOT):
 root=Path(root); errors=[]
 authority=load(root,AUTHORITY); evidence=load(root,EVIDENCE); index=load(root,INDEX); completion=load(root,COMPLETION)
 if authority.get("authorized") is not True or authority.get("milestone")!="BH-07" or authority.get("phase")!=2: errors.append("Phase 2 authority is invalid")
 for rel,expected in authority.get("bound_inputs",{}).items():
  if rel in MUTABLE_BASELINES:
   if expected!=MUTABLE_BASELINES[rel]: errors.append(f"mutable baseline identity drift: {rel}")
  elif not (root/rel).is_file() or digest(root/rel)!=expected: errors.append(f"bound input drift: {rel}")
 if evidence.get("decision")!="accept" or evidence.get("support_state")!="unsupported-development-evidence": errors.append("bootstrap evidence decision or support state drifted")
 for rel,expected in evidence.get("source_bindings",{}).items():
  if not (root/rel).is_file() or digest(root/rel)!=expected: errors.append(f"implementation source binding drift: {rel}")
 bootstrap=evidence.get("bootstrap",{}); required={"path":"/bh07/bootstrap.json","methods":["GET","HEAD"],"protocol":"blazex.bh07.bootstrap/1","trust":"public-untrusted-no-server-authority","manifest_bound":True,"attestation_bound":True,"canonical_json":True,"cache_control":"no-store","conditional_etag":True,"max_document_bytes":4096,"max_depth":4,"max_collection_items":32,"max_nodes":256,"max_key_bytes":64,"max_string_bytes":256,"max_safe_integer":9007199254740991,"retained_bootstrap_results":0}
 if any(bootstrap.get(key)!=value for key,value in required.items()): errors.append("bootstrap contract or bound drifted")
 capabilities=evidence.get("capabilities",{})
 if capabilities!={"static_delivery":True,"browser_local_execution":True,"sessions":False,"remote_commands":False,"pushes":False,"server_mutation":False}: errors.append("bootstrap capability authority drifted")
 gates={row.get("gate"):row for row in evidence.get("tests",[])}; required_gates={"blazex-phoenix-package","browser-phoenix-profile","bootstrap-validator-mutations","research-archive","dependency-boundary","patch-hygiene"}
 if set(gates)!=required_gates or any(row.get("result")!="passed" or row.get("failures",0)!=0 for row in gates.values()): errors.append("Phase 2 gate evidence is incomplete")
 engine=(root/ENGINE).read_text(); plug=(root/PLUG).read_text(); endpoint=(root/ENDPOINT).read_text(); mix=(root/PROFILE_MIX).read_text(); lock=(root/PROFILE_LOCK).read_text()
 terms=["@max_document_bytes 4_096","@max_nodes 256","@forbidden_key","bootstrap-delivery-identity-invalid","public-untrusted-no-server-authority","server_mutation\" => false","canonical_json"]
 if any(term not in engine for term in terms): errors.append("public bootstrap trust or limit implementation drifted")
 if '@path "/bh07/bootstrap.json"' not in plug or '"GET", "HEAD"' not in plug or '"no-store"' not in plug or "PublicBootstrap.build!" not in plug: errors.append("Phoenix bootstrap transport drifted")
 if endpoint.find("BootstrapPlug")<0 or endpoint.find("BootstrapPlug")>endpoint.find("AssetPlug"): errors.append("bootstrap route order drifted")
 forbidden=["blazex_renderer_dom_liveview","phoenix_live_view","local_live_view"]
 if any(re.search(r"\{:"+re.escape(name)+r"(?:,|\})",mix) for name in forbidden) or any(f'"{name}"' in lock for name in ["phoenix_live_view","local_live_view"]): errors.append("deferred dependency returned to active profile")
 active_sources="\n".join(path.read_text() for path in (root/"profiles/browser_phoenix/lib").rglob("*.ex"))
 if "BlazeX.Renderer.DOM.LiveView" in active_sources or "LocalLiveView" in active_sources: errors.append("deferred LiveView coupling returned to active source")
 if authority.get("deferred")!=evidence.get("deferred"): errors.append("deferred scope drifted")
 if index.get("status")!="complete" or Path(EVIDENCE).name not in index.get("evidence",[]): errors.append("BH-07 Phase 2 evidence index is incomplete")
 if "- [ ]" in (root/PLAN).read_text(): errors.append("Phase 2 checklist is incomplete")
 contract=(root/CONTRACT).read_text()
 if "never authorizes a server effect" not in contract or "[DEFERRED]" not in contract: errors.append("public bootstrap trust contract is incomplete")
 expected={"decision":"accept","authorization_sha256":digest(root/AUTHORITY),"evidence_sha256":digest(root/EVIDENCE)}
 if any(completion.get(key)!=value for key,value in expected.items()): errors.append("Phase 2 completion identities are stale")
 return errors

if __name__=="__main__":
 failures=validate(); print("\n".join(failures) if failures else "BH-07 Phase 2 public bootstrap: ACCEPT (validated)"); sys.exit(bool(failures))
