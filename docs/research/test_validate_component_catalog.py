#!/usr/bin/env python3
"""Focused tests for the component-catalog validator."""

from __future__ import annotations

import copy
import hashlib
import unittest

import validate_component_catalog as validator


def valid_catalog_specimen() -> dict:
    return {
        "schema_version": "1.0.0",
        "catalog_version": "0.1.0",
        "catalog_id": "BX-CATALOG-CORE",
        "reference_id": "mudblazor-v9.9.0",
        "title": "Test catalog",
        "description": "Schema-validation specimen.",
        "catalog_status": "draft",
        "authored_source": "assets/component-catalog/catalog.json",
        "generated_view": "assets/component-catalog/catalog.generated.md",
        "sort_order": "family-id-unicode-codepoint-ascending",
        "owner_roles": ["catalog owner"],
        "families": [
            {
                "id": "BX-FAM-ALERT",
                "display_name": "Alert",
                "category": "actions-feedback",
                "source": {
                    "reference_id": "mudblazor-v9.9.0",
                    "source_family": "Alert",
                    "source_paths": ["src/MudBlazor/Components/Alert"],
                    "source_identifiers": [],
                },
                "aliases": [],
                "relationships": [],
                "lifecycle_status": "active",
                "inclusion_reason": "Locked first-level component family.",
                "classification": {
                    "disposition": "unresolved",
                    "rationale": None,
                    "delivery_tier": "unassigned",
                    "target_package": None,
                    "prerequisites": [],
                    "optional_package": None,
                    "payload_class": "unassigned",
                    "intended_public_identity": None,
                },
                "capability_contract": {
                    "required_capabilities": [],
                    "optional_capabilities": [],
                    "fallback": None,
                    "rendering_modes": {"state": "unknown", "entries": [], "rationale": None},
                    "runtime_eligibility": {"state": "unknown", "entries": [], "rationale": None},
                    "backend_portability": "unknown",
                    "native_strategy": "unknown",
                    "accessibility_alternative": None,
                    "renderer_extensions": [],
                },
                "implementation": {"delivery_state": "unknown", "implementation_evidence": []},
            }
        ],
        "exceptions": [],
    }


class ComponentCatalogValidatorTests(unittest.TestCase):
    def setUp(self) -> None:
        self.lock = validator.load_json(validator.REFERENCE_LOCK_PATH)
        snapshot_name = self.lock["family_snapshot"]["path"]
        self.snapshot = (validator.CATALOG_DIR / snapshot_name).read_bytes()
        self.schema = validator.load_json(validator.CATALOG_SCHEMA_PATH)

    def test_repository_reference_is_valid(self) -> None:
        families = validator.validate_reference(self.lock, self.snapshot)
        self.assertEqual(83, len(families))
        self.assertEqual("Alert", families[0])
        self.assertEqual("Virtualize", families[-1])

    def test_wrong_commit_is_rejected(self) -> None:
        changed = copy.deepcopy(self.lock)
        changed["commit"] = "0" * 40
        with self.assertRaisesRegex(validator.CatalogValidationError, "reference.commit"):
            validator.validate_reference(changed, self.snapshot)

    def test_snapshot_hash_mismatch_is_rejected(self) -> None:
        with self.assertRaisesRegex(validator.CatalogValidationError, "SHA-256 mismatch"):
            validator.validate_reference(self.lock, self.snapshot + b"Unexpected\n")

    def test_unsorted_or_duplicate_snapshot_is_rejected(self) -> None:
        changed = copy.deepcopy(self.lock)
        lines = self.snapshot.decode("utf-8").splitlines()
        lines[1] = lines[0]
        altered = ("\n".join(lines) + "\n").encode("utf-8")
        changed["family_snapshot"]["sha256"] = hashlib.sha256(altered).hexdigest()
        with self.assertRaisesRegex(validator.CatalogValidationError, "duplicate"):
            validator.validate_reference(changed, altered)

    def test_automatic_disposition_mutation_is_rejected(self) -> None:
        changed = copy.deepcopy(self.lock)
        changed["later_reference_update"]["mutates_blazex_dispositions_automatically"] = True
        with self.assertRaisesRegex(
            validator.CatalogValidationError,
            "mutates_blazex_dispositions_automatically",
        ):
            validator.validate_reference(changed, self.snapshot)

    def test_catalog_schema_and_specimen_are_valid(self) -> None:
        validator.validate_catalog_document(valid_catalog_specimen(), self.schema)

    def test_invalid_family_id_is_rejected_by_schema(self) -> None:
        changed = valid_catalog_specimen()
        changed["families"][0]["id"] = "alert"
        with self.assertRaisesRegex(validator.CatalogValidationError, "catalog schema violation"):
            validator.validate_catalog_document(changed, self.schema)

    def test_unknown_family_field_is_rejected_by_schema(self) -> None:
        changed = valid_catalog_specimen()
        changed["families"][0]["runtime_atom"] = "alert"
        with self.assertRaisesRegex(validator.CatalogValidationError, "was unexpected"):
            validator.validate_catalog_document(changed, self.schema)

    def test_unsupported_delivery_state_is_rejected_by_schema(self) -> None:
        changed = valid_catalog_specimen()
        changed["families"][0]["implementation"]["delivery_state"] = "done"
        with self.assertRaisesRegex(validator.CatalogValidationError, "catalog schema violation"):
            validator.validate_catalog_document(changed, self.schema)


if __name__ == "__main__":
    unittest.main()
