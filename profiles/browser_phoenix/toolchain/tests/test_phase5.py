from __future__ import annotations

import copy
import importlib.util
import unittest
from pathlib import Path


TOOLCHAIN = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("verify_phase5", TOOLCHAIN / "verify_phase5.py")
VERIFY = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(VERIFY)


class Phase5BrowserEvidenceTest(unittest.TestCase):
    def setUp(self):
        self.evidence = VERIFY.load(VERIFY.EVIDENCE)

    def test_canonical_browser_evidence_passes(self):
        self.assertEqual([], VERIFY.validate_browser(self.evidence))

    def test_trace_mismatch_fails(self):
        value = copy.deepcopy(self.evidence)
        value["canonical_trace"][0]["parent_count"] = 999
        self.assertTrue(VERIFY.validate_browser(value))

    def test_behavior_network_request_fails(self):
        value = copy.deepcopy(self.evidence)
        value["runs"][0]["behavior_network_requests"].append({"path": "/authority"})
        self.assertTrue(VERIFY.validate_browser(value))

    def test_resource_leak_fails(self):
        value = copy.deepcopy(self.evidence)
        value["runs"][0]["first_stop"]["disposal_runtime"]["resources"]["timers"] = 1
        self.assertTrue(VERIFY.validate_browser(value))

    def test_partial_dom_mutation_fails(self):
        value = copy.deepcopy(self.evidence)
        value["adapter_negative_scenarios"]["partial_text_after_failure"] = "must-not-commit"
        self.assertTrue(VERIFY.validate_browser(value))

    def test_proof_promotion_fails(self):
        value = copy.deepcopy(self.evidence)
        value["proofs"]["BX-BH01-PROOF-DOM-UPDATE"]["status"] = "passed"
        self.assertTrue(VERIFY.validate_browser(value))


if __name__ == "__main__":
    unittest.main()
