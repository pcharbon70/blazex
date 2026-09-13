import json
import shutil
import tempfile
import unittest
from pathlib import Path

from research_paths import REPO_ROOT
from validate_bh07_authenticated_push import *


class AuthenticatedPushTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        authority = load(REPO_ROOT, AUTHORITY)
        evidence = load(REPO_ROOT, EVIDENCE)
        files = {
            AUTHORITY, EVIDENCE, INDEX, COMPLETION, PLAN, CONTRACT, EXECUTION,
            BOOTSTRAP, SOCKET, CHANNEL, ENDPOINT, APPLICATION, CONFIG, PROFILE_MIX,
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

    def test_bound_mutation(self):
        data = load(self.root, EVIDENCE)
        data["stream"]["max_events"] = 65
        self.write(EVIDENCE, data)
        self.assertTrue(any("stream" in error for error in validate(self.root)))

    def test_source_mutation(self):
        path = self.root / EXECUTION
        path.write_text(path.read_text().replace("@default_max_events 64", "@default_max_events 128"))
        self.assertTrue(any("source binding" in error or "implementation" in error for error in validate(self.root)))

    def test_emission_mutation(self):
        data = load(self.root, EVIDENCE)
        data["stream"]["exact_command_replay_emits"] = True
        self.write(EVIDENCE, data)
        self.assertTrue(any("stream" in error for error in validate(self.root)))

    def test_cursor_mutation(self):
        data = load(self.root, EVIDENCE)
        data["resynchronization"]["evicted_cursor"] = "empty-replay"
        self.write(EVIDENCE, data)
        self.assertTrue(any("resynchronization" in error for error in validate(self.root)))

    def test_origin_mutation(self):
        path = self.root / ENDPOINT
        path.write_text(path.read_text().replace("check_csrf: false", "check_origin: false, check_csrf: false"))
        self.assertTrue(any("origin/session" in error for error in validate(self.root)))

    def test_client_event_mutation(self):
        data = load(self.root, EVIDENCE)
        data["transport"]["client_channel_events"] = "allow"
        self.write(EVIDENCE, data)
        self.assertTrue(any("transport" in error for error in validate(self.root)))

    def test_redaction_mutation(self):
        data = load(self.root, EVIDENCE)
        data["redaction"]["csrf_proof"] = True
        self.write(EVIDENCE, data)
        self.assertTrue(any("redaction" in error for error in validate(self.root)))

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
