#!/usr/bin/env python3
"""Validate the retained BH-01 Phase 4 browser-host evidence."""

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
PLAN = PLAN_DIR / "phase-04-browser-host-loader-lifecycle-and-deployment.md"
MILESTONE = PLAN_DIR / "README.md"
REPORT = PLAN_DIR / "phase-04-implementation-evidence.md"
ASSETS = ROOT / "docs/research/assets/bh-01-baseline"
COMPLETION = ASSETS / "blazex-bh-01-phase-04-completion-v0.1.0.json"
SCHEMA = ASSETS / "blazex-bh-01-evidence-record.schema.json"
EVIDENCE = ROOT / "integration/fixtures/raw-evidence/bh01-phase4-browser.json"
SHA256 = re.compile(r"^[0-9a-f]{64}$")
COMMIT = re.compile(r"^[0-9a-f]{40}$")


def load(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as stream:
        return json.load(stream)


def file_sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def validate_browser(evidence: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    if evidence.get("status") != "observed-pass":
        errors.append("actual-browser evidence did not pass")
    if evidence.get("support_status") != "unsupported-provisional-feasibility":
        errors.append("browser evidence promotes support")
    toolchain = evidence.get("toolchain", {})
    expected = {
        "node": "v26.8.1",
        "playwright_core": "1.62.1",
        "browser_product": "Chrome for Testing",
        "browser_version": "152.0.7977.75",
        "browser_archive_sha256": "a16d36890636bd72251133b27f05825f7f9269c2425b3408fa3a76e10dccd8f1",
    }
    for key, value in expected.items():
        if toolchain.get(key) != value:
            errors.append(f"browser toolchain drifted: {key}")

    deployment = evidence.get("deployment", {})
    observed = deployment.get("observed", [])
    if deployment.get("governed_files") != 18 or len(observed) != 18:
        errors.append("deployment does not account for 18 governed files")
    if deployment.get("source_maps") != []:
        errors.append("undeclared browser source maps observed")
    if deployment.get("range_status") != 206 or deployment.get("etag_status") != 304:
        errors.append("range or ETag deployment behavior failed")
    for item in observed:
        if item.get("status") != 200 or not SHA256.fullmatch(item.get("sha256", "")):
            errors.append(f"invalid governed artifact observation: {item.get('path')}")

    positive = {item["scenario"]: item for item in evidence.get("positive_scenarios", [])}
    for name, generation in (("cold", 1), ("restart-1", 2), ("restart-2", 3), ("warm-navigation", 1)):
        item = positive.get(name, {})
        if item.get("state") != "ready" or item.get("activation_generation") != generation:
            errors.append(f"browser readiness/generation failed: {name}")
        if (item.get("echo") or {}).get("message") != "bh01-browser-roundtrip":
            errors.append(f"Elixir bridge echo failed: {name}")
    for name in ("stop-1", "stop-2", "stop-3", "warm-stop"):
        lifecycle = positive.get(name, {}).get("lifecycle") or {}
        if positive.get(name, {}).get("state") != "stopped" or lifecycle.get("resources") != {}:
            errors.append(f"browser teardown did not converge: {name}")

    negative = {item["scenario"]: item for item in evidence.get("negative_scenarios", [])}
    policy = negative.get("missing-isolation-policy", {})
    if policy.get("state") != "fallback" or policy.get("prerequisite_decision") != "unsupported":
        errors.append("missing-isolation fallback did not fail intentionally")
    for name, code in (
        ("manifest-network-failure", "fetch-failed"),
        ("manifest-digest-integrity-failure", "artifact-integrity-mismatch"),
    ):
        item = negative.get(name, {})
        if item.get("state") != "failed" or (item.get("error") or {}).get("code") != code:
            errors.append(f"browser negative scenario drifted: {name}")
        if (item.get("lifecycle") or {}).get("state") != "stopped":
            errors.append(f"browser negative scenario did not stop: {name}")

    paths = {item.get("path") for item in evidence.get("network", [])}
    declared = {"/bh01/", "blob:<runtime-worker-module>"} | {
        f"/bh01/{item['path']}" for item in observed
    }
    if paths - declared:
        errors.append(f"undeclared network paths observed: {sorted(paths - declared)}")
    return errors


def validate(
    completion: dict[str, Any],
    evidence: dict[str, Any],
    plan_text: str,
    milestone_text: str,
    report_text: str,
    repository_hashes: dict[str, str],
) -> list[str]:
    errors = validate_browser(evidence)
    if completion.get("record_id") != "BX-BH01-DECISION-PHASE-04-GO":
        errors.append("Phase 4 completion record identity changed")
    if completion.get("record_type") != "decision" or completion.get("state") != "passed":
        errors.append("Phase 4 completion is not a passed decision")
    if not COMMIT.fullmatch(completion.get("source_revision", "")):
        errors.append("Phase 4 completion lacks an exact source revision")
    if completion.get("review", {}).get("disposition") != "accepted":
        errors.append("Phase 4 completion lacks accepted owner review")
    if "Phase 5 is eligible but not authorized" not in completion.get("outcome", {}).get("summary", ""):
        errors.append("Phase 4 completion over-authorizes downstream work")
    for record in completion.get("input_hashes", []) + completion.get("output_hashes", []):
        path = record.get("path", "")
        expected = record.get("sha256", "")
        if not SHA256.fullmatch(expected) or repository_hashes.get(path) != expected:
            errors.append(f"Phase 4 evidence hash drifted: {path}")
    if "- [ ]" in plan_text:
        errors.append("Phase 4 plan still contains open work")
    if "| complete — gate passed | Implement manifest-driven loading" not in milestone_text:
        errors.append("BH-01 milestone does not record the passed Phase 4 gate")
    if "Phase 5 is eligible but not authorized" not in milestone_text:
        errors.append("BH-01 milestone does not preserve the Phase 5 authorization boundary")
    for revision in ("0e99efe", "95854d1", "91de0e4", "6924c2d"):
        if revision not in report_text:
            errors.append(f"Phase 4 report omits section revision {revision}")
    for boundary in ("all browsers remain unsupported", "No DOM", "Phase 5 is eligible but not authorized"):
        if boundary not in report_text and boundary not in milestone_text:
            errors.append(f"Phase 4 report omits claim boundary: {boundary}")
    return errors


def inputs() -> tuple[Any, ...]:
    completion = load(COMPLETION)
    records = completion.get("input_hashes", []) + completion.get("output_hashes", [])
    hashes = {
        record["path"]: file_sha256(ROOT / record["path"])
        for record in records
        if (ROOT / record["path"]).is_file()
    }
    return (
        completion,
        load(EVIDENCE),
        PLAN.read_text(encoding="utf-8"),
        MILESTONE.read_text(encoding="utf-8"),
        REPORT.read_text(encoding="utf-8"),
        hashes,
    )


def main() -> int:
    errors: list[str] = []
    for command in (
        [sys.executable, str(HERE / "verify_phase3.py")],
        [sys.executable, str(ROOT / "docs/research/validate_bh01_activation.py")],
    ):
        result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, check=False)
        if result.returncode != 0:
            errors.append(f"{Path(command[1]).name}: {result.stderr.strip() or result.stdout.strip()}")
    completion = load(COMPLETION)
    errors.extend(
        f"completion schema: {error.message}"
        for error in Draft202012Validator(load(SCHEMA), format_checker=FormatChecker()).iter_errors(completion)
    )
    errors.extend(validate(*inputs()))
    revision = completion.get("source_revision", "")
    if subprocess.run(["git", "merge-base", "--is-ancestor", revision, "HEAD"], cwd=ROOT, check=False).returncode:
        errors.append("Phase 4 source revision is not an ancestor of the delivery")
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print("BH-01 Phase 4 browser-host lifecycle and deployment gate: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
