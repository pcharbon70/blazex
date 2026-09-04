from __future__ import annotations

import copy
import importlib.util
import unittest
from pathlib import Path


TOOLCHAIN = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("verify_phase6", TOOLCHAIN / "verify_phase6.py")
VERIFY = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(VERIFY)


class Phase6TrustBoundaryEvidenceTest(unittest.TestCase):
    def setUp(self):
        self.values = list(VERIFY.inputs())

    def validate(self, index=None, value=None):
        values = copy.deepcopy(self.values)
        if index is not None:
            values[index] = value
        return VERIFY.validate(*values)

    def test_canonical_phase6_gate_passes(self):
        self.assertEqual([], self.validate())

    def test_unauthorized_effect_fails(self):
        evidence = copy.deepcopy(self.values[2])
        evidence["failure_matrix"]["unauthorized_effects"] = 1
        self.assertTrue(self.validate(2, evidence))

    def test_secret_bearing_evidence_fails(self):
        evidence = copy.deepcopy(self.values[2])
        evidence["command_path"]["session_id"] = "must-not-be-retained"
        self.assertTrue(self.validate(2, evidence))

    def test_hidden_adapter_fallback_fails(self):
        evidence = copy.deepcopy(self.values[2])
        evidence["adapter_capability"]["fallback"] = "hidden-liveview-retry"
        self.assertTrue(self.validate(2, evidence))

    def test_cleanup_leak_fails(self):
        evidence = copy.deepcopy(self.values[2])
        evidence["cleanup"]["server"]["pending"] = 1
        self.assertTrue(self.validate(2, evidence))

    def test_open_plan_item_fails(self):
        self.assertTrue(self.validate(7, self.values[7] + "\n- [ ] unfinished"))

    def test_completion_hash_drift_fails(self):
        hashes = copy.deepcopy(self.values[10])
        first = next(iter(hashes))
        hashes[first] = "0" * 64
        self.assertTrue(self.validate(10, hashes))


if __name__ == "__main__":
    unittest.main()
