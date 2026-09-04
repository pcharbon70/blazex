#!/usr/bin/env python3
"""Validate the complete BH-01 Phase 2 qualification gate."""

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
PLAN = ROOT / "docs/research/60-planning/01-browser-host/bh-01-reproducible-browser-feasibility-baseline/phase-02-toolchain-and-dependency-qualification.md"
MILESTONE = PLAN.parent / "README.md"
EVIDENCE = PLAN.parent / "phase-02-implementation-evidence.md"
ASSETS = ROOT / "docs/research/assets/bh-01-baseline"
COMPLETION = ASSETS / "blazex-bh-01-phase-02-completion-v0.1.0.json"
AUTHORIZATION = ASSETS / "blazex-bh-01-phase-02-authorization-v0.1.0.json"
SCHEMA = ASSETS / "blazex-bh-01-evidence-record.schema.json"
SHA256 = re.compile(r"^[0-9a-f]{64}$")
COMMIT = re.compile(r"^[0-9a-f]{40}$")


def load(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as stream:
        return json.load(stream)


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def validate(
    completion: dict[str, Any],
    authorization: dict[str, Any],
    plan_text: str,
    milestone_text: str,
    evidence_text: str,
    repository_hashes: dict[str, str],
) -> list[str]:
    errors: list[str] = []
    if authorization.get("status") != "approved-phase-2-only":
        errors.append("Phase 2 lacks explicit repository-owner authorization")
    if not any(item.startswith("Phase 3 runtime build") for item in authorization.get("not_authorized", [])):
        errors.append("Phase 2 authorization does not preserve the Phase 3 boundary")
    if completion.get("record_id") != "BX-BH01-DECISION-PHASE-02-GO":
        errors.append("Phase 2 completion record identity changed")
    if completion.get("record_type") != "decision" or completion.get("state") != "passed":
        errors.append("Phase 2 completion is not a passed decision")
    if not COMMIT.fullmatch(completion.get("source_revision", "")):
        errors.append("Phase 2 completion lacks an exact source revision")
    if completion.get("review", {}).get("disposition") != "accepted":
        errors.append("Phase 2 completion lacks accepted owner review")
    if "Phase 3 is eligible but not authorized" not in completion.get("outcome", {}).get("summary", ""):
        errors.append("Phase 2 completion over-authorizes downstream work")

    for record in completion.get("input_hashes", []) + completion.get("output_hashes", []):
        path = record.get("path", "")
        expected = record.get("sha256", "")
        if not SHA256.fullmatch(expected):
            errors.append(f"Phase 2 evidence hash is invalid: {path}")
        elif repository_hashes.get(path) != expected:
            errors.append(f"Phase 2 evidence hash drifted: {path}")
    if len(completion.get("limitations", [])) < 4:
        errors.append("Phase 2 completion limitations are incomplete")

    if "- [ ]" in plan_text:
        errors.append("Phase 2 plan still contains open work")
    if "[2 — Toolchain and Dependency Qualification]" not in milestone_text or "| complete — gate passed |" not in milestone_text:
        errors.append("BH-01 milestone no longer records the passed Phase 2 gate")
    allowed_phase3_states = (
        "planned — eligible, not authorized",
        "in progress — authorized",
        "complete — gate passed",
    )
    if not any(state in milestone_text for state in allowed_phase3_states):
        errors.append("BH-01 milestone has no valid post-Phase-2 state")
    required_revisions = {"6c1cc4f", "d1ec81c", "679acf8", "448fb0b"}
    if any(revision not in evidence_text for revision in required_revisions):
        errors.append("Phase 2 section delivery revisions are incomplete")
    for boundary in ("has not been configured, compiled, linked", "All browsers remain unsupported", "Phase 3 is eligible but not authorized"):
        if boundary not in evidence_text and boundary not in milestone_text:
            errors.append(f"Phase 2 evidence omits claim boundary: {boundary}")
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
    for validator_name in ("verify_environment", "verify_runtime", "verify_server", "verify_acquisition"):
        result = subprocess.run(
            [sys.executable, str(HERE / f"{validator_name}.py")],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=False,
        )
        if result.returncode != 0:
            errors.append(f"{validator_name}: {result.stderr.strip() or result.stdout.strip()}")

    completion = load(COMPLETION)
    schema = load(SCHEMA)
    errors.extend(
        f"completion schema: {error.message}"
        for error in Draft202012Validator(schema, format_checker=FormatChecker()).iter_errors(completion)
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
        errors.append("Phase 2 source revision is not an ancestor of the delivery")

    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print("BH-01 Phase 2 toolchain and dependency qualification gate: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
