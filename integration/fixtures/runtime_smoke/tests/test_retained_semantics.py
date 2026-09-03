from __future__ import annotations

import copy
import importlib.util
import sys
import unittest
from pathlib import Path


HERE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(HERE))
SPEC = importlib.util.spec_from_file_location("verify_semantics", HERE / "verify_semantics.py")
VERIFY = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(VERIFY)


class RetainedRuntimeSemanticsTest(unittest.TestCase):
    def setUp(self):
        self.values = VERIFY.inputs()

    def test_canonical_evidence_passes(self):
        self.assertEqual([], VERIFY.validate(*self.values))

    def test_incomplete_cleanup_fails(self):
        contract, evidence, manifest, scenario, schema, findings = copy.deepcopy(self.values)
        evidence["observations"]["cleanup"] = "incomplete"
        self.assertTrue(VERIFY.validate(contract, evidence, manifest, scenario, schema, findings))

    def test_unpassed_scenario_fails(self):
        contract, evidence, manifest, scenario, schema, findings = copy.deepcopy(self.values)
        scenario["status"] = "planned"
        self.assertTrue(VERIFY.validate(contract, evidence, manifest, scenario, schema, findings))


if __name__ == "__main__":
    unittest.main()
