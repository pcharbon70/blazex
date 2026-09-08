import copy
import unittest
import validate_bh04_conformance as gate

class ConformanceTests(unittest.TestCase):
    def setUp(self):
        self.data = gate.read(gate.ROOT / gate.LEDGER)

    def test_ledger(self):
        self.assertEqual(gate.ledger_errors(self.data), [])

    def test_rejects_missing_and_failed_rows(self):
        self.data["ledger"].pop()
        self.assertIn("active inventory", gate.ledger_errors(self.data))
        self.data["ledger"][0]["result"] = "failed"
        self.assertIn("active mismatch", gate.ledger_errors(self.data))

    def test_rejects_duplicate_rows(self):
        self.data["ledger"][1] = copy.deepcopy(self.data["ledger"][0])
        self.assertIn("duplicate evidence row", gate.ledger_errors(self.data))

    def test_rejects_framework_credit(self):
        self.data["ledger"][0]["path"] = "liveview"
        self.assertIn("path inventory", gate.ledger_errors(self.data))

    def test_rejects_unowned_deferral(self):
        self.data["deferred"][0]["owner"] = ""
        self.assertIn("unowned deferral", gate.ledger_errors(self.data))

    def test_rejects_support_authority_and_accessibility_overclaim(self):
        self.data["support_state"] = "supported"
        self.data["next_authorized_work"] = "BH-05"
        self.data["accessibility_method"] = "screen-reader qualified"
        errors = gate.ledger_errors(self.data)
        for reason in ["result/support promotion", "authority promotion", "accessibility overclaim"]:
            self.assertIn(reason, errors)

    def test_rejects_missing_browser_and_hash(self):
        self.data["browsers"].pop()
        self.data["source_hashes"].pop(next(iter(self.data["source_hashes"])))
        errors = gate.ledger_errors(self.data)
        self.assertIn("browser inventory", errors)
        self.assertIn("raw input inventory", errors)

    def test_rejects_malformed_ledger(self):
        self.assertTrue(gate.ledger_errors({}))

if __name__ == "__main__":
    unittest.main()
