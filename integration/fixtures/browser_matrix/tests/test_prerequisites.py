from __future__ import annotations

import copy
import importlib.util
import unittest
from pathlib import Path


HERE = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("verify_prerequisites", HERE / "verify_prerequisites.py")
VERIFY = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(VERIFY)


class BrowserPrerequisiteMatrixTest(unittest.TestCase):
    def setUp(self):
        self.values = list(VERIFY.inputs())

    def validate(self, index=None, value=None):
        values = copy.deepcopy(self.values)
        if index is not None:
            values[index] = value
        return VERIFY.validate(*values)

    def test_canonical_prerequisite_matrix_passes(self):
        self.assertEqual([], self.validate())

    def test_blocked_row_removed_fails(self):
        matrix = copy.deepcopy(self.values[0])
        matrix["required_results"].pop()
        self.assertTrue(self.validate(0, matrix))

    def test_probe_substitution_fails(self):
        matrix = copy.deepcopy(self.values[0])
        matrix["non_substituting_probe_results"][0]["required_row_credit"] = True
        self.assertTrue(self.validate(0, matrix))

    def test_partial_activation_fails(self):
        matrix = copy.deepcopy(self.values[0])
        matrix["required_results"][1]["partial_activation"] = True
        self.assertTrue(self.validate(0, matrix))

    def test_capability_regression_fails(self):
        evidence = copy.deepcopy(self.values[3])
        evidence["chromium"]["capabilities"]["shared_memory"] = False
        self.assertTrue(self.validate(3, evidence))

    def test_fallback_runtime_activation_fails(self):
        evidence = copy.deepcopy(self.values[3])
        evidence["chromium"]["negative_scenarios"][0]["runtime_ready"] = True
        self.assertTrue(self.validate(3, evidence))

    def test_evidence_hash_drift_fails(self):
        hashes = copy.deepcopy(self.values[4])
        hashes["bh01-phase8-prerequisites-chromium.json"] = "0" * 64
        self.assertTrue(self.validate(4, hashes))


if __name__ == "__main__":
    unittest.main()
