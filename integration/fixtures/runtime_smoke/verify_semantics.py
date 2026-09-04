#!/usr/bin/env python3
"""Validate retained BH-01 Phase 3 runtime-semantics evidence."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator

import run_probe


HERE = Path(__file__).resolve().parent
FIXTURES = HERE.parent


def load(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as stream:
        return json.load(stream)


def validate(
    contract: dict[str, Any],
    evidence: dict[str, Any],
    manifest: dict[str, Any],
    scenario: dict[str, Any],
    scenario_schema: dict[str, Any],
    findings: str,
) -> list[str]:
    errors = run_probe.validate_evidence(contract, evidence, manifest)
    errors.extend(
        f"scenario schema: {error.message}"
        for error in Draft202012Validator(scenario_schema).iter_errors(scenario)
    )
    if scenario.get("status") != "passed":
        errors.append("runtime semantics scenario has not passed")
    required_findings = (
        "Process.cancel_timer/1",
        "OTP release `27`",
        "worker-separated browser host",
        "message_queue_len=0",
    )
    for finding in required_findings:
        if finding not in findings:
            errors.append(f"runtime semantics findings omit {finding}")
    return errors


def inputs() -> tuple[Any, ...]:
    return (
        load(HERE / "semantics-contract.json"),
        load(FIXTURES / "raw-evidence/bh01-phase3-runtime-semantics.json"),
        load(HERE / "bundle-manifest.json"),
        load(FIXTURES / "scenarios/bh01-runtime-semantics.json"),
        load(FIXTURES / "scenario.schema.json"),
        (HERE / "runtime-semantics-findings.md").read_text(encoding="utf-8"),
    )


def main() -> int:
    errors = validate(*inputs())
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print("BH-01 Phase 3 retained runtime semantics evidence: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
