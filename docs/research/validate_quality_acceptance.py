#!/usr/bin/env python3
"""Validate BlazeX BH-00 quality budgets and acceptance traceability."""

from __future__ import annotations

import json
import sys
from collections import Counter
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator
from jsonschema.exceptions import SchemaError


ROOT = Path(__file__).resolve().parent
ASSET_DIR = ROOT / "assets" / "quality-acceptance"
QUALITY_SCHEMA_PATH = ASSET_DIR / "blazex-quality-contract.schema.json"
QUALITY_PATH = ASSET_DIR / "blazex-quality-contract-v0.1.0.json"

EXPECTED_DIMENSIONS = {"payload", "startup", "interaction", "resource", "build", "reliability"}
EXPECTED_FAILURES = {
    "BX-FAIL-CAPABILITY-DENIED",
    "BX-FAIL-COMPONENT",
    "BX-FAIL-DEPLOYMENT-MISMATCH",
    "BX-FAIL-NETWORK-LOSS",
    "BX-FAIL-PERSISTED-STATE-CORRUPT",
    "BX-FAIL-RENDERER",
    "BX-FAIL-RESOURCE-CLEANUP",
    "BX-FAIL-RUNTIME-LOSS",
}
EXPECTED_BLOCKERS = {
    "BX-BLOCK-ABANDONED-RESOURCE",
    "BX-BLOCK-FOCUS-LOSS",
    "BX-BLOCK-LEAK",
    "BX-BLOCK-RUNAWAY-LOOP",
    "BX-BLOCK-SILENT-DATA-LOSS",
    "BX-BLOCK-UNAUTHORIZED-RETRY",
    "BX-BLOCK-UNBOUNDED-QUEUE",
}
REQUIRED_PAYLOAD_SUBJECTS = {
    "browser loader and bootstrap compressed transfer",
    "AtomVM and runtime support compressed transfer",
    "minimal application code compressed transfer",
    "minimal application decoded bytes",
    "shared UI foundation compressed transfer",
    "one optional component-family bundle compressed transfer",
    "optional data package compressed transfer",
    "optional chart package compressed transfer",
    "default fonts and icons compressed transfer",
    "publicly deployable production source maps",
}
EXPECTED_GATE_REQUIREMENTS = {
    "BX-GATE-ACCESSIBILITY": {
        "BX-GREQ-A11Y-ANNOUNCEMENT",
        "BX-GREQ-A11Y-FALLBACK",
        "BX-GREQ-A11Y-INPUT-MODES",
        "BX-GREQ-A11Y-KEYBOARD-FOCUS",
        "BX-GREQ-A11Y-SEMANTICS",
        "BX-GREQ-A11Y-VISUAL-ADAPTATION",
    },
    "BX-GATE-COMPATIBILITY": {
        "BX-GREQ-COMPAT-IDENTITIES",
        "BX-GREQ-COMPAT-MISMATCH",
        "BX-GREQ-COMPAT-SUPPORT-MATRIX",
        "BX-GREQ-COMPAT-UPGRADE",
    },
    "BX-GATE-PROVENANCE": {
        "BX-GREQ-PROV-ADAPTED-CODE",
        "BX-GREQ-PROV-ASSETS",
        "BX-GREQ-PROV-DEPENDENCIES",
        "BX-GREQ-PROV-GENERATED",
        "BX-GREQ-PROV-SOURCE-LICENSE",
    },
    "BX-GATE-SECURITY": {
        "BX-GREQ-SEC-CAPABILITY-GRANTS",
        "BX-GREQ-SEC-CLIENT-STATE",
        "BX-GREQ-SEC-CSRF-ORIGIN",
        "BX-GREQ-SEC-DEPENDENCY-DIAGNOSTICS",
        "BX-GREQ-SEC-SECRETS-INTEGRITY-CSP",
        "BX-GREQ-SEC-SERVER-COMMAND",
    },
}
EXPECTED_GATE_DIMENSIONS = {
    "BX-GATE-ACCESSIBILITY": "accessibility",
    "BX-GATE-COMPATIBILITY": "compatibility",
    "BX-GATE-PROVENANCE": "provenance",
    "BX-GATE-SECURITY": "security",
}


class QualityAcceptanceValidationError(ValueError):
    """Raised when the quality/acceptance contract is incoherent."""


def load_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise QualityAcceptanceValidationError(f"cannot read valid JSON from {path}: {error}") from error
    if not isinstance(value, dict):
        raise QualityAcceptanceValidationError(f"{path} must contain a JSON object")
    return value


def validate_schema(schema: dict[str, Any]) -> Draft202012Validator:
    try:
        Draft202012Validator.check_schema(schema)
    except SchemaError as error:
        raise QualityAcceptanceValidationError(f"quality schema is invalid: {error.message}") from error
    if schema.get("$id") != "https://blazex.dev/schemas/quality-contract/1.0.0":
        raise QualityAcceptanceValidationError("quality schema ID must remain version 1.0.0")
    return Draft202012Validator(schema)


def validate_document_schema(document: dict[str, Any], schema: dict[str, Any]) -> None:
    errors = sorted(
        validate_schema(schema).iter_errors(document),
        key=lambda error: [str(part) for part in error.absolute_path],
    )
    if errors:
        error = errors[0]
        path = ".".join(str(part) for part in error.absolute_path) or "<root>"
        raise QualityAcceptanceValidationError(f"quality schema violation at {path}: {error.message}")


def _require_sorted_unique(records: list[dict[str, Any]], label: str) -> set[str]:
    ids = [record.get("id") for record in records]
    if ids != sorted(ids):
        raise QualityAcceptanceValidationError(f"{label} IDs must be sorted")
    if len(ids) != len(set(ids)):
        raise QualityAcceptanceValidationError(f"{label} IDs must be unique")
    return set(ids)


def validate_quality_contract(document: dict[str, Any], schema: dict[str, Any]) -> dict[str, int]:
    validate_document_schema(document, schema)
    environments = document["environments"]
    budgets = document["budgets"]
    failures = document["failure_scenarios"]
    blockers = document["release_blockers"]
    gates = document["cross_cutting_gates"]

    environment_ids = _require_sorted_unique(environments, "environment")
    _require_sorted_unique(budgets, "budget")
    failure_ids = _require_sorted_unique(failures, "failure scenario")
    blocker_ids = _require_sorted_unique(blockers, "release blocker")

    if failure_ids != EXPECTED_FAILURES:
        raise QualityAcceptanceValidationError("quality contract must cover all eight required failure scenarios")
    if blocker_ids != EXPECTED_BLOCKERS:
        raise QualityAcceptanceValidationError("quality contract must cover all seven unwaivable release blockers")

    dimensions = Counter(budget["dimension"] for budget in budgets)
    if set(dimensions) != EXPECTED_DIMENSIONS:
        raise QualityAcceptanceValidationError("quality contract must cover all six budget dimensions")
    payload_subjects = {budget["subject"] for budget in budgets if budget["dimension"] == "payload"}
    if payload_subjects != REQUIRED_PAYLOAD_SUBJECTS:
        raise QualityAcceptanceValidationError("payload budgets must preserve all ten ownership boundaries")

    for budget in budgets:
        unknown_environments = set(budget["environment_refs"]) - environment_ids
        if unknown_environments:
            raise QualityAcceptanceValidationError(
                f"budget {budget['id']} references unknown environments: {sorted(unknown_environments)}"
            )
        if budget["measurement_state"] != "proposed-unmeasured" or budget["evidence_ids"]:
            raise QualityAcceptanceValidationError(f"budget {budget['id']} falsely claims measurement evidence")
        if budget["direction"] == "exactly" and budget["statistic"] not in {"exact", "rate", "maximum"}:
            raise QualityAcceptanceValidationError(f"budget {budget['id']} has incoherent exact threshold semantics")
        if budget["severity"] == "release-blocking" and budget["exception_policy"] == "profile-specific-waiver":
            if len(budget["environment_refs"]) < 1:
                raise QualityAcceptanceValidationError(f"budget {budget['id']} waiver lacks profile environment scope")

    if document["evidence_state"] != {
        "implementation": "not-executed",
        "measurements": "not-executed",
        "release_gates": "not-executed",
        "evidence_ids": [],
    }:
        raise QualityAcceptanceValidationError("BH-00 quality evidence state must remain wholly unexecuted")
    if document["exceptions"]:
        raise QualityAcceptanceValidationError("Phase 5 has no approved quality exceptions")

    stage = document["stage"]
    if stage == "section-5.1" and gates:
        raise QualityAcceptanceValidationError("Section 5.1 must not pre-empt Section 5.2 cross-cutting gates")
    if stage in {"section-5.2", "complete"}:
        validate_cross_cutting_gates(gates)

    return dict(sorted(dimensions.items()))


def validate_cross_cutting_gates(gates: list[dict[str, Any]]) -> None:
    """Validate gates once Section 5.2 advances the contract stage."""

    gate_ids = _require_sorted_unique(gates, "cross-cutting gate")
    if gate_ids != set(EXPECTED_GATE_REQUIREMENTS):
        raise QualityAcceptanceValidationError("cross-cutting gate identities must remain complete")
    dimensions = Counter(gate["dimension"] for gate in gates)
    if set(dimensions) != {"accessibility", "security", "compatibility", "provenance"}:
        raise QualityAcceptanceValidationError("cross-cutting gates must cover four governed dimensions")
    if any(gate["status"] != "reviewed-planned" for gate in gates):
        raise QualityAcceptanceValidationError("cross-cutting gates must be reviewed but not executed")
    all_requirement_ids: list[str] = []
    for gate in gates:
        gate_id = gate["id"]
        if gate["dimension"] != EXPECTED_GATE_DIMENSIONS[gate_id]:
            raise QualityAcceptanceValidationError(f"gate {gate_id} has the wrong dimension")
        requirement_ids = _require_sorted_unique(gate["requirements"], f"{gate_id} requirement")
        if requirement_ids != EXPECTED_GATE_REQUIREMENTS[gate_id]:
            raise QualityAcceptanceValidationError(f"gate {gate_id} requirement coverage is incomplete")
        all_requirement_ids.extend(requirement_ids)
        if gate["evidence_state"] != "planned-not-executed" or gate["evidence_ids"]:
            raise QualityAcceptanceValidationError(f"gate {gate_id} falsely claims executed evidence")
        if "review" not in gate["evidence_classes"]:
            raise QualityAcceptanceValidationError(f"gate {gate_id} must retain independent review evidence")
    if len(all_requirement_ids) != len(set(all_requirement_ids)):
        raise QualityAcceptanceValidationError("gate requirement IDs must be globally unique")

    security = next(gate for gate in gates if gate["id"] == "BX-GATE-SECURITY")
    if any(requirement["minimum_severity"] != "blocker" for requirement in security["requirements"]):
        raise QualityAcceptanceValidationError("all governed security requirements are release blockers")
    accessibility = next(gate for gate in gates if gate["id"] == "BX-GATE-ACCESSIBILITY")
    a11y_by_id = {requirement["id"]: requirement for requirement in accessibility["requirements"]}
    for requirement_id in {"BX-GREQ-A11Y-FALLBACK", "BX-GREQ-A11Y-KEYBOARD-FOCUS", "BX-GREQ-A11Y-SEMANTICS"}:
        if a11y_by_id[requirement_id]["minimum_severity"] != "blocker":
            raise QualityAcceptanceValidationError(f"essential accessibility requirement {requirement_id} must block")


def validate_repository() -> dict[str, int]:
    return validate_quality_contract(load_json(QUALITY_PATH), load_json(QUALITY_SCHEMA_PATH))


def main() -> int:
    try:
        counts = validate_repository()
    except QualityAcceptanceValidationError as error:
        print(f"Quality/acceptance validation failed: {error}", file=sys.stderr)
        return 1
    document = load_json(QUALITY_PATH)
    print(
        "Quality/acceptance validation passed: "
        f"stage {document['stage']}; {len(document['environments'])} environments; "
        f"{len(document['budgets'])} budgets {counts}; "
        f"{len(document['failure_scenarios'])} failure scenarios; "
        f"{len(document['release_blockers'])} unwaivable blockers; "
        f"{len(document['cross_cutting_gates'])} cross-cutting gates."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
