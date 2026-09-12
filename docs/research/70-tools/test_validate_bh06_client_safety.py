import shutil
import tempfile
import unittest
from pathlib import Path

from research_paths import REPO_ROOT
from validate_bh06_client_safety import (
    AUTHORITY, BROWSER, CLOSURE, COMPLETION, INDEX, MANIFEST, PLAN, POLICY,
    REPORT, TASK, validate,
)


class BH06ClientSafetyTests(unittest.TestCase):
    paths = [AUTHORITY, BROWSER, CLOSURE, COMPLETION, INDEX, MANIFEST, PLAN, POLICY, REPORT, TASK]

    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        authority = __import__("json").loads((REPO_ROOT / AUTHORITY).read_text())
        for relative in self.paths + list(authority["bound_inputs"]):
            target = self.root / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(REPO_ROOT / relative, target)

    def tearDown(self):
        self.temporary.cleanup()

    def mutate(self, relative, old, new):
        path = self.root / relative
        path.write_text(path.read_text().replace(old, new), encoding="utf-8")

    def test_accepted_evidence_passes(self):
        self.assertEqual([], validate(self.root))

    def test_rejects_server_classification(self):
        self.mutate(REPORT, '"classification": "client-safe"', '"classification": "server-only"')
        self.assertTrue(any("not client-safe" in item for item in validate(self.root)))

    def test_rejects_policy_mutation(self):
        self.mutate(POLICY, "bounded public component fixture", "mutated policy reason")
        self.assertTrue(any("normalized policy" in item for item in validate(self.root)))

    def test_rejects_hidden_violation(self):
        self.mutate(REPORT, '"violations": []', '"violations": [{"kind": "native"}]')
        self.assertTrue(any("not a passing" in item for item in validate(self.root)))

    def test_rejects_summary_drift(self):
        self.mutate(REPORT, '"forbidden_primitives_checked": 6', '"forbidden_primitives_checked": 5')
        self.assertTrue(any("summary" in item for item in validate(self.root)))

    def test_rejects_manifest_substitution(self):
        self.mutate(BROWSER, '"manifest_sha256": "4a23', '"manifest_sha256": "0a23')
        self.assertTrue(any("exact Phase 3 manifest" in item for item in validate(self.root)))

    def test_rejects_assembly_gate_bypass(self):
        self.mutate(TASK, "ClientClosure.authorize!", "ClientClosure.bypass!")
        self.assertTrue(any("bypasses" in item for item in validate(self.root)))


if __name__ == "__main__":
    unittest.main()
