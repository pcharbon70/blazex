from __future__ import annotations

import copy
import importlib.util
import unittest
from pathlib import Path


TOOLCHAIN = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("verify_phase8", TOOLCHAIN / "verify_phase8.py")
VERIFY = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(VERIFY)


class Phase8BrowserMatrixDecisionTest(unittest.TestCase):
    def setUp(self):
        self.values = list(VERIFY.inputs())

    def validate(self, index=None, value=None):
        values = copy.deepcopy(self.values)
        if index is not None:
            values[index] = value
        return VERIFY.validate(*values)

    def test_canonical_blocked_gate_passes(self):
        self.assertEqual([], self.validate())

    def test_missing_required_row_fails(self):
        report = copy.deepcopy(self.values[3])
        report["required_rows"].pop()
        self.assertTrue(self.validate(3, report))

    def test_probe_substitution_fails(self):
        report = copy.deepcopy(self.values[3])
        report["non_substituting_probes"][0]["required_row_credit"] = True
        self.assertTrue(self.validate(3, report))

    def test_phase9_authorization_fails(self):
        aggregate = copy.deepcopy(self.values[2])
        aggregate["decision"]["phase9_authorized"] = True
        aggregate["evidence_sha256"] = VERIFY.aggregate_self_hash(aggregate)
        self.assertTrue(self.validate(2, aggregate))

    def test_raw_evidence_hash_drift_fails(self):
        raw_hashes = copy.deepcopy(self.values[9])
        raw_hashes[next(iter(raw_hashes))] = "0" * 64
        self.assertTrue(self.validate(9, raw_hashes))

    def test_profile_identity_drift_fails(self):
        self.assertTrue(self.validate(10, "0" * 64))

    def test_scenario_pass_overclaims_result(self):
        scenario = copy.deepcopy(self.values[4])
        scenario["status"] = "passed"
        self.assertTrue(self.validate(4, scenario))

    def test_open_plan_item_fails(self):
        self.assertTrue(self.validate(11, self.values[11] + "\n- [ ] unfinished"))

    def test_completion_pass_overclaims_result(self):
        completion = copy.deepcopy(self.values[0])
        completion["state"] = "passed"
        self.assertTrue(self.validate(0, completion))

    def test_report_support_claim_fails(self):
        report = self.values[13].replace("All browsers remain unsupported", "All browsers are supported")
        self.assertTrue(self.validate(13, report))


if __name__ == "__main__":
    unittest.main()
