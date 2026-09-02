#!/usr/bin/env python3
"""Focused tests for the BH-00 browser product envelope validator."""

from __future__ import annotations

import copy
import unittest

from validate_browser_product_envelope import load_contract, validate_contract


class BrowserProductEnvelopeValidatorTests(unittest.TestCase):
    """Exercise positive and important fail-closed policy paths."""

    def setUp(self) -> None:
        self.contract = load_contract()

    def test_repository_contract_is_valid(self) -> None:
        self.assertEqual(validate_contract(self.contract), [])

    def test_duplicate_browser_id_is_rejected(self) -> None:
        contract = copy.deepcopy(self.contract)
        contract["browser_configurations"].append(
            copy.deepcopy(contract["browser_configurations"][0])
        )
        errors = validate_contract(contract)
        self.assertTrue(any("duplicate id BR-CHROMIUM-DESKTOP" in item for item in errors))

    def test_browser_cannot_claim_support_before_bh01(self) -> None:
        contract = copy.deepcopy(self.contract)
        contract["browser_configurations"][0]["current_status"] = "supported"
        errors = validate_contract(contract)
        self.assertTrue(any("must remain unsupported before BH-01" in item for item in errors))

    def test_missing_evidence_class_is_rejected(self) -> None:
        contract = copy.deepcopy(self.contract)
        contract["evidence_classes"] = contract["evidence_classes"][1:]
        errors = validate_contract(contract)
        self.assertTrue(any("missing ids: EC-DESKTOP" in item for item in errors))

    def test_toolchain_cannot_skip_candidate_state(self) -> None:
        contract = copy.deepcopy(self.contract)
        contract["toolchain_inputs"][0]["current_state"] = "tested"
        errors = validate_contract(contract)
        self.assertTrue(any("must remain candidate before BH-01" in item for item in errors))


if __name__ == "__main__":
    unittest.main()
