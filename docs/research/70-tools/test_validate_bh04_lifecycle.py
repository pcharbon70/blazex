"""Negative evidence checks for the current effect and lifecycle gate."""
import copy
import unittest
import validate_bh04_lifecycle as gate

class LifecycleEvidenceTests(unittest.TestCase):
    def setUp(self): self.data = gate.read(gate.ROOT, gate.BROWSERS)
    def test_baseline(self): self.assertEqual([], gate.browser_errors(self.data))
    def test_matrix(self):
        self.data["results"].pop(); self.assertIn("active matrix incomplete", gate.browser_errors(self.data))
    def test_leak(self):
        self.data["results"][0]["late"][0]["resources"]["active"] = 1
        self.assertIn("cleanup leak", gate.browser_errors(self.data))
    def test_retry(self):
        self.data["results"][0]["late"][0]["failure"]["retry_attempts"] = 1
        self.assertIn("unbounded recovery", gate.browser_errors(self.data))
    def test_deadline(self):
        self.data["results"][0]["cleanup"][0]["elapsed_ms"] = 1001
        self.assertIn("cleanup deadline exceeded", gate.browser_errors(self.data))
    def test_missing_scenario(self):
        self.data["results"][0]["traces"].pop(); self.assertIn("scenarios incomplete", gate.browser_errors(self.data))
    def test_support(self):
        self.data["results"][0]["support_state"] = "supported"
        self.assertIn("result/support invalid", gate.browser_errors(self.data))
    def test_advance(self):
        row = next(t for t in self.data["results"][0]["traces"] if t["name"] == "failure-effect")
        row["semantic"]["count"]["count"] = 1
        self.assertIn("failure isolation/authority", gate.browser_errors(self.data))
    def test_observation(self):
        self.data["results"][0]["observation_window_ms"] = 0
        self.assertIn("observation window incomplete", gate.browser_errors(self.data))

if __name__ == "__main__": unittest.main()
