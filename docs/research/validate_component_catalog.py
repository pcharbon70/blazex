#!/usr/bin/env python3
"""Validate the pinned component-catalog reference and generated artifacts."""

from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parent
CATALOG_DIR = ROOT / "assets" / "component-catalog"
REFERENCE_LOCK_PATH = CATALOG_DIR / "mudblazor-v9.9.0-reference-lock.json"

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


def validate_repository() -> list[str]:
    lock = load_json(REFERENCE_LOCK_PATH)
    snapshot_path = CATALOG_DIR / str(lock.get("family_snapshot", {}).get("path", ""))
    try:
        snapshot_bytes = snapshot_path.read_bytes()
    except OSError as error:
        raise CatalogValidationError(f"cannot read source-family snapshot {snapshot_path}: {error}") from error
    families = validate_reference(lock, snapshot_bytes)
    return [
        f"reference {lock['reference_id']}",
        f"{len(families)} locked source families",
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
