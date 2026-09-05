#!/usr/bin/env python3
"""Compare BH-01 Phase 9 observations with unchanged quality budgets."""

from __future__ import annotations

import argparse
import json
from collections import Counter
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker

from phase9_metrics import load_json, sha256


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]


def ref(path: Path) -> dict[str, str]:
    return {"path": path.resolve().relative_to(ROOT).as_posix(), "sha256": sha256(path)}


def validate(path: Path, schema_path: Path) -> dict[str, Any]:
    value = load_json(path)
    Draft202012Validator(load_json(schema_path), format_checker=FormatChecker()).validate(value)
    return value


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--summary", type=Path, required=True)
    parser.add_argument("--economics", type=Path, required=True)
    parser.add_argument("--mitigations", type=Path, required=True)
    parser.add_argument("--deferrals", type=Path, required=True)
    parser.add_argument("--quality-contract", type=Path, required=True)
    parser.add_argument("--revision", required=True)
    parser.add_argument("--budget-output", type=Path, required=True)
    parser.add_argument("--decision-output", type=Path, required=True)
    parser.add_argument("--budget-reference-path", type=Path)
    args = parser.parse_args()
    if len(args.revision) != 40 or any(char not in "0123456789abcdef" for char in args.revision):
        raise SystemExit("--revision must be an exact lowercase commit")

    summary = validate(args.summary, HERE / "desktop-summary.schema.json")
    economics = validate(args.economics, HERE / "artifact-economics.schema.json")
    validate(args.mitigations, HERE / "mitigation-assessment.schema.json")
    deferrals = validate(args.deferrals, HERE / "qualification-deferral.schema.json")
    quality = load_json(args.quality_contract)
    budgets = {item["id"]: item for item in quality["budgets"]}
    evaluations: list[dict[str, Any]] = []

    def add(budget_id: str, scope: str, status: str, observed: Any, samples: int, evidence: str, rationale: str) -> None:
        budget = budgets[budget_id]
        evaluations.append({
            "budget_id": budget_id,
            "scope": scope,
            "status": status,
            "threshold": {"direction": budget["direction"], "value": budget["proposed_threshold"], "unit": budget["unit"], "statistic": budget["statistic"], "minimum_samples": budget["minimum_samples"]},
            "observed": observed,
            "samples": samples,
            "evidence": evidence,
            "rationale": rationale,
        })

    summary_ref = ref(args.summary)["path"]
    build = summary["build"]
    add("BX-BUD-BUILD-RELEASE-SECONDS", "linux-development-host", "observed-insufficient-boundary", build["statistics"]["p95"], build["statistics"]["count"], summary_ref, "The observed dependency-cached profile packager is below the threshold but does not cover the governed clean production source-build boundary or CI reference environment.")

    owner = {item["owner_class"]: item for item in economics["owner_costs"]}
    application = owner["application-bundle-unpruned"]
    add("BX-BUD-PAYLOAD-APPLICATION-COMPRESSED-KIB", "delivered-unpruned-application-avm", "fail-active-development", round(application["brotli_bytes"] / 1024, 3), 3, ref(args.economics)["path"], "The exact delivered application AVM exceeds the threshold; it also includes runtime/library modules, making reachability pruning the first mitigation rather than a threshold change.")
    add("BX-BUD-PAYLOAD-APPLICATION-UNCOMPRESSED-KIB", "delivered-unpruned-application-avm", "fail-active-development", round(application["decoded_bytes"] / 1024, 3), 3, ref(args.economics)["path"], "The exact delivered unpruned AVM exceeds the decoded application threshold.")
    loader = owner["loader-bootstrap"]
    add("BX-BUD-PAYLOAD-LOADER-COMPRESSED-KIB", "loader-bootstrap-conservative-owner-set", "pass-active-development", round(loader["brotli_bytes"] / 1024, 3), 3, ref(args.economics)["path"], "The owner set is broader than loader code alone and remains below the threshold, so the active-development result is conservative.")
    runtime = owner["runtime"]
    add("BX-BUD-PAYLOAD-RUNTIME-COMPRESSED-KIB", "atomvm-mjs-and-wasm-only", "observed-insufficient-boundary", round(runtime["brotli_bytes"] / 1024, 3), 3, ref(args.economics)["path"], "The measured runtime class excludes standard-library/runtime modules currently folded into the AVM and cannot receive a pass.")
    add("BX-BUD-PAYLOAD-SOURCEMAPS-PUBLIC-KIB", "public-bh01-profile", "pass-active-development-early", 0, 1, ref(args.economics)["path"], "The deployable manifest contains no source maps; this is an early observation before its BH-06 first-measurement milestone.")
    for budget_id in ["BX-BUD-PAYLOAD-SHARED-UI-KIB", "BX-BUD-PAYLOAD-FAMILY-BUNDLE-KIB", "BX-BUD-PAYLOAD-DATA-PACKAGE-KIB", "BX-BUD-PAYLOAD-CHART-PACKAGE-KIB", "BX-BUD-PAYLOAD-FONTS-ICONS-KIB"]:
        add(budget_id, "inactive-bh01-package", "not-activated", None, 0, ref(args.economics)["path"], "The governed optional/product package does not exist in the BH-01 fixture and zero is not claimed as a measurement.")

    distributions = summary["measurements"]
    def selected(metric: str, cache: str | None = None) -> list[dict[str, Any]]:
        return [item for item in distributions if item["metric_id"] == metric and (cache is None or item["cache_state"] == cache)]

    def per_environment_and_aggregate(budget_id: str, metric: str, cache: str, boundary: str = "exact") -> None:
        rows = selected(metric, cache)
        threshold = budgets[budget_id]["proposed_threshold"]
        for row in rows:
            value = row["statistics"]["p95"]
            status = "pass-active-development" if value <= threshold else "fail-active-development"
            if boundary == "narrower": status = "observed-insufficient-boundary"
            add(budget_id, f"{row['environment_id']}:{row['scenario']}:{cache}", status, value, row["statistics"]["count"], summary_ref, f"Nearest-rank p95; variance={row['statistics']['coefficient_of_variation_percent']}%; all samples retained. Boundary={boundary}.")
        by_scenario: dict[str, list[dict[str, Any]]] = {}
        for row in rows: by_scenario.setdefault(row["scenario"], []).append(row)
        for scenario, grouped in sorted(by_scenario.items()):
            value = max(row["statistics"]["p95"] for row in grouped)
            status = "pass-active-development" if value <= threshold else "fail-active-development"
            if boundary == "narrower": status = "observed-insufficient-boundary"
            add(budget_id, f"aggregate-active-linux:{scenario}:{cache}", status, value, min(row["statistics"]["count"] for row in grouped), summary_ref, "Conservative aggregate is the worst per-environment nearest-rank p95; it is not a pooled percentile.")

    per_environment_and_aggregate("BX-BUD-STARTUP-COLD-DESKTOP-MS", "BX-BH01-METRIC-STARTUP-NAVIGATION-READY-MS", "cold")
    per_environment_and_aggregate("BX-BUD-STARTUP-WARM-DESKTOP-MS", "BX-BH01-METRIC-STARTUP-NAVIGATION-READY-MS", "warm")
    per_environment_and_aggregate("BX-BUD-STARTUP-INSTANTIATE-MS", "BX-BH01-METRIC-STARTUP-INSTANTIATE-READY-MS", "cold", "broader-conservative")
    per_environment_and_aggregate("BX-BUD-STARTUP-ROOT-READINESS-MS", "BX-BH01-METRIC-STARTUP-ROOT-READY-MS", "warm", "early-bh03")
    per_environment_and_aggregate("BX-BUD-INTERACTION-LOCAL-EVENT-PAINT-MS", "BX-BH01-METRIC-INTERACTION-LOCAL-EVENT-PAINT-MS", "warm")
    per_environment_and_aggregate("BX-BUD-INTERACTION-DOM-UPDATE-MS", "BX-BH01-METRIC-INTERACTION-DOM-COMMIT-MS", "warm", "narrower")

    for row in selected("BX-BH01-METRIC-RESOURCE-CLEANUP-MS", "warm"):
        add("BX-BUD-RESOURCE-CLEANUP-MS", row["environment_id"], "observed-insufficient-samples", row["statistics"]["p95"], row["statistics"]["count"], summary_ref, "Twenty feasibility cycles do not satisfy the quality contract's one-hundred-cycle minimum or future resource-heavy root boundary.")
    heap_rows = selected("BX-BH01-METRIC-RESOURCE-JS-HEAP-BYTES", "warm")
    add("BX-BUD-RESOURCE-MEMORY-GROWTH-MIB", "active-linux-browser-memory", "observed-insufficient-boundary", max((row["statistics"]["maximum"] for row in heap_rows), default=None), sum(row["statistics"]["count"] for row in heap_rows), summary_ref, "Optional JavaScript heap snapshots exclude Wasm/browser/runtime memory, collection control, and one hundred lifecycle cycles.")
    server_rows = selected("BX-BH01-METRIC-INTERACTION-SERVER-ROUNDTRIP-MS", "warm")
    add("BX-BUD-INTERACTION-SERVER-ROUNDTRIP-MS", "same-host-linux-loopback", "observed-not-applicable-environment", max(row["statistics"]["p95"] for row in server_rows), min(row["statistics"]["count"] for row in server_rows), summary_ref, "Desktop loopback observations do not satisfy the mobile regional-server environment; mobile evaluation remains deferred.")
    add("BX-BUD-STARTUP-COLD-MOBILE-MS", "android-and-apple-mobile", "deferred", None, 0, ref(args.deferrals)["path"], "No representative physical mobile environment is available; the obligation reactivates no later than BH-22.")

    counts = dict(sorted(Counter(item["status"] for item in evaluations).items()))
    budget_report = {
        "schema_version": "1.0.0",
        "report_id": "BX-BH01-PHASE9-BUDGET-EVALUATION-0.1",
        "status": "conditional-active-development",
        "source_revision": args.revision,
        "quality_contract": {**ref(args.quality_contract), "version": quality["contract_version"], "changed": False},
        "inputs": [ref(args.summary), ref(args.economics), ref(args.mitigations), ref(args.deferrals)],
        "evaluation_policy": {
            "statistic": "Use each budget's declared statistic; browser p95 uses deterministic nearest rank.",
            "aggregate": "Worst per-environment p95 per scenario; never pool unlike environments.",
            "variance": "Flag and retain distributions above ten-percent coefficient of variation.",
            "outliers": "Exclude none; preserve every finite raw sample and failure list.",
            "deferred": "Keep unavailable environments separate and out of active pass rates.",
            "support_credit": False
        },
        "evaluations": evaluations,
        "status_counts": counts,
        "review": {
            "sample_adequacy": "All 41 active browser distributions and the build distribution meet Phase 9 harness minimums; cleanup and memory remain insufficient against their later quality-contract methods.",
            "variance": "High-variance distributions remain visible; no confidence interval or outlier deletion is used to promote a pass.",
            "harness": "Navigation and local-event boundaries are direct; instantiate is broader, DOM commit is narrower, build is partial, and memory is exploratory.",
            "environment": "One Linux host, Chrome for Testing, patched Firefox development build, same-host unshaped loopback; no support qualification.",
            "deferred_limit": "Mobile, Safari, Windows, second-machine, physical-device, and manual assistive-technology conclusions remain undecided."
        },
        "threshold_changes": []
    }
    args.budget_output.parent.mkdir(parents=True, exist_ok=True)
    args.budget_output.write_text(json.dumps(budget_report, indent=2) + "\n", encoding="utf-8")
    validate(args.budget_output, HERE / "budget-evaluation.schema.json")

    decision = {
        "schema_version": "1.0.0",
        "decision_id": "BX-BH01-PHASE9-STOP-DECISION-0.1",
        "status": "conditional-proceed",
        "source_revision": args.revision,
        "budget_evaluation_ref": ref(args.budget_reference_path or args.budget_output),
        "stop_conditions": [
            {"condition": "architecture-integrity", "status": "not-triggered", "finding": "No mitigation changes authority, host-neutral semantics, or the closed bridge/renderer boundaries."},
            {"condition": "reproducibility", "status": "not-triggered", "finding": "All evidence shares one source/profile identity and both generated report stages are byte-deterministic."},
            {"condition": "security-or-resource-regression", "status": "not-triggered-with-limits", "finding": "No page error, command failure, long task, or terminal resource growth was observed; complete memory and 100-cycle release methods remain insufficient."},
            {"condition": "payload-economics", "status": "review-triggered", "finding": "The delivered unpruned application AVM exceeds compressed and decoded application thresholds."},
            {"condition": "active-interaction", "status": "review-triggered", "finding": "Firefox timer-message p95 is 147.24 ms against the 100 ms active local-event threshold; other active local scenarios remain within threshold."},
            {"condition": "unavailable-external-qualification", "status": "deferred-not-active-blocker", "finding": "Unavailable environments do not halt Linux feasibility work but prohibit support, release, mobile, and cross-platform claims."}
        ],
        "active_failures": [
            {"budget_id": "BX-BUD-PAYLOAD-APPLICATION-COMPRESSED-KIB", "finding": "2147.601 KiB delivered versus 250 KiB proposed maximum.", "disposition": "Conditional development; execute application AVM reachability experiment before release qualification."},
            {"budget_id": "BX-BUD-PAYLOAD-APPLICATION-UNCOMPRESSED-KIB", "finding": "6424.242 KiB delivered versus 700 KiB proposed maximum.", "disposition": "Conditional development; use the same reachability experiment and preserve full proof coverage."},
            {"budget_id": "BX-BUD-INTERACTION-LOCAL-EVENT-PAINT-MS", "finding": "Firefox development-build timer-message p95 is 147.24 ms versus 100 ms.", "disposition": "Repeat with phase attribution after harness/runtime optimization; do not generalize to stable Firefox or mobile."}
        ],
        "required_mitigations": [
            {"mitigation_id": "BX-BH01-MITIGATION-APPLICATION-AVM-REACHABILITY-0.1", "owner": "build and runtime owners", "due": "before release qualification", "expiry": "review at BH-02 activation and every bundle-builder change", "repeat": "Separate before/after manifests plus Phases 3-9 evidence."},
            {"mitigation_id": "BX-BH01-MITIGATION-BROTLI-TRANSFER-0.1", "owner": "browser profile owner", "due": "before production deployment qualification", "expiry": "review when deployment topology changes", "repeat": "Before/after network and startup runs in active and later qualified environments."},
            {"mitigation_id": "BX-BH01-MITIGATION-FIREFOX-TIMER-TRACE-0.1", "owner": "browser host and runtime owners", "due": "before stable Firefox qualification", "expiry": "review when stable Firefox automation becomes available", "repeat": "Trace timer dispatch, runtime message, DOM effect, and paint with 100 retained samples."}
        ],
        "deferred_obligations": {**ref(args.deferrals), "reactivation": deferrals["policy"]["reactivation_milestone"], "phase_9_effect": "does not block active Linux completion", "support_effect": "blocks support and release qualification"},
        "decision": {
            "active_linux_development": "conditional-go",
            "framework_work": "may continue after Phase 9 integration closure and a separately authorized Phase 10",
            "mobile_viability": "undecided-deferred",
            "product_viability": "not-established-by-bh01-phase9",
            "support": "unsupported"
        },
        "phase_10": {
            "eligibility_after_phase_9_completion": True,
            "authorized": False,
            "required_inputs": ["Phase 9 integration verifier pass", "retained active failures and mitigation owners", "unchanged quality thresholds", "deferred qualification ledger"]
        },
        "prohibited_claims": ["browser support", "mobile viability", "cross-platform qualification", "accessibility conformance", "production readiness", "release approval"]
    }
    args.decision_output.write_text(json.dumps(decision, indent=2) + "\n", encoding="utf-8")
    validate(args.decision_output, HERE / "stop-decision.schema.json")
    print(f"BH-01 Phase 9 budget decision: CONDITIONAL PROCEED ({counts.get('fail-active-development', 0)} active failed evaluations)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
