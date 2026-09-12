import shutil
import tempfile
import unittest
from pathlib import Path

from research_paths import REPO_ROOT
from validate_bh06_reachability import AUTHORITY, BROWSER, COMPLETION, INDEX, MANIFEST, PLAN, REPORT, validate


class BH06ReachabilityTests(unittest.TestCase):
    paths = [AUTHORITY, BROWSER, COMPLETION, INDEX, MANIFEST, PLAN, REPORT]

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

    def test_rejects_unbound_module_mutation(self):
        self.mutate(REPORT, '"sha256": "d774', '"sha256": "0774')
        errors = validate(self.root)
        self.assertTrue(any("canonical reachability" in item for item in errors))

    def test_rejects_broken_reason_chain(self):
        self.mutate(REPORT, '"reason_chain": ["Elixir.BlazeX.BH06.VerticalSlice.Counter"]', '"reason_chain": ["Elixir.Other"]')
        self.assertTrue(any("entrypoint-rooted reason" in item for item in validate(self.root)))

    def test_rejects_hidden_unused_module(self):
        self.mutate(REPORT, '"unused_modules": ["Elixir.BlazeX.BH06.VerticalSlice.Unused"]', '"unused_modules": []')
        self.assertTrue(any("exclusion sentinel" in item for item in validate(self.root)))

    def test_rejects_summary_drift(self):
        self.mutate(REPORT, '"inventory_modules": 2', '"inventory_modules": 3')
        self.assertTrue(any("summary" in item for item in validate(self.root)))

    def test_rejects_manifest_substitution(self):
        self.mutate(BROWSER, '"manifest_sha256": "700d', '"manifest_sha256": "000d')
        self.assertTrue(any("exact Phase 2 manifest" in item for item in validate(self.root)))

    def test_rejects_stale_completion_identity(self):
        self.mutate(COMPLETION, '"decision": "accept"', '"decision": "reject"')
        self.assertTrue(any("completion identities" in item for item in validate(self.root)))


if __name__ == "__main__":
    unittest.main()
