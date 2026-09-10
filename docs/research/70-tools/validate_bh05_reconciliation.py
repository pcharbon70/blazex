"""Validate the BH-05 Phase 12 acceptance reconciliation."""
import json
import subprocess
import sys

from research_paths import REPO_ROOT
from generate_bh05_reconciliation import OUTPUT


def validate():
    errors = []
    result = subprocess.run([sys.executable, __file__.replace("validate_bh05_reconciliation.py", "generate_bh05_reconciliation.py"), "--check"],
                            cwd=REPO_ROOT, capture_output=True, text=True)
    if result.returncode:
        errors.append("generated reconciliation drift")
    try:
        record = json.loads((REPO_ROOT / OUTPUT).read_text())
        if record.get("decision") != "revise" or record.get("bh06_eligible") is not False:
            errors.append("decision/eligibility drift")
        outcomes = record.get("acceptance_outcomes", [])
        if len(outcomes) != 9 or len({row.get("acceptance_id") for row in outcomes}) != 9:
            errors.append("nine-condition reconciliation incomplete")
        reviews = record.get("reviews", [])
        if len(reviews) != 9 or len({row.get("lens") for row in reviews}) != 9:
            errors.append("review-lens coverage incomplete")
        blocker = [row for row in record.get("findings", []) if row.get("id") == "BH05-ACTIVE-FIREFOX-CLEANUP-DIVERGENCE"]
        if len(blocker) != 1 or not blocker[0].get("blocks_acceptance") or not blocker[0].get("blocks_bh06"):
            errors.append("Firefox blocker hidden")
        if not record.get("disagreements") or record.get("support_state") != "unsupported":
            errors.append("review disagreement/support truth missing")
    except (OSError, ValueError, KeyError, TypeError):
        errors.append("missing/malformed reconciliation")
    return errors


if __name__ == "__main__":
    problems = validate()
    print("\n".join(problems) if problems else "BH-05 reconciliation: REVISE (validated)")
    sys.exit(bool(problems))
