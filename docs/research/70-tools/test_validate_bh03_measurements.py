import copy
import unittest

import validate_bh03_measurements as validator


class Phase7MeasurementValidationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.authorization = validator._load(validator.AUTHORIZATION)
        cls.contract = validator._load(validator.CONTRACT)
        cls.fixtures = validator._load(validator.FIXTURES)
        cls.evidence = validator._load(validator.EVIDENCE)
        cls.index = validator._load(validator.INDEX)

    def test_active_records_pass_before_completion(self):
        validator.validate_authorization(copy.deepcopy(self.authorization))
        validator.validate_contract(copy.deepcopy(self.contract))
        validator.validate_fixtures(copy.deepcopy(self.fixtures))
        validator.validate_evidence(copy.deepcopy(self.evidence))
        validator.validate_index(copy.deepcopy(self.index))
        validator.validate_implementation()

    def test_rejects_missing_authorization(self):
        value = copy.deepcopy(self.authorization)
        value["status"] = "planned"
        with self.assertRaises(validator.ValidationError):
            validator.validate_authorization(value)

    def test_rejects_release_budget_contract(self):
        value = copy.deepcopy(self.contract)
        value["evidence_rules"]["release_budgets"] = "startup-under-250ms"
        with self.assertRaises(validator.ValidationError):
            validator.validate_contract(value)

    def test_rejects_missing_active_browser(self):
        value = copy.deepcopy(self.evidence)
        value["results"].pop()
        with self.assertRaises(validator.ValidationError):
            validator.validate_evidence(value)

    def test_rejects_negative_timing(self):
        value = copy.deepcopy(self.evidence)
        value["results"][0]["samples"][0]["startup_to_ready_ms"] = -1
        with self.assertRaises(validator.ValidationError):
            validator.validate_evidence(value)

    def test_rejects_root_or_frame_leak(self):
        value = copy.deepcopy(self.evidence)
        value["results"][0]["samples"][0]["runtime_iframes_after_shutdown"] = 1
        with self.assertRaises(validator.ValidationError):
            validator.validate_evidence(value)

    def test_rejects_fabricated_firefox_memory(self):
        value = copy.deepcopy(self.evidence)
        value["results"][1]["samples"][0]["memory"] = {"available": True, "api": "invented", "ready_bytes": 1, "after_root_cycle_bytes": 1, "after_shutdown_bytes": 1}
        with self.assertRaises(validator.ValidationError):
            validator.validate_evidence(value)

    def test_rejects_partial_failure_activation(self):
        value = copy.deepcopy(self.evidence)
        value["results"][0]["failure_scenarios"][0]["partial_activation"] = True
        with self.assertRaises(validator.ValidationError):
            validator.validate_evidence(value)

    def test_rejects_evidence_budget(self):
        value = copy.deepcopy(self.evidence)
        value["release_budgets"] = [{"startup_ms": 250}]
        with self.assertRaises(validator.ValidationError):
            validator.validate_evidence(value)

    def test_rejects_index_acceptance(self):
        value = copy.deepcopy(self.index)
        value["acceptance_evidence"] = [{"decision": "accepted"}]
        with self.assertRaises(validator.ValidationError):
            validator.validate_index(value)


if __name__ == "__main__":
    unittest.main()
