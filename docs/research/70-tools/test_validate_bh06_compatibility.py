import shutil
import tempfile
import unittest
from pathlib import Path

from research_paths import REPO_ROOT
from validate_bh06_compatibility import (
    AUTHORITY, BROWSER, CLOSURE, COMPLETION, INDEX, MANIFEST, PLAN, PROFILE,
    REPORT, REQUIREMENTS, SCHEMAS, TASK, validate,
)


class BH06CompatibilityTests(unittest.TestCase):
    paths = [AUTHORITY, BROWSER, CLOSURE, COMPLETION, INDEX, MANIFEST, PLAN, PROFILE, REPORT, REQUIREMENTS, TASK] + list(SCHEMAS.values())

    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        authority = __import__("json").loads((REPO_ROOT / AUTHORITY).read_text())
        for relative in set(self.paths + list(authority["bound_inputs"])):
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

    def test_rejects_profile_mutation(self):
        self.mutate(PROFILE, "0.6.6-dev", "0.6.5-dev")
        self.assertTrue(any("normalized profile" in item for item in validate(self.root)))

    def test_rejects_requirements_mutation(self):
        self.mutate(REQUIREMENTS, "atomvm.avm/1", "atomvm.avm/2")
        self.assertTrue(any("normalized requirements" in item for item in validate(self.root)))

    def test_rejects_hidden_incompatibility(self):
        self.mutate(REPORT, '"compatible":true', '"compatible":false')
        self.assertTrue(any("not a passing" in item for item in validate(self.root)))

    def test_rejects_decision_or_summary_drift(self):
        self.mutate(REPORT, '"matched":8', '"matched":7')
        self.assertTrue(any("summary" in item for item in validate(self.root)))

    def test_rejects_manifest_substitution(self):
        self.mutate(MANIFEST, '"profile_sha256":"64dd', '"profile_sha256":"04dd')
        self.assertTrue(any("manifest compatibility" in item for item in validate(self.root)))

    def test_rejects_failed_browser(self):
        self.mutate(BROWSER, '"result": "passed"', '"result": "failed"')
        self.assertTrue(any("browser replay failed" in item for item in validate(self.root)))

    def test_rejects_assembly_gate_bypass(self):
        self.mutate(CLOSURE, "Compatibility.evaluate!", "Compatibility.bypass!")
        self.assertTrue(any("precede assembly" in item for item in validate(self.root)))


if __name__ == "__main__":
    unittest.main()
