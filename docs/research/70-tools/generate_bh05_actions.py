"""Bind Phase 8 typed actions to accepted scheduling and effect authority."""
import argparse
import hashlib
import json
import subprocess
from research_paths import REPO_ROOT

BASE = "08dec098fde98b506d554bf8c3ff64bc65de6add"
AREA = "docs/research/assets/bh-05-baseline/"
PLAN = "docs/research/60-planning/01-browser-host/bh-05-component-programming-model-and-lifecycle/"
TARGET = AREA + "action-authorization-v0.1.0.json"
CHANGES = ["packages/blazex_core/lib/blazex/component/" + name + ".ex" for name in ["local_view", "root_guardian", "root_process", "root_schedule", "result"]] + ["packages/blazex_ui_tree/lib/blazex/ui_tree/" + name + ".ex" for name in ["root_evaluator", "nested_candidates"]]
INPUTS = [AREA + "scheduling-completion-v0.1.0.json", AREA + "scheduling-gates-v0.1.0.json", PLAN + "scheduling-contract.md", PLAN + "root-supervision-compatibility.md"] + CHANGES + ["packages/blazex_core/lib/blazex/component/" + name + ".ex" for name in ["root_port", "input", "contract", "schema"]] + ["packages/blazex_effects/lib/blazex/effects/" + name + ".ex" for name in ["effect", "capability", "negotiation", "provider", "result", "resource", "tracker"]] + ["docs/research/20-notes/architecture-decisions/adr-0005-server-adapter-and-trust-boundary.md", "docs/research/20-notes/architecture-decisions/adr-0003-host-neutral-effects-capabilities-and-resources.md", "docs/research/assets/quality-acceptance/blazex-acceptance-registry-v0.1.0.json"]


def record(root=REPO_ROOT):
    return {"schema_version": "1.0.0", "phase": 8, "base": BASE,
            "authorization": "Owner requested next BH-05 phase after Phase 7 completion; Phase 8 only.",
            "branch": "codex/bh05-phase8-actions", "sections": ["8.1", "8.2", "8.3", "8.4"],
            "delivery": ["verified section commits", "single PR", "merge", "checkout main", "sync origin", "delete feature branch"],
            "contract": "0.1.0-bh05-actions", "schema_contract": "0.2.0-bh05-schema-candidate",
            "input_hashes": {p: hashlib.sha256(subprocess.check_output(["git", "show", BASE + ":" + p], cwd=root)).hexdigest() for p in INPUTS},
            "reviewed_successor_changes": {p: "Explicit action-enabled successor; Phase 6/7 defaults and normalized traces retained." for p in CHANGES},
            "limits": {"total_work": 256, "pending_requests": 128, "leases": 512, "candidate_actions": 16, "counter": 9007199254740991},
            "excluded": ["concrete Web API providers", "Phoenix/Plug transport and server authorization", "uploads", "navigation", "persistence", "arbitrary tasks", "LiveView", "LocalLiveView", "support claims"],
            "support_state": "unsupported"}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    content = json.dumps(record(), indent=2) + "\n"
    target = REPO_ROOT / TARGET
    if args.check:
        if not target.exists() or target.read_text() != content:
            raise SystemExit("action authority drift")
    else:
        with target.open("x") as output:
            output.write(content)
    print("BH-05 action authority: PASS")
