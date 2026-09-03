#!/usr/bin/env python3
"""Validate retained BH-01 Phase 3 fail-closed probe evidence."""

from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any


HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]
EVIDENCE = HERE.parent / "raw-evidence/bh01-phase3-negative-paths.json"
SHA256 = re.compile(r"^[0-9a-f]{64}$")
EXPECTED_CASES = {
    "canonical-runtime-control",
    "missing-import",
    "incompatible-memory-contract",
    "invalid-wasm",
    "corrupt-bundle",
    "unknown-bundle",
    "missing-module",
    "cleanup-evidence-failure",
}


def load(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as stream:
        return json.load(stream)


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def validate(evidence: dict[str, Any], check_files: bool = True) -> list[str]:
    errors: list[str] = []
    if evidence.get("status") != "passed":
        errors.append("negative probe evidence is not passed")
    results = evidence.get("results", [])
    case_ids = [item.get("case_id") for item in results]
    if set(case_ids) != EXPECTED_CASES or len(case_ids) != len(set(case_ids)):
        errors.append("negative probe cases are missing or duplicated")
    if not all(item.get("passed") is True for item in results):
        errors.append("a negative probe did not fail closed")
    summary = evidence.get("summary", {})
    if summary != {"cases": len(EXPECTED_CASES), "passed": len(EXPECTED_CASES)}:
        errors.append("negative probe summary is inconsistent")
    for kind in ("runtime", "wasm", "bundle"):
        item = evidence.get(kind, {})
        if not SHA256.fullmatch(item.get("sha256", "")):
            errors.append(f"negative probe {kind} identity is invalid")
            continue
        path = REPO / item.get("path", "")
        if check_files and (not path.is_file() or digest(path) != item.get("sha256")):
            errors.append(f"negative probe {kind} identity drifted")
    if len(evidence.get("limitations", [])) < 3:
        errors.append("negative probe limitations are incomplete")
    return errors


def main() -> int:
    errors = validate(load(EVIDENCE))
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print("BH-01 Phase 3 retained negative probes: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
