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

import generate_acceptance_registry as acceptance_generator


ROOT = Path(__file__).resolve().parent
ASSET_DIR = ROOT / "assets" / "quality-acceptance"
QUALITY_SCHEMA_PATH = ASSET_DIR / "blazex-quality-contract.schema.json"
QUALITY_PATH = ASSET_DIR / "blazex-quality-contract-v0.1.0.json"
ACCEPTANCE_SCHEMA_PATH = ASSET_DIR / "blazex-acceptance-registry.schema.json"
ACCEPTANCE_PATH = ASSET_DIR / "blazex-acceptance-registry-v0.1.0.json"
CLASSIFICATION_PATH = ROOT / "assets" / "component-catalog" / "blazex-component-classification-v0.1.0.json"

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
EXPECTED_EVIDENCE_CLASSES = {
    "accessibility",
    "automated",
    "benchmark",
    "browser",
    "deployment",
    "generated",
    "manual",
    "provenance",
    "review",
    "security",
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


def validate_acceptance_document_schema(document: dict[str, Any], schema: dict[str, Any]) -> None:
    try:
        Draft202012Validator.check_schema(schema)
    except SchemaError as error:
        raise QualityAcceptanceValidationError(f"acceptance schema is invalid: {error.message}") from error
    if schema.get("$id") != "https://blazex.dev/schemas/acceptance-registry/1.0.0":
        raise QualityAcceptanceValidationError("acceptance schema ID must remain version 1.0.0")
    errors = sorted(
        Draft202012Validator(schema).iter_errors(document),
        key=lambda error: [str(part) for part in error.absolute_path],
    )
    if errors:
        error = errors[0]
        path = ".".join(str(part) for part in error.absolute_path) or "<root>"
        raise QualityAcceptanceValidationError(f"acceptance schema violation at {path}: {error.message}")


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


def _validate_acceptance_state(record: dict[str, Any]) -> None:
    acceptance_id = record["id"]
    status = record["status"]
    implementation = record["implementation_state"]
    verification = record["verification_state"]
    evidence = record["evidence_ids"]
    waiver = record["waiver"]
    supersedes = record["supersedes"]
    support = record["support_status"]
    if status == "planned":
        if implementation not in {"not-started", "not-applicable"} or verification != "not-executed":
            raise QualityAcceptanceValidationError(f"planned condition {acceptance_id} has an executed state")
        if evidence or waiver is not None or supersedes is not None:
            raise QualityAcceptanceValidationError(f"planned condition {acceptance_id} carries evidence, waiver, or supersession")
    elif status == "blocked":
        if implementation == "implemented" or verification == "passed" or waiver is not None:
            raise QualityAcceptanceValidationError(f"blocked condition {acceptance_id} has an incompatible state")
    elif status == "implemented":
        if implementation != "implemented" or verification != "not-executed" or evidence:
            raise QualityAcceptanceValidationError(f"implemented condition {acceptance_id} must await verification")
    elif status in {"passed", "failed"}:
        if implementation != "implemented" or verification != status or not evidence or waiver is not None:
            raise QualityAcceptanceValidationError(f"{status} condition {acceptance_id} lacks matching implementation and evidence")
    elif status == "waived":
        if waiver is None or verification == "passed" or not evidence:
            raise QualityAcceptanceValidationError(f"waived condition {acceptance_id} lacks failure evidence and waiver")
    elif status == "superseded":
        if supersedes is None or waiver is not None:
            raise QualityAcceptanceValidationError(f"superseded condition {acceptance_id} lacks its replacement")
    elif status == "unsupported":
        if support != "unsupported" or implementation != "not-applicable" or verification != "not-applicable":
            raise QualityAcceptanceValidationError(f"unsupported condition {acceptance_id} has a combinable delivery state")
    elif status == "not-applicable":
        if support != "not-applicable" or implementation != "not-applicable" or verification != "not-applicable":
            raise QualityAcceptanceValidationError(f"not-applicable condition {acceptance_id} has a combinable delivery state")


def validate_acceptance_registry(
    document: dict[str, Any],
    schema: dict[str, Any],
    quality: dict[str, Any],
    classification: dict[str, Any],
) -> dict[str, int]:
    validate_acceptance_document_schema(document, schema)
    requirements = document["requirements"]
    conditions = document["acceptance_conditions"]
    requirement_ids = _require_sorted_unique(requirements, "acceptance requirement")
    condition_ids = _require_sorted_unique(conditions, "acceptance condition")
    binding_ids = _require_sorted_unique(document["source_bindings"], "acceptance source binding")
    evidence_ids = _require_sorted_unique(document["evidence_classes"], "evidence class")
    if evidence_ids != EXPECTED_EVIDENCE_CLASSES:
        raise QualityAcceptanceValidationError("acceptance registry must define all ten evidence classes")
    if binding_ids != set(acceptance_generator.SOURCE_BINDINGS):
        raise QualityAcceptanceValidationError("acceptance registry source bindings are incomplete")
    for binding in document["source_bindings"]:
        path = ROOT / binding["path"]
        if not path.exists() or acceptance_generator.sha256(path) != binding["sha256"]:
            raise QualityAcceptanceValidationError(f"acceptance source binding is stale: {binding['id']}")

    requirements_by_id = {record["id"]: record for record in requirements}
    conditions_by_id = {record["id"]: record for record in conditions}
    source_keys = [(record["source_kind"], record["source_id"]) for record in requirements]
    if len(source_keys) != len(set(source_keys)):
        raise QualityAcceptanceValidationError("source claims must map to unique acceptance requirements")
    for record in requirements:
        if record["source_binding"] not in binding_ids:
            raise QualityAcceptanceValidationError(f"requirement {record['id']} references an unknown source binding")
        for acceptance_id in record["acceptance_ids"]:
            if acceptance_id not in condition_ids:
                raise QualityAcceptanceValidationError(f"requirement {record['id']} references missing condition {acceptance_id}")
            if record["id"] not in conditions_by_id[acceptance_id]["requirement_ids"]:
                raise QualityAcceptanceValidationError(f"requirement {record['id']} has a non-reciprocal condition link")
    known_budgets = {budget["id"] for budget in quality["budgets"]}
    for record in conditions:
        _validate_acceptance_state(record)
        for requirement_id in record["requirement_ids"]:
            if requirement_id not in requirement_ids:
                raise QualityAcceptanceValidationError(f"condition {record['id']} references missing requirement {requirement_id}")
            if record["id"] not in requirements_by_id[requirement_id]["acceptance_ids"]:
                raise QualityAcceptanceValidationError(f"condition {record['id']} has a non-reciprocal requirement link")
        unknown_budgets = set(record["required_budget_ids"]) - known_budgets
        if unknown_budgets:
            raise QualityAcceptanceValidationError(f"condition {record['id']} references unknown budgets")

    family_source_ids = {
        record["source_id"] for record in requirements if record["source_kind"] == "catalog-family"
    }
    if family_source_ids != {family["family_id"] for family in classification["families"]}:
        raise QualityAcceptanceValidationError("every classified family must have acceptance coverage")
    budget_source_ids = {
        record["source_id"] for record in requirements if record["source_kind"] == "quality-budget"
    }
    if budget_source_ids != known_budgets:
        raise QualityAcceptanceValidationError("every quality budget must have acceptance coverage")
    roadmap_ids = {
        record["source_id"] for record in requirements if record["source_kind"] == "roadmap-milestone"
    }
    if roadmap_ids != {f"BH-{index:02d}" for index in range(24)}:
        raise QualityAcceptanceValidationError("all BH-00 through BH-23 roadmap outcomes require coverage")
    covered_profiles = {profile for record in conditions for profile in record["profiles"] if profile.startswith("PROFILE-")}
    if covered_profiles != set(acceptance_generator.PROFILE_IDS):
        raise QualityAcceptanceValidationError("all declared profiles require acceptance coverage")
    if any(document["coverage_findings"].values()):
        raise QualityAcceptanceValidationError("acceptance registry contains unresolved deterministic coverage findings")

    expected = acceptance_generator.build_registry()
    if document != expected:
        raise QualityAcceptanceValidationError("acceptance registry is stale relative to its governed sources and generator")
    return dict(sorted(Counter(record["source_kind"] for record in requirements).items()))


def validate_repository() -> tuple[dict[str, int], dict[str, int]]:
    quality = load_json(QUALITY_PATH)
    quality_counts = validate_quality_contract(quality, load_json(QUALITY_SCHEMA_PATH))
    acceptance_counts = validate_acceptance_registry(
        load_json(ACCEPTANCE_PATH),
        load_json(ACCEPTANCE_SCHEMA_PATH),
        quality,
        load_json(CLASSIFICATION_PATH),
    )
    return quality_counts, acceptance_counts


def main() -> int:
    try:
        counts, acceptance_counts = validate_repository()
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
        f"{len(document['cross_cutting_gates'])} cross-cutting gates; "
        f"{sum(acceptance_counts.values())} acceptance requirements {acceptance_counts}; zero executed evidence."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
