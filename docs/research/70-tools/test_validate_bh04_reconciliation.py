"""Negative governance checks, isolated from user source."""
import contextlib
import json
from pathlib import Path
import shutil
import tempfile
import unittest
import validate_bh04_reconciliation as gate
from bh04_phase4_history import snapshot


class ReconciliationGovernanceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.history = snapshot(gate.ROOT)
        cls.source_root = cls.history.__enter__()
        cls.temp = tempfile.TemporaryDirectory(prefix="bh04-reconciliation-governance-")
        cls.root = Path(cls.temp.name)
        for name in gate.git(cls.source_root, "ls-files", "--cached", "--others", "--exclude-standard").decode().splitlines():
            source = cls.source_root / name
            if source.is_file():
                target = cls.root / name
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(source, target)
        directory = gate.git(cls.source_root, "rev-parse", "--absolute-git-dir").decode().strip()
        (cls.root / ".git").write_text("gitdir: " + directory + "\n")

    @classmethod
    def tearDownClass(cls):
        cls.temp.cleanup()
        cls.history.__exit__(None, None, None)

    @contextlib.contextmanager
    def change(self, path, content):
        path = self.root / path
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

    def mutate(self, path, mutate, expected):
        value = gate.read(self.root, path)
        mutate(value)
        with self.change(path, json.dumps(value).encode()):
            self.assertIn(expected, "\n".join(gate.validate(self.root, completion=False)))

    def test_candidate(self):
        self.assertEqual([], gate.validate(self.root, completion=False))

    def test_gate_inventory(self):
        gates = [{"name": name, "exit_code": 0} for name in gate.REQUIRED_GATES]
        self.assertTrue(gate.complete_gates(gates))
        self.assertFalse(gate.complete_gates([]))
        self.assertFalse(gate.complete_gates(gates[:-1]))
        gates[0]["exit_code"] = 1
        self.assertFalse(gate.complete_gates(gates))

    def test_authority(self):
        self.mutate(gate.AUTH, lambda d: d.update(phase=4), "authority")

    def test_source_hash(self):
        self.mutate(gate.INDEX, lambda d: d["source_bindings"].update({gate.SOURCES[0]: "0" * 64}), "source binding changed")

    def test_source_omission(self):
        self.mutate(gate.INDEX, lambda d: d["source_bindings"].pop(gate.SOURCES[0]), "inventory incomplete")

    def test_schema_drift(self):
        self.mutate("integration/bh-04/render-transaction-v2.schema.json",
                    lambda d: d["$defs"]["transaction"]["properties"]["schema"].update(enum=["3.0.0"]),
                    "schema drift")

    def test_unindexed_behavior(self):
        with self.change("js/blazex_runtime/src/unauthorized.js", b"export const x = true;\n"):
            self.assertIn("unindexed", "\n".join(gate.validate(self.root, completion=False)))

    def test_historical_rewrite(self):
        path = "packages/blazex_renderer_dom/lib/blazex/renderer/dom.ex"
        with self.change(path, (self.root / path).read_bytes() + b"\n"):
            self.assertIn("historical source changed", "\n".join(gate.validate(self.root, completion=False)))

    def test_protocol_v1_rewrite(self):
        path = "js/blazex_runtime/src/render-transaction.js"
        with self.change(path, (self.root / path).read_bytes() + b"\n"):
            self.assertIn("historical Phase 2 source changed", "\n".join(gate.validate(self.root, completion=False)))

    def test_host_execution(self):
        path = "js/blazex_runtime/src/render-transaction-v2.js"
        with self.change(path, (self.root / path).read_bytes() + b"\ndocument.createElement('div');\n"):
            self.assertIn("forbidden host", "\n".join(gate.validate(self.root, completion=False)))

    def test_fixture_omission(self):
        with self.change("integration/bh-04/reconciliation-fixtures-v0.1.0.txt", b""):
            self.assertIn("fixture coverage", "\n".join(gate.validate(self.root, completion=False)))

if __name__ == "__main__":
    unittest.main()
