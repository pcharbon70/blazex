#!/usr/bin/env python3
"""Compare representative Phase 9 browser reruns with primary distributions."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker

from phase9_metrics import load_json, sha256, summarize_measurements


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
EXCLUDED = ["BX-BH01-METRIC-CLOCK-RESOLUTION-MS", "BX-BH01-METRIC-RESOURCE-JS-HEAP-BYTES"]


def validate(path: Path) -> dict[str, Any]:
    value = load_json(path)
    Draft202012Validator(load_json(HERE / "measurement-run.schema.json"), format_checker=FormatChecker()).validate(value)
    return value


def ref(role: str, path: Path, value: dict[str, Any]) -> dict[str, str]:
    return {"role": role, "path": path.resolve().relative_to(ROOT).as_posix(), "sha256": sha256(path), "environment_id": value["environment_id"], "source_revision": value["source_revision"]}


def key(item: dict[str, Any]) -> tuple[str, str, str]:
    return item["metric_id"], item["scenario"], item["cache_state"]


def relative_delta(primary: float, rerun: float, absolute_floor: float) -> float:
    if abs(primary) <= absolute_floor:
        return 0.0 if abs(rerun - primary) <= absolute_floor else float("inf")
    return abs(rerun - primary) / abs(primary)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--primary", action="append", type=Path, required=True)
    parser.add_argument("--rerun", action="append", type=Path, required=True)
    parser.add_argument("--revision", required=True)
    parser.add_argument("--attempt-label")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if len(args.primary) != len(args.rerun) or len(args.primary) < 2:
        raise SystemExit("matched primary/rerun pairs for both active browsers are required")

    policy = {
        "median_relative_floor": 0.5,
        "p95_relative_floor": 0.75,
        "variance_multiplier_median": 3,
        "variance_multiplier_p95": 4,
        "near_zero_absolute_ms": 0.5,
        "excluded_metrics": EXCLUDED,
    }
    inputs = []
    identity_checks = []
    comparisons = []
    for primary_path, rerun_path in zip(args.primary, args.rerun, strict=True):
        primary = validate(primary_path)
        rerun = validate(rerun_path)
        inputs.extend([ref("primary", primary_path, primary), ref("representative-rerun", rerun_path, rerun)])
        identity = {
            "environment_id": primary["environment_id"],
            "browser_binary_match": primary["browser"]["executable_sha256"] == rerun["browser"]["executable_sha256"],
            "profile_manifest_match": primary["artifact_manifest"] == rerun["artifact_manifest"],
            "environment_match": primary["environment_id"] == rerun["environment_id"],
        }
        identity_checks.append(identity)
        if not all(value for name, value in identity.items() if name != "environment_id"):
            raise SystemExit(f"rerun identity drift: {primary['environment_id']}")
        primary_stats = {key(item): item for item in summarize_measurements(primary["measurements"]) if item["metric_id"] not in EXCLUDED}
        rerun_stats = {key(item): item for item in summarize_measurements(rerun["measurements"]) if item["metric_id"] not in EXCLUDED}
        if set(primary_stats) != set(rerun_stats):
            raise SystemExit(f"rerun metric coverage drift: {primary['environment_id']}")
        for identity_key in sorted(primary_stats):
            left = primary_stats[identity_key]["statistics"]
            right = rerun_stats[identity_key]["statistics"]
            cv = left["coefficient_of_variation_percent"] / 100
            median_tolerance = max(policy["median_relative_floor"], policy["variance_multiplier_median"] * cv)
            p95_tolerance = max(policy["p95_relative_floor"], policy["variance_multiplier_p95"] * cv)
            median_delta = relative_delta(left["median"], right["median"], policy["near_zero_absolute_ms"])
            p95_delta = relative_delta(left["p95"], right["p95"], policy["near_zero_absolute_ms"])
            status = "within-development-tolerance" if median_delta <= median_tolerance and p95_delta <= p95_tolerance else "drift"
            comparisons.append({
                "environment_id": primary["environment_id"],
                "metric_id": identity_key[0],
                "scenario": identity_key[1],
                "cache_state": identity_key[2],
                "primary": {"count": left["count"], "median": left["median"], "p95": left["p95"], "variance_percent": left["coefficient_of_variation_percent"]},
                "rerun": {"count": right["count"], "median": right["median"], "p95": right["p95"], "variance_percent": right["coefficient_of_variation_percent"]},
                "tolerance": {"median_relative": round(median_tolerance, 6), "p95_relative": round(p95_tolerance, 6), "observed_median_relative_delta": round(median_delta, 6), "observed_p95_relative_delta": round(p95_delta, 6)},
                "status": status,
            })
    drift = sum(item["status"] == "drift" for item in comparisons)
    report_id = "BX-BH01-PHASE9-RERUN-COMPARISON"
    if args.attempt_label:
        if not all(char in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-" for char in args.attempt_label):
            raise SystemExit("--attempt-label must be an uppercase stable identifier")
        report_id += f"-{args.attempt_label}"
    report_id += "-0.1"
    record = {
        "schema_version": "1.0.0",
        "report_id": report_id,
        "status": "observed-drift" if drift else "observed-within-development-tolerance",
        "source_revision": args.revision,
        "policy": policy,
        "inputs": inputs,
        "identity_checks": identity_checks,
        "comparisons": comparisons,
        "drift_count": drift,
        "limitations": [
            "The representative rerun uses fewer samples than the primary run and is a development drift check, not a second-machine or support qualification.",
            "Tolerance expands with retained primary coefficient of variation and cannot turn a failed budget into a pass.",
            "Clock calibration and optional JavaScript heap are excluded because they are capability observations rather than comparable workload distributions."
        ]
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
    Draft202012Validator(load_json(HERE / "rerun-comparison.schema.json"), format_checker=FormatChecker()).validate(record)
    print(f"BH-01 Phase 9 representative rerun: {record['status'].upper()} ({len(comparisons)} distributions; {drift} drift)")
    return 1 if drift else 0


if __name__ == "__main__":
    raise SystemExit(main())
