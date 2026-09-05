from __future__ import annotations

import copy
import importlib.util
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("version_phase10_baseline", ROOT / "version_phase10_baseline.py")
BASELINE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(BASELINE)


class FeasibilityBaselineTest(unittest.TestCase):
    def setUp(self):
        self.record = BASELINE.build()

    def test_canonical_baseline_passes(self):
        self.assertEqual([], BASELINE.validate(self.record))

    def test_stale_source_binding_fails(self):
        value = copy.deepcopy(self.record)
        value["source_bindings"][0]["sha256"] = "0" * 64
        self.assertTrue(BASELINE.validate(value))

    def test_omitted_deferred_environment_fails(self):
        value = copy.deepcopy(self.record)
        value["environments"]["deferred"].pop()
        self.assertTrue(BASELINE.validate(value))

    def test_changed_active_scenario_fails(self):
        value = copy.deepcopy(self.record)
        value["browser_scenarios"][0]["semantic_sha256"] = "0" * 64
        self.assertTrue(BASELINE.validate(value))

    def test_support_or_bh02_promotion_fails(self):
        value = copy.deepcopy(self.record)
        value["support_status"] = "supported"
        value["review"]["bh02_authorized"] = True
        self.assertTrue(BASELINE.validate(value))

    def test_missing_invalidation_trigger_fails(self):
        value = copy.deepcopy(self.record)
        value["supersession"]["invalidation_triggers"].pop()
        self.assertTrue(BASELINE.validate(value))


if __name__ == "__main__":
    unittest.main()
