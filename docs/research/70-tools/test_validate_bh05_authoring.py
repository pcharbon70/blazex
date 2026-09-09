"""Isolated mutation tests for the Phase 2 successor evidence boundary."""
import copy
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from research_paths import REPO_ROOT
from generate_bh05_authoring import BASE, TARGET, PLAN
from validate_bh05_authoring import GATES, files, gate_errors, validate


class AuthoringEvidenceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.directory = tempfile.TemporaryDirectory(prefix="bh05-authoring-test-")
        cls.root = Path(cls.directory.name) / "repo"
        subprocess.run(["git", "clone", "--quiet", "--shared", "--no-checkout", str(REPO_ROOT), str(cls.root)], check=True)
        subprocess.run(["git", "checkout", "--quiet", BASE], cwd=cls.root, check=True)
        changed = subprocess.check_output(["git", "diff", "--name-only", BASE], cwd=REPO_ROOT, text=True).splitlines()
        old = set(subprocess.check_output(["git", "ls-tree", "-r", "--name-only", BASE], cwd=REPO_ROOT, text=True).splitlines())
        for path in set(changed) | (set(files(REPO_ROOT)) - old):
            source, target = REPO_ROOT / path, cls.root / path
            if source.is_file():
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(source, target)
            elif target.is_file():
                target.unlink()

    @classmethod
    def tearDownClass(cls):
        cls.directory.cleanup()

    def mutate(self, path, transform):
        target = self.root / path
        before = target.read_bytes() if target.exists() else None
        try:
            if transform is None: target.unlink()
            else:
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(transform(before))
            self.assertTrue(validate(self.root))
        finally:
            if before is None: target.unlink(missing_ok=True)
            else: target.write_bytes(before)

    def test_valid_candidate(self):
        self.assertEqual(validate(self.root), [])

    def test_authority_and_inherited_evidence(self):
        for path in [TARGET, "docs/research/assets/bh-05-baseline/phase-01-completion-v0.1.0.json"]:
            self.mutate(path, lambda data: data.replace(b"unsupported", b"supported"))

    def test_inherited_kernel_and_dependencies_are_immutable(self):
        for path in ["packages/blazex_core/lib/blazex/core/evaluator.ex", "packages/blazex_core/mix.exs", "docs/research/70-tools/validate_bh05_activation.py"]:
            self.mutate(path, lambda data: data + b"\n# drift\n")

    def test_missing_or_changed_fixture(self):
        self.mutate("integration/bh-05/authoring-fixtures.exs", None)
        self.mutate("integration/bh-05/authoring-fixtures.exs", lambda data: data + b"\n# drift\n")

    def test_unknown_surface_and_future_completion(self):
        self.mutate("packages/blazex_core/lib/blazex/component/process.ex", lambda _: b"defmodule Rogue do end\n")
        self.mutate(PLAN + "phase-03-prop-slot-and-host-boundary-contracts.md", lambda data: data.replace(b"[ ]", b"[x]", 1))

    def test_inventory_rejects_runtime_credit(self):
        self.mutate("integration/bh-05/authoring-index-v0.1.0.json", lambda data: data.replace(b'"runtime_execution": false', b'"runtime_execution": true'))

    def test_gate_failure_missing_duplicate_and_source_tampering(self):
        record = {"source_hashes": {"fixture": "hash"}, "final_source_hashes": {"fixture": "hash"}, "predecessor_revision": BASE,
                  "results": [{"name": name, "exit_code": 0, "error": None, "command": [name]} for name in GATES]}
        self.assertEqual(gate_errors(record, {"fixture": "hash"}), [])
        self.assertTrue(gate_errors(record, {"fixture": "new"}))
        for change in [lambda r: r["results"].pop(), lambda r: r["results"].append(r["results"][0]),
                       lambda r: r["results"][0].update(exit_code=1), lambda r: r.update(predecessor_revision="bad"),
                       lambda r: r.update(final_source_hashes={})]:
            mutated = copy.deepcopy(record)
            change(mutated)
            self.assertTrue(gate_errors(mutated, {"fixture": "hash"}))


if __name__ == "__main__":
    unittest.main()
