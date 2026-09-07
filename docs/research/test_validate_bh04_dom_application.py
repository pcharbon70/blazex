"""Negative Phase 4 governance tests; never modify the user's source tree."""
import contextlib
import json
from pathlib import Path
import shutil
import tempfile
import unittest
import validate_bh04_dom_application as gate

class DOMApplicationGovernanceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory(prefix="bh04-dom-governance-")
        cls.root = Path(cls.temp.name)
        for name in gate.git(gate.ROOT, "ls-files", "--cached", "--others", "--exclude-standard").decode().splitlines():
            source = gate.ROOT / name
            if source.is_file():
                target = cls.root / name
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(source, target)
        directory = gate.git(gate.ROOT, "rev-parse", "--absolute-git-dir").decode().strip()
        (cls.root / ".git").write_text("gitdir: " + directory + "\n")
    @classmethod
    def tearDownClass(cls):
        cls.temp.cleanup()
    @contextlib.contextmanager
    def change(self, name, content):
        path = self.root / name
        old = path.read_bytes() if path.exists() else None
        path.parent.mkdir(parents=True, exist_ok=True)
        try:
            path.write_bytes(content)
            yield
        finally:
            if old is None:
                path.unlink()
            else:
                path.write_bytes(old)
    def mutate(self, path, mutate, expected, completion=False):
        value = gate.read(self.root, path); mutate(value)
        with self.change(path, json.dumps(value).encode()):
            self.assertIn(expected, "\n".join(gate.validate(self.root, completion=completion)))
    def test_candidate(self):
        self.assertEqual([], gate.validate(self.root, completion=False))
    def test_authority(self):
        self.mutate(gate.AUTH, lambda d: d.update(phase=5), "authority")
    def test_index_inventory(self):
        self.mutate(gate.INDEX, lambda d: d["source_bindings"].pop(gate.SOURCES[0]), "inventory incomplete")
    def test_source_hash(self):
        self.mutate(gate.INDEX, lambda d: d["source_bindings"].update({gate.SOURCES[0]: "0" * 64}), "source binding changed")
    def test_extra_behavior(self):
        with self.change("js/blazex_runtime/src/unapproved.js", b"export const x = true;\n"):
            self.assertIn("unindexed executable", "\n".join(gate.validate(self.root, completion=False)))
    def test_historical_source(self):
        path = "js/blazex_runtime/src/root-lifecycle.js"
        with self.change(path, (self.root / path).read_bytes() + b"// mutation\n"):
            self.assertIn("inherited source changed", "\n".join(gate.validate(self.root, completion=False)))
    def test_missing_browser(self):
        self.mutate(gate.BROWSERS, lambda d: d["results"].pop(), "matrix incomplete")
    def test_browser_failure(self):
        self.mutate(gate.BROWSERS, lambda d: d["results"][0].update(result="failed"), "result/support invalid")
    def test_stale_pass(self):
        def mutate(d):
            next(t for t in d["results"][0]["traces"] if t["name"] == "random-delayed")["state"] = "committed"
        self.mutate(gate.BROWSERS, mutate, "stale rejection evidence incomplete")
    def test_rollback_omission(self):
        self.mutate(gate.BROWSERS, lambda d: d["results"][0]["traces"].pop(1), "atomic rollback evidence incomplete")
    def test_queue_overflow(self):
        self.mutate(gate.BROWSERS, lambda d: d["results"][0]["counters"].update(max_queue=65), "counters incomplete")
    def test_gate_inventory(self):
        gates = [{"name": name, "exit_code": 0} for name in gate.REQUIRED_GATES]
        self.assertTrue(gate.complete_gates(gates)); self.assertFalse(gate.complete_gates(gates[:-1]))
        gates[0]["exit_code"] = 1; self.assertFalse(gate.complete_gates(gates))

if __name__ == "__main__":
    unittest.main()
