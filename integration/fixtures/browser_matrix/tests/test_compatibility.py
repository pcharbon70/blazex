from __future__ import annotations

import copy
import importlib.util
import unittest
from pathlib import Path


HERE = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("verify_compatibility", HERE / "verify_compatibility.py")
VERIFY = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(VERIFY)


class BrowserCompatibilityMatrixTest(unittest.TestCase):
    def setUp(self):
        self.values = list(VERIFY.inputs())

    def validate(self, index=None, value=None):
        values = copy.deepcopy(self.values)
        if index is not None:
            values[index] = value
        return VERIFY.validate(*values)

    def test_canonical_compatibility_matrix_passes(self):
        self.assertEqual([], self.validate())

    def test_mismatch_category_removed_fails(self):
        matrix = copy.deepcopy(self.values[0])
        matrix["mismatch_coverage"].pop()
        self.assertTrue(self.validate(0, matrix))

    def test_adjacent_package_overclaim_fails(self):
        matrix = copy.deepcopy(self.values[0])
        matrix["adjacent_dependency_probes"][0]["installed_and_executed"] = True
        self.assertTrue(self.validate(0, matrix))

    def test_private_api_escape_fails(self):
        private_api = copy.deepcopy(self.values[2])
        private_api["phase8_compatibility"]["fallback_success"] = "portable-liveview-diff"
        self.assertTrue(self.validate(2, private_api))

    def test_partial_activation_fails(self):
        evidence = copy.deepcopy(self.values[3])
        evidence["chromium"]["mismatch_scenarios"]["runtime_bundle"]["partial_activation"] = True
        self.assertTrue(self.validate(3, evidence))

    def test_hidden_semantic_change_fails(self):
        evidence = copy.deepcopy(self.values[3])
        evidence["firefox"]["cache_and_rollback"]["hidden_semantic_change"] = True
        self.assertTrue(self.validate(3, evidence))

    def test_evidence_hash_drift_fails(self):
        hashes = copy.deepcopy(self.values[4])
        hashes["bh01-phase8-compatibility-chromium.json"] = "0" * 64
        self.assertTrue(self.validate(4, hashes))


if __name__ == "__main__":
    unittest.main()
