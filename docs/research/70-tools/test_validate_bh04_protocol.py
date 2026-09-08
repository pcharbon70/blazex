"""Negative governance checks, isolated from user source."""
import contextlib
import json
from pathlib import Path
import shutil
import tempfile
import unittest
import validate_bh04_protocol as gate
from bh04_phase3_history import snapshot


class ProtocolGovernanceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.history = snapshot(gate.ROOT)
        cls.source_root = cls.history.__enter__()
        cls.temp = tempfile.TemporaryDirectory(prefix="bh04-protocol-governance-")
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

    def test_empty_gate_list_is_not_completion(self):
        self.assertFalse(gate.complete_gates([]))

    def test_failed_gate_is_not_completion(self):
        gates = [{"name": name, "exit_code": 0} for name in gate.REQUIRED_GATES]
        gates[0]["exit_code"] = 1
        self.assertFalse(gate.complete_gates(gates))

    def test_exact_active_gate_inventory(self):
        gates = [{"name": name, "exit_code": 0} for name in gate.REQUIRED_GATES]
        self.assertTrue(gate.complete_gates(gates))
        gates[0]["name"] = "invented"
        self.assertFalse(gate.complete_gates(gates))

    def test_authority(self):
        self.mutate(gate.AUTH, lambda d: d.update(phase=3), "authority")

    def test_stale_source(self):
        self.mutate(gate.INDEX, lambda d: d["source_bindings"].update({gate.SOURCES[0]: "0" * 64}), "binding changed")

    def test_missing_source(self):
        self.mutate(gate.INDEX, lambda d: d["source_bindings"].pop(gate.SOURCES[0]), "inventory incomplete")

    def test_premature_browser_pass(self):
        self.mutate("integration/bh-04/protocol-inventory-v0.1.0.json",
                    lambda d: d["results"]["browser"].append({"result": "passed"}), "premature behavior")

    def test_support_promotion(self):
        self.mutate("integration/bh-04/protocol-inventory-v0.1.0.json",
                    lambda d: d.update(support_state="supported"), "promotion")

    def test_future_authority(self):
        self.mutate("integration/bh-04/protocol-inventory-v0.1.0.json",
                    lambda d: d.update(phase3_authorized=True), "promotion")

    def test_historical_behavior_rewrite(self):
        path = "js/blazex_runtime/src/root-lifecycle.js"
        with self.change(path, (self.root / path).read_bytes() + b"\n"):
            self.assertIn("historical behavior changed", "\n".join(gate.validate(self.root, completion=False)))

    def test_unindexed_applicator(self):
        with self.change("js/blazex_runtime/src/new-applicator.js", b"export const apply = () => {};"):
            self.assertIn("unindexed", "\n".join(gate.validate(self.root, completion=False)))

    def test_schema_drift(self):
        self.mutate("integration/bh-04/render-transaction.schema.json",
                    lambda d: d["$defs"]["transaction"]["properties"]["schema"].update(enum=["2.0.0"]),
                    "schema drift")

    def test_execution_surface(self):
        path = "js/blazex_runtime/src/render-transaction.js"
        with self.change(path, (self.root / path).read_bytes() + b"\ndocument.createElement('div');\n"):
            self.assertIn("forbidden execution", "\n".join(gate.validate(self.root, completion=False)))


if __name__ == "__main__":
    unittest.main()
