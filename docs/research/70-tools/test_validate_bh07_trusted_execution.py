import json
import shutil
import tempfile
import unittest
from pathlib import Path

from research_paths import REPO_ROOT
from validate_bh07_trusted_execution import *


class TrustedExecutionTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        authority = load(REPO_ROOT, AUTHORITY)
        evidence = load(REPO_ROOT, EVIDENCE)
        files = {
            AUTHORITY, EVIDENCE, INDEX, COMPLETION, PLAN, CONTRACT, ADMISSION,
            EXECUTION, BOOTSTRAP, PLUG, SESSION_PLUG, ENDPOINT, PROFILE_MIX,
            PROFILE_LOCK, *authority["bound_inputs"], *evidence["source_bindings"],
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

    def test_operation_mutation(self):
        data = load(self.root, EVIDENCE)
        data["execution"]["command"] = "counter.delete"
        self.write(EVIDENCE, data)
        self.assertTrue(any("execution boundary" in error for error in validate(self.root)))

    def test_source_mutation(self):
        path = self.root / EXECUTION
        path.write_text(path.read_text().replace("@default_max_executions 256", "@default_max_executions 512"))
        self.assertTrue(any("source binding" in error or "implementation" in error for error in validate(self.root)))

    def test_replay_mutation(self):
        data = load(self.root, EVIDENCE)
        data["idempotency"]["concurrent_exact_replay_single_mutation"] = False
        self.write(EVIDENCE, data)
        self.assertTrue(any("replay behavior" in error for error in validate(self.root)))

    def test_stale_retention_mutation(self):
        data = load(self.root, EVIDENCE)
        data["idempotency"]["exact_stale_replay"] = "may-execute-later"
        self.write(EVIDENCE, data)
        self.assertTrue(any("stale replay" in error for error in validate(self.root)))

    def test_audit_mutation(self):
        data = load(self.root, EVIDENCE)
        data["audit"]["max_entries"] = 65
        self.write(EVIDENCE, data)
        self.assertTrue(any("audit bound" in error for error in validate(self.root)))

    def test_transport_mutation(self):
        data = load(self.root, EVIDENCE)
        data["transport"]["requires"].remove("current-csrf")
        self.write(EVIDENCE, data)
        self.assertTrue(any("transport security" in error for error in validate(self.root)))

    def test_capability_mutation(self):
        data = load(self.root, EVIDENCE)
        data["capabilities"]["pushes"] = True
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
