#!/usr/bin/env python3
"""Validate Phase 7 diagnostics, redaction, and failure-observability policy."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any


HERE = Path(__file__).resolve().parent


def load(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def validate(contract: dict[str, Any], taxonomy: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    if contract.get("status") != "phase7-fixture-contract" or contract.get("protocol") != "blazex.bh01.diagnostic/0.1":
        errors.append("diagnostic contract identity/status drifted")
    required_identity = set(contract.get("required_identity", []))
    if required_identity != {"scenario_id", "generation", "correlation_id", "sequence", "source", "clock_id"}:
        errors.append("diagnostic correlation identity is incomplete")
    categories = contract.get("categories", {})
    required_categories = {item.get("diagnostic_category") for item in taxonomy.get("failures", [])}
    if set(categories) != required_categories:
        errors.append("diagnostic categories do not cover the failure taxonomy")
    for category, value in categories.items():
        if not value.get("owner") or value.get("severity") not in contract.get("severities", []) or not value.get("user_message"):
            errors.append(f"diagnostic category is incomplete: {category}")
    fragments = set(contract.get("redacted_key_fragments", []))
    if not {"authorization", "cookie", "credential", "csrf", "password", "query", "secret", "session", "stack", "token"}.issubset(fragments):
        errors.append("diagnostic redaction classes are incomplete")
    retention = contract.get("retention", {})
    if retention.get("in_memory_events") != 256 or retention.get("duplicate_policy") != "drop-identical-and-count":
        errors.append("diagnostic retention/deduplication is unbounded")
    observability = contract.get("failure_observability", {})
    if any(observability.get(key) is not False for key in ("console_only_allowed", "uncaught_allowed", "orphan_correlation_allowed")):
        errors.append("diagnostics permit silent, uncaught, or orphan failures")
    if observability.get("server_audit_required_for_authority") is not True or observability.get("cleanup_evidence_required") is not True:
        errors.append("authority audit or cleanup evidence is optional")
    if "production telemetry API" not in contract.get("claims_not_made", []):
        errors.append("fixture diagnostics are promoted to a production API")
    return errors


def inputs() -> tuple[dict[str, Any], dict[str, Any]]:
    return load(HERE / "diagnostic-contract.json"), load(HERE / "failure-taxonomy.json")


def main() -> int:
    errors = validate(*inputs())
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print("BH-01 Phase 7 diagnostic and observability contract: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
