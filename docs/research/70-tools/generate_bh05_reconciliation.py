"""Generate the deterministic BH-05 Phase 12 reconciliation and review ledger."""
import argparse
import hashlib
import json
import sys
from pathlib import Path

from research_paths import REPO_ROOT

OUTPUT = "docs/research/assets/bh-05-baseline/acceptance-reconciliation-v0.1.0.json"
INPUTS = [
    "docs/research/assets/bh-05-baseline/acceptance-authorization-v0.1.0.json",
    "integration/bh-05/acceptance-counts-v0.1.0.json",
    "integration/bh-05/acceptance-counts-raw-v0.1.0.json",
    "integration/bh-05/acceptance-cleanup-v0.1.0.json",
    "integration/bh-05/acceptance-cleanup-raw-v0.1.0.json",
    "docs/research/60-planning/01-browser-host/bh-05-component-programming-model-and-lifecycle/acceptance-contract.md",
]


def digest(path):
    return hashlib.sha256((REPO_ROOT / path).read_bytes()).hexdigest()


def build():
    counts = json.loads((REPO_ROOT / INPUTS[1]).read_text())
    cleanup = json.loads((REPO_ROOT / INPUTS[3]).read_text())
    outcomes = []
    for acceptance_id, budget_id in [
        ("BX-ACC-BUDGET-BX-BUD-RELIABILITY-EVENT-BACKLOG-COUNT", "BX-BUD-RELIABILITY-EVENT-BACKLOG-COUNT"),
        ("BX-ACC-BUDGET-BX-BUD-RELIABILITY-PENDING-EFFECTS-COUNT", "BX-BUD-RELIABILITY-PENDING-EFFECTS-COUNT"),
        ("BX-ACC-BUDGET-BX-BUD-RELIABILITY-RESOURCE-COUNT", "BX-BUD-RELIABILITY-RESOURCE-COUNT"),
        ("BX-ACC-BUDGET-BX-BUD-RELIABILITY-RESTART-INTENSITY", "BX-BUD-RELIABILITY-RESTART-INTENSITY"),
    ]:
        outcomes.append({"acceptance_id": acceptance_id, "result": counts["budgets"][budget_id]["result"],
                         "evidence": INPUTS[1], "detail": counts["budgets"][budget_id]})
    for acceptance_id, budget_id in [
        ("BX-ACC-BUDGET-BX-BUD-RESOURCE-CLEANUP-MS", "BX-BUD-RESOURCE-CLEANUP-MS"),
        ("BX-ACC-BUDGET-BX-BUD-RESOURCE-PROCESS-GROWTH-COUNT", "BX-BUD-RESOURCE-PROCESS-GROWTH-COUNT"),
    ]:
        outcomes.append({"acceptance_id": acceptance_id, "result": cleanup["budgets"][budget_id]["result"],
                         "evidence": INPUTS[3], "detail": cleanup["budgets"][budget_id]})
    for acceptance_id in ["BX-ACC-FAILURE-BX-FAIL-COMPONENT", "BX-ACC-FAILURE-BX-FAIL-RESOURCE-CLEANUP"]:
        outcomes.append({"acceptance_id": acceptance_id,
                         "result": cleanup["failure_gates"][acceptance_id]["result"],
                         "evidence": INPUTS[3], "detail": cleanup["failure_gates"][acceptance_id]})
    outcomes.append({"acceptance_id": "BX-ACC-ROADMAP-BH-05", "result": "revise",
                     "evidence": INPUTS[3], "detail": {"active_blocker": "BH05-ACTIVE-FIREFOX-CLEANUP-DIVERGENCE"}})

    contracts = [
        "facade and authoring", "props and slots", "composition", "nested state",
        "process roots", "scheduling", "effects resources and commands",
        "context and registry", "failure and disposal", "cross-runtime conformance",
    ]
    reviews = [
        ("architecture", "revise", "The host-neutral ownership model holds, but active runtime terminal-state parity does not."),
        ("implementation", "revise", "Terminal guardian growth is fixed and tested; Firefox bounded cleanup remains unresolved."),
        ("elixir-language", "passed", "Public handles remain portable; terminal release validates handle, state and idempotence."),
        ("runtime", "blocked", "Chrome resolves 513 requests while Firefox leaves 452 unresolved under the same bound."),
        ("security", "passed", "No server trust, raw exception, provider object or new dependency crosses the public boundary."),
        ("accessibility", "bounded", "Semantic fallback and focus gates pass; manual assistive-technology qualification remains BH-22."),
        ("reliability", "blocked", "Six quantitative budgets pass, but an active runtime retains an unresolved cleanup inventory."),
        ("packaging", "bounded", "The fixed AtomVM fixture is reproducible evidence, not a general BH-06 build system."),
        ("provenance", "passed", "Frozen inputs, raw failures, hashes, commands and unsupported/deferred labels remain visible."),
    ]
    return {
        "schema_version": "1.0.0", "phase": 12, "decision": "revise",
        "support_state": "unsupported", "input_hashes": {path: digest(path) for path in INPUTS},
        "acceptance_outcomes": outcomes,
        "contract_reconciliation": [{"area": area, "state": "implemented", "evidence": "Phase 1-11 source-bound completion records"} for area in contracts],
        "findings": [
            {"id": "BH05-FIND-TERMINAL-GUARDIAN-GROWTH", "severity": "high", "state": "fixed",
             "owner": "BH-05", "mitigation": "LocalView.release_terminal/2 plus ten zero-growth samples",
             "review_trigger": "terminal lifecycle API change", "due": "Phase 12", "blocks_acceptance": False, "blocks_bh06": False},
            {"id": "BH05-ACTIVE-FIREFOX-CLEANUP-DIVERGENCE", "severity": "blocking", "state": "open",
             "owner": "BH-05", "mitigation": "redesign or otherwise prove bounded complete cleanup without changing the frozen threshold",
             "review_trigger": "fresh Chrome/Firefox exact terminal inventory", "due": "BH-05 re-entry", "blocks_acceptance": True, "blocks_bh06": True},
            {"id": "BH05-COND-FIXED-BROWSER-FIXTURE", "severity": "bounded", "state": "open",
             "owner": "BH-06", "mitigation": "prove general build and dynamic dependency reachability",
             "review_trigger": "BH-06 authorization", "due": "BH-06", "blocks_acceptance": False, "blocks_bh06": False},
            {"id": "BH05-COND-PLATFORM-QUALIFICATION", "severity": "deferred", "state": "open",
             "owner": "BH-22", "mitigation": "qualify deferred operating systems, WebKit, devices and manual AT",
             "review_trigger": "BH-22 authorization", "due": "BH-22", "blocks_acceptance": False, "blocks_bh06": False},
        ],
        "reviews": [{"lens": lens, "verdict": verdict, "finding": finding,
                     "method": "separate evidence-first pass over frozen inputs; not an independent human attestation"}
                    for lens, verdict, finding in reviews],
        "disagreements": [{
            "question": "Is the Firefox result only diagnostic timing variation?",
            "positions": ["wall-clock duration is diagnostic", "unresolved terminal inventory is semantic state"],
            "resolution": "The terminal-state mismatch is an active semantic blocker under the frozen decision rule.",
        }],
        "deferred_bh22": ["Windows", "macOS", "Safari/WebKit product", "Android/iOS devices", "manual assistive-technology pairings"],
        "separately_deferred": ["LiveView", "LocalLiveView"], "bh06_eligible": False, "bh06_authorized": False,
    }


def render():
    return json.dumps(build(), indent=2) + "\n"


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    target = REPO_ROOT / OUTPUT
    value = render()
    if args.check:
        if not target.exists() or target.read_text() != value:
            print("BH-05 reconciliation drift", file=sys.stderr)
            sys.exit(1)
        print("BH-05 reconciliation: REVISE (exact)")
    else:
        target.write_text(value)
        print("BH-05 reconciliation generated")
