"""Bind bounded Phase 6 authority to accepted nested and host/renderer contracts."""
import argparse
import hashlib
import json
import subprocess
from research_paths import REPO_ROOT

BASE = "f2fdc745118f0ad84e5b3ab53ea9e5221310f957"
AREA = "docs/research/assets/bh-05-baseline/"
PLAN = "docs/research/60-planning/01-browser-host/bh-05-component-programming-model-and-lifecycle/"
TARGET = AREA + "root-authorization-v0.1.0.json"
CHANGES = ["packages/blazex_ui_tree/lib/blazex/ui_tree/" + p + ".ex" for p in ["composition_plan", "nested_candidates"]]
INPUTS = [AREA + "nested-completion-v0.1.0.json", AREA + "nested-gates-v0.1.0.json", PLAN + "nested-contract.md"] + CHANGES + [
    "packages/blazex_core/lib/blazex/component/" + p + ".ex" for p in ["root", "contract", "input", "result", "schema", "invocation", "nested_table"]] + [
    "packages/blazex_ui_tree/lib/blazex/ui_tree/semantic_acceptance.ex", "packages/blazex_renderer/lib/blazex/renderer/session.ex",
    "js/blazex_runtime/src/root-lifecycle.js", "js/blazex_runtime/src/render-transaction-v2.js", "js/blazex_runtime/src/atomic-dom.js",
    "docs/research/assets/bh-03-baseline/blazex-bh-03-phase-04-completion-v0.1.0.json",
    "docs/research/assets/bh-04-baseline/blazex-bh-04-phase-10-completion-v0.1.0.json"]


def record(root=REPO_ROOT):
    return {"schema_version": "1.0.0", "phase": 6, "base": BASE,
            "authorization": "Owner requested next BH-05 phase; Phase 6 only.",
            "branch": "codex/bh05-phase6-root-lifecycle", "sections": ["6.1", "6.2", "6.3", "6.4"],
            "delivery": ["verified section commits", "single PR", "merge", "checkout main", "sync origin", "delete feature branch"],
            "contract": "0.1.0-bh05-root-lifecycle", "schema_contract": "0.2.0-bh05-schema-candidate",
            "input_hashes": {p: hashlib.sha256(subprocess.check_output(["git", "show", BASE + ":" + p], cwd=root)).hexdigest() for p in INPUTS},
            "reviewed_successor_changes": {p: "Explicit root-role mode; inherited default behavior unchanged." for p in CHANGES},
            "limits": {"depth": 12, "nodes": 256, "invocations": 128, "counter": 9007199254740991, "in_flight": 1},
            "excluded": ["event backlog", "user handle_info", "application timers", "effects/commands", "context registry resolution", "automatic retry", "LiveView", "LocalLiveView", "support claims"],
            "support_state": "unsupported"}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    content = json.dumps(record(), indent=2) + "\n"
    target = REPO_ROOT / TARGET
    if args.check:
        if not target.exists() or target.read_text() != content:
            raise SystemExit("root authority drift")
    else:
        with target.open("x") as output:
            output.write(content)
    print("BH-05 root authority: PASS")
