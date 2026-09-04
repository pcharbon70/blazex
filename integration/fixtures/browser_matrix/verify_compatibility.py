#!/usr/bin/env python3
"""Verify Phase 8 exact-pin compatibility and mismatch evidence."""

from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
MATRIX = HERE / "compatibility-matrix.json"
POLICY = HERE / "matrix-policy.json"
PRIVATE_API = ROOT / "profiles/browser_phoenix/toolchain/private-api-inventory.json"
EVIDENCE_PATHS = {
    "chromium": ROOT / "integration/fixtures/raw-evidence/bh01-phase8-compatibility-chromium.json",
    "firefox": ROOT / "integration/fixtures/raw-evidence/bh01-phase8-compatibility-firefox-probe.json",
    "webkit": ROOT / "integration/fixtures/raw-evidence/bh01-phase8-compatibility-webkit-probe.json",
}
COMMIT = re.compile(r"^[0-9a-f]{40}$")
CATEGORIES = {"runtime-bundle", "loader-manifest", "artifact-cache", "browser-feature", "phoenix-liveview-local-liveview", "renderer-data", "server-client-generation"}


def load(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def file_sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def evidence_self_hash(evidence: dict[str, Any]) -> str:
    keys = ("exact_baseline", "mismatch_scenarios", "retained_server_adapter_evidence", "cache_and_rollback")
    value = {key: evidence.get(key) for key in keys}
    payload = json.dumps(value, ensure_ascii=False, separators=(",", ":"))
    return hashlib.sha256(payload.encode()).hexdigest()


def validate(matrix: dict[str, Any], policy: dict[str, Any], private_api: dict[str, Any], evidence: dict[str, dict[str, Any]], file_hashes: dict[str, str]) -> list[str]:
    errors: list[str] = []
    if matrix.get("status") != "executed-partial-environment-blocked-exact-pins-only":
        errors.append("compatibility matrix status is not truthful")
    if not COMMIT.fullmatch(matrix.get("source_revision", "")):
        errors.append("compatibility matrix lacks an exact source revision")
    coverage = matrix.get("mismatch_coverage", [])
    if {item.get("category") for item in coverage} != CATEGORIES or len(coverage) != 7:
        errors.append("compatibility mismatch coverage is incomplete")

    required = matrix.get("required_results", [])
    required_ids = [item.get("configuration_id") for item in required]
    if set(required_ids) != set(policy.get("required_configuration_ids", [])) or len(required_ids) != 5:
        errors.append("compatibility matrix omits or duplicates a required row")
    passed = [item for item in required if item.get("status") == "passed"]
    blocked = [item for item in required if item.get("status") == "environment-blocked"]
    if [item.get("configuration_id") for item in passed] != ["BR-CHROMIUM-DESKTOP"] or passed[0].get("compatibility_scope") != "exact-pins-only" or len(blocked) != 4:
        errors.append("compatibility required-row outcomes drifted")
    probes = matrix.get("non_substituting_probe_results", [])
    if len(probes) != 2 or any(item.get("required_row_credit") is not False for item in probes):
        errors.append("compatibility engine probe substitutes for required evidence")
    adjacent = matrix.get("adjacent_dependency_probes", [])
    if {item.get("dependency") for item in adjacent} != {"phoenix", "phoenix_live_view", "local_live_view"} or any(item.get("installed_and_executed") is not False or item.get("compatibility_credit") is not False for item in adjacent):
        errors.append("adjacent dependency probe overclaims package execution or compatibility")

    phase8 = private_api.get("phase8_compatibility", {})
    if phase8.get("authoritative_versions") != {"phoenix": "1.8.13", "phoenix_live_view": "1.2.11", "local_live_view": "0.1.0"}:
        errors.append("private API authoritative pins drifted")
    if phase8.get("fallback_success") != "standalone-dom" or phase8.get("actual_adjacent_package_probe") != "not-executed-no-locally-available-input":
        errors.append("private API fallback or adjacent-package boundary drifted")
    if len(private_api.get("entries", [])) != 8 or any(item.get("pin_sensitivity") != "high" for item in private_api.get("entries", [])):
        errors.append("private API entry inventory drifted")

    for browser_name, value in evidence.items():
        if value.get("status") != "observed" or value.get("support_status") != "unsupported":
            errors.append(f"{browser_name} compatibility evidence overclaims its result")
        expected_authority = "required-row" if browser_name == "chromium" else "experimental-unqualified"
        if value.get("authority") != expected_authority:
            errors.append(f"{browser_name} compatibility authority drifted")
        baseline = value.get("exact_baseline", {})
        if baseline.get("state") != "ready" or baseline.get("manifest_id") != "BX-BH01-BROWSER-RUNTIME-MANIFEST-0.1" or baseline.get("manifest_cache_control") != "no-store":
            errors.append(f"{browser_name} exact baseline drifted")
        if baseline.get("profile_manifest_sha256") != policy.get("artifact_policy", {}).get("profile_manifest_sha256"):
            errors.append(f"{browser_name} compatibility profile identity drifted")
        scenarios = value.get("mismatch_scenarios", {})
        for name, code in (("loader_manifest", "manifest-schema-unsupported"), ("runtime_bundle", "artifact-integrity-mismatch"), ("artifact_cache", "artifact-integrity-mismatch")):
            item = scenarios.get(name, {})
            if item.get("code") != code or item.get("detected_before_runtime_ready") is not True or item.get("partial_activation") is not False or item.get("retry_visible") is not True:
                errors.append(f"{browser_name} {name} did not fail closed")
        feature = scenarios.get("browser_feature", {})
        if feature.get("state") != "fallback" or feature.get("code") != "browser-capability-missing" or feature.get("partial_activation") is not False:
            errors.append(f"{browser_name} browser feature mismatch drifted")
        renderer = scenarios.get("renderer_data", {})
        if renderer.get("code") != "fixture-target-missing" or renderer.get("stale_generation") != "fixture-generation-stale" or renderer.get("partial_text_after_failure") != "before" or renderer.get("final_roots") != 0:
            errors.append(f"{browser_name} renderer-data fail-closed behavior drifted")
        generation = scenarios.get("server_client_generation", {})
        if generation != {"code": "bridge-response-identity-mismatch", "failures": 1, "responses": 0, "pending": 0, "partial_activation": False}:
            errors.append(f"{browser_name} server/client generation boundary drifted")
        rollback = value.get("cache_and_rollback", {})
        if rollback.get("fresh_baseline_after_mismatches") is not True or rollback.get("hidden_semantic_change") is not False or rollback.get("scoped_client_cache_owner") != "none":
            errors.append(f"{browser_name} rollback/cache boundary drifted")
        adapter = value.get("retained_server_adapter_evidence", {})
        if adapter.get("adapter_disable") != "standalone-dom" or adapter.get("private_data_confinement") != "packages/blazex_renderer_dom_liveview":
            errors.append(f"{browser_name} adapter confinement drifted")
        if value.get("page_errors") != [] or value.get("evidence_sha256") != evidence_self_hash(value):
            errors.append(f"{browser_name} compatibility evidence has browser errors or hash drift")

    declarations = [passed[0], *probes] if passed else probes
    for declaration in declarations:
        relative = declaration.get("evidence", "").removeprefix("../raw-evidence/")
        if declaration.get("evidence_sha256") != file_hashes.get(relative):
            errors.append(f"compatibility evidence file hash drifted: {relative}")
    if matrix.get("phase_effect") != "blocked-until-four-required-browser-environments-execute":
        errors.append("missing compatibility rows do not block Phase 8")
    return errors


def inputs() -> tuple[Any, ...]:
    return (
        load(MATRIX), load(POLICY), load(PRIVATE_API),
        {name: load(path) for name, path in EVIDENCE_PATHS.items()},
        {path.name: file_sha256(path) for path in EVIDENCE_PATHS.values()},
    )


def main() -> int:
    errors = validate(*inputs())
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print("BH-01 Phase 8 compatibility matrix: PASS (exact pins only; 4 required rows environment-blocked; adjacent packages untested)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
