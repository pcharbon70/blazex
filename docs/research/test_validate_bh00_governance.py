#!/usr/bin/env python3
"""Tests for the BlazeX BH-00 governance validator."""

from __future__ import annotations

import copy
import unittest

import validate_bh00_governance as validator


class GovernanceValidationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.schema = validator.load_json(validator.SCHEMA_PATH)
        cls.document = validator.load_json(validator.CONTRACT_PATH)

    def validate(self, document: dict) -> dict[str, int]:
        return validator.validate_contract(document, self.schema)

    def test_repository_contract_passes(self) -> None:
        counts = self.validate(copy.deepcopy(self.document))
        self.assertEqual(counts["packages"], 18)
        self.assertEqual(counts["reconciliation_checks"], 17)
        self.assertEqual(counts["reviews"], 8)
        self.assertEqual(counts["findings"], 8)
        self.assertEqual(counts["risks"], 8)
        self.assertEqual(self.document["bh01_entry"]["decision"], "conditionally-ready")

    def test_rejects_stale_source_hash(self) -> None:
        document = copy.deepcopy(self.document)
        document["source_bindings"][0]["sha256"] = "0" * 64
        with self.assertRaisesRegex(validator.GovernanceValidationError, "source binding is stale"):
            self.validate(document)

    def test_rejects_missing_adr_binding(self) -> None:
        document = copy.deepcopy(self.document)
        document["source_bindings"] = [record for record in document["source_bindings"] if record["id"] != "BX-BH00-SOURCE-ADR-0008"]
        with self.assertRaisesRegex(validator.GovernanceValidationError, "eight accepted ADRs"):
            self.validate(document)

    def test_rejects_missing_architecture_axis(self) -> None:
        document = copy.deepcopy(self.document)
        document["architecture_axes"].pop()
        with self.assertRaisesRegex(validator.GovernanceValidationError, "schema violation|six independent"):
            self.validate(document)

    def test_rejects_missing_package_boundary(self) -> None:
        document = copy.deepcopy(self.document)
        document["package_boundaries"].pop()
        with self.assertRaisesRegex(validator.GovernanceValidationError, "schema violation|eighteen package"):
            self.validate(document)

    def test_rejects_missing_plug_exclusion(self) -> None:
        document = copy.deepcopy(self.document)
        plug = next(record for record in document["profile_boundaries"] if record["id"] == "PROFILE-BROWSER-PLUG")
        plug["forbidden_dependencies"].remove("phoenix")
        with self.assertRaisesRegex(validator.GovernanceValidationError, "Plug profile transitive exclusions"):
            self.validate(document)

    def test_rejects_unresolved_reconciliation_conflict(self) -> None:
        document = copy.deepcopy(self.document)
        document["reconciliation_checks"][0]["conflicts"] = ["conflict"]
        with self.assertRaisesRegex(validator.GovernanceValidationError, "schema violation|unresolved conflict"):
            self.validate(document)

    def test_rejects_false_runtime_implementation(self) -> None:
        document = copy.deepcopy(self.document)
        document["evidence_boundary"]["runtime_implementation"] = "implemented"
        with self.assertRaisesRegex(validator.GovernanceValidationError, "schema violation|overstates"):
            self.validate(document)

    def test_rejects_false_browser_support(self) -> None:
        document = copy.deepcopy(self.document)
        document["evidence_boundary"]["browser_support"] = "supported"
        with self.assertRaisesRegex(validator.GovernanceValidationError, "schema violation|overstates"):
            self.validate(document)

    def test_rejects_premature_review(self) -> None:
        document = copy.deepcopy(self.document)
        document["stage"] = "section-6.1"
        document["status"] = "reconciled-pending-review"
        document["findings"] = []
        document["risks"] = []
        document["evidence_boundary"]["contract_evidence"] = "reconciled"
        document["evidence_boundary"]["evidence_ids"] = ["BX-BH00-EVIDENCE-RECONCILIATION-6-1"]
        document["reviews"] = [{
            "id": "BX-BH00-REVIEW-TEST",
            "discipline": "product",
            "reviewer_role": "test-reviewer",
            "independence": "A deliberately invalid premature review record for validator testing only.",
            "scope": ["scope-a", "scope-b"],
            "outcome": "accepted",
            "finding_ids": [],
            "evidence_id": "BX-BH00-EVIDENCE-TEST",
        }]
        with self.assertRaisesRegex(validator.GovernanceValidationError, "cannot pre-empt"):
            self.validate(document)

    def test_rejects_premature_release(self) -> None:
        document = copy.deepcopy(self.document)
        document["release"] = {}
        with self.assertRaisesRegex(validator.GovernanceValidationError, "schema violation"):
            self.validate(document)

    def test_rejects_accepted_exception(self) -> None:
        document = copy.deepcopy(self.document)
        document["exceptions"] = ["exception"]
        with self.assertRaisesRegex(validator.GovernanceValidationError, "schema violation|no accepted exception"):
            self.validate(document)

    def test_rejects_missing_discipline_review(self) -> None:
        document = copy.deepcopy(self.document)
        document["reviews"].pop()
        with self.assertRaisesRegex(validator.GovernanceValidationError, "eight independent"):
            self.validate(document)

    def test_rejects_blocking_review_finding(self) -> None:
        document = copy.deepcopy(self.document)
        document["findings"][0]["severity"] = "blocker"
        document["findings"][0]["status"] = "blocking"
        with self.assertRaisesRegex(validator.GovernanceValidationError, "remains blocking"):
            self.validate(document)

    def test_rejects_unknown_review_finding(self) -> None:
        document = copy.deepcopy(self.document)
        document["reviews"][0]["finding_ids"] = ["BX-BH00-FIND-NOT-DECLARED"]
        with self.assertRaisesRegex(validator.GovernanceValidationError, "unknown finding"):
            self.validate(document)

    def test_rejects_missing_bh01_risk(self) -> None:
        document = copy.deepcopy(self.document)
        document["risks"].pop()
        with self.assertRaisesRegex(validator.GovernanceValidationError, "risk register is incomplete"):
            self.validate(document)

    def test_rejects_premature_entry_decision(self) -> None:
        document = copy.deepcopy(self.document)
        document["bh01_entry"] = {}
        with self.assertRaisesRegex(validator.GovernanceValidationError, "schema violation"):
            self.validate(document)

    def test_rejects_unconditional_bh01_readiness(self) -> None:
        document = copy.deepcopy(self.document)
        document["bh01_entry"]["decision"] = "ready"
        with self.assertRaisesRegex(validator.GovernanceValidationError, "must remain conditional"):
            self.validate(document)

    def test_rejects_missing_bh01_input(self) -> None:
        document = copy.deepcopy(self.document)
        document["bh01_entry"]["input_manifest"].pop()
        with self.assertRaisesRegex(validator.GovernanceValidationError, "schema violation|input manifest is incomplete"):
            self.validate(document)

    def test_rejects_missing_bh01_proof(self) -> None:
        document = copy.deepcopy(self.document)
        document["bh01_entry"]["proof_obligations"].pop()
        with self.assertRaisesRegex(validator.GovernanceValidationError, "proof obligations are incomplete"):
            self.validate(document)

    def test_rejects_unknown_proof_acceptance(self) -> None:
        document = copy.deepcopy(self.document)
        document["bh01_entry"]["proof_obligations"][0]["acceptance_refs"] = ["BX-ACC-NOT-DECLARED"]
        with self.assertRaisesRegex(validator.GovernanceValidationError, "unknown acceptance condition"):
            self.validate(document)

    def test_rejects_stale_release_manifest_hash(self) -> None:
        document = copy.deepcopy(self.document)
        document["release"]["source_manifest_sha256"] = "0" * 64
        with self.assertRaisesRegex(validator.GovernanceValidationError, "source manifest hash is stale"):
            self.validate(document)

    def test_rejects_failed_proof_without_stop(self) -> None:
        document = copy.deepcopy(self.document)
        document["bh01_entry"]["proof_obligations"][0]["stop_on_failure"] = False
        with self.assertRaisesRegex(validator.GovernanceValidationError, "cannot continue after failure"):
            self.validate(document)

    def test_rejects_missing_final_acceptance_evidence(self) -> None:
        document = copy.deepcopy(self.document)
        document["evidence_boundary"]["evidence_ids"].remove("BX-BH00-EVIDENCE-FINAL-ACCEPTANCE-6-4")
        with self.assertRaisesRegex(validator.GovernanceValidationError, "complete BH-00 evidence identities"):
            self.validate(document)


if __name__ == "__main__":
    unittest.main()
