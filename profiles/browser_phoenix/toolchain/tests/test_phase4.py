from __future__ import annotations

import copy
import importlib.util
import unittest
from pathlib import Path


TOOLCHAIN = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("verify_phase4", TOOLCHAIN / "verify_phase4.py")
VERIFY = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(VERIFY)


class Phase4BrowserEvidenceTest(unittest.TestCase):
    def setUp(self):
        self.evidence = VERIFY.load(VERIFY.EVIDENCE)

    def test_canonical_browser_evidence_passes(self):
        self.assertEqual([], VERIFY.validate_browser(self.evidence))

    def test_support_promotion_fails(self):
        value = copy.deepcopy(self.evidence)
        value["support_status"] = "supported"
        self.assertTrue(VERIFY.validate_browser(value))

    def test_resource_leak_fails(self):
        value = copy.deepcopy(self.evidence)
        value["positive_scenarios"][1]["lifecycle"]["resources"] = {"worker": 1}
        self.assertTrue(VERIFY.validate_browser(value))

    def test_integrity_failure_drift_fails(self):
        value = copy.deepcopy(self.evidence)
        value["negative_scenarios"][2]["error"]["code"] = "unknown"
        self.assertTrue(VERIFY.validate_browser(value))

    def test_hidden_network_path_fails(self):
        value = copy.deepcopy(self.evidence)
        value["network"].append({"phase": "positive", "type": "request", "path": "/hidden.js"})
        self.assertTrue(VERIFY.validate_browser(value))


if __name__ == "__main__":
    unittest.main()
