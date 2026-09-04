#!/usr/bin/env python3
"""Validate the BH-01 Phase 7 failure taxonomy and coordinated recovery policy."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any


HERE = Path(__file__).resolve().parent
EXPECTED_LAYERS = {
    "acquisition-build", "artifact", "network-cache", "prerequisite", "loader",
    "wasm", "runtime", "bridge", "dom", "optional-adapter", "server-transport",
    "authentication", "authorization", "server-state", "server", "cleanup",
}


def load(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def validate(taxonomy: dict[str, Any], policy: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    failures = taxonomy.get("failures", [])
    required = set(taxonomy.get("required_fields", []))
    ids = [item.get("id") for item in failures]
    if taxonomy.get("status") != "phase7-policy" or policy.get("status") != "phase7-policy":
        errors.append("Phase 7 failure/recovery policy is not active")
    if len(ids) != len(set(ids)) or None in ids:
        errors.append("failure identities are missing or duplicated")
    if {item.get("layer") for item in failures} != EXPECTED_LAYERS:
        errors.append("cross-layer failure taxonomy coverage drifted")
    for failure in failures:
        missing = required - set(failure)
        if missing:
            errors.append(f"failure {failure.get('id')} lacks fields: {sorted(missing)}")
        if not failure.get("owner") or not failure.get("cleanup_owner"):
            errors.append(f"failure {failure.get('id')} lacks one owning boundary")
        if failure.get("retryable") is True and failure.get("retry_owner") != policy.get("coordinator"):
            errors.append(f"retryable failure {failure.get('id')} has a contradictory retry owner")
        if failure.get("retryable") is False and failure.get("retry_owner") is not None:
            errors.append(f"terminal failure {failure.get('id')} declares a retry owner")
        if not failure.get("terminal_outcome") or not failure.get("diagnostic_category"):
            errors.append(f"failure {failure.get('id')} has no terminal/diagnostic outcome")
        if not failure.get("requirement_refs") or not failure.get("stop_rule"):
            errors.append(f"failure {failure.get('id')} lacks risk/proof or stop linkage")

    authority = policy.get("authority_bearing", {})
    if authority.get("retry_owner") != policy.get("coordinator"):
        errors.append("authority-bearing retry owner is not the shared coordinator")
    if authority.get("preserve_idempotency_key") is not True or authority.get("lower_layer_automatic_retry") is not False:
        errors.append("authority-bearing retry amplification is not prohibited")
    if policy.get("max_attempts_per_correlation") != 2 or policy.get("backoff_ms") != [100, 250]:
        errors.append("recovery attempt/backoff budget drifted")
    generation = policy.get("generation", {})
    if generation.get("replacement_cancels_inflight") is not True or generation.get("stale_result") != "drop":
        errors.append("generation replacement does not cancel and drop stale work")
    convergence = policy.get("convergence", {})
    if convergence.get("pending_after_terminal") != 0 or convergence.get("inflight_per_correlation") != 1:
        errors.append("terminal recovery convergence is unbounded")
    if policy.get("reconnect", {}).get("hidden_fallback") is not False:
        errors.append("recovery policy permits hidden fallback")
    return errors


def inputs() -> tuple[dict[str, Any], dict[str, Any]]:
    return load(HERE / "failure-taxonomy.json"), load(HERE / "recovery-policy.json")


def main() -> int:
    errors = validate(*inputs())
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print("BH-01 Phase 7 failure and recovery model: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
