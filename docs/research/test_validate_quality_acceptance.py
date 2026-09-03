#!/usr/bin/env python3
"""Tests for the BlazeX quality and acceptance validator."""

from __future__ import annotations

import copy
import unittest

import validate_quality_acceptance as validator


class QualityAcceptanceValidationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.schema = validator.load_json(validator.QUALITY_SCHEMA_PATH)
        cls.document = validator.load_json(validator.QUALITY_PATH)

    def validate(self, document: dict) -> dict[str, int]:
        return validator.validate_quality_contract(document, self.schema)

    def test_repository_contract_passes(self) -> None:
        counts = self.validate(copy.deepcopy(self.document))
        self.assertEqual(set(counts), validator.EXPECTED_DIMENSIONS)

    def test_rejects_duplicate_budget_id(self) -> None:
        document = copy.deepcopy(self.document)
        document["budgets"][1]["id"] = document["budgets"][0]["id"]
        with self.assertRaisesRegex(validator.QualityAcceptanceValidationError, "sorted|unique"):
            self.validate(document)

    def test_rejects_unknown_environment(self) -> None:
        document = copy.deepcopy(self.document)
        document["budgets"][0]["environment_refs"] = ["BX-ENV-NOT-DECLARED"]
        with self.assertRaisesRegex(validator.QualityAcceptanceValidationError, "unknown environments"):
            self.validate(document)

    def test_rejects_missing_payload_boundary(self) -> None:
        document = copy.deepcopy(self.document)
        document["budgets"] = [
            budget for budget in document["budgets"]
            if budget["id"] != "BX-BUD-PAYLOAD-LOADER-COMPRESSED-KIB"
        ]
        with self.assertRaisesRegex(validator.QualityAcceptanceValidationError, "payload budgets"):
            self.validate(document)

    def test_rejects_missing_failure_scenario(self) -> None:
        document = copy.deepcopy(self.document)
        document["failure_scenarios"].pop()
        with self.assertRaisesRegex(validator.QualityAcceptanceValidationError, "schema violation|eight required"):
            self.validate(document)

    def test_rejects_waivable_release_blocker(self) -> None:
        document = copy.deepcopy(self.document)
        document["release_blockers"][0]["waiver"] = "time-bounded"
        with self.assertRaisesRegex(validator.QualityAcceptanceValidationError, "schema violation"):
            self.validate(document)

    def test_rejects_premature_measurement(self) -> None:
        document = copy.deepcopy(self.document)
        document["budgets"][0]["measurement_state"] = "passed"
        with self.assertRaisesRegex(validator.QualityAcceptanceValidationError, "schema violation|falsely claims"):
            self.validate(document)

    def test_rejects_evidence_id(self) -> None:
        document = copy.deepcopy(self.document)
        document["evidence_state"]["evidence_ids"] = ["BX-EVIDENCE-FABRICATED"]
        with self.assertRaisesRegex(validator.QualityAcceptanceValidationError, "schema violation"):
            self.validate(document)

    def test_rejects_section_5_2_gate_in_section_5_1(self) -> None:
        document = copy.deepcopy(self.document)
        document["stage"] = "section-5.1"
        with self.assertRaisesRegex(validator.QualityAcceptanceValidationError, "pre-empt"):
            self.validate(document)

    def test_rejects_approved_exception_during_bh_00(self) -> None:
        document = copy.deepcopy(self.document)
        document["exceptions"] = [{
            "id": "BX-EXC-TEST",
            "scope": "test budget",
            "rationale": "A deliberately invalid exception for validation testing.",
            "owner": "quality-owner",
            "approved_by": "product-owner",
            "expires_on": "2026-12-01",
            "status": "approved",
        }]
        with self.assertRaisesRegex(validator.QualityAcceptanceValidationError, "no approved"):
            self.validate(document)

    def test_rejects_missing_cross_cutting_gate(self) -> None:
        document = copy.deepcopy(self.document)
        document["cross_cutting_gates"].pop()
        with self.assertRaisesRegex(validator.QualityAcceptanceValidationError, "identities"):
            self.validate(document)

    def test_rejects_missing_gate_requirement(self) -> None:
        document = copy.deepcopy(self.document)
        document["cross_cutting_gates"][0]["requirements"].pop()
        with self.assertRaisesRegex(validator.QualityAcceptanceValidationError, "coverage is incomplete"):
            self.validate(document)

    def test_rejects_executed_gate_evidence(self) -> None:
        document = copy.deepcopy(self.document)
        document["cross_cutting_gates"][0]["evidence_ids"] = ["BX-EVIDENCE-FABRICATED"]
        with self.assertRaisesRegex(validator.QualityAcceptanceValidationError, "schema violation|falsely claims"):
            self.validate(document)

    def test_rejects_downgraded_security_requirement(self) -> None:
        document = copy.deepcopy(self.document)
        security = next(gate for gate in document["cross_cutting_gates"] if gate["id"] == "BX-GATE-SECURITY")
        security["requirements"][0]["minimum_severity"] = "high"
        with self.assertRaisesRegex(validator.QualityAcceptanceValidationError, "security requirements"):
            self.validate(document)

    def test_rejects_downgraded_essential_accessibility_requirement(self) -> None:
        document = copy.deepcopy(self.document)
        accessibility = next(gate for gate in document["cross_cutting_gates"] if gate["id"] == "BX-GATE-ACCESSIBILITY")
        fallback = next(req for req in accessibility["requirements"] if req["id"] == "BX-GREQ-A11Y-FALLBACK")
        fallback["minimum_severity"] = "high"
        with self.assertRaisesRegex(validator.QualityAcceptanceValidationError, "essential accessibility"):
            self.validate(document)


if __name__ == "__main__":
    unittest.main()
