#!/usr/bin/env python3
"""Validate the complete BH-01 Phase 3 runtime and packaging gate."""

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
PLAN = PLAN_DIR / "phase-03-runtime-build-and-beam-packaging.md"
MILESTONE = PLAN_DIR / "README.md"
EVIDENCE = PLAN_DIR / "phase-03-implementation-evidence.md"
ASSETS = ROOT / "docs/research/assets/bh-01-baseline"
COMPLETION = ASSETS / "blazex-bh-01-phase-03-completion-v0.1.0.json"
AUTHORIZATION = ASSETS / "blazex-bh-01-phase-03-authorization-v0.1.0.json"
SCHEMA = ASSETS / "blazex-bh-01-evidence-record.schema.json"
SHA256 = re.compile(r"^[0-9a-f]{64}$")
COMMIT = re.compile(r"^[0-9a-f]{40}$")


def load(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as stream:
        return json.load(stream)


def file_sha256(path: Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            value.update(chunk)
    return value.hexdigest()


def validate(
    completion: dict[str, Any],
    authorization: dict[str, Any],
    plan_text: str,
    milestone_text: str,
    evidence_text: str,
    repository_hashes: dict[str, str],
) -> list[str]:
    errors: list[str] = []
    if authorization.get("status") != "approved-phase-3-only":
        errors.append("Phase 3 lacks explicit repository-owner authorization")
    if not any(item.startswith("Phase 4 browser host") for item in authorization.get("not_authorized", [])):
        errors.append("Phase 3 authorization does not preserve the Phase 4 boundary")
    if completion.get("record_id") != "BX-BH01-DECISION-PHASE-03-GO":
        errors.append("Phase 3 completion record identity changed")
    if completion.get("record_type") != "decision" or completion.get("state") != "passed":
        errors.append("Phase 3 completion is not a passed decision")
    if not COMMIT.fullmatch(completion.get("source_revision", "")):
        errors.append("Phase 3 completion lacks an exact source revision")
    if completion.get("review", {}).get("disposition") != "accepted":
        errors.append("Phase 3 completion lacks accepted owner review")
    if "Phase 4 is eligible but not authorized" not in completion.get("outcome", {}).get("summary", ""):
        errors.append("Phase 3 completion over-authorizes downstream work")
    if len(completion.get("limitations", [])) < 6:
        errors.append("Phase 3 completion limitations are incomplete")

    for record in completion.get("input_hashes", []) + completion.get("output_hashes", []):
        path = record.get("path", "")
        expected = record.get("sha256", "")
        if not SHA256.fullmatch(expected):
            errors.append(f"Phase 3 evidence hash is invalid: {path}")
        elif repository_hashes.get(path) != expected:
            errors.append(f"Phase 3 evidence hash drifted: {path}")

    if "- [ ]" in plan_text:
        errors.append("Phase 3 plan still contains open work")
    required_milestone = "| complete — gate passed | Build the pinned Wasm runtime"
    if required_milestone not in milestone_text:
        errors.append("BH-01 milestone no longer records the passed Phase 3 gate")
    if "planned — eligible, not authorized" not in milestone_text:
        errors.append("BH-01 milestone does not preserve Phase 4 authorization boundary")
    for revision in ("93fb260", "5371a15", "7893ac6", "dd6b827"):
        if revision not in evidence_text:
            errors.append(f"Phase 3 evidence omits section revision {revision}")
    for boundary in (
        "No browser has loaded these artifacts",
        "all browsers remain unsupported",
        "Phase 4 is eligible but not authorized",
        "not a passed payload budget",
    ):
        if boundary not in evidence_text and boundary not in milestone_text:
            errors.append(f"Phase 3 evidence omits claim boundary: {boundary}")
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
        load(AUTHORIZATION),
        PLAN.read_text(encoding="utf-8"),
        MILESTONE.read_text(encoding="utf-8"),
        EVIDENCE.read_text(encoding="utf-8"),
        hashes,
    )


def main() -> int:
    errors: list[str] = []
    commands = [
        [sys.executable, str(HERE / "verify_phase2.py")],
        [sys.executable, str(ROOT / "packages/blazex_runtime_popcorn/runtime/verify_runtime_build.py")],
        [sys.executable, str(ROOT / "integration/fixtures/runtime_smoke/verify_fixture.py"), "--generated", str(ROOT / "integration/fixtures/runtime_smoke/generated")],
        [sys.executable, str(ROOT / "integration/fixtures/runtime_smoke/verify_semantics.py")],
        [sys.executable, str(ROOT / "integration/fixtures/runtime_smoke/verify_artifact_accounting.py")],
        [sys.executable, str(ROOT / "integration/fixtures/runtime_smoke/verify_negative_probes.py")],
        [sys.executable, str(ROOT / "docs/research/validate_bh01_activation.py")],
    ]
    for command in commands:
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
    ancestry = subprocess.run(
        ["git", "merge-base", "--is-ancestor", revision, "HEAD"],
        cwd=ROOT,
        capture_output=True,
        check=False,
    )
    if ancestry.returncode != 0:
        errors.append("Phase 3 source revision is not an ancestor of the delivery")

    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print("BH-01 Phase 3 runtime build and BEAM packaging gate: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
