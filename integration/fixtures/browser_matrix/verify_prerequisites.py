#!/usr/bin/env python3
"""Verify Phase 8 prerequisite observations and fail-closed outcomes."""

from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
MATRIX = HERE / "prerequisite-matrix.json"
CATALOG = HERE / "environment-catalog.json"
POLICY = HERE / "matrix-policy.json"
EVIDENCE_PATHS = {
    "chromium": ROOT / "integration/fixtures/raw-evidence/bh01-phase8-prerequisites-chromium.json",
    "firefox": ROOT / "integration/fixtures/raw-evidence/bh01-phase8-prerequisites-firefox-probe.json",
    "webkit": ROOT / "integration/fixtures/raw-evidence/bh01-phase8-prerequisites-webkit-probe.json",
}
COMMIT = re.compile(r"^[0-9a-f]{40}$")
EXPECTED_NEGATIVE = [
    ("webassembly", "fallback", "static-server-fallback", False),
    ("workers", "fallback", "static-server-fallback", False),
    ("streaming", "ready", "alternate-loading", True),
    ("cross-origin-isolation", "fallback", "unsupported", False),
]


def load(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def file_sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def evidence_self_hash(evidence: dict[str, Any]) -> str:
    value = {key: evidence.get(key) for key in ("profile", "capabilities", "deployment", "initial", "negative_scenarios", "lifecycle_changes")}
    return hashlib.sha256(json.dumps(value, ensure_ascii=False, separators=(",", ":")).encode()).hexdigest()


def validate(matrix: dict[str, Any], catalog: dict[str, Any], policy: dict[str, Any], evidence: dict[str, dict[str, Any]], file_hashes: dict[str, str]) -> list[str]:
    errors: list[str] = []
    if matrix.get("status") != "executed-partial-environment-blocked":
        errors.append("prerequisite matrix status is not truthful")
    if not COMMIT.fullmatch(matrix.get("source_revision", "")):
        errors.append("prerequisite matrix lacks an exact source revision")
    required = matrix.get("required_results", [])
    required_ids = [item.get("configuration_id") for item in required]
    if set(required_ids) != set(policy.get("required_configuration_ids", [])) or len(required_ids) != 5:
        errors.append("prerequisite matrix omits or duplicates a required row")
    passed = [item for item in required if item.get("status") == "passed"]
    blocked = [item for item in required if item.get("status") == "environment-blocked"]
    if [item.get("configuration_id") for item in passed] != ["BR-CHROMIUM-DESKTOP"] or len(blocked) != 4:
        errors.append("prerequisite required-row outcomes drifted")
    if any(item.get("activation") != "not-executed" or item.get("partial_activation") is not False for item in blocked):
        errors.append("blocked prerequisite row implies partial execution")
    if matrix.get("phase_effect") != "blocked-until-four-required-environments-execute":
        errors.append("missing prerequisite rows do not block Phase 8")

    probes = matrix.get("non_substituting_probe_results", [])
    if len(probes) != 2 or any(item.get("required_row_credit") is not False for item in probes):
        errors.append("engine probe substitutes for required browser evidence")
    catalog_probes = {item.get("probe_id") for item in catalog.get("non_substituting_probes", [])}
    if {item.get("probe_id") for item in probes} != catalog_probes:
        errors.append("prerequisite probe inventory drifted")

    for browser_name, value in evidence.items():
        if value.get("profile", {}).get("manifest_sha256") != policy.get("artifact_policy", {}).get("profile_manifest_sha256"):
            errors.append(f"{browser_name} prerequisite profile identity drifted")
        if value.get("status") != "observed" or value.get("support_status") != "unsupported":
            errors.append(f"{browser_name} prerequisite evidence overclaims its result")
        expected_authority = "required-row" if browser_name == "chromium" else "experimental-unqualified"
        if value.get("authority") != expected_authority:
            errors.append(f"{browser_name} evidence authority drifted")
        if value.get("initial", {}).get("state") != "ready" or value.get("initial", {}).get("prerequisites", {}).get("decision") != "proceed":
            errors.append(f"{browser_name} did not reach prerequisite readiness")
        capabilities = value.get("capabilities", {})
        expected_capabilities = {"webassembly_validate", "memory", "table", "shared_memory", "workers", "modules", "streaming", "buffered", "structured_clone", "transferable_array_buffer", "timers", "secure_context", "cross_origin_isolated"}
        if set(capabilities) != expected_capabilities or any(item is not True for item in capabilities.values()):
            errors.append(f"{browser_name} capability probe is incomplete")
        observed_negative = [(item.get("name"), item.get("state"), item.get("prerequisites", {}).get("decision"), item.get("runtime_ready")) for item in value.get("negative_scenarios", [])]
        if observed_negative != EXPECTED_NEGATIVE:
            errors.append(f"{browser_name} prerequisite fallback matrix drifted")
        deployment = value.get("deployment", {})
        if deployment.get("wasm_mime") != "application/wasm" or deployment.get("wasm_redirected") is not False or deployment.get("cors") is not None:
            errors.append(f"{browser_name} deployment artifact policy drifted")
        lifecycle = value.get("lifecycle_changes", {})
        if lifecycle.get("offline") != "network-unavailable" or lifecycle.get("online_status") != 200:
            errors.append(f"{browser_name} offline/online transition drifted")
        if lifecycle.get("disposed", {}).get("dom") != {"roots": 0, "listeners": 0, "nodes": 0} or lifecycle.get("disposed", {}).get("bridge", {}).get("pending") != 0:
            errors.append(f"{browser_name} post-readiness disposal retained resources")
        if value.get("page_errors") != [] or value.get("evidence_sha256") != evidence_self_hash(value):
            errors.append(f"{browser_name} prerequisite evidence has browser errors or hash drift")

    declarations = [passed[0], *probes] if passed else probes
    for declaration in declarations:
        relative = declaration.get("evidence", "").removeprefix("../raw-evidence/")
        if declaration.get("evidence_sha256") != file_hashes.get(relative):
            errors.append(f"prerequisite evidence file hash drifted: {relative}")
    return errors


def inputs() -> tuple[Any, ...]:
    return (
        load(MATRIX), load(CATALOG), load(POLICY),
        {name: load(path) for name, path in EVIDENCE_PATHS.items()},
        {path.name: file_sha256(path) for path in EVIDENCE_PATHS.values()},
    )


def main() -> int:
    errors = validate(*inputs())
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print("BH-01 Phase 8 prerequisite matrix: PASS (1 required row passed, 4 environment-blocked, 2 probes unqualified)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
