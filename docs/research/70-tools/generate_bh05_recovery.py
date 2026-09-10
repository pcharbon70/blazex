"""Bind bounded Phase 10 recovery to accepted lifecycle and reliability authority."""
import argparse
import hashlib
import json
import subprocess
from research_paths import REPO_ROOT

BASE = "77bf199bebb680b24efef0130b19d93ef181f4d5"
AREA = "docs/research/assets/bh-05-baseline/"
PLAN = "docs/research/60-planning/01-browser-host/bh-05-component-programming-model-and-lifecycle/"
TARGET = AREA + "recovery-authorization-v0.1.0.json"
CHANGES = ["packages/blazex_core/lib/blazex/component/" + name + ".ex" for name in ["local_view", "root_process", "root_port"]] + ["packages/blazex_ui_tree/lib/blazex/ui_tree/root_evaluator.ex"]
INPUTS = [AREA + "scope-completion-v0.1.0.json", AREA + "scope-gates-v0.1.0.json", PLAN + "scope-contract.md", PLAN + "action-contract.md", PLAN + "scheduling-contract.md", PLAN + "root-supervision-compatibility.md"] + CHANGES + ["packages/blazex_core/lib/blazex/component/" + name + ".ex" for name in ["root_guardian", "root_schedule", "root_timers", "action_runtime", "action_ledger", "scoped_context", "component_registry"]] + ["packages/blazex_ui_tree/lib/blazex/ui_tree/accessibility.ex", "packages/blazex_ui_tree/lib/blazex/ui_tree/focus.ex", "docs/research/assets/quality-acceptance/blazex-acceptance-registry-v0.1.0.json", "docs/research/assets/bh-03-baseline/blazex-bh-03-phase-09-acceptance-v0.1.0.json", "docs/research/assets/bh-04-baseline/blazex-bh-04-phase-10-acceptance-overlay-v0.1.0.json"]


def record(root=REPO_ROOT):
    return {"schema_version": "1.0.0", "phase": 10, "base": BASE,
            "authorization": "Owner requested next BH-05 phase after accepted Phase 9 PR 60; Phase 10 only.",
            "branch": "codex/bh05-phase10-recovery", "sections": ["10.1", "10.2", "10.3", "10.4"],
            "delivery": ["verified section commits", "single PR", "merge", "checkout main", "sync origin", "delete feature branch"],
            "contract": "0.1.0-bh05-recovery",
            "input_hashes": {p: hashlib.sha256(subprocess.check_output(["git", "show", BASE + ":" + p], cwd=root)).hexdigest() for p in INPUTS},
            "reviewed_successor_changes": {p: "Opt-in root recovery; default Phase 1–9 behavior and normalized traces retained." for p in CHANGES},
            "limits": {"automatic_restarts": 3, "window_ms": 5000, "cleanup_ms": 1000, "owners": 128, "pending_requests": 128, "leases": 512},
            "excluded": ["BH-15 offline recovery", "whole-VM restart", "non-idempotent replay", "production reporting", "nested process-free isolation", "LiveView", "LocalLiveView", "support claims"],
            "support_state": "unsupported"}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    content = json.dumps(record(), indent=2) + "\n"
    target = REPO_ROOT / TARGET
    if args.check:
        if not target.exists() or target.read_text() != content:
            raise SystemExit("recovery authority drift")
    else:
        with target.open("x") as output:
            output.write(content)
    print("BH-05 recovery authority: PASS")
