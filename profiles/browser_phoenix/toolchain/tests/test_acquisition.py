from __future__ import annotations

import copy
import importlib.util
import unittest
from pathlib import Path


TOOLCHAIN = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("verify_acquisition", TOOLCHAIN / "verify_acquisition.py")
VERIFY = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(VERIFY)


class AcquisitionQualificationTest(unittest.TestCase):
    def setUp(self):
        self.values = list(VERIFY.inputs())

    def validate(self, index=None, value=None):
        values = copy.deepcopy(self.values)
        if index is not None:
            values[index] = value
        return VERIFY.validate(*values)

    def test_canonical_acquisition_evidence_passes(self):
        self.assertEqual([], self.validate())

    def test_repository_hash_drift_fails(self):
        hashes = copy.deepcopy(self.values[6])
        first = next(iter(hashes))
        hashes[first] = "0" * 64
        self.assertTrue(self.validate(6, hashes))

    def test_lock_mutation_fails(self):
        evidence = copy.deepcopy(self.values[1])
        evidence["successful_replays"][0]["lock_after_sha256"] = "0" * 64
        self.assertTrue(self.validate(1, evidence))

    def test_private_credentials_fail(self):
        policy = copy.deepcopy(self.values[0])
        policy["private_credentials_allowed"] = True
        self.assertTrue(self.validate(0, policy))

    def test_unapproved_lifecycle_script_fails(self):
        policy = copy.deepcopy(self.values[0])
        policy["npm"]["lifecycle_allowlist"].append({"package": "other", "version": "1", "script": "install"})
        self.assertTrue(self.validate(0, policy))

    def test_unrecorded_insecure_registry_fails(self):
        policy = copy.deepcopy(self.values[0])
        policy["registries"]["other"] = "http://private.invalid"
        self.assertTrue(self.validate(0, policy))

    def test_missing_failure_replay_fails(self):
        evidence = copy.deepcopy(self.values[1])
        evidence["failure_replays"].pop()
        self.assertTrue(self.validate(1, evidence))

    def test_ownerless_inventory_fails(self):
        inventory = copy.deepcopy(self.values[2])
        inventory["owners"] = []
        self.assertTrue(self.validate(2, inventory))


if __name__ == "__main__":
    unittest.main()
