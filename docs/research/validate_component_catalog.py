#!/usr/bin/env python3
"""Validate the pinned component-catalog reference and generated artifacts."""

from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator
from jsonschema.exceptions import SchemaError


ROOT = Path(__file__).resolve().parent
CATALOG_DIR = ROOT / "assets" / "component-catalog"
REFERENCE_LOCK_PATH = CATALOG_DIR / "mudblazor-v9.9.0-reference-lock.json"
CATALOG_SCHEMA_PATH = CATALOG_DIR / "blazex-component-catalog.schema.json"
CATALOG_PATH = CATALOG_DIR / "blazex-component-catalog-v0.1.0.json"
GENERATED_CATALOG_PATH = CATALOG_DIR / "blazex-component-catalog-v0-1-0-generated.md"

EXPECTED_REFERENCE = {
    "schema_version": "1.0.0",
    "reference_id": "mudblazor-v9.9.0",
    "repository": "https://github.com/MudBlazor/MudBlazor.git",
    "tag": "v9.9.0",
    "commit": "3d85eed63a2c886d0a2e37f9f0cad78be655ad1c",
    "entry_count": 83,
}
EXPECTED_GIT_OBJECTS = {
    "root_tree": "9d22822949515751b9c011e588238dcf5787686a",
    "components_tree": "d3f33e5039ea0974f648f32365242714831f757a",
    "documentation_components_tree": "90c6b7127c5e3e24681306effb38604bbf631ff2",
    "project_file_blob": "c9d8509eaf4c135fd4b7728914faff2f5f23dacb",
}
REQUIRED_PRINCIPAL_PATHS = {
    "LICENSE",
    "src/MudBlazor/MudBlazor.csproj",
    "src/MudBlazor/Base/",
    "src/MudBlazor/Components/",
    "src/MudBlazor/Extensions/ServiceCollectionExtensions.cs",
    "src/MudBlazor/Icons/",
    "src/MudBlazor/Services/",
    "src/MudBlazor/State/",
    "src/MudBlazor/Styles/",
    "src/MudBlazor/Themes/",
    "src/MudBlazor/TScripts/",
    "src/MudBlazor.Docs/Pages/Components/",
    "src/MudBlazor.UnitTests/",
}
REQUIRED_UPDATE_FLAGS = {
    "requires_new_lock": True,
    "requires_source_tree_diff": True,
    "requires_normalized_catalog_diff": True,
    "requires_license_and_provenance_review": True,
    "requires_human_acceptance": True,
    "mutates_blazex_dispositions_automatically": False,
    "preserves_previous_lock_and_catalog": True,
}
SHA1_RE = re.compile(r"^[0-9a-f]{40}$")
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
SOURCE_FAMILY_RE = re.compile(r"^[A-Z][A-Za-z0-9]*$")
EXPECTED_DELIVERY_STATES = {
    "planned",
    "accepted",
    "implemented",
    "evidenced",
    "supported",
    "deferred",
    "omitted",
    "superseded",
    "unknown",
}
EXPECTED_CATEGORIES = {
    "foundation-provider",
    "layout-content",
    "actions-feedback",
    "navigation-disclosure",
    "forms-input",
    "data-visualization",
    "browser-interaction",
}
EXPECTED_EXCEPTION_CLASSES = {
    "excluded",
    "obsolete",
    "experimental",
    "service-only",
    "infrastructure-only",
    "duplicate",
    "unresolved",
}


class CatalogValidationError(ValueError):
    """Raised when a catalog artifact violates the locked contract."""


def load_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise CatalogValidationError(f"cannot read valid JSON from {path}: {error}") from error
    if not isinstance(value, dict):
        raise CatalogValidationError(f"{path} must contain a JSON object")
    return value


def _require_sha1(value: Any, field: str) -> None:
    if not isinstance(value, str) or not SHA1_RE.fullmatch(value):
        raise CatalogValidationError(f"{field} must be a lowercase 40-character Git object ID")


def _require_exact(mapping: dict[str, Any], expected: dict[str, Any], context: str) -> None:
    for field, expected_value in expected.items():
        actual = mapping.get(field)
        if actual != expected_value:
            raise CatalogValidationError(
                f"{context}.{field} must be {expected_value!r}, found {actual!r}"
            )


def validate_reference(lock: dict[str, Any], snapshot_bytes: bytes) -> list[str]:
    """Validate the immutable MudBlazor lock and return its source-family names."""

    _require_exact(lock, {key: EXPECTED_REFERENCE[key] for key in (
        "schema_version", "reference_id", "repository", "tag", "commit"
    )}, "reference")
    _require_sha1(lock.get("commit"), "reference.commit")

    license_record = lock.get("license")
    if not isinstance(license_record, dict):
        raise CatalogValidationError("reference.license must be an object")
    _require_exact(license_record, {"spdx": "MIT", "path": "LICENSE"}, "reference.license")
    _require_sha1(license_record.get("git_blob"), "reference.license.git_blob")

    git_objects = lock.get("git_objects")
    if not isinstance(git_objects, dict):
        raise CatalogValidationError("reference.git_objects must be an object")
    _require_exact(git_objects, EXPECTED_GIT_OBJECTS, "reference.git_objects")
    for field, value in git_objects.items():
        _require_sha1(value, f"reference.git_objects.{field}")

    principal_paths = lock.get("principal_paths")
    if not isinstance(principal_paths, list) or not all(
        isinstance(path, str) and path for path in principal_paths
    ):
        raise CatalogValidationError("reference.principal_paths must contain nonempty strings")
    missing_paths = sorted(REQUIRED_PRINCIPAL_PATHS - set(principal_paths))
    if missing_paths:
        raise CatalogValidationError(
            "reference.principal_paths is missing: " + ", ".join(missing_paths)
        )

    authoritative_inputs = lock.get("authoritative_inputs")
    if not isinstance(authoritative_inputs, list) or not authoritative_inputs:
        raise CatalogValidationError("reference.authoritative_inputs must be a nonempty list")
    for index, record in enumerate(authoritative_inputs):
        if not isinstance(record, dict):
            raise CatalogValidationError(f"reference.authoritative_inputs[{index}] must be an object")
        for field in ("classification", "authority", "inventory_role"):
            if not isinstance(record.get(field), str) or not record[field]:
                raise CatalogValidationError(
                    f"reference.authoritative_inputs[{index}].{field} must be a nonempty string"
                )
        paths = record.get("paths")
        if not isinstance(paths, list) or not paths or not all(
            isinstance(path, str) and path for path in paths
        ):
            raise CatalogValidationError(
                f"reference.authoritative_inputs[{index}].paths must contain nonempty strings"
            )

    update_policy = lock.get("later_reference_update")
    if not isinstance(update_policy, dict):
        raise CatalogValidationError("reference.later_reference_update must be an object")
    _require_exact(update_policy, REQUIRED_UPDATE_FLAGS, "reference.later_reference_update")

    snapshot = lock.get("family_snapshot")
    if not isinstance(snapshot, dict):
        raise CatalogValidationError("reference.family_snapshot must be an object")
    _require_exact(
        snapshot,
        {
            "path": "mudblazor-v9.9.0-source-families.txt",
            "source_path": "src/MudBlazor/Components/",
            "extraction": "git ls-tree -d --name-only HEAD:src/MudBlazor/Components",
            "ordering": "unicode-codepoint-ascending",
            "entry_count": EXPECTED_REFERENCE["entry_count"],
        },
        "reference.family_snapshot",
    )
    expected_hash = snapshot.get("sha256")
    if not isinstance(expected_hash, str) or not SHA256_RE.fullmatch(expected_hash):
        raise CatalogValidationError("reference.family_snapshot.sha256 must be lowercase SHA-256")
    actual_hash = hashlib.sha256(snapshot_bytes).hexdigest()
    if actual_hash != expected_hash:
        raise CatalogValidationError(
            f"source-family snapshot SHA-256 mismatch: expected {expected_hash}, found {actual_hash}"
        )

    try:
        snapshot_text = snapshot_bytes.decode("utf-8")
    except UnicodeDecodeError as error:
        raise CatalogValidationError("source-family snapshot must be UTF-8") from error
    if not snapshot_text.endswith("\n"):
        raise CatalogValidationError("source-family snapshot must end with one newline")
    families = snapshot_text.splitlines()
    if not families or any(not family for family in families):
        raise CatalogValidationError("source-family snapshot must contain only nonempty lines")
    if families != sorted(families):
        raise CatalogValidationError("source-family snapshot must be Unicode-codepoint sorted")
    if len(families) != len(set(families)):
        raise CatalogValidationError("source-family snapshot contains duplicate names")
    if len(families) != EXPECTED_REFERENCE["entry_count"]:
        raise CatalogValidationError(
            f"source-family snapshot must contain {EXPECTED_REFERENCE['entry_count']} names"
        )
    invalid_names = [family for family in families if not SOURCE_FAMILY_RE.fullmatch(family)]
    if invalid_names:
        raise CatalogValidationError(
            "source-family snapshot contains invalid names: " + ", ".join(invalid_names)
        )
    return families


def validate_catalog_schema(schema: dict[str, Any]) -> Draft202012Validator:
    """Validate the catalog schema's own structure and governed constants."""

    try:
        Draft202012Validator.check_schema(schema)
    except SchemaError as error:
        raise CatalogValidationError(f"component catalog JSON Schema is invalid: {error.message}") from error
    _require_exact(
        schema,
        {
            "$schema": "https://json-schema.org/draft/2020-12/schema",
            "$id": "https://blazex.dev/schemas/component-catalog/1.0.0",
        },
        "catalog_schema",
    )
    definitions = schema.get("$defs")
    if not isinstance(definitions, dict):
        raise CatalogValidationError("catalog_schema.$defs must be an object")
    required_definitions = {
        "family",
        "exception",
        "sourceIdentity",
        "relationship",
        "classification",
        "capabilityContract",
        "implementation",
        "deliveryState",
    }
    missing = sorted(required_definitions - set(definitions))
    if missing:
        raise CatalogValidationError("catalog schema is missing definitions: " + ", ".join(missing))
    states = definitions.get("deliveryState", {}).get("enum")
    if not isinstance(states, list) or set(states) != EXPECTED_DELIVERY_STATES:
        raise CatalogValidationError("catalog schema deliveryState enum is incomplete or changed")
    if len(states) != len(set(states)):
        raise CatalogValidationError("catalog schema deliveryState enum contains duplicates")
    return Draft202012Validator(schema)


def validate_catalog_document(document: dict[str, Any], schema: dict[str, Any]) -> None:
    """Validate one authored catalog document against the governed JSON Schema."""

    schema_validator = validate_catalog_schema(schema)
    errors = sorted(schema_validator.iter_errors(document), key=lambda error: list(error.absolute_path))
    if errors:
        error = errors[0]
        path = ".".join(str(part) for part in error.absolute_path) or "<root>"
        raise CatalogValidationError(f"catalog schema violation at {path}: {error.message}")


def stable_family_id(source_family: str) -> str:
    words = re.sub(r"([A-Z]+)([A-Z][a-z])", r"\1-\2", source_family)
    words = re.sub(r"([a-z0-9])([A-Z])", r"\1-\2", words)
    return "BX-FAM-" + words.upper()


def validate_catalog_semantics(document: dict[str, Any], locked_families: list[str]) -> dict[str, int]:
    """Validate source closure, deterministic identity, and Phase 3 nonclaims."""

    schema = load_json(CATALOG_SCHEMA_PATH)
    validate_catalog_document(document, schema)
    _require_exact(
        document,
        {
            "schema_version": "1.0.0",
            "catalog_version": "0.1.0",
            "catalog_id": "BX-CATALOG-CORE",
            "reference_id": "mudblazor-v9.9.0",
            "authored_source": "assets/component-catalog/blazex-component-catalog-v0.1.0.json",
            "generated_view": "assets/component-catalog/blazex-component-catalog-v0-1-0-generated.md",
            "sort_order": "family-id-unicode-codepoint-ascending",
        },
        "catalog",
    )
    if document.get("catalog_status") not in {"reviewed", "locked"}:
        raise CatalogValidationError("catalog.catalog_status must be reviewed or locked in Phase 3")
    owner_roles = document.get("owner_roles", [])
    if owner_roles != sorted(owner_roles) or len(owner_roles) != len(set(owner_roles)):
        raise CatalogValidationError("catalog.owner_roles must be sorted and unique")

    records = document["families"]
    ids = [record["id"] for record in records]
    source_names = [record["source"]["source_family"] for record in records]
    if ids != sorted(ids):
        raise CatalogValidationError("catalog families must be sorted by stable family ID")
    if len(ids) != len(set(ids)):
        raise CatalogValidationError("catalog contains duplicate stable family IDs")
    if len(source_names) != len(set(source_names)):
        raise CatalogValidationError("catalog contains duplicate source-family identities")
    missing_sources = sorted(set(locked_families) - set(source_names))
    unexpected_sources = sorted(set(source_names) - set(locked_families))
    if missing_sources or unexpected_sources:
        raise CatalogValidationError(
            "catalog source coverage mismatch; missing={} unexpected={}".format(
                missing_sources, unexpected_sources
            )
        )

    for record in records:
        source = record["source"]
        source_family = source["source_family"]
        expected_id = stable_family_id(source_family)
        if record["id"] != expected_id:
            raise CatalogValidationError(
                f"family {source_family} must use stable ID {expected_id}, found {record['id']}"
            )
        expected_path = f"src/MudBlazor/Components/{source_family}"
        if source["source_paths"] != [expected_path]:
            raise CatalogValidationError(
                f"family {record['id']} must cite exact source path {expected_path}"
            )
        source_identifiers = source["source_identifiers"]
        if not source_identifiers:
            raise CatalogValidationError(f"family {record['id']} needs at least one source identifier")
        if source_identifiers != sorted(source_identifiers):
            raise CatalogValidationError(f"family {record['id']} source identifiers must be sorted")
        if record["aliases"] != sorted(record["aliases"]):
            raise CatalogValidationError(f"family {record['id']} aliases must be sorted")
        classification = record["classification"]
        expected_classification = {
            "disposition": "unresolved",
            "rationale": None,
            "delivery_tier": "unassigned",
            "target_package": None,
            "prerequisites": [],
            "optional_package": None,
            "payload_class": "unassigned",
            "intended_public_identity": None,
        }
        if classification != expected_classification:
            raise CatalogValidationError(
                f"family {record['id']} contains a premature Phase 4 classification"
            )
        capability = record["capability_contract"]
        expected_capability = {
            "required_capabilities": [],
            "optional_capabilities": [],
            "fallback": None,
            "rendering_modes": {"state": "unknown", "entries": [], "rationale": None},
            "runtime_eligibility": {"state": "unknown", "entries": [], "rationale": None},
            "backend_portability": "unknown",
            "native_strategy": "unknown",
            "accessibility_alternative": None,
            "renderer_extensions": [],
        }
        if capability != expected_capability:
            raise CatalogValidationError(
                f"family {record['id']} contains a premature capability or portability claim"
            )
        if record["implementation"] != {
            "delivery_state": "unknown",
            "implementation_evidence": [],
        }:
            raise CatalogValidationError(
                f"family {record['id']} contains a premature implementation or support claim"
            )

    category_counts = {category: 0 for category in EXPECTED_CATEGORIES}
    for record in records:
        category_counts[record["category"]] += 1
    missing_categories = sorted(category for category, count in category_counts.items() if count == 0)
    if missing_categories:
        raise CatalogValidationError("catalog has empty required categories: " + ", ".join(missing_categories))

    record_ids = set(ids)
    for record in records:
        seen_relationships: set[tuple[str, str]] = set()
        for relationship in record["relationships"]:
            edge = (relationship["type"], relationship["target_id"])
            if edge in seen_relationships:
                raise CatalogValidationError(f"family {record['id']} has duplicate relationship {edge}")
            seen_relationships.add(edge)
            if relationship["target_id"] not in record_ids:
                raise CatalogValidationError(
                    f"family {record['id']} relationship target does not exist: {relationship['target_id']}"
                )

    exceptions = document["exceptions"]
    exception_ids = [record["id"] for record in exceptions]
    if exception_ids != sorted(exception_ids) or len(exception_ids) != len(set(exception_ids)):
        raise CatalogValidationError("catalog exceptions must have sorted unique IDs")
    present_classes = {record["classification"] for record in exceptions}
    missing_exception_classes = sorted(EXPECTED_EXCEPTION_CLASSES - present_classes)
    if missing_exception_classes:
        raise CatalogValidationError(
            "catalog is missing exception classifications: " + ", ".join(missing_exception_classes)
        )
    for record in exceptions:
        entries = record["source_entries"]
        if entries != sorted(entries) or len(entries) != len(set(entries)):
            raise CatalogValidationError(f"exception {record['id']} source entries must be sorted and unique")
        if record["review_state"] != "accepted":
            raise CatalogValidationError(f"exception {record['id']} must have accepted source-review state")

    return {
        "families": len(records),
        "categories": len(category_counts),
        "exceptions": len(exceptions),
        "unresolved_dispositions": sum(
            record["classification"]["disposition"] == "unresolved" for record in records
        ),
    }


def validate_generated_view(document: dict[str, Any], generated_text: str) -> None:
    from generate_component_catalog import render_catalog

    expected = render_catalog(document)
    if generated_text != expected:
        raise CatalogValidationError("generated component-catalog view is stale")


def validate_repository() -> list[str]:
    lock = load_json(REFERENCE_LOCK_PATH)
    snapshot_path = CATALOG_DIR / str(lock.get("family_snapshot", {}).get("path", ""))
    try:
        snapshot_bytes = snapshot_path.read_bytes()
    except OSError as error:
        raise CatalogValidationError(f"cannot read source-family snapshot {snapshot_path}: {error}") from error
    families = validate_reference(lock, snapshot_bytes)
    schema = load_json(CATALOG_SCHEMA_PATH)
    validate_catalog_schema(schema)
    catalog = load_json(CATALOG_PATH)
    summary = validate_catalog_semantics(catalog, families)
    try:
        generated_text = GENERATED_CATALOG_PATH.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as error:
        raise CatalogValidationError(
            f"cannot read generated component-catalog view {GENERATED_CATALOG_PATH}: {error}"
        ) from error
    validate_generated_view(catalog, generated_text)
    return [
        f"reference {lock['reference_id']}",
        f"{len(families)} locked source families",
        "catalog schema 1.0.0",
        f"{summary['families']} normalized families in {summary['categories']} categories",
        f"{summary['exceptions']} source-closure exceptions",
        f"{summary['unresolved_dispositions']} unresolved product dispositions",
        "fresh generated view",
    ]


def main() -> int:
    try:
        checks = validate_repository()
    except CatalogValidationError as error:
        print(f"Component catalog validation failed: {error}", file=sys.stderr)
        return 1
    print("Component catalog validation passed: " + "; ".join(checks) + ".")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
