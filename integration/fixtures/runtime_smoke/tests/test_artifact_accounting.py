from __future__ import annotations

import copy
import importlib.util
import unittest
from pathlib import Path


HERE = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "verify_artifact_accounting", HERE / "verify_artifact_accounting.py"
)
VERIFY = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(VERIFY)


class ArtifactAccountingTest(unittest.TestCase):
    def setUp(self):
        self.manifest, self.evidence, self.contract = VERIFY.inputs()

    def validate(self, manifest=None, evidence=None):
        return VERIFY.validate(
            manifest or copy.deepcopy(self.manifest),
            evidence or copy.deepcopy(self.evidence),
            copy.deepcopy(self.contract),
            check_files=False,
        )

    def test_canonical_records_pass(self):
        self.assertEqual([], VERIFY.validate(*VERIFY.inputs()))

    def test_duplicate_artifact_id_fails(self):
        manifest = copy.deepcopy(self.manifest)
        manifest["artifacts"][1]["artifact_id"] = manifest["artifacts"][0]["artifact_id"]
        self.assertTrue(self.validate(manifest=manifest))

    def test_unhashed_artifact_fails(self):
        manifest = copy.deepcopy(self.manifest)
        manifest["artifacts"][0]["sha256"] = ""
        self.assertTrue(self.validate(manifest=manifest))

    def test_unknown_license_fails(self):
        manifest = copy.deepcopy(self.manifest)
        manifest["artifacts"][0]["license_record_ids"] = ["BX-UNKNOWN"]
        self.assertTrue(self.validate(manifest=manifest))

    def test_unreachable_artifact_fails(self):
        manifest = copy.deepcopy(self.manifest)
        manifest["artifacts"][0]["reachability_root"] = ""
        self.assertTrue(self.validate(manifest=manifest))

    def test_repeat_difference_fails(self):
        evidence = copy.deepcopy(self.evidence)
        evidence["comparisons"][0]["byte_identical"] = False
        self.assertTrue(self.validate(evidence=evidence))

    def test_budget_pass_claim_fails(self):
        manifest = copy.deepcopy(self.manifest)
        manifest["payload_observations"]["budget_gate"] = "passed"
        self.assertTrue(self.validate(manifest=manifest))


if __name__ == "__main__":
    unittest.main()
