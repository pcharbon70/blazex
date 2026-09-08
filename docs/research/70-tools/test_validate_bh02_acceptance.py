from __future__ import annotations

import copy
import json
import unittest

import validate_bh02_acceptance as validator


class BH02AcceptanceValidatorTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.phase_contract = json.loads(validator.PHASE_CONTRACT.read_text(encoding="utf-8"))
        cls.reconciliation = json.loads(validator.RECONCILIATION.read_text(encoding="utf-8"))
        cls.baseline = json.loads(validator.CONTRACT_BASELINE.read_text(encoding="utf-8"))
        cls.review = json.loads(validator.REVIEW.read_text(encoding="utf-8"))
        cls.overlay = json.loads(validator.OVERLAY.read_text(encoding="utf-8"))
        cls.decision = json.loads(validator.CANDIDATE_DECISION.read_text(encoding="utf-8"))
        cls.entry = json.loads(validator.ENTRY.read_text(encoding="utf-8"))
        cls.registry = json.loads(validator.REGISTRY.read_text(encoding="utf-8"))
        cls.conformance = json.loads(validator.CONFORMANCE.read_text(encoding="utf-8"))

    def test_current_candidate_passes(self) -> None:
        validator.validate()

    def test_rejects_missing_required_output(self) -> None:
        reconciliation = copy.deepcopy(self.reconciliation)
        reconciliation["required_outputs"].pop()
        with self.assertRaisesRegex(validator.ValidationError, "required outputs"):
            validator.validate_reconciliation(self.phase_contract, reconciliation, self.entry, self.conformance)

    def test_rejects_stale_phase_evidence(self) -> None:
        reconciliation = copy.deepcopy(self.reconciliation)
        reconciliation["phase_decisions"][0]["sha256"] = "0" * 64
        with self.assertRaisesRegex(validator.ValidationError, "stale evidence"):
            validator.validate_reconciliation(self.phase_contract, reconciliation, self.entry, self.conformance)

    def test_rejects_hidden_finding(self) -> None:
        review = copy.deepcopy(self.review)
        review["finding_dispositions"].pop()
        with self.assertRaisesRegex(validator.ValidationError, "hides or invents"):
            validator.validate_review(review, self.reconciliation)

    def test_rejects_false_accessibility_qualification(self) -> None:
        overlay = copy.deepcopy(self.overlay)
        overlay["condition_updates"][2].update(status="passed", implementation_state="implemented", verification_state="passed", evidence_ids=["invented"])
        with self.assertRaisesRegex(validator.ValidationError, "falsely qualified"):
            validator.validate_overlay(overlay, self.registry)

    def test_rejects_public_api_stability(self) -> None:
        baseline = copy.deepcopy(self.baseline)
        baseline["stability"]["public_api"] = "stable"
        with self.assertRaisesRegex(validator.ValidationError, "promotes stability"):
            validator.validate_contract_baseline(baseline)

    def test_rejects_premature_bh03_authorization(self) -> None:
        overlay = copy.deepcopy(self.overlay)
        overlay["bh03_state"] = "authorized"
        with self.assertRaisesRegex(validator.ValidationError, "prematurely authorized"):
            validator.validate_overlay(overlay, self.registry)


if __name__ == "__main__":
    unittest.main()
