"""Bind bounded Phase 5 authority to accepted Phase 4 contracts."""
import argparse
import hashlib
import json
import subprocess
from research_paths import REPO_ROOT

BASE = "ea09d05a2709a163ff0c8776c4039f1a712a95de"
AREA = "docs/research/assets/bh-05-baseline/"
PLAN = "docs/research/60-planning/01-browser-host/bh-05-component-programming-model-and-lifecycle/"
TARGET = AREA + "nested-authorization-v0.1.0.json"
PLANNER = "packages/blazex_ui_tree/lib/blazex/ui_tree/composition_plan.ex"
INPUTS = [AREA + "composition-completion-v0.1.0.json", AREA + "composition-gates-v0.1.0.json", PLAN + "composition-contract.md", PLANNER] + [
    "packages/blazex_core/lib/blazex/component/" + p + ".ex" for p in ["stateful", "contract", "input", "result", "schema", "invocation"]] + [
    "packages/blazex_core/lib/blazex/core/" + p + ".ex" for p in ["identity", "event", "evaluator"]] + [
    "packages/blazex_ui_tree/lib/blazex/ui_tree/" + p + ".ex" for p in ["semantic_acceptance", "node", "document", "intent_set"]]

def record(root=REPO_ROOT):
    return {"schema_version": "1.0.0", "phase": 5, "base": BASE,
            "authorization": "Owner requested next BH-05 phase; Phase 5 only.",
            "branch": "codex/bh05-phase5-nested-state", "sections": ["5.1", "5.2", "5.3", "5.4"],
            "delivery": ["verified section commits", "single PR", "merge", "checkout main", "sync origin", "delete feature branch"],
            "contract": "0.1.0-bh05-nested-state", "schema_contract": "0.2.0-bh05-schema-candidate",
            "input_hashes": {p: hashlib.sha256(subprocess.check_output(["git", "show", BASE + ":" + p], cwd=root)).hexdigest() for p in INPUTS},
            "reviewed_successor_changes": {PLANNER: "Optional internal mixed-role planning; default Phase 4 pure behavior unchanged."},
            "limits": {"depth": 12, "nodes": 256, "invocations": 128, "counter": 9007199254740991, "notifications": 128},
            "excluded": ["root processes", "external messages/timers", "effects/commands", "renderer commit", "context registry resolution", "independent recovery", "LiveView", "LocalLiveView", "support claims"], "support_state": "unsupported"}

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    content = json.dumps(record(), indent=2) + "\n"
    target = REPO_ROOT / TARGET
    if args.check:
        if not target.exists() or target.read_text() != content: raise SystemExit("nested authority drift")
    else:
        with target.open("x") as output: output.write(content)
    print("BH-05 nested authority: PASS")
