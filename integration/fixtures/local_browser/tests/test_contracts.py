from __future__ import annotations

import copy
import importlib.util
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("verify_contracts", ROOT / "verify_contracts.py")
VERIFY = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(VERIFY)


class LocalBrowserContractTest(unittest.TestCase):
    def setUp(self):
        self.values = list(VERIFY.inputs())

    def validate(self, index=None, value=None):
        values = copy.deepcopy(self.values)
        if index is not None:
            values[index] = value
        return VERIFY.validate_contracts(*values)

    def test_canonical_contracts_pass(self):
        self.assertEqual([], self.validate())

    def test_public_fixture_status_fails(self):
        catalog = copy.deepcopy(self.values[1])
        catalog["status"] = "stable-public"
        self.assertTrue(self.validate(1, catalog))

    def test_missing_proof_fails(self):
        catalog = copy.deepcopy(self.values[1])
        for scenario in catalog["scenarios"]:
            scenario["proofs"] = [proof for proof in scenario["proofs"] if proof != "BX-BH01-PROOF-DOM-UPDATE"]
        self.assertTrue(self.validate(1, catalog))

    def test_missing_negative_matrix_fails(self):
        catalog = copy.deepcopy(self.values[1])
        catalog["scenarios"][0]["negative"] = []
        self.assertTrue(self.validate(1, catalog))

    def test_identity_normalization_fails(self):
        policy = copy.deepcopy(self.values[2])
        policy["never_normalize"] = []
        self.assertTrue(self.validate(2, policy))

    def test_production_fixture_import_fails(self):
        self.assertTrue(self.validate(3, self.values[3] + "\nimport integration/fixtures/local_browser"))


if __name__ == "__main__":
    unittest.main()
