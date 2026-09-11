import shutil
import tempfile
import unittest
from pathlib import Path

from research_paths import REPO_ROOT
from validate_bh06_vertical_slice import AUTHORITY, BROWSER, COUNTER, INDEX, MANIFEST, PLAN, PROJECT, validate


class BH06VerticalSliceTests(unittest.TestCase):
    paths = [AUTHORITY, BROWSER, COUNTER, INDEX, MANIFEST, PLAN, PROJECT]

    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        authority = __import__("json").loads((REPO_ROOT / AUTHORITY).read_text())
        paths = self.paths + list(authority["bound_inputs"])
        for relative in paths:
            target = self.root / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(REPO_ROOT / relative, target)

    def tearDown(self):
        self.temporary.cleanup()

    def mutate(self, relative, old, new):
        path = self.root / relative
        path.write_text(path.read_text().replace(old, new), encoding="utf-8")

    def test_accepted_candidate_passes(self):
        self.assertEqual([], validate(self.root))

    def test_rejects_failed_browser(self):
        self.mutate(BROWSER, '"result": "passed"', '"result": "failed"')
        self.assertTrue(any("active browser failed" in item for item in validate(self.root)))

    def test_rejects_manifest_drift(self):
        self.mutate(MANIFEST, '"bytes":529', '"bytes":530')
        self.assertTrue(any("does not bind" in item for item in validate(self.root)))

    def test_rejects_js_only_substitute(self):
        self.mutate(BROWSER, '"runtime": "atomvm-wasm"', '"runtime": "javascript"')
        self.assertTrue(any("active browser failed" in item for item in validate(self.root)))

    def test_rejects_private_component_import(self):
        with (self.root / COUNTER).open("a", encoding="utf-8") as stream:
            stream.write("\n# BlazeX.Renderer private import\n")
        self.assertTrue(any("public component imports" in item for item in validate(self.root)))


if __name__ == "__main__":
    unittest.main()
