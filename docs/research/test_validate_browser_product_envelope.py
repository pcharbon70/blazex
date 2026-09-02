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

    def test_missing_rendering_mode_is_rejected(self) -> None:
        contract = copy.deepcopy(self.contract)
        contract["rendering_modes"] = contract["rendering_modes"][1:]
        errors = validate_contract(contract)
        self.assertTrue(any("missing ids: MODE-STATIC-FALLBACK" in item for item in errors))

    def test_incomplete_profile_capability_matrix_is_rejected(self) -> None:
        contract = copy.deepcopy(self.contract)
        del contract["profile_capabilities"][0]["profile_values"]["PROFILE-HEADLESS"]
        errors = validate_contract(contract)
        self.assertTrue(any("missing ids: PROFILE-HEADLESS" in item for item in errors))

    def test_plug_cannot_inherit_realtime(self) -> None:
        contract = copy.deepcopy(self.contract)
        for capability in contract["profile_capabilities"]:
            if capability["id"] == "CAP-REALTIME":
                capability["profile_values"]["PROFILE-BROWSER-PLUG"] = "required"
        errors = validate_contract(contract)
        self.assertTrue(any("browser/Plug baseline must be absent" in item for item in errors))

    def test_plug_renderer_must_remain_standalone(self) -> None:
        contract = copy.deepcopy(self.contract)
        for profile in contract["profiles"]:
            if profile["id"] == "PROFILE-BROWSER-PLUG":
                profile["renderer"] = "liveview-dom"
        errors = validate_contract(contract)
        self.assertTrue(any("renderer must be standalone-dom" in item for item in errors))


if __name__ == "__main__":
    unittest.main()
