#!/usr/bin/env python3
"""Focused tests for the Phase 4 component-classification validator."""

from __future__ import annotations

import copy
import unittest

import validate_component_classification as validator


class ComponentClassificationValidatorTests(unittest.TestCase):
    def setUp(self) -> None:
        self.schema = validator.load_json(validator.SCHEMA_PATH)
        self.document = validator.load_json(validator.CLASSIFICATION_PATH)
        self.source = validator.load_json(validator.SOURCE_CATALOG_PATH)

    def validate(self, document: dict) -> dict:
        return validator.validate_classification(document, self.source, self.schema)

    def test_repository_classification_is_valid(self) -> None:
        summary = self.validate(self.document)
        self.assertEqual(83, summary["families"])
        self.assertEqual(12, summary["exceptions"])

    def test_source_hash_drift_is_rejected(self) -> None:
        changed = copy.deepcopy(self.document)
        changed["source_catalog_sha256"] = "0" * 64
        with self.assertRaisesRegex(validator.ClassificationValidationError, "source catalog hash mismatch"):
            self.validate(changed)

    def test_missing_family_is_rejected(self) -> None:
        changed = copy.deepcopy(self.document)
        changed["families"] = changed["families"][1:]
        with self.assertRaisesRegex(validator.ClassificationValidationError, "family mismatch"):
            self.validate(changed)

    def test_duplicate_public_identity_is_rejected(self) -> None:
        changed = copy.deepcopy(self.document)
        changed["families"][1]["product"]["intended_public_identity"] = changed["families"][0]["product"]["intended_public_identity"]
        with self.assertRaisesRegex(validator.ClassificationValidationError, "duplicate intended public identities"):
            self.validate(changed)

    def test_later_tier_prerequisite_is_rejected(self) -> None:
        changed = copy.deepcopy(self.document)
        changed["families"][0]["product"]["prerequisites"] = ["BX-FAM-CHART"]
        with self.assertRaisesRegex(validator.ClassificationValidationError, "later-tier"):
            self.validate(changed)

    def test_forbidden_package_layer_is_rejected(self) -> None:
        changed = copy.deepcopy(self.document)
        alert = next(record for record in changed["families"] if record["family_id"] == "BX-FAM-ALERT")
        alert["product"]["prerequisites"] = ["BX-FAM-OVERLAY"]
        with self.assertRaisesRegex(validator.ClassificationValidationError, "cannot depend"):
            self.validate(changed)

    def test_premature_implementation_claim_is_rejected(self) -> None:
        changed = copy.deepcopy(self.document)
        changed["families"][0]["implementation_state"] = "implemented"
        with self.assertRaisesRegex(validator.ClassificationValidationError, "schema violation"):
            self.validate(changed)

    def test_section_4_1_rejects_capability_assignment(self) -> None:
        changed = copy.deepcopy(self.document)
        changed["stage"] = "section-4.1"
        with self.assertRaisesRegex(validator.ClassificationValidationError, "leave capability"):
            self.validate(changed)

    def test_section_4_2_rejects_unassigned_remote_authority(self) -> None:
        changed = copy.deepcopy(self.document)
        changed["families"][0]["remote"] = {"authority": "unassigned", "rationale": None}
        with self.assertRaisesRegex(validator.ClassificationValidationError, "remote-authority"):
            self.validate(changed)

    def test_unknown_capability_is_rejected(self) -> None:
        changed = copy.deepcopy(self.document)
        target = next(
            record for record in changed["families"]
            if record["portability"]["status"] == "portable-with-capabilities"
        )
        target["capability"]["optional"].append("BX-CAP-NOT-REGISTERED")
        with self.assertRaisesRegex(validator.ClassificationValidationError, "unknown capabilities"):
            self.validate(changed)

    def test_required_capability_without_fallback_is_rejected(self) -> None:
        changed = copy.deepcopy(self.document)
        changed["families"][0]["fallback"]["conditions"]["missing-capability"] = "not-required"
        with self.assertRaisesRegex(validator.ClassificationValidationError, "missing-capability fallback"):
            self.validate(changed)

    def test_backend_specific_portable_requirement_is_rejected(self) -> None:
        changed = copy.deepcopy(self.document)
        changed["families"][0]["capability"]["portable_requirement_tokens"].append("javascript.handle")
        with self.assertRaisesRegex(validator.ClassificationValidationError, "leaks backend token"):
            self.validate(changed)

    def test_unproven_portability_is_rejected_after_section_4_2(self) -> None:
        changed = copy.deepcopy(self.document)
        changed["families"][0]["portability"]["status"] = "unproven"
        with self.assertRaisesRegex(validator.ClassificationValidationError, "unproven portability"):
            self.validate(changed)

    def test_portable_semantic_with_specialized_capability_is_rejected(self) -> None:
        changed = copy.deepcopy(self.document)
        target = next(
            record for record in changed["families"]
            if record["portability"]["status"] == "portable-with-capabilities"
        )
        target["portability"]["status"] = "portable-semantic"
        with self.assertRaisesRegex(validator.ClassificationValidationError, "specialized capabilities"):
            self.validate(changed)

    def test_renderer_extension_without_extension_id_is_rejected(self) -> None:
        changed = copy.deepcopy(self.document)
        target = next(
            record for record in changed["families"]
            if record["portability"]["status"] == "renderer-extension"
        )
        target["portability"]["renderer_extensions"] = []
        with self.assertRaisesRegex(validator.ClassificationValidationError, "renderer-extension classification"):
            self.validate(changed)

    def test_headless_and_dom_cannot_skip_native_spike_gate(self) -> None:
        changed = copy.deepcopy(self.document)
        target = next(
            record for record in changed["families"]
            if record["portability"]["status"] != "renderer-extension"
        )
        target["portability"]["future_backend_gate"]["native_spike"] = "not-applicable"
        with self.assertRaisesRegex(validator.ClassificationValidationError, "native-spike gate"):
            self.validate(changed)

    def test_stale_generated_view_is_rejected(self) -> None:
        with self.assertRaisesRegex(validator.ClassificationValidationError, "stale"):
            validator.validate_generated_view(self.document, self.source, "stale\n")


if __name__ == "__main__":
    unittest.main()
