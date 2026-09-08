"""Regression checks for exact, prospective planning amendments."""

import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import planning_policy as policy


class PlanningAmendmentTests(unittest.TestCase):
    def check_hash(self, actual):
        return policy.roadmap_amendment_error(policy.HISTORICAL_ROADMAP_SHA256, actual)

    def test_both_exact_amendments_remain_valid(self):
        self.assertIsNone(self.check_hash(policy.AMENDED_ROADMAP_SHA256))
        self.assertIsNone(self.check_hash(policy.DEFERRED_ROADMAP_SHA256))

    def test_arbitrary_roadmap_change_is_rejected(self):
        self.assertIsNotNone(self.check_hash("0" * 64))

    def test_unknown_historical_source_is_rejected(self):
        self.assertIsNotNone(policy.roadmap_amendment_error("0" * 64, policy.DEFERRED_ROADMAP_SHA256))

    def test_environment_policy_still_required(self):
        self.assertIsNotNone(policy.roadmap_amendment_error(
            policy.HISTORICAL_ROADMAP_SHA256, policy.DEFERRED_ROADMAP_SHA256, ""))

    def test_missing_or_changed_deferral_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            missing = Path(directory) / "missing.md"
            with patch.object(policy, "FRAMEWORK_DEFERRAL_PATH", missing):
                self.assertIn("missing", self.check_hash(policy.DEFERRED_ROADMAP_SHA256))
        with patch.object(policy, "FRAMEWORK_DEFERRAL_SHA256", "0" * 64):
            self.assertIn("unbound", self.check_hash(policy.DEFERRED_ROADMAP_SHA256))

    def test_active_gates_do_not_require_adapter_completion(self):
        root = policy.ROOT / "60-planning/01-browser-host/bh-04-dom-renderer-and-interaction-transport"
        phase8 = next(root.glob("phase-08-*.md")).read_text()
        phase9 = next(root.glob("phase-09-*.md")).read_text()
        phase10 = next(root.glob("phase-10-*.md")).read_text()
        self.assertIn("[DEFERRED] 8 Phase", phase8)
        self.assertNotIn("Phase 8 completion identity", phase9)
        self.assertNotIn("Phase 1–9 completion identities", phase10)
        self.assertNotIn("headless/standalone/adapter conformance", phase10)
        for text in (phase8, phase9, phase10):
            self.assertIn("liveview-integration-deferral.md", text)


if __name__ == "__main__":
    unittest.main()
