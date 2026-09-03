#!/usr/bin/env python3
"""Validate the versioned BlazeX component product classification."""

from __future__ import annotations

import hashlib
import json
import re
import sys
from collections import Counter
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator
from jsonschema.exceptions import SchemaError


ROOT = Path(__file__).resolve().parent
ASSET_DIR = ROOT / "assets" / "component-catalog"
SCHEMA_PATH = ASSET_DIR / "blazex-component-classification.schema.json"
CLASSIFICATION_PATH = ASSET_DIR / "blazex-component-classification-v0.1.0.json"
SOURCE_CATALOG_PATH = ASSET_DIR / "blazex-component-catalog-v0.1.0.json"
GENERATED_PATH = ASSET_DIR / "blazex-component-classification-v0-1-0-generated.md"

TIER_RANK = {"F0": 0, "F1": 1, "F2": 2, "F3": 3, "F4": 4, "post-1.0": 5, "not-applicable": 6}
PACKAGE_DEPENDENCIES = {
    "blazex_ui_tree": {"blazex_ui_tree"},
    "blazex_ui": {"blazex_ui_tree", "blazex_ui"},
    "blazex_surfaces": {"blazex_ui_tree", "blazex_ui", "blazex_surfaces"},
    "blazex_forms": {"blazex_ui_tree", "blazex_ui", "blazex_surfaces", "blazex_forms"},
    "blazex_data": {"blazex_ui_tree", "blazex_ui", "blazex_surfaces", "blazex_forms", "blazex_data"},
    "blazex_charts": {"blazex_ui_tree", "blazex_ui", "blazex_surfaces", "blazex_forms", "blazex_data", "blazex_charts"},
}
OPTIONAL_PACKAGES = {"blazex_forms", "blazex_surfaces", "blazex_data", "blazex_charts"}
EXPECTED_PAYLOAD = {
    "blazex_ui_tree": "core",
    "blazex_ui": "core",
    "blazex_forms": "optional",
    "blazex_surfaces": "optional",
    "blazex_data": "runtime-heavy",
    "blazex_charts": "asset-heavy",
}
FORBIDDEN_PORTABLE_TOKENS = re.compile(
    r"(?:dom|javascript|js-handle|css|selector|phoenix|liveview|socket|native-widget|filesystem|script)",
    re.IGNORECASE,
)


class ClassificationValidationError(ValueError):
    """Raised when the classification violates its schema or coherence policy."""


def load_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise ClassificationValidationError(f"cannot read valid JSON from {path}: {error}") from error
    if not isinstance(value, dict):
        raise ClassificationValidationError(f"{path} must contain a JSON object")
    return value


def validate_schema(schema: dict[str, Any]) -> Draft202012Validator:
    try:
        Draft202012Validator.check_schema(schema)
    except SchemaError as error:
        raise ClassificationValidationError(f"classification schema is invalid: {error.message}") from error
    if schema.get("$id") != "https://blazex.dev/schemas/component-classification/1.0.0":
        raise ClassificationValidationError("classification schema ID must remain version 1.0.0")
    return Draft202012Validator(schema)


def validate_document_schema(document: dict[str, Any], schema: dict[str, Any]) -> None:
    validator = validate_schema(schema)
    errors = sorted(validator.iter_errors(document), key=lambda error: [str(part) for part in error.absolute_path])
    if errors:
        error = errors[0]
        path = ".".join(str(part) for part in error.absolute_path) or "<root>"
        raise ClassificationValidationError(f"classification schema violation at {path}: {error.message}")


def _validate_graph(records: list[dict[str, Any]]) -> None:
    by_id = {record["family_id"]: record for record in records}
    visiting: set[str] = set()
    visited: set[str] = set()

    def visit(family_id: str) -> None:
        if family_id in visited:
            return
        if family_id in visiting:
            raise ClassificationValidationError(f"classification prerequisite cycle includes {family_id}")
        visiting.add(family_id)
        record = by_id[family_id]
        for prerequisite_id in record["product"]["prerequisites"]:
            if prerequisite_id not in by_id:
                raise ClassificationValidationError(
                    f"family {family_id} prerequisite is absent: {prerequisite_id}"
                )
            prerequisite = by_id[prerequisite_id]
            if TIER_RANK[prerequisite["product"]["delivery_tier"]] > TIER_RANK[record["product"]["delivery_tier"]]:
                raise ClassificationValidationError(
                    f"family {family_id} depends on later-tier {prerequisite_id}"
                )
            package = record["product"]["target_package"]
            prerequisite_package = prerequisite["product"]["target_package"]
            if prerequisite_package not in PACKAGE_DEPENDENCIES[package]:
                raise ClassificationValidationError(
                    f"family {family_id} package {package} cannot depend on {prerequisite_package}"
                )
            visit(prerequisite_id)
        visiting.remove(family_id)
        visited.add(family_id)

    for family_id in by_id:
        visit(family_id)


def _is_unassigned_capability(record: dict[str, Any]) -> bool:
    capability = record["capability"]
    remote = record["remote"]
    fallback = record["fallback"]
    return (
        capability["required"] == []
        and capability["optional"] == []
        and capability["renderer_semantics"] == []
        and capability["effect_ownership"] == "unassigned"
        and capability["resource_lifecycle"] == "unassigned"
        and capability["cancellation"] == "unassigned"
        and capability["timeout"] == "unassigned"
        and capability["cleanup"] == "unassigned"
        and capability["portable_requirement_tokens"] == []
        and remote == {"authority": "unassigned", "rationale": None}
        and fallback["primary"] == "unassigned"
        and fallback["rationale"] is None
        and set(fallback["conditions"].values()) == {"unassigned"}
    )


def _is_unassigned_portability(record: dict[str, Any]) -> bool:
    portability = record["portability"]
    return (
        portability["status"] == "unproven"
        and portability["rationale"] is None
        and all(not values for values in portability["semantic_contract"].values())
        and portability["renderer_extensions"] == []
        and portability["native_strategy"] == "unproven"
        and portability["visual_profile"] == "unproven"
        and portability["visual_profile_rationale"] is None
        and set(portability["future_backend_gate"].values()) == {"unassigned"}
    )


def validate_classification(
    document: dict[str, Any], source_catalog: dict[str, Any], schema: dict[str, Any]
) -> dict[str, Any]:
    validate_document_schema(document, schema)
    source_bytes = SOURCE_CATALOG_PATH.read_bytes()
    source_hash = hashlib.sha256(source_bytes).hexdigest()
    if document["source_catalog_sha256"] != source_hash:
        raise ClassificationValidationError(
            f"source catalog hash mismatch: expected {source_hash}, found {document['source_catalog_sha256']}"
        )
    source_ids = [record["id"] for record in source_catalog["families"]]
    family_ids = [record["family_id"] for record in document["families"]]
    if family_ids != sorted(family_ids) or len(family_ids) != len(set(family_ids)):
        raise ClassificationValidationError("family classifications must have sorted unique IDs")
    if set(family_ids) != set(source_ids):
        raise ClassificationValidationError(
            f"classification/source family mismatch; missing={sorted(set(source_ids)-set(family_ids))} extra={sorted(set(family_ids)-set(source_ids))}"
        )
    source_exception_ids = [record["id"] for record in source_catalog["exceptions"]]
    exception_ids = [record["exception_id"] for record in document["exceptions"]]
    if exception_ids != sorted(exception_ids) or len(exception_ids) != len(set(exception_ids)):
        raise ClassificationValidationError("exception classifications must have sorted unique IDs")
    if set(exception_ids) != set(source_exception_ids):
        raise ClassificationValidationError("classification/source exception coverage mismatch")
    if document["owner_roles"] != sorted(document["owner_roles"]):
        raise ClassificationValidationError("classification owner roles must be sorted")

    public_identities: list[str] = []
    for record in document["families"]:
        family_id = record["family_id"]
        product = record["product"]
        if product["disposition"] in {"defer", "omit"}:
            if product["delivery_tier"] != "not-applicable" or product["target_package"] != "none":
                raise ClassificationValidationError(f"deferred/omitted family {family_id} cannot be tiered or packaged")
        else:
            if product["delivery_tier"] not in {"F0", "F1", "F2", "F3", "F4"}:
                raise ClassificationValidationError(f"planned family {family_id} needs an F0-F4 tier")
            package = product["target_package"]
            if package not in PACKAGE_DEPENDENCIES:
                raise ClassificationValidationError(f"planned family {family_id} has forbidden package {package}")
            if product["optional_package"] != (package in OPTIONAL_PACKAGES):
                raise ClassificationValidationError(f"family {family_id} optional-package flag contradicts {package}")
            if product["payload_class"] != EXPECTED_PAYLOAD[package]:
                raise ClassificationValidationError(f"family {family_id} payload class contradicts {package}")
            public_identity = product["intended_public_identity"]
            if not isinstance(public_identity, str) or not public_identity.startswith("BlazeX."):
                raise ClassificationValidationError(f"family {family_id} needs a BlazeX public identity")
            if re.search(r"Mud|Blazor|Razor|\.NET|NuGet", public_identity, re.IGNORECASE):
                raise ClassificationValidationError(f"family {family_id} public identity implies compatibility")
            public_identities.append(public_identity)
        if record["implementation_state"] != "unknown" or record["implementation_evidence"]:
            raise ClassificationValidationError(f"family {family_id} has a premature implementation/evidence claim")
    if len(public_identities) != len(set(public_identities)):
        raise ClassificationValidationError("classification contains duplicate intended public identities")

    _validate_graph(document["families"])

    stage = document["stage"]
    for record in document["families"]:
        if stage == "section-4.1" and not _is_unassigned_capability(record):
            raise ClassificationValidationError(
                f"section-4.1 family {record['family_id']} must leave capability/remote/fallback unassigned"
            )
        if stage in {"section-4.1", "section-4.2"} and not _is_unassigned_portability(record):
            raise ClassificationValidationError(
                f"{stage} family {record['family_id']} must leave portability unproven"
            )
        for token in record["capability"]["portable_requirement_tokens"]:
            if FORBIDDEN_PORTABLE_TOKENS.search(token):
                raise ClassificationValidationError(
                    f"family {record['family_id']} portable requirement leaks backend token: {token}"
                )

    return {
        "stage": stage,
        "families": len(document["families"]),
        "exceptions": len(document["exceptions"]),
        "dispositions": dict(sorted(Counter(record["product"]["disposition"] for record in document["families"]).items())),
        "tiers": dict(sorted(Counter(record["product"]["delivery_tier"] for record in document["families"]).items())),
        "packages": dict(sorted(Counter(record["product"]["target_package"] for record in document["families"]).items())),
    }


def validate_generated_view(
    document: dict[str, Any], source_catalog: dict[str, Any], generated_text: str
) -> None:
    from generate_component_classification import render_classification

    if generated_text != render_classification(document, source_catalog):
        raise ClassificationValidationError("generated component-classification view is stale")


def validate_repository() -> dict[str, Any]:
    schema = load_json(SCHEMA_PATH)
    document = load_json(CLASSIFICATION_PATH)
    source_catalog = load_json(SOURCE_CATALOG_PATH)
    summary = validate_classification(document, source_catalog, schema)
    try:
        generated = GENERATED_PATH.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as error:
        raise ClassificationValidationError(f"cannot read generated classification: {error}") from error
    validate_generated_view(document, source_catalog, generated)
    return summary


def main() -> int:
    try:
        summary = validate_repository()
    except (ClassificationValidationError, OSError) as error:
        print(f"Component classification validation failed: {error}", file=sys.stderr)
        return 1
    print(
        "Component classification validation passed: "
        f"stage {summary['stage']}; {summary['families']} families; {summary['exceptions']} exceptions; "
        f"dispositions {summary['dispositions']}; tiers {summary['tiers']}; packages {summary['packages']}."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
