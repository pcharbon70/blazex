from __future__ import annotations

import copy
import importlib.util
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("verify_adversarial_matrix", ROOT / "verify_adversarial_matrix.py")
VERIFY = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(VERIFY)


class AdversarialMatrixTest(unittest.TestCase):
    def setUp(self):
        self.matrix = VERIFY.load(ROOT / "adversarial-matrix.json")

    def test_canonical_matrix_passes(self):
        self.assertEqual([], VERIFY.validate(self.matrix))

    def test_payload_gap_fails(self):
        value = copy.deepcopy(self.matrix)
        value["payload_vectors"].remove("atom-key-growth")
        self.assertTrue(VERIFY.validate(value))

    def test_artifact_gap_fails(self):
        value = copy.deepcopy(self.matrix)
        value["artifact_vectors"].remove("modified-wasm")
        self.assertTrue(VERIFY.validate(value))

    def test_unauthorized_effect_fails(self):
        value = copy.deepcopy(self.matrix)
        value["required_outcomes"]["unauthorized_effect"] = True
        self.assertTrue(VERIFY.validate(value))

    def test_missing_security_review_fails(self):
        value = copy.deepcopy(self.matrix)
        value["specialist_review"]["disposition"] = "pending"
        self.assertTrue(VERIFY.validate(value))


if __name__ == "__main__":
    unittest.main()
