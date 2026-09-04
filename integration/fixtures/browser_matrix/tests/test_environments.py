from __future__ import annotations

import copy
import importlib.util
import unittest
from pathlib import Path


HERE = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("verify_environments", HERE / "verify_environments.py")
VERIFY = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(VERIFY)


class BrowserEnvironmentGovernanceTest(unittest.TestCase):
    def setUp(self):
        self.catalog = VERIFY.load(VERIFY.CATALOG)
        self.policy = VERIFY.load(VERIFY.POLICY)
        self.envelope = VERIFY.load(VERIFY.ENVELOPE)
        self.fingerprint = VERIFY.load(VERIFY.FINGERPRINT)

    def validate(self, **changes):
        values = {name: copy.deepcopy(value) for name, value in {
            "catalog": self.catalog, "policy": self.policy,
            "envelope": self.envelope, "fingerprint": self.fingerprint,
        }.items()}
        values.update(changes)
        return VERIFY.validate(**values)

    def test_canonical_environment_governance_passes(self):
        self.assertEqual([], self.validate())

    def test_missing_required_row_fails(self):
        catalog = copy.deepcopy(self.catalog)
        catalog["required_rows"].pop()
        self.assertTrue(self.validate(catalog=catalog))

    def test_probe_substitution_fails(self):
        policy = copy.deepcopy(self.policy)
        policy["probe_may_substitute_required_row"] = True
        self.assertTrue(self.validate(policy=policy))

    def test_silent_retry_fails(self):
        policy = copy.deepcopy(self.policy)
        policy["scheduling"]["maximum_automatic_retries"] = 2
        self.assertTrue(self.validate(policy=policy))

    def test_unexplained_blocked_row_fails(self):
        catalog = copy.deepcopy(self.catalog)
        del catalog["required_rows"][1]["blocker"]
        self.assertTrue(self.validate(catalog=catalog))

    def test_webkit_probe_as_safari_fails(self):
        catalog = copy.deepcopy(self.catalog)
        catalog["non_substituting_probes"][1]["authority"] = "required-row"
        self.assertTrue(self.validate(catalog=catalog))


if __name__ == "__main__":
    unittest.main()
