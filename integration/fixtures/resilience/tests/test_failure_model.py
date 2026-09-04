from __future__ import annotations

import copy
import importlib.util
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("verify_failure_model", ROOT / "verify_failure_model.py")
VERIFY = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(VERIFY)


class FailureModelTest(unittest.TestCase):
    def setUp(self):
        self.values = list(VERIFY.inputs())

    def validate(self, index=None, value=None):
        values = copy.deepcopy(self.values)
        if index is not None:
            values[index] = value
        return VERIFY.validate(*values)

    def test_canonical_model_passes(self):
        self.assertEqual([], self.validate())

    def test_missing_layer_fails(self):
        taxonomy = copy.deepcopy(self.values[0])
        taxonomy["failures"].pop()
        self.assertTrue(self.validate(0, taxonomy))

    def test_duplicate_identity_fails(self):
        taxonomy = copy.deepcopy(self.values[0])
        taxonomy["failures"][1]["id"] = taxonomy["failures"][0]["id"]
        self.assertTrue(self.validate(0, taxonomy))

    def test_retry_owner_conflict_fails(self):
        taxonomy = copy.deepcopy(self.values[0])
        taxonomy["failures"][2]["retry_owner"] = "network-layer"
        self.assertTrue(self.validate(0, taxonomy))

    def test_authority_retry_amplification_fails(self):
        policy = copy.deepcopy(self.values[1])
        policy["authority_bearing"]["lower_layer_automatic_retry"] = True
        self.assertTrue(self.validate(1, policy))

    def test_hidden_fallback_fails(self):
        policy = copy.deepcopy(self.values[1])
        policy["reconnect"]["hidden_fallback"] = True
        self.assertTrue(self.validate(1, policy))


if __name__ == "__main__":
    unittest.main()
