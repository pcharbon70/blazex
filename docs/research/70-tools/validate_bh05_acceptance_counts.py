"""Validate Phase 12 count-budget raw evidence and report bindings."""
import hashlib
import json
import sys
from pathlib import Path

from research_paths import REPO_ROOT
from run_bh05_acceptance_counts import RAW, REPORT, valid


def validate(root=REPO_ROOT):
    root = Path(root)
    errors = []
    try:
        raw_bytes = (root / RAW).read_bytes()
        raw = json.loads(raw_bytes)
        report = json.loads((root / REPORT).read_text())
        rows = raw["erts"]["samples"]
        browsers = raw["browser"]["results"]
        if report.get("raw_sha256") != hashlib.sha256(raw_bytes).hexdigest():
            errors.append("count raw/report hash drift")
        if report.get("result") != "passed" or report.get("support_state") != "unsupported":
            errors.append("count report state drift")
        if len(rows) != 20 or not valid(rows):
            errors.append("ERTS count samples failed")
        if [row.get("browser") for row in browsers] != ["chrome", "firefox"]:
            errors.append("browser count matrix drift")
        elif any(row.get("result") != "passed" or len(row.get("samples", [])) != 1 for row in browsers):
            errors.append("browser count observation failed")
        elif json.dumps(browsers[0]["samples"], sort_keys=True) != json.dumps(browsers[1]["samples"], sort_keys=True):
            errors.append("browser count divergence")
        if len(raw.get("retained_failed_trials", [])) != 3:
            errors.append("failed count trials were dropped")
        if any(all(row.get("result") == "passed" for row in trial.get("results", [])) for trial in raw.get("retained_failed_trials", [])):
            errors.append("retained count trial is not a failure")
        expected = {key: value["threshold"] for key, value in report.get("budgets", {}).items()}
        if expected != {
            "BX-BUD-RELIABILITY-EVENT-BACKLOG-COUNT": 256,
            "BX-BUD-RELIABILITY-PENDING-EFFECTS-COUNT": 128,
            "BX-BUD-RELIABILITY-RESOURCE-COUNT": 512,
            "BX-BUD-RELIABILITY-RESTART-INTENSITY": 3,
        }:
            errors.append("count threshold drift")
    except (OSError, ValueError, KeyError, TypeError) as error:
        errors.append("missing/malformed count evidence: " + type(error).__name__)
    return errors


if __name__ == "__main__":
    errors = validate()
    print("\n".join(errors) if errors else "BH-05 Phase 12 count evidence: PASS")
    sys.exit(bool(errors))
