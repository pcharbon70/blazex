from __future__ import annotations

import copy
import importlib.util
import unittest
from pathlib import Path


HERE = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("verify_accessibility_input", HERE / "verify_accessibility_input.py")
VERIFY = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(VERIFY)


class BrowserAccessibilityInputMatrixTest(unittest.TestCase):
    def setUp(self):
        self.values = list(VERIFY.inputs())

    def validate(self, index=None, value=None):
        values = copy.deepcopy(self.values)
        if index is not None:
            values[index] = value
        return VERIFY.validate(*values)

    def test_canonical_accessibility_matrix_passes(self):
        self.assertEqual([], self.validate())

    def test_fallback_value_removed_fails(self):
        matrix = copy.deepcopy(self.values[0])
        matrix["fallback_values"].pop()
        self.assertTrue(self.validate(0, matrix))

    def test_manual_evidence_overclaim_fails(self):
        evidence = copy.deepcopy(self.values[2])
        evidence["chromium"]["manual_evidence"]["assistive_technology"] = "passed"
        self.assertTrue(self.validate(2, evidence))

    def test_missing_retry_fails(self):
        evidence = copy.deepcopy(self.values[2])
        evidence["chromium"]["fallback"]["capability_unavailable"]["before_retry"]["retry_visible"] = False
        self.assertTrue(self.validate(2, evidence))

    def test_keyboard_order_regression_fails(self):
        evidence = copy.deepcopy(self.values[2])
        evidence["firefox"]["keyboard_focus"]["tab_order"] = list(reversed(VERIFY.TAB_PREFIX))
        self.assertTrue(self.validate(2, evidence))

    def test_disabled_event_acceptance_fails(self):
        evidence = copy.deepcopy(self.values[2])
        evidence["webkit"]["field_input"]["disabled"]["event_rejection"] = "accepted"
        self.assertTrue(self.validate(2, evidence))

    def test_evidence_hash_drift_fails(self):
        hashes = copy.deepcopy(self.values[3])
        hashes["bh01-phase8-accessibility-chromium.json"] = "0" * 64
        self.assertTrue(self.validate(3, hashes))


if __name__ == "__main__":
    unittest.main()
