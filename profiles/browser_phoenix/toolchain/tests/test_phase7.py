from __future__ import annotations

import copy
import importlib.util
import unittest
from pathlib import Path


TOOLCHAIN = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("verify_phase7", TOOLCHAIN / "verify_phase7.py")
VERIFY = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(VERIFY)


class Phase7ResilienceSecurityResourceEvidenceTest(unittest.TestCase):
    def setUp(self):
        self.values = list(VERIFY.inputs())

    def validate(self, index=None, value=None):
        values = copy.deepcopy(self.values)
        if index is not None:
            values[index] = value
        return VERIFY.validate(*values)

    def test_canonical_phase7_gate_passes(self):
        self.assertEqual([], self.validate())

    def test_stress_count_drift_fails(self):
        evidence = copy.deepcopy(self.values[2])
        evidence["stress"]["iterations"] = 19
        self.assertTrue(self.validate(2, evidence))

    def test_duplicate_authority_effect_fails(self):
        evidence = copy.deepcopy(self.values[2])
        evidence["stress"]["iteration_results"][0]["resource_value"] = 2
        self.assertTrue(self.validate(2, evidence))

    def test_resource_leak_fails(self):
        evidence = copy.deepcopy(self.values[2])
        evidence["resources"]["disposed"]["resources"]["runtime.timers"] = 1
        self.assertTrue(self.validate(2, evidence))

    def test_artifact_ready_after_tamper_fails(self):
        evidence = copy.deepcopy(self.values[2])
        evidence["adversarial"]["artifact_tamper"]["runtime_ready"] = True
        self.assertTrue(self.validate(2, evidence))

    def test_diagnostic_leakage_fails(self):
        evidence = copy.deepcopy(self.values[2])
        evidence["diagnostics"]["redaction"] = "failed"
        self.assertTrue(self.validate(2, evidence))

    def test_recovery_pending_work_fails(self):
        evidence = copy.deepcopy(self.values[2])
        evidence["recovery"]["pending"] = 1
        self.assertTrue(self.validate(2, evidence))

    def test_open_plan_item_fails(self):
        self.assertTrue(self.validate(6, self.values[6] + "\n- [ ] unfinished"))

    def test_completion_hash_drift_fails(self):
        hashes = copy.deepcopy(self.values[9])
        first = next(iter(hashes))
        hashes[first] = "0" * 64
        self.assertTrue(self.validate(9, hashes))


if __name__ == "__main__":
    unittest.main()
