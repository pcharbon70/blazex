from __future__ import annotations

import copy
import importlib.util
import unittest
from pathlib import Path


HERE = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("verify_behavior_trust", HERE / "verify_behavior_trust.py")
VERIFY = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(VERIFY)


class BrowserBehaviorTrustMatrixTest(unittest.TestCase):
    def setUp(self):
        self.values = list(VERIFY.inputs())

    def validate(self, index=None, value=None):
        values = copy.deepcopy(self.values)
        if index is not None:
            values[index] = value
        return VERIFY.validate(*values)

    def test_canonical_behavior_matrix_passes(self):
        self.assertEqual([], self.validate())

    def test_required_row_removed_fails(self):
        matrix = copy.deepcopy(self.values[0])
        matrix["required_results"].pop()
        self.assertTrue(self.validate(0, matrix))

    def test_probe_substitution_fails(self):
        matrix = copy.deepcopy(self.values[0])
        matrix["non_substituting_probe_results"][0]["required_row_credit"] = True
        self.assertTrue(self.validate(0, matrix))

    def test_semantic_divergence_fails(self):
        evidence = copy.deepcopy(self.values[2])
        evidence["firefox"]["semantic_trace_sha256"] = "0" * 64
        self.assertTrue(self.validate(2, evidence))

    def test_unauthorized_effect_fails(self):
        evidence = copy.deepcopy(self.values[2])
        evidence["chromium"]["trust"]["unauthorized_effects"] = 1
        self.assertTrue(self.validate(2, evidence))

    def test_resource_retention_fails(self):
        evidence = copy.deepcopy(self.values[2])
        evidence["webkit"]["resilience"]["lifecycle_iterations"][0]["dom"]["listeners"] = 1
        self.assertTrue(self.validate(2, evidence))

    def test_evidence_hash_drift_fails(self):
        hashes = copy.deepcopy(self.values[3])
        hashes["bh01-phase8-behavior-chromium.json"] = "0" * 64
        self.assertTrue(self.validate(3, hashes))


if __name__ == "__main__":
    unittest.main()
