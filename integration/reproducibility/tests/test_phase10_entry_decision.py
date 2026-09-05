from __future__ import annotations

import copy
import importlib.util
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("decide_phase10_entry", ROOT / "decide_phase10_entry.py")
ENTRY = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(ENTRY)


class EntryDecisionTest(unittest.TestCase):
    def setUp(self):
        self.decision = ENTRY.build_decision()
        self.entry = ENTRY.build_entry(self.decision)

    def test_canonical_decision_and_entry_pass(self):
        self.assertEqual([], ENTRY.validate(self.decision, self.entry))

    def test_bh02_activation_fails(self):
        value = copy.deepcopy(self.entry)
        value["activation"]["authorized"] = True
        value["activation"]["may_start"] = True
        self.assertTrue(ENTRY.validate(self.decision, value))

    def test_stale_baseline_binding_fails(self):
        value = copy.deepcopy(self.decision)
        value["baseline_ref"]["sha256"] = "0" * 64
        self.assertTrue(ENTRY.validate(value, self.entry))

    def test_missing_condition_fails(self):
        value = copy.deepcopy(self.entry)
        value["conditions"].pop()
        self.assertTrue(ENTRY.validate(self.decision, value))

    def test_missing_deferred_obligation_fails(self):
        value = copy.deepcopy(self.entry)
        value["deferred_qualification"].pop()
        self.assertTrue(ENTRY.validate(self.decision, value))

    def test_backend_leakage_in_neutral_constraint_fails(self):
        value = copy.deepcopy(self.entry)
        value["neutral_contract_constraints"][0] = "Use DOM nodes as semantic nodes."
        self.assertTrue(ENTRY.validate(self.decision, value))


if __name__ == "__main__":
    unittest.main()
