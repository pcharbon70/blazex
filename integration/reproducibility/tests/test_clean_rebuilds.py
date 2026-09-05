from __future__ import annotations

import copy
import importlib.util
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("compare_clean_rebuilds", ROOT / "compare_clean_rebuilds.py")
COMPARE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(COMPARE)


def record(identity: str) -> dict:
    return {
        "record_id": identity,
        "status": "passed",
        "source_revision": "a" * 40,
        "tools": [{"name": "tool", "identity": "1", "sha256": "b" * 64}],
        "artifacts": {"runtime_manifest_sha256": "c" * 64, "browser_bundle_manifest_sha256": "d" * 64, "profile_manifest_sha256": "e" * 64},
        "browser_scenarios": [{"browser": "chromium", "scenario": "behavior", "semantic_sha256": "f" * 64}],
        "reports": [{"id": str(index), "sha256": str(index) * 64, "matches_canonical": True} for index in range(1, 8)],
        "manual_actions": [],
        "failures": [],
    }


class CleanRebuildComparisonTest(unittest.TestCase):
    def setUp(self):
        self.first = record("BX-BH01-PHASE10-CLEAN-A-0.1")
        self.second = record("BX-BH01-PHASE10-CLEAN-B-0.1")

    def test_equivalent_records_pass(self):
        report, errors = COMPARE.compare(self.first, self.second)
        self.assertEqual([], errors)
        self.assertEqual("pass-with-declared-host-variance", report["status"])

    def test_artifact_drift_fails(self):
        second = copy.deepcopy(self.second)
        second["artifacts"]["profile_manifest_sha256"] = "0" * 64
        self.assertTrue(COMPARE.compare(self.first, second)[1])

    def test_semantic_drift_fails(self):
        second = copy.deepcopy(self.second)
        second["browser_scenarios"][0]["semantic_sha256"] = "0" * 64
        self.assertTrue(COMPARE.compare(self.first, second)[1])

    def test_manual_intervention_fails(self):
        second = copy.deepcopy(self.second)
        second["manual_actions"] = ["repair"]
        self.assertTrue(COMPARE.compare(self.first, second)[1])


if __name__ == "__main__":
    unittest.main()
