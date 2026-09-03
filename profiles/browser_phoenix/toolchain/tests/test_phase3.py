from __future__ import annotations

import copy
import importlib.util
import unittest
from pathlib import Path


TOOLCHAIN = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("verify_phase3", TOOLCHAIN / "verify_phase3.py")
VERIFY = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(VERIFY)


class Phase3CompletionTest(unittest.TestCase):
    def setUp(self):
        self.values = list(VERIFY.inputs())

    def validate(self, index=None, value=None):
        values = copy.deepcopy(self.values)
        if index is not None:
            values[index] = value
        return VERIFY.validate(*values)

    def test_canonical_phase3_completion_passes(self):
        self.assertEqual([], self.validate())

    def test_missing_authorization_fails(self):
        authorization = copy.deepcopy(self.values[1])
        authorization["status"] = "not-authorized"
        self.assertTrue(self.validate(1, authorization))

    def test_evidence_hash_drift_fails(self):
        hashes = copy.deepcopy(self.values[5])
        first = next(iter(hashes))
        hashes[first] = "0" * 64
        self.assertTrue(self.validate(5, hashes))

    def test_open_plan_item_fails(self):
        self.assertTrue(self.validate(2, self.values[2] + "\n- [ ] unfinished"))

    def test_phase4_authorization_fails(self):
        completion = copy.deepcopy(self.values[0])
        completion["outcome"]["summary"] = "Phase 4 authorized"
        self.assertTrue(self.validate(0, completion))

    def test_browser_support_overclaim_fails(self):
        evidence = self.values[4].replace("all browsers remain unsupported", "all browsers are supported")
        self.assertTrue(self.validate(4, evidence))


if __name__ == "__main__":
    unittest.main()
