import hashlib
from pathlib import Path
import subprocess
import tempfile
import unittest
import bh03_history as history
from research_paths import REPO_ROOT


class HistoricalBindings(unittest.TestCase):
    def test_exact_authorized_snapshot(self):
        root = REPO_ROOT
        path = "js/blazex_runtime/src/runtime-startup.js"
        raw = subprocess.check_output(["git", "show", f"{history.BASE}:{path}"], cwd=root)
        digest = hashlib.sha256(raw).hexdigest()
        self.assertTrue(history.phase9_historical_binding(root, path, digest))
        self.assertFalse(history.phase9_historical_binding(root, path, "0" * 64))
        self.assertFalse(history.phase9_historical_binding(root, "README.md", digest))

    def test_missing_or_modified_authorization_fails_closed(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.assertFalse(history.phase9_historical_binding(root, "anything", "0" * 64))
            path = root / history.AUTH
            path.parent.mkdir(parents=True)
            path.write_text('{"mutable_historical_paths":["anything"]}')
            self.assertFalse(history.phase9_historical_binding(root, "anything", "0" * 64))


if __name__ == "__main__":
    unittest.main()
