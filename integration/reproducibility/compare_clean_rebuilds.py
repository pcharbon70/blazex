#!/usr/bin/env python3
"""Compare two BH-01 clean execution records without hiding declared variance."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker


HERE = Path(__file__).resolve().parent


def load(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def compare(first: dict[str, Any], second: dict[str, Any]) -> tuple[dict[str, Any], list[str]]:
    errors: list[str] = []
    if first.get("status") != "passed" or second.get("status") != "passed":
        errors.append("both clean rebuilds must pass")
    if first.get("source_revision") != second.get("source_revision"):
        errors.append("clean rebuild source revisions differ")
    first_tools = {(item["name"], item["identity"], item["sha256"]) for item in first.get("tools", [])}
    second_tools = {(item["name"], item["identity"], item["sha256"]) for item in second.get("tools", [])}
    if first_tools != second_tools:
        errors.append("clean rebuild tool identities differ")
    artifact_fields = ("runtime_manifest_sha256", "browser_bundle_manifest_sha256", "profile_manifest_sha256")
    artifact_matches = sum(first.get("artifacts", {}).get(key) == second.get("artifacts", {}).get(key) for key in artifact_fields)
    if artifact_matches != len(artifact_fields):
        errors.append("clean rebuild artifact identities differ")
    first_scenarios = {(item["browser"], item["scenario"]): item for item in first.get("browser_scenarios", [])}
    second_scenarios = {(item["browser"], item["scenario"]): item for item in second.get("browser_scenarios", [])}
    if set(first_scenarios) != set(second_scenarios):
        errors.append("clean rebuild browser scenario coverage differs")
    scenario_matches = sum(first_scenarios[key]["semantic_sha256"] == second_scenarios[key]["semantic_sha256"] for key in set(first_scenarios) & set(second_scenarios))
    if scenario_matches != len(first_scenarios):
        errors.append("clean rebuild semantic browser outcomes differ")
    first_reports = {item["id"]: item["sha256"] for item in first.get("reports", []) if item.get("matches_canonical")}
    second_reports = {item["id"]: item["sha256"] for item in second.get("reports", []) if item.get("matches_canonical")}
    if first_reports != second_reports or len(first_reports) != 7:
        errors.append("clean rebuild canonical reports differ")
    if first.get("manual_actions") or second.get("manual_actions") or first.get("failures") or second.get("failures"):
        errors.append("clean rebuild contains manual action or failure")
    report = {
        "schema_version": "1.0.0",
        "report_id": "BX-BH01-PHASE10-CLEAN-REBUILD-COMPARISON-0.1",
        "status": "pass-with-declared-host-variance" if not errors else "failed",
        "source_revision": first.get("source_revision", ""),
        "environment_records": [first.get("record_id"), second.get("record_id")],
        "exact_artifact_matches": artifact_matches,
        "semantic_scenario_matches": scenario_matches,
        "canonical_report_matches": len(set(first_reports) & set(second_reports)),
        "declared_variance": ["captured timestamps", "command and acquisition durations", "raw browser timing samples and raw-record hashes", "ephemeral ports and clean source/cache paths"],
        "unexplained_variance": errors,
        "manual_intervention": [],
        "physical_host_scope": "same-linux-host-two-clean-execution-contexts-not-two-physical-machines",
        "support_status": "unsupported",
    }
    return report, errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--first", type=Path, required=True)
    parser.add_argument("--second", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    schema = load(HERE / "clean-rebuild.schema.json")
    records = [load(args.first), load(args.second)]
    schema_errors = [error.message for record in records for error in Draft202012Validator(schema, format_checker=FormatChecker()).iter_errors(record)]
    report, errors = compare(*records)
    errors = schema_errors + errors
    if errors:
        report["status"] = "failed"
        report["unexplained_variance"] = errors
    args.output.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        return 1
    print(f"BH-01 Phase 10 clean rebuild comparison: PASS ({report['exact_artifact_matches']} exact artifacts; {report['semantic_scenario_matches']} semantic scenarios)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
