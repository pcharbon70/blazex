#!/usr/bin/env python3
"""Validate and summarize retained BH-01 Phase 9 Linux evidence."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker

from phase9_metrics import load_json, sha256, summarize, summarize_measurements, validate_measurements


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]


def validate(path: Path, schema_name: str) -> dict[str, Any]:
    value = load_json(path)
    schema = load_json(HERE / schema_name)
    Draft202012Validator(schema, format_checker=FormatChecker()).validate(value)
    return value


def relative(path: Path) -> str:
    return path.resolve().relative_to(ROOT).as_posix()


def adequacy(observed: int, minimum: int) -> dict[str, Any]:
    return {
        "observed_samples": observed,
        "governed_minimum": minimum,
        "status": "adequate" if observed >= minimum else "insufficient",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--browser", action="append", type=Path, required=True)
    parser.add_argument("--build", type=Path, required=True)
    parser.add_argument("--artifacts", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    definitions_record = load_json(HERE / "phase9-metric-definitions.json")
    definitions = {item["id"]: item for item in definitions_record["metrics"]}
    browsers = [(path, validate(path, "measurement-run.schema.json")) for path in args.browser]
    build = validate(args.build, "build-run.schema.json")
    artifacts = validate(args.artifacts, "artifact-run.schema.json")
    records = [value for _, value in browsers] + [build, artifacts]
    revisions = {value["source_revision"] for value in records}
    if len(revisions) != 1:
        raise SystemExit("Phase 9 evidence spans multiple source revisions")

    manifest_hashes = {value["artifact_manifest"]["sha256"] for _, value in browsers}
    manifest_hashes.add(build["output_manifest_sha256"])
    manifest_hashes.add(artifacts["profile_manifest"]["sha256"])
    measurements = []
    reliability = []
    for path, browser in browsers:
        validate_measurements(browser["measurements"], definitions)
        for item in summarize_measurements(browser["measurements"]):
            definition = definitions[item["metric_id"]]
            stats = item["statistics"]
            measurements.append({
                "environment_id": browser["environment_id"],
                **item,
                "adequacy": adequacy(stats["count"], definition["minimum_samples"]),
                "outlier_review": {
                    "samples_excluded": 0,
                    "flag": "variance-review" if stats["coefficient_of_variation_percent"] > definitions_record["sample_policy"]["variance_review_above_percent"] else "none",
                    "rationale": "All finite non-negative samples are retained; high variance is reported rather than removed.",
                },
                "confidence": "No parametric interval asserted; the full distribution and deterministic nearest-rank p95 are retained.",
            })
        reliability.append({"environment_id": browser["environment_id"], **browser["reliability"]})

    build_stats = summarize(sample["seconds"] for sample in build["samples"])
    build_definition = definitions["BX-BH01-METRIC-BUILD-RELEASE-SECONDS"]
    captured = max(value["captured_at"] for value in records)
    record = {
        "schema_version": "1.0.0",
        "summary_id": "BX-BH01-PHASE9-LINUX-DESKTOP-SUMMARY-0.1",
        "status": "observed-with-failures" if any(value.get("failures") for value in records) else "observed",
        "source_revision": revisions.pop(),
        "generated_from_captured_at": captured,
        "raw_evidence": [
            {
                "kind": kind,
                "path": relative(path),
                "sha256": sha256(path),
                "environment_id": value["environment_id"],
                "status": value["status"],
            }
            for kind, path, value in [
                *[("browser", path, value) for path, value in browsers],
                ("build", args.build, build),
                ("artifacts", args.artifacts, artifacts),
            ]
        ],
        "measurements": sorted(measurements, key=lambda item: (item["environment_id"], item["metric_id"], item["scenario"], item["cache_state"])),
        "build": {
            "environment_id": build["environment_id"],
            "metric_id": build_definition["id"],
            "statistics": build_stats,
            "adequacy": adequacy(build_stats["count"], build_definition["minimum_samples"]),
            "manifest_sha256": build["output_manifest_sha256"],
        },
        "payload": {
            "environment_id": artifacts["environment_id"],
            "metric_id": "BX-BH01-METRIC-PAYLOAD-BROTLI-BYTES",
            "compression": artifacts["compression"],
            "totals": artifacts["totals"],
            "artifact_count": len(artifacts["artifacts"]),
            "source_maps": artifacts["source_maps"],
        },
        "reliability": reliability,
        "environment_drift": {
            "source_revision_consistent": True,
            "profile_manifest_consistent": len(manifest_hashes) == 1,
            "drift_detected": len(manifest_hashes) != 1,
        },
        "cross_machine_comparison": {
            "status": "deferred",
            "reason": "No second controlled Linux development machine is currently available.",
            "reactivation": "BH-22 qualification infrastructure or earlier when another controlled host becomes available",
        },
        "limitations": [
            "Results describe the available Linux development host and do not establish browser support.",
            "Firefox is a patched Playwright development build and receives no stable Firefox required-row credit.",
            "Loopback is unshaped and does not substitute for constrained-network or mobile evidence.",
            "The build duration covers dependency-cached profile packaging, not the complete clean source-build boundary.",
        ],
    }
    if record["environment_drift"]["drift_detected"]:
        raise SystemExit("Phase 9 evidence does not share one profile manifest")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
    Draft202012Validator(load_json(HERE / "desktop-summary.schema.json"), format_checker=FormatChecker()).validate(record)
    print(f"BH-01 Phase 9 desktop summary: {record['status'].upper()} ({len(measurements)} distributions)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
