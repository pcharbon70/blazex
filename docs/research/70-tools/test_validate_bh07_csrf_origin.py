import json
import shutil
import tempfile
import unittest
from pathlib import Path

from research_paths import REPO_ROOT
from validate_bh07_csrf_origin import *


class CsrfOriginTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        authority = load(REPO_ROOT, AUTHORITY)
        evidence = load(REPO_ROOT, EVIDENCE)
        files = {
            AUTHORITY,
            EVIDENCE,
            INDEX,
            COMPLETION,
            PLAN,
            CONTRACT,
            REGISTRY,
            ORIGIN,
            BOOTSTRAP,
            PLUG,
            CONTROL,
            ENDPOINT,
            PROFILE_MIX,
            PROFILE_LOCK,
            *authority["bound_inputs"],
            *evidence["source_bindings"],
        }
        for relative in files:
            target = self.root / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(REPO_ROOT / relative, target)

    def tearDown(self):
        self.temp.cleanup()

    def write(self, relative, data):
        (self.root / relative).write_text(json.dumps(data))

    def test_valid(self):
        self.assertEqual([], validate(self.root))

    def test_decision_mutation(self):
        data = load(self.root, EVIDENCE)
        data["decision"] = "reject"
        self.write(EVIDENCE, data)
        self.assertTrue(any("decision" in error for error in validate(self.root)))

    def test_entropy_mutation(self):
        data = load(self.root, EVIDENCE)
        data["csrf"]["random_bytes"] = 16
        self.write(EVIDENCE, data)
        self.assertTrue(any("CSRF authority" in error for error in validate(self.root)))

    def test_source_mutation(self):
        path = self.root / REGISTRY
        path.write_text(path.read_text().replace("strong_rand_bytes(32)", "strong_rand_bytes(8)"))
        self.assertTrue(any("source binding" in error or "registry implementation" in error for error in validate(self.root)))

    def test_origin_mutation(self):
        data = load(self.root, EVIDENCE)
        data["origin"]["cardinality"] = 2
        self.write(EVIDENCE, data)
        self.assertTrue(any("origin policy" in error for error in validate(self.root)))

    def test_projection_mutation(self):
        data = load(self.root, EVIDENCE)
        data["transport"]["authenticated_projection_fields"].append("role")
        self.write(EVIDENCE, data)
        self.assertTrue(any("projection" in error for error in validate(self.root)))

    def test_cookie_mutation(self):
        data = load(self.root, EVIDENCE)
        data["transport"]["cookie"]["same_site"] = "Lax"
        self.write(EVIDENCE, data)
        self.assertTrue(any("transport" in error for error in validate(self.root)))

    def test_dependency_mutation(self):
        path = self.root / PROFILE_MIX
        path.write_text(path.read_text() + '\n# {:local_live_view, "== 0.1.0"}\n')
        self.assertTrue(any("deferred dependency" in error for error in validate(self.root)))

    def test_plan_mutation(self):
        path = self.root / PLAN
        path.write_text(path.read_text() + "\n- [ ] bypass\n")
        self.assertTrue(any("checklist" in error for error in validate(self.root)))


if __name__ == "__main__":
    unittest.main()
