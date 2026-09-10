"""Validate Phase 12 cleanup, process-growth, and failure-gate evidence."""
import argparse
import hashlib
import json
import sys
from pathlib import Path

from research_paths import REPO_ROOT
from run_bh05_acceptance_cleanup import RAW, REPORT, cleanup_valid, growth_valid


def validate(root=REPO_ROOT):
    root, errors = Path(root), []
    try:
        raw_bytes = (root / RAW).read_bytes()
        raw = json.loads(raw_bytes)
        report = json.loads((root / REPORT).read_text())
        if report.get("raw_sha256") != hashlib.sha256(raw_bytes).hexdigest():
            errors.append("cleanup raw/report hash drift")
        if report.get("decision") != "revise" or report.get("result") != "failed":
            errors.append("active Firefox failure must retain revise decision")
        if report.get("support_state") != "unsupported":
            errors.append("support-state drift")
        if not cleanup_valid(raw["erts"]["cleanup"]):
            errors.append("ERTS cleanup budget failed")
        if not growth_valid(raw["erts"]["process_growth"]):
            errors.append("ERTS process-growth budget failed")
        if any(value.get("result") != "passed" for value in report["failure_gates"].values()):
            errors.append("failure gate failed")
        browsers = raw["browser"]["results"]
        if [row.get("browser") for row in browsers] != ["chrome", "firefox"]:
            errors.append("browser matrix drift")
        if browsers[0]["cleanup"][0]["unresolved"] != 0 or browsers[1]["cleanup"][0]["unresolved"] <= 0:
            errors.append("retained Firefox divergence drift")
        if raw["browser"].get("comparison", {}).get("state") != "fail":
            errors.append("browser divergence was hidden")
        if len(raw.get("retained_failed_trials", [])) < 3:
            errors.append("failed cleanup trials were dropped")
        if not raw.get("active_blockers") or not report.get("active_blockers"):
            errors.append("active blocker was hidden")
        budgets = report.get("budgets", {})
        if budgets.get("BX-BUD-RESOURCE-CLEANUP-MS", {}).get("threshold") != 1000:
            errors.append("cleanup threshold drift")
        if budgets.get("BX-BUD-RESOURCE-PROCESS-GROWTH-COUNT", {}).get("threshold") != 0:
            errors.append("process-growth threshold drift")
    except (OSError, ValueError, KeyError, TypeError, IndexError) as error:
        errors.append("missing/malformed cleanup evidence: " + type(error).__name__)
    return errors


def validate_browser_observation(path):
    errors = []
    try:
        value = json.loads(Path(path).read_text())
        rows = value.get("results", [])
        if [row.get("browser") for row in rows] != ["chrome", "firefox"]:
            errors.append("repeat browser matrix drift")
        elif any(row.get("result") != "passed" for row in rows):
            errors.append("repeat browser harness failed")
        elif rows[0]["cleanup"][0]["unresolved"] != 0 or rows[1]["cleanup"][0]["unresolved"] <= 0:
            errors.append("repeat did not reproduce the active Firefox divergence")
        elif any(row["process_growth"][0]["unexpected_growth"] != 0 for row in rows):
            errors.append("repeat process growth regressed")
        if value.get("comparison", {}).get("state") != "fail":
            errors.append("repeat Firefox divergence was hidden")
    except (OSError, ValueError, KeyError, TypeError, IndexError):
        errors.append("missing/malformed browser repeat")
    return errors


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--browser-observation", type=Path)
    args = parser.parse_args()
    problems = validate_browser_observation(args.browser_observation) if args.browser_observation else validate()
    success = "BH-05 browser cleanup repeat: REVISE reproduced" if args.browser_observation else "BH-05 Phase 12 cleanup evidence: REVISE (validated)"
    print("\n".join(problems) if problems else success)
    sys.exit(bool(problems))
