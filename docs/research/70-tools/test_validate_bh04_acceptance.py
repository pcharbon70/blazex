import copy
import unittest
import validate_bh04_acceptance as gate

class AcceptanceTests(unittest.TestCase):
    def setUp(self):
        self.record = gate.read(gate.ROOT, "acceptance-overlay")
    def test_truthful_revise(self):
        self.assertEqual(gate.decision_errors(self.record), [])
    def test_rejects_acceptance(self):
        self.record["decision"] = "accepted"
        self.assertTrue(gate.decision_errors(self.record))
    def test_rejects_bh05(self):
        self.record["bh05_eligible"] = True
        self.assertTrue(gate.decision_errors(self.record))
    def test_rejects_hidden_blocker(self):
        self.record["open_blockers"].pop()
        self.assertTrue(gate.decision_errors(self.record))
    def test_rejects_missing_condition(self):
        self.record["conditions"].pop()
        self.assertTrue(gate.decision_errors(self.record))
    def test_rejects_duplicate_condition(self):
        self.record["conditions"][1] = copy.deepcopy(self.record["conditions"][0])
        self.assertTrue(gate.decision_errors(self.record))
    def test_rejects_support(self):
        self.record["support_state"] = "supported"
        self.assertTrue(gate.decision_errors(self.record))
    def test_rejects_registry_rewrite(self):
        self.record["canonical_registry_modified"] = True
        self.assertTrue(gate.decision_errors(self.record))
    def test_rejects_release_credit(self):
        self.record["conditions"][1]["release_pass_credit"] = True
        self.assertTrue(gate.decision_errors(self.record))
    def test_rejects_unowned_blocker(self):
        self.record["open_blockers"][0]["owner"] = ""
        self.assertTrue(gate.decision_errors(self.record))
    def test_rejects_malformed(self):
        self.assertTrue(gate.decision_errors({}))

if __name__ == "__main__":
    unittest.main()
