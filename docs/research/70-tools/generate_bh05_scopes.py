"""Bind Phase 9 scoped context and registry to accepted component/runtime authority."""
import argparse
import hashlib
import json
import subprocess
from research_paths import REPO_ROOT

BASE = "8e26ed110e1de2ab3be8039f27e5efaf7dea4117"
AREA = "docs/research/assets/bh-05-baseline/"
PLAN = "docs/research/60-planning/01-browser-host/bh-05-component-programming-model-and-lifecycle/"
TARGET = AREA + "scope-authorization-v0.1.0.json"
CHANGES = ["packages/blazex_core/lib/blazex/component/" + name + ".ex" for name in ["input", "root_process"]] + ["packages/blazex_ui_tree/lib/blazex/ui_tree/" + name + ".ex" for name in ["root_evaluator", "nested_candidates"]]
INPUTS = [AREA + "action-completion-v0.1.0.json", AREA + "action-gates-v0.1.0.json", PLAN + "action-contract.md", PLAN + "root-supervision-compatibility.md"] + CHANGES + ["packages/blazex_core/lib/blazex/component/" + name + ".ex" for name in ["root_port", "contract", "schema", "invocation", "nested_table", "root_schedule", "action", "action_manifest"]] + ["packages/blazex_core/lib/blazex/core/authoring.ex", "packages/blazex_ui_tree/lib/blazex/ui_tree/composition_plan.ex", "docs/research/20-notes/architecture-decisions/adr-0005-server-adapter-and-trust-boundary.md"]


def record(root=REPO_ROOT):
    return {"schema_version": "1.0.0", "phase": 9, "base": BASE,
            "authorization": "Owner requested next BH-05 phase after accepted Phase 8 PR 59; Phase 9 only.",
            "branch": "codex/bh05-phase9-scopes", "sections": ["9.1", "9.2", "9.3", "9.4"],
            "delivery": ["verified section commits", "single PR", "merge", "checkout main", "sync origin", "delete feature branch"],
            "contract": "0.1.0-bh05-scopes", "schema_contract": "0.2.0-bh05-schema-candidate",
            "input_hashes": {p: hashlib.sha256(subprocess.check_output(["git", "show", BASE + ":" + p], cwd=root)).hexdigest() for p in INPUTS},
            "reviewed_successor_changes": {p: "Explicit scoped-runtime successor; Phase 1–8 defaults and normalized traces retained." for p in CHANGES},
            "limits": {"total_work": 256, "contexts": 16, "providers": 32, "subscriptions": 128, "registry_entries": 128, "composition_depth": 12},
            "excluded": ["BH-06 bundles and lazy loading", "theme/form/auth product providers", "Phoenix sessions", "arbitrary plugins", "remote code loading", "LiveView", "LocalLiveView", "support claims"],
            "support_state": "unsupported"}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    content = json.dumps(record(), indent=2) + "\n"
    target = REPO_ROOT / TARGET
    if args.check:
        if not target.exists() or target.read_text() != content:
            raise SystemExit("scope authority drift")
    else:
        with target.open("x") as output:
            output.write(content)
    print("BH-05 scope authority: PASS")
