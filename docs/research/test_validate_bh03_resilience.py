from __future__ import annotations

import copy
import json
import unittest

import validate_bh03_resilience as validator


class BH03ResilienceValidatorTest(unittest.TestCase):
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

    def test_rejects_unbounded_replacement_contract(self) -> None:
        contract = copy.deepcopy(self.contract)
        contract["runtime_loss"]["max_replacements"] = 2
        with self.assertRaisesRegex(validator.ValidationError, "bounds diverge"):
            validator.validate_contract(contract)

    def test_rejects_partial_fallback(self) -> None:
        fixtures = copy.deepcopy(self.fixtures)
        fixtures["fallback"]["partial_activation"] = True
        with self.assertRaisesRegex(validator.ValidationError, "overclaims presentation"):
            validator.validate_fixtures(fixtures)

    def test_rejects_rewritten_predecessor_fixture(self) -> None:
        index = copy.deepcopy(self.index)
        index["fixture_sets"][2]["state"] = "implemented-unit-conformance"
        with self.assertRaisesRegex(validator.ValidationError, "fixture states diverge"):
            validator.validate_index(index)

    def test_rejects_false_result_count(self) -> None:
        index = copy.deepcopy(self.index)
        index["recovery_results"][0]["cases"] = 99
        with self.assertRaisesRegex(validator.ValidationError, "recovery_results"):
            validator.validate_index(index)

    def test_rejects_browser_overclaim(self) -> None:
        index = copy.deepcopy(self.index)
        index["browser_results"] = [{"result": "passed"}]
        with self.assertRaisesRegex(validator.ValidationError, "overclaims later evidence"):
            validator.validate_index(index)

    def test_rejects_stale_completion_binding(self) -> None:
        completion = copy.deepcopy(self.completion)
        completion["artifact_hashes"][0]["sha256"] = "0" * 64
        with self.assertRaisesRegex(validator.ValidationError, "stale"):
            validator.validate_completion(completion)

    def test_rejects_phase_6_authorization(self) -> None:
        completion = copy.deepcopy(self.completion)
        completion["next_authorized_work"] = "BH-03 Phase 6"
        with self.assertRaisesRegex(validator.ValidationError, "next-work state diverges"):
            validator.validate_completion(completion)


if __name__ == "__main__":
    unittest.main()
