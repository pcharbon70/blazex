#!/usr/bin/env python3
"""Verify Phase 8 browser environment and scheduling governance."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker


ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
CATALOG = HERE / "environment-catalog.json"
POLICY = HERE / "matrix-policy.json"
ENVELOPE = ROOT / "docs/research/assets/browser-product-envelope-v0.1.json"
FINGERPRINT = ROOT / "integration/benchmarks/environments/bh01-phase8-local-linux.json"
FINGERPRINT_SCHEMA = ROOT / "integration/benchmarks/environment-fingerprint.schema.json"
SHA256_LENGTH = 64


def load(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def validate(catalog: dict[str, Any], policy: dict[str, Any], envelope: dict[str, Any], fingerprint: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    envelope_ids = {item["id"] for item in envelope.get("browser_configurations", [])}
    rows = catalog.get("required_rows", [])
    row_ids = [item.get("configuration_id") for item in rows]
    if len(rows) != 5 or set(row_ids) != envelope_ids or len(row_ids) != len(set(row_ids)):
        errors.append("environment catalog does not retain the five unique browser-envelope rows")
    if set(policy.get("required_configuration_ids", [])) != envelope_ids:
        errors.append("matrix policy required rows drifted from the browser envelope")
    if catalog.get("support_status") != "unsupported":
        errors.append("environment inventory promotes browser support")
    if policy.get("required_row_may_be_omitted") or policy.get("probe_may_substitute_required_row"):
        errors.append("matrix policy permits silent row reduction or probe substitution")
    if policy.get("environment_blocked_is_product_pass") or policy.get("environment_blocked_is_product_failure"):
        errors.append("environment-blocked is collapsed into a product outcome")
    schedule = policy.get("scheduling", {})
    if schedule.get("maximum_automatic_retries") != 0 or schedule.get("silent_retry_allowed") is not False:
        errors.append("matrix scheduling permits an unrecorded retry")
    if len(schedule.get("quarantine_requires", [])) != 5:
        errors.append("matrix quarantine is not review-bounded")

    available = [item for item in rows if item.get("availability") == "available"]
    blocked = [item for item in rows if item.get("availability") == "environment-blocked"]
    if [item.get("configuration_id") for item in available] != ["BR-CHROMIUM-DESKTOP"] or len(blocked) != 4:
        errors.append("local required-row availability is not truthful")
    for row in rows:
        if row.get("availability") == "environment-blocked" and not row.get("blocker"):
            errors.append(f"blocked row lacks a reason: {row.get('configuration_id')}")
        if row.get("availability") == "available":
            if any(not row.get(field) for field in ("product_version", "engine_version", "os_build", "architecture", "artifact_identity")):
                errors.append("available browser row lacks an exact fingerprint")
            if len(row.get("artifact_identity", "")) != SHA256_LENGTH:
                errors.append("available browser artifact identity is not a SHA-256")
    probes = catalog.get("non_substituting_probes", [])
    if len(probes) != 2 or any("experimental-unqualified" not in item.get("authority", "") for item in probes):
        errors.append("adjacent engine probes are absent or over-authoritative")
    if not any("not-safari" in item.get("authority", "") for item in probes):
        errors.append("Linux WebKit probe is not distinguished from Safari")
    gate = policy.get("phase_gate", {})
    if gate.get("missing_or_blocked_required_rows") != "blocked":
        errors.append("missing required environments do not block the phase gate")
    if fingerprint.get("browser", {}).get("required_row") != "BR-CHROMIUM-DESKTOP":
        errors.append("local fingerprint is not tied to the executable required row")
    return errors


def main() -> int:
    catalog, policy, envelope, fingerprint = map(load, (CATALOG, POLICY, ENVELOPE, FINGERPRINT))
    errors = validate(catalog, policy, envelope, fingerprint)
    errors.extend(
        f"fingerprint schema: {error.message}"
        for error in Draft202012Validator(load(FINGERPRINT_SCHEMA), format_checker=FormatChecker()).iter_errors(fingerprint)
    )
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print("BH-01 Phase 8 browser environment governance: PASS (1 available, 4 environment-blocked, 2 non-substituting probes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
