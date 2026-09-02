#!/usr/bin/env python3
"""Validate the machine-readable BH-00 browser product envelope."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parent
CONTRACT_PATH = ROOT / "assets" / "browser-product-envelope-v0.1.json"
STAGES = ("section-2.1", "section-2.2", "section-2.3", "complete")

BROWSER_STATUSES = {
    "BS-UNSUPPORTED": "unsupported",
    "BS-BEST-EFFORT": "best-effort",
    "BS-PREVIEW": "preview",
    "BS-SUPPORTED": "supported",
}
BROWSER_CONFIGURATIONS = {
    "BR-CHROMIUM-DESKTOP",
    "BR-CHROMIUM-ANDROID",
    "BR-FIREFOX-DESKTOP",
    "BR-WEBKIT-DESKTOP",
    "BR-WEBKIT-MOBILE",
}
EVIDENCE_CLASSES = {
    "EC-DESKTOP",
    "EC-MOBILE",
    "EC-MEMORY",
    "EC-CPU",
    "EC-NETWORK",
    "EC-INPUT",
    "EC-ZOOM",
    "EC-CONTRAST",
    "EC-DIRECTION",
    "EC-ASSISTIVE-TECH",
}
TOOLCHAIN_STATUSES = {
    "TS-CANDIDATE": "candidate",
    "TS-PINNED": "pinned",
    "TS-TESTED": "tested",
    "TS-SUPPORTED": "supported",
    "TS-DEPRECATED": "deprecated",
    "TS-BLOCKED": "blocked",
}
TOOLCHAIN_INPUTS = {
    "TC-PHOENIX",
    "TC-LIVEVIEW",
    "TC-LOCAL-LIVEVIEW",
    "TC-POPCORN",
    "TC-ATOMVM",
    "TC-ELIXIR",
    "TC-OTP",
    "TC-MIX",
    "TC-JS-TOOLING",
    "TC-BROWSER",
    "TC-OPERATING-SYSTEM",
}
BH01_RECORDS = {
    "REC-LOCKS",
    "REC-ARTIFACTS",
    "REC-PROVENANCE",
    "REC-REBUILD",
    "REC-SECURITY",
    "REC-SUPPORT-MATRIX",
}
RENDERING_MODES = {
    "MODE-STATIC-FALLBACK",
    "MODE-SERVER-RENDERED",
    "MODE-PRERENDERED",
    "MODE-BROWSER-LOCAL",
    "MODE-ACTIVATED",
    "MODE-HEADLESS",
}
PROFILE_CAPABILITY_STATUSES = {
    "PCS-REQUIRED": "required",
    "PCS-CONDITIONAL": "conditional",
    "PCS-HOST-PROVIDED": "host-provided",
    "PCS-TEST-DOUBLE": "test-double",
    "PCS-ABSENT": "absent",
    "PCS-NOT-APPLICABLE": "not-applicable",
}
PROFILES = {
    "PROFILE-BROWSER-PHOENIX",
    "PROFILE-BROWSER-PLUG",
    "PROFILE-HEADLESS",
}
ADAPTERS = {
    "ADAPTER-PHOENIX-SERVER",
    "ADAPTER-PLUG-SERVER",
    "ADAPTER-LIVEVIEW-DOM",
}
PROFILE_CAPABILITIES = {
    "CAP-STATIC-DELIVERY",
    "CAP-BOOTSTRAP",
    "CAP-SESSIONS",
    "CAP-CSRF",
    "CAP-TYPED-COMMANDS",
    "CAP-PUSHES",
    "CAP-REALTIME",
    "CAP-UPLOADS",
    "CAP-NAVIGATION",
    "CAP-PRERENDER",
    "CAP-ACTIVATION",
    "CAP-TELEMETRY",
}
PLUG_ABSENT_CAPABILITIES = {
    "CAP-PUSHES",
    "CAP-REALTIME",
    "CAP-UPLOADS",
    "CAP-PRERENDER",
    "CAP-ACTIVATION",
}
PLUG_TRANSITIVE_EXCLUSIONS = {
    "blazex_phoenix",
    "blazex_renderer_dom_liveview",
    "phoenix-or-liveview-package-or-application",
    "local-live-view-package-or-application",
}


def load_contract(path: Path = CONTRACT_PATH) -> dict[str, Any]:
    """Load the contract as a JSON object."""

    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise ValueError("contract root must be an object")
    return data


def require_keys(
    record: dict[str, Any], required: set[str], context: str, errors: list[str]
) -> None:
    """Require keys on a record and append stable diagnostics."""

    missing = sorted(required - set(record))
    if missing:
        errors.append(f"{context}: missing fields: {', '.join(missing)}")


def indexed_records(
    contract: dict[str, Any], key: str, errors: list[str]
) -> dict[str, dict[str, Any]]:
    """Return one record list indexed by unique ID."""

    raw_records = contract.get(key)
    if not isinstance(raw_records, list):
        errors.append(f"{key}: must be an array")
        return {}

    indexed: dict[str, dict[str, Any]] = {}
    for position, raw_record in enumerate(raw_records):
        context = f"{key}[{position}]"
        if not isinstance(raw_record, dict):
            errors.append(f"{context}: must be an object")
            continue
        record_id = raw_record.get("id")
        if not isinstance(record_id, str) or not record_id:
            errors.append(f"{context}: id must be a non-empty string")
            continue
        if record_id in indexed:
            errors.append(f"{key}: duplicate id {record_id}")
            continue
        indexed[record_id] = raw_record
    return indexed


def require_exact_ids(
    actual: set[str], expected: set[str], context: str, errors: list[str]
) -> None:
    """Require a complete, non-extra ID set."""

    missing = sorted(expected - actual)
    extra = sorted(actual - expected)
    if missing:
        errors.append(f"{context}: missing ids: {', '.join(missing)}")
    if extra:
        errors.append(f"{context}: unexpected ids: {', '.join(extra)}")


def validate_section_2_1(contract: dict[str, Any], errors: list[str]) -> None:
    """Validate browser and toolchain support-policy records."""

    browser_statuses = indexed_records(
        contract, "browser_status_vocabulary", errors
    )
    require_exact_ids(
        set(browser_statuses), set(BROWSER_STATUSES), "browser statuses", errors
    )
    for record_id, expected_status in BROWSER_STATUSES.items():
        record = browser_statuses.get(record_id)
        if not record:
            continue
        require_keys(record, {"id", "status", "binding", "promotion_evidence"}, record_id, errors)
        if record.get("status") != expected_status:
            errors.append(f"{record_id}: status must be {expected_status}")
        if not isinstance(record.get("promotion_evidence"), list):
            errors.append(f"{record_id}: promotion_evidence must be an array")

    browsers = indexed_records(contract, "browser_configurations", errors)
    require_exact_ids(
        set(browsers), BROWSER_CONFIGURATIONS, "browser configurations", errors
    )
    browser_required = {
        "id",
        "family",
        "products",
        "channel_policy",
        "minimum_rule",
        "device_classes",
        "operating_system_classes",
        "current_status",
        "status_reason",
        "earliest_target_status",
        "review_cadence",
        "bh01_evidence",
    }
    for record_id, record in browsers.items():
        require_keys(record, browser_required, record_id, errors)
        if record.get("channel_policy") != "stable-only":
            errors.append(f"{record_id}: only stable-only is in the candidate envelope")
        if record.get("current_status") != "unsupported":
            errors.append(f"{record_id}: must remain unsupported before BH-01 evidence")
        if record.get("status_reason") != "unproven-before-bh-01":
            errors.append(f"{record_id}: must record the unproven BH-01 reason")
        if record.get("earliest_target_status") != "preview":
            errors.append(f"{record_id}: earliest target must be preview")
        for field in (
            "products",
            "device_classes",
            "operating_system_classes",
            "review_cadence",
            "bh01_evidence",
        ):
            value = record.get(field)
            if not isinstance(value, list) or not value:
                errors.append(f"{record_id}: {field} must be a non-empty array")

    evidence = indexed_records(contract, "evidence_classes", errors)
    require_exact_ids(set(evidence), EVIDENCE_CLASSES, "evidence classes", errors)
    for record_id, record in evidence.items():
        require_keys(record, {"id", "name", "dimensions", "required_for"}, record_id, errors)
        if not isinstance(record.get("dimensions"), list) or not record.get("dimensions"):
            errors.append(f"{record_id}: dimensions must be a non-empty array")
        required_for = record.get("required_for")
        if not isinstance(required_for, list) or "supported" not in required_for:
            errors.append(f"{record_id}: supported must require this evidence class")

    toolchain_statuses = indexed_records(
        contract, "toolchain_status_vocabulary", errors
    )
    require_exact_ids(
        set(toolchain_statuses),
        set(TOOLCHAIN_STATUSES),
        "toolchain statuses",
        errors,
    )
    for record_id, expected_status in TOOLCHAIN_STATUSES.items():
        record = toolchain_statuses.get(record_id)
        if not record:
            continue
        require_keys(record, {"id", "status", "meaning"}, record_id, errors)
        if record.get("status") != expected_status:
            errors.append(f"{record_id}: status must be {expected_status}")

    toolchains = indexed_records(contract, "toolchain_inputs", errors)
    require_exact_ids(set(toolchains), TOOLCHAIN_INPUTS, "toolchain inputs", errors)
    for record_id, record in toolchains.items():
        require_keys(
            record,
            {"id", "layer", "current_state", "private_api_risk", "bh01_resolution"},
            record_id,
            errors,
        )
        if record.get("current_state") != "candidate":
            errors.append(f"{record_id}: must remain candidate before BH-01")
        if not isinstance(record.get("bh01_resolution"), list) or not record.get("bh01_resolution"):
            errors.append(f"{record_id}: bh01_resolution must be a non-empty array")

    required_records = indexed_records(contract, "bh01_required_records", errors)
    require_exact_ids(set(required_records), BH01_RECORDS, "BH-01 records", errors)
    for record_id, record in required_records.items():
        require_keys(record, {"id", "name", "required_for"}, record_id, errors)
        if not isinstance(record.get("required_for"), list) or not record.get("required_for"):
            errors.append(f"{record_id}: required_for must be a non-empty array")

    unresolved = contract.get("unresolved_bh01_inputs")
    if not isinstance(unresolved, list) or not unresolved:
        errors.append("unresolved_bh01_inputs: must be a non-empty array")


def validate_section_2_2(contract: dict[str, Any], errors: list[str]) -> None:
    """Validate rendering, profile, adapter, and capability records."""

    modes = indexed_records(contract, "rendering_modes", errors)
    require_exact_ids(set(modes), RENDERING_MODES, "rendering modes", errors)
    mode_required = {
        "id",
        "name",
        "logic_location",
        "surface_owner",
        "pre_activation_output",
        "identity",
        "public_state",
        "effects",
        "event_owner",
        "focus",
        "accessibility",
        "mismatch",
        "replacement",
        "disposal",
        "bh00_status",
        "browser_1_0_disposition",
        "evidence_gate",
    }
    allowed_dispositions = {"committed", "conditional", "conformance-only"}
    for record_id, record in modes.items():
        require_keys(record, mode_required, record_id, errors)
        if record.get("bh00_status") != "defined":
            errors.append(f"{record_id}: bh00_status must be defined")
        if record.get("browser_1_0_disposition") not in allowed_dispositions:
            errors.append(f"{record_id}: invalid browser_1_0_disposition")
        for field in mode_required - {"id"}:
            if not isinstance(record.get(field), str) or not record.get(field):
                errors.append(f"{record_id}: {field} must be a non-empty string")

    capability_statuses = indexed_records(
        contract, "profile_capability_status_vocabulary", errors
    )
    require_exact_ids(
        set(capability_statuses),
        set(PROFILE_CAPABILITY_STATUSES),
        "profile capability statuses",
        errors,
    )
    for record_id, expected_status in PROFILE_CAPABILITY_STATUSES.items():
        record = capability_statuses.get(record_id)
        if not record:
            continue
        require_keys(record, {"id", "status", "meaning"}, record_id, errors)
        if record.get("status") != expected_status:
            errors.append(f"{record_id}: status must be {expected_status}")

    profiles = indexed_records(contract, "profiles", errors)
    require_exact_ids(set(profiles), PROFILES, "profiles", errors)
    profile_required = {
        "id",
        "runtime",
        "execution_host",
        "renderer",
        "capability_provider",
        "server_adapter",
        "shell",
        "evidence_state",
        "optional_adapters",
        "forbidden_dependencies",
    }
    for record_id, record in profiles.items():
        require_keys(record, profile_required, record_id, errors)
        if record.get("evidence_state") != "planned-unproven":
            errors.append(f"{record_id}: evidence_state must be planned-unproven")
        if not isinstance(record.get("optional_adapters"), list):
            errors.append(f"{record_id}: optional_adapters must be an array")
        forbidden = record.get("forbidden_dependencies")
        if not isinstance(forbidden, list) or not forbidden:
            errors.append(f"{record_id}: forbidden_dependencies must be non-empty")

    plug = profiles.get("PROFILE-BROWSER-PLUG", {})
    if plug.get("renderer") != "standalone-dom":
        errors.append("PROFILE-BROWSER-PLUG: renderer must be standalone-dom")
    if plug.get("optional_adapters"):
        errors.append("PROFILE-BROWSER-PLUG: optional_adapters must remain empty")
    phoenix = profiles.get("PROFILE-BROWSER-PHOENIX", {})
    if phoenix.get("execution_host") != "browser":
        errors.append("PROFILE-BROWSER-PHOENIX: browser must remain execution host")

    adapters = indexed_records(contract, "adapters", errors)
    require_exact_ids(set(adapters), ADAPTERS, "adapters", errors)
    for record_id, record in adapters.items():
        require_keys(
            record,
            {"id", "category", "profiles", "owns", "must_not_own"},
            record_id,
            errors,
        )
        for field in ("profiles", "owns", "must_not_own"):
            value = record.get(field)
            if not isinstance(value, list) or not value:
                errors.append(f"{record_id}: {field} must be a non-empty array")

    capabilities = indexed_records(contract, "profile_capabilities", errors)
    require_exact_ids(
        set(capabilities), PROFILE_CAPABILITIES, "profile capabilities", errors
    )
    allowed_values = set(PROFILE_CAPABILITY_STATUSES.values())
    for record_id, record in capabilities.items():
        require_keys(record, {"id", "name", "profile_values"}, record_id, errors)
        values = record.get("profile_values")
        if not isinstance(values, dict):
            errors.append(f"{record_id}: profile_values must be an object")
            continue
        require_exact_ids(set(values), PROFILES, f"{record_id} profile matrix", errors)
        for profile_id, value in values.items():
            if value not in allowed_values:
                errors.append(f"{record_id}: invalid value {value} for {profile_id}")
        if (
            record_id in PLUG_ABSENT_CAPABILITIES
            and values.get("PROFILE-BROWSER-PLUG") != "absent"
        ):
            errors.append(f"{record_id}: browser/Plug baseline must be absent")

    exclusions = contract.get("plug_transitive_exclusions")
    if not isinstance(exclusions, list):
        errors.append("plug_transitive_exclusions: must be an array")
    else:
        require_exact_ids(
            set(exclusions),
            PLUG_TRANSITIVE_EXCLUSIONS,
            "Plug transitive exclusions",
            errors,
        )
    replaceability = contract.get("plug_replaceability_rules")
    if not isinstance(replaceability, list) or not replaceability:
        errors.append("plug_replaceability_rules: must be a non-empty array")


def validate_contract(contract: dict[str, Any]) -> list[str]:
    """Return deterministic validation errors for the product envelope."""

    errors: list[str] = []
    require_keys(
        contract,
        {
            "schema_version",
            "contract_id",
            "completion_stage",
            "evidence_state",
        },
        "contract",
        errors,
    )
    if contract.get("schema_version") != "0.1.0":
        errors.append("contract: schema_version must be 0.1.0")
    if contract.get("contract_id") != "BH00-BROWSER-ENVELOPE-0.1":
        errors.append("contract: unexpected contract_id")
    stage = contract.get("completion_stage")
    if stage not in STAGES:
        errors.append(f"contract: completion_stage must be one of {', '.join(STAGES)}")
    if contract.get("evidence_state") != "policy-only-unproven":
        errors.append("contract: evidence_state must remain policy-only-unproven in BH-00")

    validate_section_2_1(contract, errors)
    if stage in STAGES[1:]:
        validate_section_2_2(contract, errors)
    return errors


def summary(contract: dict[str, Any]) -> str:
    """Return a compact successful-validation summary."""

    result = (
        "Browser product envelope validation passed: "
        f"stage {contract['completion_stage']}; "
        f"{len(contract['browser_configurations'])} browser configurations, "
        f"{len(contract['evidence_classes'])} evidence classes, "
        f"{len(contract['toolchain_inputs'])} toolchain inputs, and "
        f"{len(contract['bh01_required_records'])} BH-01 records"
    )
    stage = contract["completion_stage"]
    if stage in STAGES[1:]:
        result += (
            f", {len(contract['rendering_modes'])} rendering modes, "
            f"{len(contract['profiles'])} profiles, and "
            f"{len(contract['profile_capabilities'])} profile capabilities"
        )
    return result + " checked."


def main() -> int:
    """Validate the repository contract and print a stable result."""

    path = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else CONTRACT_PATH
    try:
        contract = load_contract(path)
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"Browser product envelope validation failed: {error}", file=sys.stderr)
        return 1

    errors = validate_contract(contract)
    if errors:
        print(
            f"Browser product envelope validation failed with {len(errors)} error(s):",
            file=sys.stderr,
        )
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print(summary(contract))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
