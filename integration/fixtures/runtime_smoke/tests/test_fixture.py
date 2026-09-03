from __future__ import annotations

import copy
import importlib.util
import unittest
from pathlib import Path


HERE = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("verify_fixture", HERE / "verify_fixture.py")
VERIFY = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(VERIFY)


class RuntimeSmokeFixtureTest(unittest.TestCase):
    def setUp(self):
        self.contract = VERIFY.load(HERE / "build-contract.json")
        self.manifest = VERIFY.load(HERE / "bundle-manifest.json")

    def test_canonical_source_contract_passes(self):
        self.assertEqual([], VERIFY.validate(copy.deepcopy(self.contract), manifest=copy.deepcopy(self.manifest)))

    def test_public_fixture_fails(self):
        contract = copy.deepcopy(self.contract)
        contract["public_api"] = True
        self.assertTrue(VERIFY.validate(contract))

    def test_missing_mode_fails(self):
        contract = copy.deepcopy(self.contract)
        contract["modes"].pop()
        self.assertTrue(VERIFY.validate(contract))

    def test_resource_inclusion_fails(self):
        contract = copy.deepcopy(self.contract)
        contract["resources"] = ["host-dependent-resource"]
        self.assertTrue(VERIFY.validate(contract))

    def test_unaccounted_artifact_fails(self):
        manifest = copy.deepcopy(self.manifest)
        manifest["artifacts"].pop()
        self.assertTrue(VERIFY.validate(copy.deepcopy(self.contract), manifest=manifest))


if __name__ == "__main__":
    unittest.main()
