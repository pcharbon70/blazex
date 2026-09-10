"""Validate the Phase 11 cross-runtime ledger and source-frozen completion."""
import hashlib
import json
from pathlib import Path
from research_paths import REPO_ROOT
from generate_bh05_conformance import TARGET, record as authority_record
from generate_bh05_conformance_corpus import validate as validate_corpus
from validate_bh05_browser_conformance import validate as validate_browser
from validate_bh05_authoring import files

AREA="docs/research/assets/bh-05-baseline/"
PLAN="docs/research/60-planning/01-browser-host/bh-05-component-programming-model-and-lifecycle/"
GATES=["packages","browser-project","javascript","local-repeat","browser-repeat","phase10-replay","historical-sweep","validator-tests","authority","corpus","browser-validator","archive","json","hygiene"]
def sha(data): return hashlib.sha256(data).hexdigest()
def sources(root=REPO_ROOT):
    paths=[p for p in files(root) if p.startswith(("packages/","js/","integration/","profiles/","experiments/","docs/research/70-tools/")) and not p.endswith(".md")]
    paths += [TARGET,PLAN+"conformance-contract.md"]
    return {p:sha((root/p).read_bytes()) for p in sorted(set(paths))}
def gate_errors(value,current):
    errors=[]; rows=value.get("results",[])
    if value.get("phase")!=11: errors.append("wrong phase")
    if value.get("source_hashes")!=current or value.get("final_source_hashes")!=current: errors.append("stale source closure")
    if [r.get("name") for r in rows]!=GATES or any(r.get("exit_code")!=0 or r.get("error") for r in rows): errors.append("incomplete or failed gates")
    return errors
def completion(root=REPO_ROOT):
    paths=[TARGET,"integration/bh-05/conformance-corpus-v0.1.0.json","integration/bh-05/local-conformance-v0.1.0.json","integration/bh-05/browser-conformance-v0.1.0.json",AREA+"conformance-gates-v0.1.0.json"]
    return {"schema_version":"1.0.0","phase":11,"decision":"active-cross-runtime-conformance-complete","phase12_eligible":True,"phase12_authorized":False,"bh06_eligible":False,"support_state":"unsupported","artifact_hashes":{p:sha((root/p).read_bytes()) for p in paths}}
def validate(root=REPO_ROOT,final=False):
    root=Path(root); errors=[]
    try:
        errors += validate_corpus(root)+validate_browser(root)
        local=json.loads((root/"integration/bh-05/local-conformance-v0.1.0.json").read_text())
        if local.get("result")!="passed" or len(local.get("erts",{}).get("digests",{}))!=23 or local.get("differences")!=[]: errors.append("local ledger drift")
        source=(root/"packages/blazex_core/lib/blazex/component/root_port.ex").read_text()+(root/"packages/blazex_core/lib/blazex/component/nested_table.ex").read_text()
        if "Regex" in source or "term_to_binary(value, [:deterministic])" in source: errors.append("ERTS-only digest dependency restored")
        if json.loads((root/TARGET).read_text()) != authority_record(root): errors.append("authority drift")
        if final:
            gates=json.loads((root/AREA/"conformance-gates-v0.1.0.json").read_text()); errors+=gate_errors(gates,sources(root))
            if json.loads((root/AREA/"conformance-completion-v0.1.0.json").read_text())!=completion(root): errors.append("completion drift")
    except (OSError,ValueError,KeyError) as error: errors.append("missing/malformed conformance evidence: "+type(error).__name__)
    return errors
if __name__=="__main__":
    import argparse,sys; parser=argparse.ArgumentParser();parser.add_argument("--final",action="store_true");args=parser.parse_args();errors=validate(final=args.final);print("\n".join(errors) if errors else "BH-05 cross-runtime conformance: PASS");sys.exit(bool(errors))
