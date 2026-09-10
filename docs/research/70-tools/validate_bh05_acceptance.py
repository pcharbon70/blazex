"""Validate the source-bound BH-05 Phase 12 revise decision and completion."""
import hashlib
import json
import subprocess
import sys
from pathlib import Path

from research_paths import REPO_ROOT
from validate_bh05_acceptance_cleanup import validate as validate_cleanup
from validate_bh05_acceptance_counts import validate as validate_counts
from validate_bh05_reconciliation import validate as validate_reconciliation
from validate_bh05_release import validate as validate_release

AREA = "docs/research/assets/bh-05-baseline/"
GATE_FILE = AREA + "acceptance-gates-v0.1.0.json"
COMPLETION_FILE = AREA + "acceptance-completion-v0.1.0.json"
GATES = [
    "packages", "browser-project", "javascript", "count-evidence", "cleanup-evidence",
    "browser-cleanup-repeat", "phase11-replay", "historical-sweep", "release-reconciliation",
    "archive", "json", "clean-repeat", "hygiene",
]


def sha(data):
    return hashlib.sha256(data).hexdigest()


def files(root=REPO_ROOT):
    output = subprocess.check_output(
        ["git", "ls-files", "--cached", "--others", "--exclude-standard"], cwd=root, text=True
    ).splitlines()
    paths = []
    for path in output:
        if path.endswith(".md") or path in [GATE_FILE, COMPLETION_FILE]:
            continue
        if path.startswith(("packages/", "js/", "integration/", "profiles/", "experiments/")):
            paths.append(path)
        elif path.startswith("docs/research/70-tools/") and "bh05" in Path(path).name:
            paths.append(path)
        elif path.startswith(AREA):
            paths.append(path)
    return sorted(set(paths))


def sources(root=REPO_ROOT):
    root = Path(root)
    return {path: sha((root / path).read_bytes()) for path in files(root)}


def gate_errors(record, current):
    errors = []
    rows = record.get("results", [])
    if record.get("phase") != 12 or record.get("decision") != "revise":
        errors.append("wrong phase/decision")
    if record.get("source_hashes") != current or record.get("final_source_hashes") != current:
        errors.append("stale source closure")
    if [row.get("name") for row in rows] != GATES:
        errors.append("gate order/cardinality drift")
    if any(row.get("exit_code") != 0 or row.get("error") for row in rows):
        errors.append("incomplete or failed meta-gate")
    if record.get("active_product_blocker") != "BH05-ACTIVE-FIREFOX-CLEANUP-DIVERGENCE":
        errors.append("active blocker hidden")
    return errors


def completion(root=REPO_ROOT):
    root = Path(root)
    paths = [
        AREA + "acceptance-reconciliation-v0.1.0.json",
        AREA + "bh-05-release-index-v0.1.0.json",
        AREA + "bh-05-acceptance-overlay-v0.1.0.json",
        AREA + "bh-06-entry-decision-v0.1.0.json",
        "integration/bh-05/acceptance-counts-v0.1.0.json",
        "integration/bh-05/acceptance-cleanup-v0.1.0.json",
        GATE_FILE,
    ]
    return {
        "schema_version": "1.0.0", "phase": 12, "decision": "revise",
        "milestone_state": "revision-required", "milestone_accepted": False,
        "active_blocker": "BH05-ACTIVE-FIREFOX-CLEANUP-DIVERGENCE",
        "bh06_eligible": False, "bh06_authorized": False, "support_state": "unsupported",
        "artifact_hashes": {path: sha((root / path).read_bytes()) for path in paths},
    }


def validate(root=REPO_ROOT, final=False):
    root = Path(root)
    errors = validate_counts(root) + validate_cleanup(root)
    if root == REPO_ROOT:
        errors += validate_reconciliation() + validate_release()
    try:
        overlay = json.loads((root / (AREA + "bh-05-acceptance-overlay-v0.1.0.json")).read_text())
        entry = json.loads((root / (AREA + "bh-06-entry-decision-v0.1.0.json")).read_text())
        if overlay.get("decision") != "revise" or not overlay.get("active_blockers"):
            errors.append("acceptance overlay lost revise blocker")
        if entry.get("state") != "ineligible" or entry.get("authorized") is not False:
            errors.append("BH-06 authority drift")
        if final:
            gates = json.loads((root / GATE_FILE).read_text())
            errors += gate_errors(gates, sources(root))
            if json.loads((root / COMPLETION_FILE).read_text()) != completion(root):
                errors.append("completion drift")
    except (OSError, ValueError, KeyError, TypeError):
        errors.append("missing/malformed final acceptance evidence")
    return errors


if __name__ == "__main__":
    final = "--final" in sys.argv
    problems = validate(final=final)
    print("\n".join(problems) if problems else "BH-05 Phase 12: REVISE (validated)")
    sys.exit(bool(problems))
