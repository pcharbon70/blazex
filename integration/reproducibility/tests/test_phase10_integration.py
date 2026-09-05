from __future__ import annotations

import copy
import importlib.util
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("verify_phase10", ROOT / "verify_phase10.py")
VERIFY = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(VERIFY)


class Phase10IntegrationTest(unittest.TestCase):
    def setUp(self):
        self.value = VERIFY.inputs()

    def test_canonical_phase10_passes(self):
        self.assertEqual([], VERIFY.validate(self.value))

    def test_missing_proof_fails(self):
        value = copy.deepcopy(self.value)
        value["closure"]["proof_obligations"].pop()
        self.assertTrue(VERIFY.validate(value))

    def test_stale_completion_hash_fails(self):
        value = copy.deepcopy(self.value)
        value["completion"]["input_hashes"][0]["sha256"] = "0" * 64
        self.assertTrue(VERIFY.validate(value))

    def test_bh02_activation_fails(self):
        value = copy.deepcopy(self.value)
        value["entry"]["activation"]["authorized"] = True
        value["entry"]["activation"]["may_start"] = True
        self.assertTrue(VERIFY.validate(value))

    def test_open_phase_checklist_fails(self):
        value = copy.deepcopy(self.value)
        value["plan"] += "\n- [ ] synthetic open gate\n"
        self.assertTrue(VERIFY.validate(value))


if __name__ == "__main__":
    unittest.main()
