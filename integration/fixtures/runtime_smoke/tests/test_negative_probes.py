from __future__ import annotations

import copy
import importlib.util
import unittest
from pathlib import Path


HERE = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "verify_negative_probes", HERE / "verify_negative_probes.py"
)
VERIFY = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(VERIFY)


class NegativeProbeEvidenceTest(unittest.TestCase):
    def setUp(self):
        self.evidence = VERIFY.load(VERIFY.EVIDENCE)

    def test_canonical_evidence_passes(self):
        self.assertEqual([], VERIFY.validate(copy.deepcopy(self.evidence)))

    def test_missing_case_fails(self):
        evidence = copy.deepcopy(self.evidence)
        evidence["results"].pop()
        self.assertTrue(VERIFY.validate(evidence, check_files=False))

    def test_unpassed_case_fails(self):
        evidence = copy.deepcopy(self.evidence)
        evidence["results"][0]["passed"] = False
        self.assertTrue(VERIFY.validate(evidence, check_files=False))

    def test_drifting_identity_fails(self):
        evidence = copy.deepcopy(self.evidence)
        evidence["bundle"]["sha256"] = "0" * 64
        self.assertTrue(VERIFY.validate(evidence))


if __name__ == "__main__":
    unittest.main()
