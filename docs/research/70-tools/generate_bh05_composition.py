"""Generate bounded Phase 4 composition authority from the accepted schema snapshot."""
import argparse
import hashlib
import json
import subprocess
from research_paths import REPO_ROOT

BASE = "fc5048d4db7cc80fd21b492e0638182abceda1af"
AREA = "docs/research/assets/bh-05-baseline/"
PLAN = "docs/research/60-planning/01-browser-host/bh-05-component-programming-model-and-lifecycle/"
TARGET = AREA + "composition-authorization-v0.1.0.json"
INPUTS = [AREA + "schema-completion-v0.1.0.json", AREA + "schema-gates-v0.1.0.json", PLAN + "schema-contract.md"] + [
    "packages/blazex_core/lib/blazex/component/" + p + ".ex" for p in ["pure", "schema", "props", "slots", "invocation", "result"]] + [
    "packages/blazex_core/lib/blazex/core/identity.ex"] + [
    "packages/blazex_ui_tree/lib/blazex/ui_tree/" + p + ".ex" for p in ["node", "document", "intent_set", "binding", "layout", "accessibility", "focus", "selection"]]


def record(root=REPO_ROOT):
    return {"schema_version": "1.0.0", "phase": 4, "base": BASE,
            "authorization": "Owner explicitly requested next BH-05 phase; Phase 4 only.",
            "branch": "codex/bh05-phase4-composition", "sections": ["4.1", "4.2", "4.3", "4.4"],
            "delivery": ["verified section commits", "single PR", "merge", "checkout main", "sync origin", "delete feature branch"],
            "contract": "0.1.0-bh05-pure-composition", "schema_contract": "0.2.0-bh05-schema-candidate",
            "input_hashes": {p: hashlib.sha256(subprocess.check_output(["git", "show", BASE + ":" + p], cwd=root)).hexdigest() for p in INPUTS},
            "limits": {"depth": 12, "nodes": 256, "invocations": 128},
            "excluded": ["retained state", "root processes", "events/messages/effects", "dynamic registry", "renderer execution", "HEEx/DOM", "LiveView", "LocalLiveView", "support claims"], "support_state": "unsupported"}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    content = json.dumps(record(), indent=2) + "\n"
    target = REPO_ROOT / TARGET
    if args.check:
        if not target.exists() or target.read_text() != content: raise SystemExit("composition authority drift")
    else:
        with target.open("x") as output: output.write(content)
    print("BH-05 composition authority: PASS")
