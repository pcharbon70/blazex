#!/usr/bin/env python3
"""Focused fail-closed tests for BH-02 Phase 7 native evidence."""

from __future__ import annotations

import copy
import unittest

import validate_bh02_native as native


class NativeValidationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.auth = native._load_json(native.AUTHORIZATION)
        cls.contract = native._load_json(native.CONTRACT)
        cls.ledger = native._load_json(native.LEDGER)
        cls.fixtures = native._load_json(native.FIXTURES)
        cls.index = native._load_json(native.INDEX)
        cls.experiment = native._load_json(native.EXPERIMENT_INDEX)
        cls.evidence = native._load_json(native.GTK_EVIDENCE)

    def rejects(self, function, value, *extra) -> None:
        with self.assertRaises(native.ValidationError):
            function(value, *extra)

    def test_current_authorization_and_contract_pass(self) -> None:
        native.validate_authorization(copy.deepcopy(self.auth))
        native.validate_contract(copy.deepcopy(self.contract), copy.deepcopy(self.auth))

    def test_rejects_unapproved_authorization(self) -> None:
        value = copy.deepcopy(self.auth)
        value["status"] = "draft"
        self.rejects(native.validate_authorization, value)

    def test_rejects_stale_authorization_input(self) -> None:
        value = copy.deepcopy(self.auth)
        value["approval_basis"][0]["sha256"] = "0" * 64
        self.rejects(native.validate_authorization, value)

    def test_rejects_missing_delivery_rule(self) -> None:
        value = copy.deepcopy(self.auth)
        value["delivery_rules"]["single_pull_request"] = False
        self.rejects(native.validate_authorization, value)

    def test_rejects_cross_platform_toolkit_authorization(self) -> None:
        value = copy.deepcopy(self.contract)
        value["experiment_boundary"]["forbidden_direct_or_transitive"].remove("qt")
        self.rejects(native.validate_contract, value, self.auth)

    def test_rejects_changed_native_surface(self) -> None:
        value = copy.deepcopy(self.contract)
        value["native_node"]["fields"].append("platform_object")
        self.rejects(native.validate_contract, value, self.auth)

    def test_rejects_platform_object_in_portable_source(self) -> None:
        self.rejects(native.validate_source_text, "def render, do: GtkWidget")

    def test_rejects_false_gtk_pass(self) -> None:
        value = copy.deepcopy(self.evidence)
        value["result"] = "failed"
        self.rejects(native.validate_gtk_evidence, value)

    def test_rejects_missing_actual_control(self) -> None:
        value = copy.deepcopy(self.evidence)
        value["controls"].pop()
        self.rejects(native.validate_gtk_evidence, value)

    def test_rejects_missing_stale_rejection(self) -> None:
        value = copy.deepcopy(self.evidence)
        value["observation"] = value["observation"].replace("stale_rejected=1", "stale_rejected=0")
        self.rejects(native.validate_gtk_evidence, value)

    def test_rejects_gtk_support_claim(self) -> None:
        value = copy.deepcopy(self.evidence)
        value["support_state"] = "supported"
        self.rejects(native.validate_gtk_evidence, value)

    def test_rejects_false_windows_pass(self) -> None:
        value = copy.deepcopy(self.experiment)
        value["adapters"][0]["state"] = "passed"
        self.rejects(native.validate_experiment_index, value, self.evidence)

    def test_rejects_missing_native_scenario(self) -> None:
        value = copy.deepcopy(self.fixtures)
        value["scenarios"].pop()
        self.rejects(native.validate_fixtures, value)

    def test_rejects_visual_overclaim(self) -> None:
        value = copy.deepcopy(self.fixtures)
        value["visual_results"] = [{"result": "passed"}]
        self.rejects(native.validate_fixtures, value)

    def test_rejects_stale_fixture_binding(self) -> None:
        value = copy.deepcopy(self.index)
        value["fixture_sets"][-1]["sha256"] = "0" * 64
        self.rejects(native.validate_conformance_index, value)

    def test_rejects_premature_phase_8_authority(self) -> None:
        value = copy.deepcopy(self.index)
        value["next_authorized_work"] = "BH-02 Phase 8"
        self.rejects(native.validate_conformance_index, value)

    def test_rejects_native_ledger_overclaim(self) -> None:
        value = copy.deepcopy(self.ledger)
        value["evidence_boundary"]["native_accessibility_roles"] = "qualified"
        self.rejects(native.validate_ledger, value)

    def test_rejects_supported_ledger(self) -> None:
        value = copy.deepcopy(self.ledger)
        value["evidence_boundary"]["support"] = "supported"
        self.rejects(native.validate_ledger, value)


if __name__ == "__main__":
    unittest.main()
