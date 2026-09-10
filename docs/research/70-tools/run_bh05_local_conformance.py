"""Run and normalize the Phase 11 local ERTS, DOM, and GTK reference rows."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
from research_paths import REPO_ROOT

DIGEST_NAMES = ["COMPOSITION_OUTPUT_SHA256", "COMPOSITION_TRACE_SHA256", "COMPOSITION_HEADLESS_SHA256", "COMPOSITION_SLOTS_OUTPUT_SHA256", "COMPOSITION_SLOTS_TRACE_SHA256", "NESTED_SCRIPT_SHA256", "NESTED_HEADLESS_SHA256", "NESTED_FINAL_STATE_SHA256", "ROOT_SCRIPT_SHA256", "ROOT_TRACE_SHA256", "ROOT_FINAL_STATE_SHA256", "SCHEDULING_SAMPLE_SHA256", "SCHEDULING_TRACE_SHA256", "SCHEDULING_FINAL_STATE_SHA256", "ACTION_FINAL_STATE_SHA256", "ACTION_PENDING_SHA256", "ACTION_LEASE_SHA256", "SCOPE_TRACE_SHA256", "SCOPE_FINAL_STATE_SHA256", "SCOPE_REGISTRY_SHA256", "RECOVERY_FAILURE_SHA256", "RECOVERY_CLEANUP_SHA256", "RECOVERY_RESTART_SHA256"]

def command(args, cwd=REPO_ROOT):
    return subprocess.run(args, cwd=cwd, check=True, capture_output=True, text=True, timeout=600).stdout

def run():
    docker=["docker","run","--rm","--network","none","--user",f"{os.getuid()}:{os.getgid()}","-v",str(REPO_ROOT)+":/workspace:ro","-w","/workspace/integration/conformance","-e","MIX_BUILD_PATH=/tmp/bh05-phase11","a2386c21edd5","mix","test"]
    output=command(docker)
    digests={name: values[0] for name in DIGEST_NAMES if len(values := re.findall(name+r" ([0-9a-f]{64})", output)) == 1}
    if len(digests) != len(DIGEST_NAMES) or not re.search(r"93 tests, 0 failures", output): raise ValueError("incomplete ERTS trace")
    with tempfile.TemporaryDirectory(prefix="bh05-local-") as temp:
        dom=Path(temp)/"dom.json"; gtk=Path(temp)/"gtk.json"
        command([sys.executable,"packages/blazex_renderer_dom/js/run-browser-conformance.py","--output",str(dom)])
        command([sys.executable,"experiments/native_renderer_spike/scripts/run_gtk4.py","--output",str(gtk)])
        dom_value=json.loads(dom.read_text()); gtk_value=json.loads(gtk.read_text())
    if any(row["result"] != "passed" for row in dom_value["results"]) or gtk_value["result"] != "passed": raise ValueError("backend failure")
    return {"schema_version":"1.0.0","phase":11,"support_state":"unsupported","result":"passed","erts":{"image":"a2386c21edd5","elixir":"1.17.3","otp":"26.0.2","tests":93,"digests":digests},"dom":{"state":"exact-match","rows":[{"browser":r["browser"],"version":r["version"],"checks":r["checks"],"result":r["result"]} for r in dom_value["results"]]},"gtk":{"state":"exact-match-portability-only","environment":gtk_value["environment"],"controls":gtk_value["controls"],"services":gtk_value["services"],"observation":gtk_value["observation"]},"differences":[],"deferred":[{"row":"Windows direct renderer","reactivation":"BH-22"},{"row":"macOS direct renderer","reactivation":"BH-22"},{"row":"manual assistive-technology pairing","reactivation":"BH-22"}]}

if __name__ == "__main__":
    parser=argparse.ArgumentParser(description=__doc__); parser.add_argument("--output",type=Path,required=True); parser.add_argument("--check",action="store_true"); args=parser.parse_args()
    value=run(); rendered=json.dumps(value,indent=2,sort_keys=True)+"\n"
    if args.check:
        if not args.output.exists() or args.output.read_text()!=rendered: raise SystemExit("local conformance drift")
    else: args.output.write_text(rendered)
    print("BH-05 local ERTS/DOM/GTK conformance: PASS")
