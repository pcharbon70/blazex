#!/usr/bin/env python3
"""Validate Phase 7 resource ownership, stress, and convergence policy."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any


HERE = Path(__file__).resolve().parent
DOMAINS = {"runtime", "browser", "renderer", "transport", "server", "adapter"}
INTERRUPTIONS = {"startup", "dom-update", "timer", "validation", "server-command", "adapter-patch", "measurement", "shutdown"}


def load(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def validate(policy: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    if policy.get("status") != "proposed-feasibility-limits":
        errors.append("resource limits are promoted or inactive")
    if policy.get("stress_iterations", 0) < 20:
        errors.append("resource stress iteration floor is too small")
    if set(policy.get("required_domains", [])) != DOMAINS:
        errors.append("resource ownership domains are incomplete")
    if set(policy.get("interruption_points", [])) != INTERRUPTIONS:
        errors.append("lifecycle interruption matrix is incomplete")
    zero_paths = policy.get("zero_at_disposal", [])
    if len(zero_paths) != len(set(zero_paths)) or any(path.split(".")[0] not in DOMAINS for path in zero_paths):
        errors.append("zero-at-disposal paths are duplicated or ownerless")
    bounds = policy.get("bounded_during_stress", {})
    if any(not isinstance(value, int) or value < 0 for value in bounds.values()):
        errors.append("stress resource bounds are invalid")
    if not set(bounds).issubset(set(zero_paths)):
        errors.append("bounded transient resources lack disposal convergence")
    if "browser.workers" not in policy.get("unknown_observations", {}):
        errors.append("unavailable worker observation is not explicit")
    dispositions = set(policy.get("nonconvergence_dispositions", []))
    if not {"instrumentation-unavailable", "bounded-mitigation", "upstream-issue", "blocker"}.issubset(dispositions):
        errors.append("nonconverging resource dispositions are incomplete")
    if "passed production resource budget" not in policy.get("claims_not_made", []):
        errors.append("resource policy overclaims a passed production budget")
    return errors


def main() -> int:
    errors = validate(load(HERE / "resource-policy.json"))
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print("BH-01 Phase 7 resource policy: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
