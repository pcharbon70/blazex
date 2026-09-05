from __future__ import annotations

import copy
import importlib.util
import unittest
from pathlib import Path


TOOLCHAIN = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("verify_phase9", TOOLCHAIN / "verify_phase9.py")
VERIFY = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(VERIFY)


class Phase9MeasurementDecisionTest(unittest.TestCase):
    def setUp(self):
        self.value = VERIFY.inputs()

    def mutate(self, key, callback):
        value = copy.deepcopy(self.value)
        callback(value[key])
        return VERIFY.validate(value)

    def test_canonical_conditional_gate_passes(self):
        self.assertEqual([], VERIFY.validate(copy.deepcopy(self.value)))

    def test_support_promotion_fails(self):
        self.assertTrue(self.mutate("decision", lambda value: value["decision"].update({"support": "supported"})))

    def test_missing_raw_sample_fails(self):
        self.assertTrue(self.mutate("chrome", lambda value: value["measurements"][0]["samples"].pop()))

    def test_excluded_outlier_fails(self):
        self.assertTrue(self.mutate("summary", lambda value: value["measurements"][0]["outlier_review"].update({"samples_excluded": 1})))

    def test_payload_failure_removal_fails(self):
        self.assertTrue(self.mutate("budgets", lambda value: value["evaluations"].pop(1)))

    def test_threshold_change_fails(self):
        self.assertTrue(self.mutate("mitigations", lambda value: value["threshold_changes"].append({"budget": "changed"})))

    def test_mobile_pass_fails(self):
        self.assertTrue(self.mutate("deferrals", lambda value: value["phase_effect"].update({"mobile_viability": "passed"})))

    def test_hidden_rerun_drift_fails(self):
        self.assertTrue(self.mutate("rerun_final", lambda value: value.update({"status": "observed-within-development-tolerance", "drift_count": 0})))

    def test_phase10_authorization_fails(self):
        self.assertTrue(self.mutate("decision", lambda value: value["phase_10"].update({"authorized": True})))

    def test_open_plan_item_fails(self):
        value = copy.deepcopy(self.value)
        value["plan"] += "\n- [ ] unfinished"
        self.assertTrue(VERIFY.validate(value))


if __name__ == "__main__":
    unittest.main()
