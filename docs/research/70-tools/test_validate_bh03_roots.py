from __future__ import annotations

import copy
import json
import unittest

import validate_bh03_roots as validator


class BH03RootsValidatorTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.authorization = json.loads(validator.AUTHORIZATION.read_text(encoding="utf-8"))
        cls.contract = json.loads(validator.CONTRACT.read_text(encoding="utf-8"))
        cls.fixtures = json.loads(validator.FIXTURES.read_text(encoding="utf-8"))
        cls.index = json.loads(validator.INTEGRATION_INDEX.read_text(encoding="utf-8"))
        cls.completion = json.loads(validator.COMPLETION.read_text(encoding="utf-8"))

    def test_current_repository_passes(self) -> None:
        validator.validate()

    def test_rejects_missing_authority(self) -> None:
        authorization = copy.deepcopy(self.authorization)
        authorization["status"] = "pending"
        with self.assertRaisesRegex(validator.ValidationError, "lacks explicit approval"):
            validator.validate_authorization(authorization)

    def test_rejects_stale_predecessor(self) -> None:
        authorization = copy.deepcopy(self.authorization)
        authorization["approval_basis"][0]["sha256"] = "0" * 64
        with self.assertRaisesRegex(validator.ValidationError, "stale"):
            validator.validate_authorization(authorization)

    def test_rejects_non_coalesced_runtime_contract(self) -> None:
        contract = copy.deepcopy(self.contract)
        contract["runtime_registry"]["startup"] = "one-attempt-per-caller"
        with self.assertRaisesRegex(validator.ValidationError, "not coalesced"):
            validator.validate_contract(contract)

    def test_rejects_changed_root_operation_set(self) -> None:
        contract = copy.deepcopy(self.contract)
        contract["root_lifecycle"]["operations"].pop()
        with self.assertRaisesRegex(validator.ValidationError, "vocabulary diverges"):
            validator.validate_contract(contract)

    def test_rejects_later_fixture_evidence(self) -> None:
        fixtures = copy.deepcopy(self.fixtures)
        fixtures["evidence_boundary"]["browser_results"] = 1
        with self.assertRaisesRegex(validator.ValidationError, "overclaims later evidence"):
            validator.validate_fixtures(fixtures)

    def test_rejects_rewritten_predecessor_fixture_state(self) -> None:
        index = copy.deepcopy(self.index)
        index["fixture_sets"][0]["state"] = "implemented-unit-conformance"
        with self.assertRaisesRegex(validator.ValidationError, "fixture states diverge"):
            validator.validate_index(index)

    def test_rejects_later_phase_authorization(self) -> None:
        index = copy.deepcopy(self.index)
        index["next_authorized_work"] = "BH-03 Phase 5"
        with self.assertRaisesRegex(validator.ValidationError, "authorizes later work"):
            validator.validate_index(index)

    def test_rejects_support_promotion(self) -> None:
        completion = copy.deepcopy(self.completion)
        completion["outcome"]["support_state"] = "supported"
        with self.assertRaisesRegex(validator.ValidationError, "promotes stability or support"):
            validator.validate_completion(completion)

    def test_rejects_shutdown_overclaim(self) -> None:
        completion = copy.deepcopy(self.completion)
        completion["outcome"]["shutdown_results"] = 1
        with self.assertRaisesRegex(validator.ValidationError, "overclaims later evidence"):
            validator.validate_completion(completion)


if __name__ == "__main__":
    unittest.main()
