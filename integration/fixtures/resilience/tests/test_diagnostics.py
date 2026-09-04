from __future__ import annotations

import copy
import importlib.util
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("verify_diagnostics", ROOT / "verify_diagnostics.py")
VERIFY = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(VERIFY)


class DiagnosticContractTest(unittest.TestCase):
    def setUp(self):
        self.values = list(VERIFY.inputs())

    def test_canonical_contract_passes(self):
        self.assertEqual([], VERIFY.validate(*self.values))

    def test_missing_failure_category_fails(self):
        contract = copy.deepcopy(self.values[0])
        del contract["categories"][next(iter(contract["categories"]))]
        self.assertTrue(VERIFY.validate(contract, self.values[1]))

    def test_console_only_failure_fails(self):
        contract = copy.deepcopy(self.values[0])
        contract["failure_observability"]["console_only_allowed"] = True
        self.assertTrue(VERIFY.validate(contract, self.values[1]))

    def test_unbounded_retention_fails(self):
        contract = copy.deepcopy(self.values[0])
        contract["retention"]["in_memory_events"] = 10_000
        self.assertTrue(VERIFY.validate(contract, self.values[1]))

    def test_missing_redaction_class_fails(self):
        contract = copy.deepcopy(self.values[0])
        contract["redacted_key_fragments"].remove("csrf")
        self.assertTrue(VERIFY.validate(contract, self.values[1]))


if __name__ == "__main__":
    unittest.main()
