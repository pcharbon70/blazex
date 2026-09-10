"""Validate Phase 11 fixed browser bundle evidence and fixture isolation."""
import json
import re
import sys
from research_paths import REPO_ROOT
from generate_bh05_conformance_corpus import validate as validate_corpus

EVIDENCE = "integration/bh-05/browser-conformance-v0.1.0.json"
COMPONENTS = "integration/bh-05/browser_conformance/lib/components.ex"

def validate(root=REPO_ROOT):
    errors=list(validate_corpus(root))
    value=json.loads((root/EVIDENCE).read_text()); rows=value.get("results",[])
    if [r.get("browser") for r in rows] != ["chrome","firefox"] or any(r.get("result")!="passed" or r.get("page_errors") for r in rows): errors.append("active browser row failed")
    if value.get("comparison",{}).get("state") != "exact-match" or len({json.dumps({"trace":r.get("trace"),"final_state":r.get("final_state"),"dom":r.get("dom")},sort_keys=True) for r in rows}) != 1: errors.append("runtime semantic divergence")
    if any(r.get("memory_pages") != 256 for r in rows): errors.append("runtime memory drift")
    source=(root/COMPONENTS).read_text()
    if re.search(r"\b(?:Popcorn|Phoenix|LiveView|LocalLiveView|document|window)\b|BlazeX\.(?:Runtime|Renderer|Host)",source): errors.append("portable components import host/runtime surface")
    required={"spawn_opt","monitor","unlink","exit","monotonic"}; primitives=next((r for r in rows[0].get("trace",[]) if r.get("step")=="runtime-primitives"),{})
    if not all(primitives.get(key) is True for key in required): errors.append("recovery primitive not qualified")
    return errors

if __name__=="__main__":
    errors=validate(); print("\n".join(errors) if errors else "BH-05 browser AtomVM conformance: PASS"); sys.exit(bool(errors))
