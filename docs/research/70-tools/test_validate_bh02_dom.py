from __future__ import annotations

import copy
import unittest

import validate_bh02_dom as validator


class DOMValidationTest(unittest.TestCase):
    def setUp(self) -> None:
        self.authorization = validator._load_json(validator.AUTHORIZATION)
        self.contract = validator._load_json(validator.CONTRACT)
        self.index = validator._load_json(validator.INDEX)
        self.fixtures = validator._load_json(validator.FIXTURES)
        self.matrix = validator._load_json(validator.BROWSER_MATRIX)
        self.ledger = validator._load_json(validator.LEDGER)
        self.completion = validator._load_json(validator.COMPLETION)

    def assert_rejected(self, callback) -> None:
        with self.assertRaises(validator.ValidationError):
            callback()

    def test_accepts_current_phase_records(self) -> None:
        validator.validate()

    def test_rejects_stale_authority(self) -> None:
        changed = copy.deepcopy(self.authorization)
        changed["approval_basis"][0]["sha256"] = "0" * 64
        self.assert_rejected(lambda: validator.validate_authorization(changed))

    def test_rejects_expanded_tags(self) -> None:
        changed = copy.deepcopy(self.contract)
        changed["dom_node"]["tags"].append("canvas")
        self.assert_rejected(lambda: validator.validate_contract(changed, self.authorization))

    def test_rejects_expanded_node_fields(self) -> None:
        changed = copy.deepcopy(self.contract)
        changed["dom_node"]["fields"].append("style")
        self.assert_rejected(lambda: validator.validate_contract(changed, self.authorization))

    def test_rejects_changed_event_mapping(self) -> None:
        changed = copy.deepcopy(self.contract)
        changed["dom_listener"]["native_mapping"]["activate"] = "pointerup"
        self.assert_rejected(lambda: validator.validate_contract(changed, self.authorization))

    def test_rejects_changed_dependencies(self) -> None:
        changed = copy.deepcopy(self.contract)
        changed["package_boundary"]["dependencies"].append("blazex_phoenix")
        self.assert_rejected(lambda: validator.validate_contract(changed, self.authorization))

    def test_rejects_server_framework_leakage(self) -> None:
        self.assert_rejected(lambda: validator.validate_source_text("use Phoenix.LiveView"))

    def test_rejects_missing_browser_row(self) -> None:
        changed = copy.deepcopy(self.matrix)
        changed["results"].pop()
        self.assert_rejected(lambda: validator.validate_browser_matrix(changed))

    def test_rejects_failed_browser_check(self) -> None:
        changed = copy.deepcopy(self.matrix)
        changed["results"][0]["result"] = "failed"
        self.assert_rejected(lambda: validator.validate_browser_matrix(changed))

    def test_rejects_missing_fixture_coverage(self) -> None:
        changed = copy.deepcopy(self.fixtures)
        changed["scenarios"].pop()
        self.assert_rejected(lambda: validator.validate_fixtures(self.index, changed, self.matrix))

    def test_rejects_visual_overclaim(self) -> None:
        changed = copy.deepcopy(self.index)
        changed["visual_results"] = [{"result": "passed"}]
        self.assert_rejected(lambda: validator.validate_fixtures(changed, self.fixtures, self.matrix))

    def test_rejects_stable_api_overclaim(self) -> None:
        changed = copy.deepcopy(self.contract)
        changed["api_state"] = "stable"
        self.assert_rejected(lambda: validator.validate_contract(changed, self.authorization))

    def test_rejects_support_overclaim(self) -> None:
        changed = copy.deepcopy(self.matrix)
        changed["support_state"] = "supported"
        self.assert_rejected(lambda: validator.validate_browser_matrix(changed))

    def test_rejects_premature_phase_7_authority(self) -> None:
        changed = copy.deepcopy(self.index)
        changed["next_authorized_work"] = "BH-02 Phase 7"
        self.assert_rejected(lambda: validator.validate_fixtures(changed, self.fixtures, self.matrix))

    def test_rejects_native_output_overclaim(self) -> None:
        changed = copy.deepcopy(self.ledger)
        changed["required_outputs"][7]["state"] = "implemented"
        self.assert_rejected(lambda: validator.validate_ledger(changed))

    def test_rejects_stale_completion_binding(self) -> None:
        changed = copy.deepcopy(self.completion)
        changed["artifact_hashes"][0]["sha256"] = "0" * 64
        self.assert_rejected(lambda: validator.validate_completion(changed))


if __name__ == "__main__":
    unittest.main()
