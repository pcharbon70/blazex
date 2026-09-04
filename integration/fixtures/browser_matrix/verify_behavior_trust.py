#!/usr/bin/env python3
"""Verify Phase 8 behavior, trust, resilience, and cleanup observations."""

from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
MATRIX = HERE / "behavior-trust-matrix.json"
POLICY = HERE / "matrix-policy.json"
EVIDENCE_PATHS = {
    "chromium": ROOT / "integration/fixtures/raw-evidence/bh01-phase8-behavior-chromium.json",
    "firefox": ROOT / "integration/fixtures/raw-evidence/bh01-phase8-behavior-firefox-probe.json",
    "webkit": ROOT / "integration/fixtures/raw-evidence/bh01-phase8-behavior-webkit-probe.json",
}
COMMIT = re.compile(r"^[0-9a-f]{40}$")
EXPECTED_OUTCOMES = ["accepted", "replayed", "state-stale"]
EXPECTED_EFFECTS = [True, False, False]


def load(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def file_sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def evidence_self_hash(evidence: dict[str, Any]) -> str:
    keys = ("semantic_trace", "trust", "adapter", "resilience", "cleanup", "diagnostics")
    value = {key: evidence.get(key) for key in keys}
    payload = json.dumps(value, ensure_ascii=False, separators=(",", ":"))
    return hashlib.sha256(payload.encode()).hexdigest()


def validate(matrix: dict[str, Any], policy: dict[str, Any], evidence: dict[str, dict[str, Any]], file_hashes: dict[str, str]) -> list[str]:
    errors: list[str] = []
    if matrix.get("status") != "executed-partial-environment-blocked":
        errors.append("behavior matrix status is not truthful")
    if not COMMIT.fullmatch(matrix.get("source_revision", "")):
        errors.append("behavior matrix lacks an exact source revision")

    required = matrix.get("required_results", [])
    required_ids = [item.get("configuration_id") for item in required]
    if set(required_ids) != set(policy.get("required_configuration_ids", [])) or len(required_ids) != 5:
        errors.append("behavior matrix omits or duplicates a required row")
    passed = [item for item in required if item.get("status") == "passed"]
    blocked = [item for item in required if item.get("status") == "environment-blocked"]
    if [item.get("configuration_id") for item in passed] != ["BR-CHROMIUM-DESKTOP"] or len(blocked) != 4:
        errors.append("behavior required-row outcomes drifted")
    if any(item.get("semantic_equivalence") != "not-executed" for item in blocked):
        errors.append("blocked behavior row implies execution")
    if matrix.get("phase_effect") != "blocked-until-four-required-environments-execute":
        errors.append("missing behavior rows do not block Phase 8")

    probes = matrix.get("non_substituting_probe_results", [])
    if len(probes) != 2 or any(item.get("required_row_credit") is not False for item in probes):
        errors.append("engine behavior probe substitutes for required browser evidence")

    trace_hashes = {item.get("semantic_trace_sha256") for item in evidence.values()}
    if trace_hashes != {matrix.get("semantic_trace_sha256")}:
        errors.append("normalized semantic behavior diverged across executed environments")

    for browser_name, value in evidence.items():
        if value.get("status") != "observed" or value.get("support_status") != "unsupported":
            errors.append(f"{browser_name} behavior evidence overclaims its result")
        expected_authority = "required-row" if browser_name == "chromium" else "experimental-unqualified"
        if value.get("authority") != expected_authority:
            errors.append(f"{browser_name} behavior evidence authority drifted")
        trust = value.get("trust", {})
        expected_trust = {
            "stale": "state-stale",
            "denied": "authorization-denied",
            "disconnected": "transport-unavailable",
            "recovered": "ok",
            "authoritative_value_after_recovery": 1,
            "unauthorized_effects": 0,
            "client_role_trusted": False,
        }
        if any(trust.get(key) != expected for key, expected in expected_trust.items()):
            errors.append(f"{browser_name} trust outcome drifted")
        if trust.get("audit_outcomes") != EXPECTED_OUTCOMES or trust.get("audit_effects") != EXPECTED_EFFECTS:
            errors.append(f"{browser_name} server audit/effect trace drifted")
        if trust.get("exact_replay", {}).get("replayed") is not True or trust.get("forged") != {"http_status": 403, "code": "csrf-invalid"}:
            errors.append(f"{browser_name} replay or forgery boundary drifted")
        adapter = value.get("adapter", {})
        if adapter.get("activation") != "not-adopted" or adapter.get("standalone_dom") != "executed" or adapter.get("private_data_outside_adapter") is not False:
            errors.append(f"{browser_name} optional adapter isolation drifted")
        lifecycle = value.get("resilience", {}).get("lifecycle_iterations", [])
        if len(lifecycle) != 3 or any(item.get("dom") != {"roots": 0, "listeners": 0, "nodes": 0} or item.get("bridge_pending") != 0 or item.get("server_pending") != 0 for item in lifecycle):
            errors.append(f"{browser_name} lifecycle resources did not converge")
        if value.get("resilience", {}).get("oversized_boundary") != "bridge-payload-string-exceeded":
            errors.append(f"{browser_name} malformed boundary did not fail closed")
        if value.get("diagnostics") != {"count": 3, "correlated_transport_failure": True, "redaction": "passed", "console_only": 0}:
            errors.append(f"{browser_name} diagnostic contract drifted")
        if value.get("page_errors") != [] or value.get("evidence_sha256") != evidence_self_hash(value):
            errors.append(f"{browser_name} behavior evidence has browser errors or hash drift")

    declarations = [passed[0], *probes] if passed else probes
    for declaration in declarations:
        relative = declaration.get("evidence", "").removeprefix("../raw-evidence/")
        if declaration.get("evidence_sha256") != file_hashes.get(relative):
            errors.append(f"behavior evidence file hash drifted: {relative}")
    return errors


def inputs() -> tuple[Any, ...]:
    return (
        load(MATRIX), load(POLICY),
        {name: load(path) for name, path in EVIDENCE_PATHS.items()},
        {path.name: file_sha256(path) for path in EVIDENCE_PATHS.values()},
    )


def main() -> int:
    errors = validate(*inputs())
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print("BH-01 Phase 8 behavior/trust matrix: PASS (1 required row passed, 4 environment-blocked, 2 probes unqualified)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
