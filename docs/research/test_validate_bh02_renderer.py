from __future__ import annotations

import copy
import unittest

import validate_bh02_renderer as validator


class RendererValidationTest(unittest.TestCase):
    def setUp(self) -> None:
        self.authorization = validator._load_json(validator.AUTHORIZATION)
        self.contract = validator._load_json(validator.CONTRACT)
        self.index = validator._load_json(validator.INDEX)
        self.fixtures = validator._load_json(validator.FIXTURES)
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

    def test_rejects_expanded_capabilities(self) -> None:
        changed = copy.deepcopy(self.contract)
        changed["renderer_capabilities"]["features"].append("pixels")
        self.assert_rejected(lambda: validator.validate_contract(changed, self.authorization))

    def test_rejects_changed_lifecycle_surface(self) -> None:
        changed = copy.deepcopy(self.contract)
        changed["backend_behavior"]["callbacks"].append("measure")
        self.assert_rejected(lambda: validator.validate_contract(changed, self.authorization))

    def test_rejects_changed_snapshot_surface(self) -> None:
        changed = copy.deepcopy(self.contract)
        changed["headless_snapshot"]["fields"].append("bounds")
        self.assert_rejected(lambda: validator.validate_contract(changed, self.authorization))

    def test_rejects_concrete_backend_leakage(self) -> None:
        self.assert_rejected(lambda: validator.validate_source_text("call the DOM here"))

    def test_rejects_missing_fixture_coverage(self) -> None:
        changed = copy.deepcopy(self.fixtures)
        changed["scenarios"].pop()
        self.assert_rejected(lambda: validator.validate_fixtures(self.index, changed))

    def test_rejects_missing_trace_transition(self) -> None:
        changed = copy.deepcopy(self.fixtures)
        changed["canonical_trace"].pop()
        self.assert_rejected(lambda: validator.validate_fixtures(self.index, changed))

    def test_rejects_visual_result_overclaim(self) -> None:
        changed = copy.deepcopy(self.index)
        changed["visual_results"] = [{"result": "passed"}]
        self.assert_rejected(lambda: validator.validate_fixtures(changed, self.fixtures))

    def test_rejects_stable_api_overclaim(self) -> None:
        changed = copy.deepcopy(self.contract)
        changed["api_state"] = "stable"
        self.assert_rejected(lambda: validator.validate_contract(changed, self.authorization))

    def test_rejects_support_overclaim(self) -> None:
        changed = copy.deepcopy(self.fixtures)
        changed["support_state"] = "supported"
        self.assert_rejected(lambda: validator.validate_fixtures(self.index, changed))

    def test_rejects_premature_phase_6_authority(self) -> None:
        changed = copy.deepcopy(self.index)
        changed["next_authorized_work"] = "BH-02 Phase 6"
        self.assert_rejected(lambda: validator.validate_fixtures(changed, self.fixtures))

    def test_rejects_later_output_overclaim(self) -> None:
        changed = copy.deepcopy(self.ledger)
        changed["required_outputs"][6]["state"] = "implemented"
        self.assert_rejected(lambda: validator.validate_ledger(changed))

    def test_rejects_stale_completion_binding(self) -> None:
        changed = copy.deepcopy(self.completion)
        changed["artifact_hashes"][0]["sha256"] = "0" * 64
        self.assert_rejected(lambda: validator.validate_completion(changed))


if __name__ == "__main__":
    unittest.main()
