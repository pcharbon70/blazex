import json
import shutil
import tempfile
import unittest
from pathlib import Path

from research_paths import REPO_ROOT
from validate_bh07_command_admission import *


class CommandAdmissionTests(unittest.TestCase):
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
            ADMISSION,
            BOOTSTRAP,
            PLUG,
            SESSION_PLUG,
            APPLICATION,
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

    def test_bound_mutation(self):
        data = load(self.root, EVIDENCE)
        data["admission"]["max_admissions"] = 257
        self.write(EVIDENCE, data)
        self.assertTrue(any("bounds" in error for error in validate(self.root)))

    def test_source_mutation(self):
        path = self.root / ADMISSION
        path.write_text(path.read_text().replace("@default_max_admissions 256", "@default_max_admissions 512"))
        self.assertTrue(any("source binding" in error or "implementation" in error for error in validate(self.root)))

    def test_execution_mutation(self):
        data = load(self.root, EVIDENCE)
        data["admission"]["command_execution"] = True
        self.write(EVIDENCE, data)
        self.assertTrue(any("non-execution" in error for error in validate(self.root)))

    def test_authorization_mutation(self):
        data = load(self.root, EVIDENCE)
        data["authorization"]["subject_grants_server_owned"] = False
        self.write(EVIDENCE, data)
        self.assertTrue(any("authorization boundary" in error for error in validate(self.root)))

    def test_transport_mutation(self):
        data = load(self.root, EVIDENCE)
        data["transport"]["requires"].remove("current-csrf")
        self.write(EVIDENCE, data)
        self.assertTrue(any("transport security" in error for error in validate(self.root)))

    def test_capability_mutation(self):
        data = load(self.root, EVIDENCE)
        data["capabilities"]["remote_commands"] = True
        self.write(EVIDENCE, data)
        self.assertTrue(any("capability" in error for error in validate(self.root)))

    def test_dependency_mutation(self):
        path = self.root / PROFILE_MIX
        path.write_text(path.read_text() + '\n# {:phoenix_live_view, "== 1.0.0"}\n')
        self.assertTrue(any("deferred dependency" in error for error in validate(self.root)))

    def test_plan_mutation(self):
        path = self.root / PLAN
        path.write_text(path.read_text() + "\n- [ ] bypass\n")
        self.assertTrue(any("checklist" in error for error in validate(self.root)))


if __name__ == "__main__":
    unittest.main()
