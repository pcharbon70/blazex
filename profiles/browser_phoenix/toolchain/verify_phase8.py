#!/usr/bin/env python3
"""Validate the complete BH-01 Phase 8 browser-matrix decision."""

from __future__ import annotations

import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
PLAN_DIR = ROOT / "docs/research/60-planning/01-browser-host/bh-01-reproducible-browser-feasibility-baseline"
PLAN = PLAN_DIR / "phase-08-browser-compatibility-and-fallback-matrix.md"
MILESTONE = PLAN_DIR / "README.md"
REPORT_TEXT = PLAN_DIR / "phase-08-implementation-evidence.md"
ASSETS = ROOT / "docs/research/assets/bh-01-baseline"
AUTHORIZATION = ASSETS / "blazex-bh-01-phase-08-authorization-v0.1.0.json"
COMPLETION = ASSETS / "blazex-bh-01-phase-08-completion-v0.1.0.json"
COMPLETION_SCHEMA = ASSETS / "blazex-bh-01-evidence-record.schema.json"
FIXTURES = ROOT / "integration/fixtures"
SCENARIO = FIXTURES / "scenarios/bh01-phase8-browser-matrix.json"
SCENARIO_SCHEMA = FIXTURES / "scenario.schema.json"
FIXTURE_INDEX = FIXTURES / "fixture-index.json"
MATRIX_DIR = FIXTURES / "browser_matrix"
AGGREGATE = FIXTURES / "raw-evidence/bh01-phase8-browser-matrix.json"
PROFILE_MANIFEST = ROOT / "profiles/browser_phoenix/priv/static/bh01/profile-assets-manifest.json"
MATRIX_NAMES = (
    "environment-catalog.json",
    "matrix-policy.json",
    "prerequisite-matrix.json",
    "behavior-trust-matrix.json",
    "accessibility-input-matrix.json",
    "compatibility-matrix.json",
)
RAW_NAMES = tuple(
    f"bh01-phase8-{family}-{browser}.json"
    for family in ("prerequisites", "behavior", "accessibility", "compatibility")
    for browser in ("chromium", "firefox-probe", "webkit-probe")
)
REQUIRED_IDS = {
    "BR-CHROMIUM-DESKTOP",
    "BR-CHROMIUM-ANDROID",
    "BR-FIREFOX-DESKTOP",
    "BR-WEBKIT-DESKTOP",
    "BR-WEBKIT-MOBILE",
}
SHA256 = re.compile(r"^[0-9a-f]{64}$")
COMMIT = re.compile(r"^[0-9a-f]{40}$")


def load(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def file_sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def historical_sha256(revision: str, path: str) -> str | None:
    result = subprocess.run(
        ["git", "show", f"{revision}:{path}"],
        cwd=ROOT,
        capture_output=True,
        check=False,
    )
    return hashlib.sha256(result.stdout).hexdigest() if result.returncode == 0 else None


def committed_sha256s(path: str) -> set[str]:
    history = subprocess.run(
        ["git", "log", "--format=%H", "--", path],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    values: set[str] = set()
    for revision in history.stdout.splitlines():
        value = historical_sha256(revision, path)
        if value:
            values.add(value)
    return values


def aggregate_self_hash(aggregate: dict[str, Any]) -> str:
    keys = ("required_matrix", "executed", "raw_evidence_sha256", "outcomes", "proofs", "decision")
    value = {key: aggregate.get(key) for key in keys}
    payload = json.dumps(value, ensure_ascii=False, separators=(",", ":"))
    return hashlib.sha256(payload.encode()).hexdigest()


def validate(
    completion: dict[str, Any],
    authorization: dict[str, Any],
    aggregate: dict[str, Any],
    matrix_report: dict[str, Any],
    scenario: dict[str, Any],
    fixture_index: dict[str, Any],
    catalog: dict[str, Any],
    policy: dict[str, Any],
    matrices: dict[str, dict[str, Any]],
    raw_hashes: dict[str, str],
    profile_hash: str,
    plan_text: str,
    milestone_text: str,
    report_text: str,
    repository_hashes: dict[str, set[str]],
) -> list[str]:
    errors: list[str] = []

    if authorization.get("status") != "approved-phase-8-only":
        errors.append("Phase 8 lacks explicit repository-owner authorization")
    if not any("Phase 9 measurement" in item for item in authorization.get("not_authorized", [])):
        errors.append("Phase 8 authorization does not preserve the Phase 9 boundary")

    if completion.get("record_id") != "BX-BH01-DECISION-PHASE-08-BLOCKED":
        errors.append("Phase 8 completion record identity changed")
    if completion.get("record_type") != "decision" or completion.get("state") != "blocked":
        errors.append("Phase 8 completion is not a blocked decision")
    if not COMMIT.fullmatch(completion.get("source_revision", "")):
        errors.append("Phase 8 completion lacks an exact source revision")
    if completion.get("review", {}).get("disposition") != "accepted":
        errors.append("Phase 8 completion lacks accepted owner review")
    summary = completion.get("outcome", {}).get("summary", "")
    if "Phase 9 is not eligible and is not authorized" not in summary:
        errors.append("Phase 8 completion over-authorizes downstream work")
    for record in completion.get("input_hashes", []) + completion.get("output_hashes", []):
        path = record.get("path", "")
        expected = record.get("sha256", "")
        if not SHA256.fullmatch(expected) or expected not in repository_hashes.get(path, set()):
            errors.append(f"Phase 8 evidence hash drifted: {path}")

    required_rows = matrix_report.get("required_rows", [])
    required_ids = [item.get("configuration_id") for item in required_rows]
    if len(required_ids) != 5 or set(required_ids) != REQUIRED_IDS or len(required_ids) != len(set(required_ids)):
        errors.append("final report omits or duplicates a required browser row")
    blocked_environments = [item for item in required_rows if item.get("overall") == "environment-blocked"]
    chromium = [item for item in required_rows if item.get("configuration_id") == "BR-CHROMIUM-DESKTOP"]
    if len(blocked_environments) != 4 or len(chromium) != 1 or chromium[0].get("overall") != "blocked-manual-evidence":
        errors.append("final required-row result is not the observed blocked matrix")
    probes = matrix_report.get("non_substituting_probes", [])
    if len(probes) != 2 or any(item.get("required_row_credit") is not False for item in probes):
        errors.append("final report substitutes an engine probe for required browser evidence")
    decision = matrix_report.get("decision", {})
    if matrix_report.get("status") != "blocked" or decision != {
        "result": "blocked",
        "reason": "Four required browser environments and all required assistive-technology pairings are unavailable; a partial matrix cannot pass.",
        "phase9_eligible": False,
        "phase9_authorized": False,
        "browser_support": "unsupported",
    }:
        errors.append("final report does not preserve the blocked and unsupported decision")

    matrix_hashes = {item.get("path"): item.get("sha256") for item in matrix_report.get("matrix_inputs", [])}
    for name in MATRIX_NAMES:
        if matrix_hashes.get(name) != file_sha256(MATRIX_DIR / name):
            errors.append(f"final report matrix input drifted: {name}")
    if matrix_report.get("profile_manifest_sha256") != profile_hash:
        errors.append("final report profile identity drifted")
    if policy.get("artifact_policy", {}).get("profile_manifest_sha256") != profile_hash:
        errors.append("matrix policy profile identity drifted")
    catalog_rows = catalog.get("required_rows", [])
    if len(catalog_rows) != 5 or {item.get("configuration_id") for item in catalog_rows} != REQUIRED_IDS:
        errors.append("environment catalog no longer materializes the required matrix")
    if sum(item.get("availability") == "available" for item in catalog_rows) != 1 or sum(item.get("availability") == "environment-blocked" for item in catalog_rows) != 4:
        errors.append("environment availability no longer matches the observed matrix")
    for name in MATRIX_NAMES[2:]:
        if matrices[name].get("source_revision") != matrix_report.get("source_revision"):
            errors.append(f"matrix source revision drifted: {name}")

    if aggregate.get("status") != "observed-blocked" or aggregate.get("support_status") != "unsupported":
        errors.append("aggregate evidence overclaims the Phase 8 result")
    if aggregate.get("required_matrix") != {
        "total": 5,
        "available": 1,
        "environment_blocked": 4,
        "fully_passed": 0,
        "manual_evidence_blocked": 1,
    }:
        errors.append("aggregate required-matrix counts drifted")
    if aggregate.get("executed") != {
        "required_browser_runs": 4,
        "unqualified_engine_probe_runs": 8,
        "scenario_families_per_environment": 4,
        "automatic_retries": 0,
        "quarantines": 0,
    }:
        errors.append("aggregate execution accounting drifted")
    if set(aggregate.get("raw_evidence_sha256", {})) != set(RAW_NAMES):
        errors.append("aggregate evidence omits or adds a raw browser record")
    for name in RAW_NAMES:
        if aggregate.get("raw_evidence_sha256", {}).get(name) != raw_hashes.get(name):
            errors.append(f"aggregate raw evidence hash drifted: {name}")
    aggregate_decision = aggregate.get("decision", {})
    if aggregate_decision != {
        "result": "blocked",
        "phase9_eligible": False,
        "phase9_authorized": False,
        "all_browsers": "unsupported",
    }:
        errors.append("aggregate evidence does not retain the blocked decision")
    if aggregate.get("profile_manifest_sha256") != profile_hash:
        errors.append("aggregate profile identity drifted")
    if aggregate.get("evidence_sha256") != aggregate_self_hash(aggregate):
        errors.append("aggregate evidence self-hash drifted")

    if scenario.get("scenario_id") != "BX-BH01-SCENARIO-PHASE8-BROWSER-MATRIX" or scenario.get("status") != "blocked":
        errors.append("Phase 8 governed scenario is not blocked")
    indexed = [item for item in fixture_index.get("scenarios", []) if item.get("scenario_id") == scenario.get("scenario_id")]
    if len(indexed) != 1 or indexed[0].get("status") != "blocked" or indexed[0].get("evidence") != "raw-evidence/bh01-phase8-browser-matrix.json":
        errors.append("Phase 8 scenario/evidence is not uniquely indexed as blocked")

    if "- [ ]" in plan_text:
        errors.append("Phase 8 plan still contains open work")
    if "| complete — local evidence accepted; external qualification deferred |" not in milestone_text:
        errors.append("BH-01 milestone does not preserve the Phase 8 deferred-qualification disposition")
    if "| [9 — Measurement" not in milestone_text or "| eligible — not authorized | Measure payload" not in milestone_text:
        errors.append("BH-01 milestone does not preserve Phase 9 eligibility and non-authorization")
    if "development environment and deferred qualification policy" not in milestone_text.lower():
        errors.append("BH-01 milestone does not link the governing development-environment policy")
    normalized_report = " ".join(report_text.split()).lower()
    for boundary in (
        "all browsers remain unsupported",
        "phase 9 is therefore not eligible and is not authorized",
        "linux webkit is not macos or mobile safari evidence",
        "assistive-technology and physical-input review",
    ):
        if boundary not in normalized_report:
            errors.append(f"Phase 8 report omits claim boundary: {boundary}")
    for revision in ("24f6958", "e7c5f88", "083c587", "b14cb8f", "b84aaeb"):
        if revision not in report_text:
            errors.append(f"Phase 8 report omits section revision {revision}")
    return errors


def inputs() -> tuple[Any, ...]:
    completion = load(COMPLETION)
    records = completion.get("input_hashes", []) + completion.get("output_hashes", [])
    hashes: dict[str, set[str]] = {}
    for record in records:
        path = record["path"]
        values: set[str] = set()
        if (ROOT / path).is_file():
            values.add(file_sha256(ROOT / path))
        values.update(committed_sha256s(path))
        hashes[path] = values
    return (
        completion,
        load(AUTHORIZATION),
        load(AGGREGATE),
        load(MATRIX_DIR / "matrix-report.json"),
        load(SCENARIO),
        load(FIXTURE_INDEX),
        load(MATRIX_DIR / "environment-catalog.json"),
        load(MATRIX_DIR / "matrix-policy.json"),
        {name: load(MATRIX_DIR / name) for name in MATRIX_NAMES[2:]},
        {name: file_sha256(FIXTURES / "raw-evidence" / name) for name in RAW_NAMES},
        file_sha256(PROFILE_MANIFEST),
        PLAN.read_text(encoding="utf-8"),
        MILESTONE.read_text(encoding="utf-8"),
        REPORT_TEXT.read_text(encoding="utf-8"),
        hashes,
    )


def main() -> int:
    errors: list[str] = []
    commands = [
        [sys.executable, str(HERE / "verify_phase7.py")],
        *[
            [sys.executable, str(MATRIX_DIR / name)]
            for name in (
                "verify_environments.py",
                "verify_prerequisites.py",
                "verify_behavior_trust.py",
                "verify_accessibility_input.py",
                "verify_compatibility.py",
            )
        ],
        [sys.executable, str(ROOT / "profiles/browser_phoenix/assets/phase4/verify_profile.py"), "profiles/browser_phoenix/priv/static/bh01"],
    ]
    for command in commands:
        result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, check=False)
        if result.returncode != 0:
            errors.append(f"{Path(command[1]).name}: {result.stderr.strip() or result.stdout.strip()}")

    completion = load(COMPLETION)
    errors.extend(
        f"completion schema: {error.message}"
        for error in Draft202012Validator(load(COMPLETION_SCHEMA), format_checker=FormatChecker()).iter_errors(completion)
    )
    scenario = load(SCENARIO)
    errors.extend(
        f"scenario schema: {error.message}"
        for error in Draft202012Validator(load(SCENARIO_SCHEMA), format_checker=FormatChecker()).iter_errors(scenario)
    )
    errors.extend(validate(*inputs()))
    revision = completion.get("source_revision", "")
    if subprocess.run(["git", "merge-base", "--is-ancestor", revision, "HEAD"], cwd=ROOT, check=False).returncode:
        errors.append("Phase 8 source revision is not an ancestor of the delivery")
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print("BH-01 Phase 8 historical browser matrix: BLOCKED (evidence valid; external qualification deferred by current planning policy)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
