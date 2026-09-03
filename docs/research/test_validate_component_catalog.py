#!/usr/bin/env python3
"""Focused tests for the component-catalog validator."""

from __future__ import annotations

import copy
import hashlib
import unittest

import validate_component_catalog as validator


class ComponentCatalogValidatorTests(unittest.TestCase):
    def setUp(self) -> None:
        self.lock = validator.load_json(validator.REFERENCE_LOCK_PATH)
        snapshot_name = self.lock["family_snapshot"]["path"]
        self.snapshot = (validator.CATALOG_DIR / snapshot_name).read_bytes()

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


if __name__ == "__main__":
    unittest.main()
