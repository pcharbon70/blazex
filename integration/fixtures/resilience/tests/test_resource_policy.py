from __future__ import annotations

import copy
import importlib.util
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("verify_resource_policy", ROOT / "verify_resource_policy.py")
VERIFY = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(VERIFY)


class ResourcePolicyTest(unittest.TestCase):
    def setUp(self):
        self.policy = VERIFY.load(ROOT / "resource-policy.json")

    def test_canonical_policy_passes(self):
        self.assertEqual([], VERIFY.validate(self.policy))

    def test_missing_domain_fails(self):
        value = copy.deepcopy(self.policy)
        value["required_domains"].remove("server")
        self.assertTrue(VERIFY.validate(value))

    def test_missing_interruption_fails(self):
        value = copy.deepcopy(self.policy)
        value["interruption_points"].remove("shutdown")
        self.assertTrue(VERIFY.validate(value))

    def test_unbounded_transient_fails(self):
        value = copy.deepcopy(self.policy)
        value["bounded_during_stress"]["transport.bridge_pending"] = None
        self.assertTrue(VERIFY.validate(value))

    def test_worker_unknown_must_remain_explicit(self):
        value = copy.deepcopy(self.policy)
        del value["unknown_observations"]["browser.workers"]
        self.assertTrue(VERIFY.validate(value))


if __name__ == "__main__":
    unittest.main()
