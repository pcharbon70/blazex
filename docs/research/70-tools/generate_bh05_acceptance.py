"""Generate the bounded BH-05 Phase 12 acceptance authorization."""
import argparse
import hashlib
import json
import subprocess

from research_paths import REPO_ROOT

BASE = "23446e711d5791eb6eea0b23dd6fdcde3bebc62e"
AREA = "docs/research/assets/bh-05-baseline/"
PLAN = "docs/research/60-planning/01-browser-host/bh-05-component-programming-model-and-lifecycle/"
TARGET = AREA + "acceptance-authorization-v0.1.0.json"

PHASES = [
    ("phase-01", "phase-01"),
    ("authoring", "authoring"),
    ("schema", "schema"),
    ("composition", "composition"),
    ("nested", "nested"),
    ("root", "root"),
    ("scheduling", "scheduling"),
    ("action", "action"),
    ("scope", "scope"),
    ("recovery", "recovery"),
    ("conformance", "conformance"),
]
INPUTS = [AREA + name + "-completion-v0.1.0.json" for name, _ in PHASES]
INPUTS += [AREA + name + "-gates-v0.1.0.json" for name, _ in PHASES]
INPUTS += [
    "docs/research/assets/quality-acceptance/blazex-acceptance-registry-v0.1.0.json",
    "docs/research/assets/quality-acceptance/blazex-quality-contract-v0.1.0.json",
    "docs/research/20-notes/browser-host-implementation-milestones.md",
    "docs/research/20-notes/blazex-acceptance-traceability-and-evidence-policy.md",
    "docs/research/20-notes/blazex-quality-budget-and-measurement-policy.md",
    "docs/research/20-notes/architecture-decisions/adr-0001-host-neutral-semantic-component-kernel.md",
    "docs/research/10-maps/blazex-repository-ownership-and-dependency-map.md",
    "docs/research/60-planning/development-environment-and-deferred-qualification-policy.md",
    "docs/research/60-planning/liveview-integration-deferral.md",
    "integration/bh-05/conformance-corpus-v0.1.0.json",
    "integration/bh-05/local-conformance-v0.1.0.json",
    "integration/bh-05/browser-conformance-v0.1.0.json",
]

BUDGETS = {
    "BX-BUD-RELIABILITY-EVENT-BACKLOG-COUNT": ["maximum", "at-most", 256, 20],
    "BX-BUD-RELIABILITY-PENDING-EFFECTS-COUNT": ["maximum", "at-most", 128, 20],
    "BX-BUD-RELIABILITY-RESOURCE-COUNT": ["maximum", "at-most", 512, 20],
    "BX-BUD-RELIABILITY-RESTART-INTENSITY": ["maximum", "at-most", 3, 20],
    "BX-BUD-RESOURCE-CLEANUP-MS": ["p95-nearest-rank", "at-most", 1000, 100],
    "BX-BUD-RESOURCE-PROCESS-GROWTH-COUNT": ["maximum", "exactly", 0, 10],
}


def sha(data):
    return hashlib.sha256(data).hexdigest()


def record(root=REPO_ROOT):
    return {
        "schema_version": "1.0.0",
        "phase": 12,
        "base": BASE,
        "authorization": "Owner requested next BH-05 phase after merged Phase 11 PR 62; Phase 12 only.",
        "branch": "codex/bh05-phase12-acceptance",
        "sections": ["12.1", "12.2", "12.3", "12.4", "12.5", "12.6"],
        "delivery": ["verified section commits", "single PR", "merge", "checkout main", "sync origin", "delete feature branch"],
        "input_hashes": {
            path: sha(subprocess.check_output(["git", "show", BASE + ":" + path], cwd=root))
            for path in INPUTS
        },
        "acceptance_ids": [
            "BX-ACC-BUDGET-" + budget for budget in BUDGETS
        ] + [
            "BX-ACC-FAILURE-BX-FAIL-COMPONENT",
            "BX-ACC-FAILURE-BX-FAIL-RESOURCE-CLEANUP",
            "BX-ACC-ROADMAP-BH-05",
        ],
        "budgets": {
            key: {"statistic": row[0], "direction": row[1], "threshold": row[2], "minimum_samples": row[3]}
            for key, row in BUDGETS.items()
        },
        "active": ["local ERTS/headless", "Linux Chrome AtomVM/DOM", "Linux Firefox development AtomVM/DOM", "GTK portability"],
        "measurement": {
            "clock": "monotonic milliseconds",
            "warmup": "one unmeasured fixture cycle before every measured series",
            "negative_samples": "retain every failure, timeout, leak, divergence, and instrumentation error",
            "process_baseline_exclusions": ["measurement runner", "LocalView.Supervisor", "browser shared AtomVM/Popcorn service"],
        },
        "outcomes": ["accept", "accept-with-bounded-conditions", "revise", "block"],
        "excluded": ["BH-06 implementation", "threshold reduction", "sample deletion", "hidden waiver", "Plug profile fabrication", "public or support promotion", "deferred environment substitution", "LiveView", "LocalLiveView"],
        "deferred_bh22": ["Windows", "macOS", "Safari/WebKit product", "Android/iOS devices", "manual assistive-technology pairings"],
        "support_state": "unsupported",
        "bh06_authorized": False,
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    content = json.dumps(record(), indent=2) + "\n"
    target = REPO_ROOT / TARGET
    if args.check:
        if not target.exists() or target.read_text() != content:
            raise SystemExit("BH-05 acceptance authority drift")
    else:
        with target.open("x") as stream:
            stream.write(content)
    print("BH-05 Phase 12 acceptance authority: PASS")
