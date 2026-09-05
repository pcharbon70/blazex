from __future__ import annotations

import copy
import importlib.util
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("close_phase10_ledgers", ROOT / "close_phase10_ledgers.py")
LEDGERS = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(LEDGERS)


class LedgerClosureTest(unittest.TestCase):
    def setUp(self):
        self.record = LEDGERS.build()

    def test_canonical_closure_passes(self):
        self.assertEqual([], LEDGERS.validate(self.record))

    def test_missing_input_identity_fails(self):
        value = copy.deepcopy(self.record)
        value["inputs"].pop()
        self.assertTrue(LEDGERS.validate(value))

    def test_deferred_proof_cannot_claim_execution(self):
        value = copy.deepcopy(self.record)
        mobile = next(item for item in value["proof_obligations"] if item["scope"] == "deferred-bh22")
        mobile["positive_and_negative_executed"] = True
        self.assertTrue(LEDGERS.validate(value))

    def test_requirement_trace_drift_fails(self):
        value = copy.deepcopy(self.record)
        value["proof_obligations"][0]["acceptance_refs"] = []
        self.assertTrue(LEDGERS.validate(value))

    def test_unreviewed_exception_fails(self):
        value = copy.deepcopy(self.record)
        value["exceptions"] = ["waive failure"]
        self.assertTrue(LEDGERS.validate(value))


if __name__ == "__main__":
    unittest.main()
