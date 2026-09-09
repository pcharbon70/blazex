"""Bind Phase 7 scheduling authority to accepted root and interaction contracts."""
import argparse
import hashlib
import json
import subprocess
from research_paths import REPO_ROOT

BASE = "e373e96891207ea4b6c2fdfae9533181334b3cab"
AREA = "docs/research/assets/bh-05-baseline/"
PLAN = "docs/research/60-planning/01-browser-host/bh-05-component-programming-model-and-lifecycle/"
TARGET = AREA + "scheduling-authorization-v0.1.0.json"
CHANGES = ["packages/blazex_core/lib/blazex/component/" + p + ".ex" for p in ["local_view", "root_guardian", "root_process"]] + [
    "packages/blazex_ui_tree/lib/blazex/ui_tree/" + p + ".ex" for p in ["root_evaluator", "nested_candidates"]]
INPUTS = [AREA + "root-completion-v0.1.0.json", AREA + "root-gates-v0.1.0.json", PLAN + "root-lifecycle-contract.md", PLAN + "root-supervision-compatibility.md"] + CHANGES + [
    "packages/blazex_core/lib/blazex/component/" + p + ".ex" for p in ["root_port", "input", "result", "contract", "schema"]] + [
    "packages/blazex_core/lib/blazex/core/event.ex", "js/blazex_runtime/src/interaction-stream.js", "js/blazex_runtime/src/interaction-record.js",
    "docs/research/assets/quality-acceptance/blazex-acceptance-registry-v0.1.0.json"]


def record(root=REPO_ROOT):
    return {"schema_version": "1.0.0", "phase": 7, "base": BASE,
            "authorization": "Owner requested next BH-05 phase; Phase 7 only.",
            "branch": "codex/bh05-phase7-scheduling", "sections": ["7.1", "7.2", "7.3", "7.4"],
            "delivery": ["verified section commits", "single PR", "merge", "checkout main", "sync origin", "delete feature branch"],
            "contract": "0.1.0-bh05-scheduling", "schema_contract": "0.2.0-bh05-schema-candidate",
            "input_hashes": {p: hashlib.sha256(subprocess.check_output(["git", "show", BASE + ":" + p], cwd=root)).hexdigest() for p in INPUTS},
            "reviewed_successor_changes": {p: "Opt-in bounded scheduling and typed dispatch; Phase 6 defaults retained." for p in CHANGES},
            "limits": {"total_work": 256, "active_timers": 32, "in_flight": 1, "counter": 9007199254740991},
            "excluded": ["effects/provider results", "remote commands", "unrestricted send", "dynamic registry/context", "restart policy", "forms", "LiveView", "LocalLiveView", "support claims"],
            "support_state": "unsupported"}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    content = json.dumps(record(), indent=2) + "\n"
    target = REPO_ROOT / TARGET
    if args.check:
        if not target.exists() or target.read_text() != content:
            raise SystemExit("scheduling authority drift")
    else:
        with target.open("x") as output:
            output.write(content)
    print("BH-05 scheduling authority: PASS")
