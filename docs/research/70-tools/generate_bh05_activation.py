"""Deterministic BH-05 Phase 1 authority and inherited-entry records."""
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
from research_paths import REPO_ROOT

BASE = "506c254ddd4a14dd8d1d4cbdba8fcf9556bd15cb"
AREA = "docs/research/assets/bh-05-baseline/"
PLAN = "docs/research/60-planning/01-browser-host/bh-05-component-programming-model-and-lifecycle/"
DECISION = "docs/research/assets/bh-04-correction/decision.json"
REGISTRY = "docs/research/assets/quality-acceptance/blazex-acceptance-registry-v0.1.0.json"
PACKAGES = ["blazex_core", "blazex_effects", "blazex_ui_tree", "blazex_test"]
GROUPS = ["facade", "schemas", "composition", "state", "roots", "scheduling", "effects", "context", "registry", "failure", "runtime", "measurement", "review", "acceptance"]
PHASES = {"BX-ACC-ROADMAP-BH-05": (2, 12), "BX-ACC-BUDGET-BX-BUD-RELIABILITY-EVENT-BACKLOG-COUNT": (7, 12),
          "BX-ACC-BUDGET-BX-BUD-RELIABILITY-PENDING-EFFECTS-COUNT": (8, 12), "BX-ACC-BUDGET-BX-BUD-RELIABILITY-RESOURCE-COUNT": (8, 12),
          "BX-ACC-BUDGET-BX-BUD-RELIABILITY-RESTART-INTENSITY": (10, 12), "BX-ACC-BUDGET-BX-BUD-RESOURCE-CLEANUP-MS": (10, 12),
          "BX-ACC-BUDGET-BX-BUD-RESOURCE-PROCESS-GROWTH-COUNT": (6, 12), "BX-ACC-FAILURE-BX-FAIL-COMPONENT": (10, 12), "BX-ACC-FAILURE-BX-FAIL-RESOURCE-CLEANUP": (10, 12)}


def blob(root, path):
    return subprocess.check_output(["git", "show", BASE + ":" + path], cwd=root)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def plans(root):
    return {p.relative_to(root).as_posix(): sha(p.read_text().replace("[x]", "[ ]").encode()) for p in sorted((root / PLAN).glob("phase-*.md")) if re.match(r"phase-\d\d-", p.name)}


def records(root=REPO_ROOT):
    root = Path(root)
    decision = json.loads(blob(root, DECISION))
    if decision["decision"] != "accepted-development-only" or not decision["bh05_eligible"]:
        raise ValueError("BH-04 handoff not accepted")
    inputs = [DECISION, "docs/research/assets/bh-04-baseline/blazex-bh-04-entry-ledger-v0.1.0.json",
              "docs/research/assets/bh-04-baseline/blazex-bh-04-phase-10-completion-v0.1.0.json",
              "docs/research/assets/bh-04-baseline/blazex-bh-04-phase-10-release-index-v0.1.0.json",
              "docs/research/assets/bh-02-baseline/blazex-bh-02-contract-baseline-v0.1.0.json", REGISTRY,
              "docs/research/assets/quality-acceptance/blazex-quality-contract-v0.1.0.json",
              "docs/research/20-notes/browser-host-implementation-milestones.md",
              "docs/research/60-planning/development-environment-and-deferred-qualification-policy.md",
              "docs/research/60-planning/liveview-integration-deferral.md"]
    inputs += [p.relative_to(root).as_posix() for p in sorted((root / "docs/research/20-notes/architecture-decisions").glob("adr-000[1-5]-*.md"))]
    plan_hashes = plans(root)
    if len(plan_hashes) != 12:
        raise ValueError("twelve phase plans required")
    authority = {"schema_version": "1.0.0", "milestone": "BH-05", "phase": 1, "base_revision": BASE,
                 "branch": "codex/bh05-phase1-activation", "authorization": "Owner requested the next BH-05 phase with section commits, one PR, merge, synchronized main and feature-branch deletion; approved prerequisite BH-04 publication.",
                 "authorized_work": ["reconciliation", "ownership", "empty-evidence-activation", "validation", "completion-evidence"],
                 "phase2_authorized": False, "behavior_implemented": False, "public_api_stable": False, "support_state": "unsupported", "bh06_eligible": False,
                 "delivery": {"sections": ["1.1", "1.2", "1.3", "1.4"], "pr_count": 1, "merge": "merge-commit", "cleanup_order": ["merge-pr", "checkout-main", "sync-origin", "delete-feature-branch"]},
                 "source_bindings": {p: sha(blob(root, p)) for p in inputs}, "phase_plan_hashes": plan_hashes,
                 "plan_hash_normalization": "checkbox-only [x] to [ ]; no other content normalization",
                 "planning_origin": "Restored owner-authored BH-05 revisions; demo and root README excluded"}
    registry = json.loads(blob(root, REGISTRY))
    selected = [r for r in registry["acceptance_conditions"] if r["id"] in PHASES]
    if {r["id"] for r in selected} != set(PHASES):
        raise ValueError("canonical nine-condition set missing")
    ledger = {"schema_version": "1.0.0", "milestone": "BH-05", "phase": 1, "entry": "accepted-governance-only", "support_state": "unsupported", "bh06_eligible": False,
              "predecessor": {"revision": BASE, "decision_path": DECISION, "decision_sha256": sha(blob(root, DECISION)),
                              "conditions": decision["conditions"], "inherited_obligations": decision["inherited_obligations"], "deferred": decision["deferred"], "open_blockers": decision["open_blockers"],
                              "variance_obligation": json.loads(blob(root, "docs/research/assets/bh-04-correction/review-status.json"))["variance"]},
              "historical_release": "Original Phase 10 completion/release records remain revise; the corrective decision is the accepted successor, not a rewritten original release.",
              "restrictions": ["no Phase 2 facade or callbacks", "no stable API or support promotion", "no BH-06 implementation", "no private runtime/renderer imports by application code", "no production Wasm or ERTS/AtomVM parity claim", "LiveView/LocalLiveView deferred by separate scope decision"],
              "outcomes": {"entry": "all inherited bindings valid", "stop": "authority, ownership, identity or evidence violation", "revise": "active failure requires a corrective decision", "defer": "owned unavailable qualification only; no pass credit", "acceptance": "Phase 1 governance only; Phase 2 eligible but unauthorized after final gate"},
              "acceptance": [{"canonical": row, "first_phase": PHASES[row["id"]][0], "closure_phase": PHASES[row["id"]][1], "owner": row["evidence_owner"], "suite": "integration/bh-05", "stop_rule": "missing, divergent, unbounded, unauthorized or fabricated evidence blocks closure", "state": "planned", "evidence": []} for row in selected]}
    return {"authorization-v0.1.0.json": authority, "entry-ledger-v0.1.0.json": ledger}


if __name__ == "__main__":
    for name, data in records().items():
        target = REPO_ROOT / AREA / name
        output = json.dumps(data, indent=2) + "\n"
        if "--write" in sys.argv:
            target.parent.mkdir(parents=True, exist_ok=True); target.write_text(output)
        elif target.read_text() != output:
            raise SystemExit("stale activation record: " + name)
    print("BH-05 authority and nine-condition entry ledger verified; no behavior or support credit.")
