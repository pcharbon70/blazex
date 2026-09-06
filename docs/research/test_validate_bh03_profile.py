from __future__ import annotations

import copy
import json
import unittest

import validate_bh03_profile as validator


class BH03ProfileValidatorTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.authorization = json.loads(validator.AUTHORIZATION.read_text(encoding="utf-8"))
        cls.contract = json.loads(validator.CONTRACT.read_text(encoding="utf-8"))
        cls.fixtures = json.loads(validator.FIXTURES.read_text(encoding="utf-8"))
        cls.index = json.loads(validator.INTEGRATION_INDEX.read_text(encoding="utf-8"))
        cls.evidence = json.loads(validator.EVIDENCE.read_text(encoding="utf-8"))

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

    def test_rejects_profile_overwrite(self) -> None:
        contract = copy.deepcopy(self.contract)
        contract["profile"]["legacy_profile_policy"] = "replace"
        with self.assertRaisesRegex(validator.ValidationError, "separation"):
            validator.validate_contract(contract)

    def test_rejects_missing_active_browser(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        evidence["results"].pop()
        with self.assertRaisesRegex(validator.ValidationError, "both active"):
            validator.validate_evidence(evidence)

    def test_rejects_divergent_scenario_set(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        evidence["results"][1]["scenario_set"].pop()
        with self.assertRaisesRegex(validator.ValidationError, "did not pass"):
            validator.validate_evidence(evidence)

    def test_rejects_false_browser_pass(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        evidence["results"][0]["result"] = "unavailable"
        with self.assertRaisesRegex(validator.ValidationError, "did not pass"):
            validator.validate_evidence(evidence)

    def test_rejects_missing_elixir_acknowledgements(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        evidence["results"][0]["observations"]["positive"]["runtime_acknowledgements_before_shutdown"] = 0
        with self.assertRaisesRegex(validator.ValidationError, "acknowledgements"):
            validator.validate_evidence(evidence)

    def test_rejects_false_deferred_pass(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        evidence["deferred"][0]["state"] = "passed"
        with self.assertRaisesRegex(validator.ValidationError, "false passes"):
            validator.validate_evidence(evidence)

    def test_rejects_measurement_overclaim(self) -> None:
        index = copy.deepcopy(self.index)
        index["measurements"] = [{"result": "passed"}]
        with self.assertRaisesRegex(validator.ValidationError, "overclaims later"):
            validator.validate_index(index)

    def test_rejects_support_promotion(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        evidence["support_state"] = "supported"
        with self.assertRaisesRegex(validator.ValidationError, "promotes support"):
            validator.validate_evidence(evidence)


if __name__ == "__main__":
    unittest.main()
