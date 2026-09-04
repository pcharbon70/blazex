#!/usr/bin/env python3
"""Verify Phase 8 automated fallback accessibility and input observations."""

from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
MATRIX = HERE / "accessibility-input-matrix.json"
POLICY = HERE / "matrix-policy.json"
EVIDENCE_PATHS = {
    "chromium": ROOT / "integration/fixtures/raw-evidence/bh01-phase8-accessibility-chromium.json",
    "firefox": ROOT / "integration/fixtures/raw-evidence/bh01-phase8-accessibility-firefox-probe.json",
    "webkit": ROOT / "integration/fixtures/raw-evidence/bh01-phase8-accessibility-webkit-probe.json",
}
COMMIT = re.compile(r"^[0-9a-f]{40}$")
FALLBACK_VALUES = {"static-content", "alternative-interaction", "in-app-substitute", "server-round-trip", "explicit-unavailability", "nonvisual-representation", "omission"}
TAB_PREFIX = ["bx-parent-action", "bx-child-alpha-action", "bx-child-beta-action", "bx-field", "bx-field-reset", "bx-server-action"]


def load(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def file_sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def evidence_self_hash(evidence: dict[str, Any]) -> str:
    keys = ("fallback", "keyboard_focus", "field_input", "user_preferences", "manual_evidence")
    value = {key: evidence.get(key) for key in keys}
    payload = json.dumps(value, ensure_ascii=False, separators=(",", ":"))
    return hashlib.sha256(payload.encode()).hexdigest()


def validate(matrix: dict[str, Any], policy: dict[str, Any], evidence: dict[str, dict[str, Any]], file_hashes: dict[str, str]) -> list[str]:
    errors: list[str] = []
    if matrix.get("status") != "executed-partial-environment-blocked-manual-review-required":
        errors.append("accessibility/input matrix status is not truthful")
    if not COMMIT.fullmatch(matrix.get("source_revision", "")):
        errors.append("accessibility/input matrix lacks an exact source revision")
    values = matrix.get("fallback_values", [])
    if {item.get("value") for item in values} != FALLBACK_VALUES or len(values) != 7:
        errors.append("fallback value matrix is incomplete")
    if {item.get("status") for item in values} - {"passed", "failed", "environment-blocked", "flaky", "not-applicable"}:
        errors.append("fallback value uses an ungoverned outcome")

    required = matrix.get("required_results", [])
    required_ids = [item.get("configuration_id") for item in required]
    if set(required_ids) != set(policy.get("required_configuration_ids", [])) or len(required_ids) != 5:
        errors.append("accessibility/input matrix omits or duplicates a required row")
    chromium = [item for item in required if item.get("configuration_id") == "BR-CHROMIUM-DESKTOP"]
    blocked = [item for item in required if item.get("status") == "environment-blocked"]
    if len(chromium) != 1 or chromium[0].get("status") != "automated-pass-manual-evidence-blocked" or len(blocked) != 4:
        errors.append("accessibility/input required-row outcomes drifted")
    probes = matrix.get("non_substituting_probe_results", [])
    if len(probes) != 2 or any(item.get("required_row_credit") is not False for item in probes):
        errors.append("accessibility engine probe substitutes for required evidence")
    if matrix.get("phase_effect") != "blocked-until-required-browser-and-assistive-technology-evidence-executes":
        errors.append("missing accessibility evidence does not block Phase 8")

    for browser_name, value in evidence.items():
        if value.get("status") != "observed" or value.get("support_status") != "unsupported":
            errors.append(f"{browser_name} accessibility evidence overclaims its result")
        expected_authority = "required-row" if browser_name == "chromium" else "experimental-unqualified"
        if value.get("authority") != expected_authority:
            errors.append(f"{browser_name} accessibility evidence authority drifted")
        keyboard = value.get("keyboard_focus", {})
        if keyboard.get("tab_order", [])[:6] != TAB_PREFIX or keyboard.get("field_before_reset") is not True or keyboard.get("keyboard_action") != "enter-activated-reset" or keyboard.get("focus_preserved_after_dom_update") is not True:
            errors.append(f"{browser_name} keyboard/focus contract drifted")
        focus = keyboard.get("focus_visible", {})
        if focus.get("matches") is not True or focus.get("outline_style") == "none":
            errors.append(f"{browser_name} visible focus observation failed")
        field = value.get("field_input", {})
        invalid = field.get("invalid_accessibility", {})
        if field.get("composition_like_sequence") != "passed" or field.get("rapid_input_final_value") != "Ada" or field.get("input_change_blur") != "passed":
            errors.append(f"{browser_name} field input semantics drifted")
        if invalid.get("accessible_name") != "Name" or invalid.get("invalid") != "true" or invalid.get("relationships") != {"described_by": "bx-field-help bx-field-error", "error_message": "bx-field-error"} or invalid.get("alert_count") != 1:
            errors.append(f"{browser_name} field accessibility semantics drifted")
        if field.get("disabled") != {"property": True, "event_rejection": "fixture-field-disabled"} or field.get("read_only") != {"property": True, "event_rejection": "fixture-field-read-only"}:
            errors.append(f"{browser_name} disabled/read-only behavior drifted")

        for name in ("capability_unavailable", "unsupported_browser"):
            observed = value.get("fallback", {}).get(name, {})
            candidate = observed.get("before_retry", observed)
            if candidate.get("state") != "fallback" or candidate.get("runtime_ready") is not False or candidate.get("status_role") != "status" or candidate.get("status_live") != "polite" or candidate.get("retry_visible") is not True or candidate.get("diagnostic_code") is None or candidate.get("correlation_id") != "prerequisite-check" or candidate.get("fixture_children") != 0:
                errors.append(f"{browser_name} accessible {name} fallback drifted")
        no_js = value.get("fallback", {}).get("no_javascript", {})
        if no_js.get("partial_activation") is not False or no_js.get("retry_hidden") is not True or "requires JavaScript" not in no_js.get("noscript_text", ""):
            errors.append(f"{browser_name} no-JavaScript fallback drifted")
        for name in ("reduced_motion", "forced_colors"):
            preference = value.get("user_preferences", {}).get(name, {})
            if preference.get("active") is not True or preference.get("state") != "ready" or preference.get("outline_style") == "none":
                errors.append(f"{browser_name} {name} observation drifted")
        manual = value.get("manual_evidence", {})
        if manual.get("assistive_technology") != "not-executed-environment-unavailable":
            errors.append(f"{browser_name} falsely claims assistive-technology evidence")
        if value.get("page_errors") != [] or value.get("evidence_sha256") != evidence_self_hash(value):
            errors.append(f"{browser_name} accessibility evidence has browser errors or hash drift")

    declarations = [chromium[0], *probes] if chromium else probes
    for declaration in declarations:
        relative = declaration.get("evidence", "").removeprefix("../raw-evidence/")
        if declaration.get("evidence_sha256") != file_hashes.get(relative):
            errors.append(f"accessibility evidence file hash drifted: {relative}")
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
    print("BH-01 Phase 8 accessibility/input matrix: PASS (automation passed; required browser and AT evidence remains blocked)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
