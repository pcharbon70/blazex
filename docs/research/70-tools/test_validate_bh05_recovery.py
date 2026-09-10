"""Isolated negative tests of the Phase 10 successor boundary and gate evidence."""
import copy
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from research_paths import REPO_ROOT
from generate_bh05_recovery import BASE, TARGET, PLAN
from validate_bh05_recovery import GATES, DIGESTS, RAW_MARKERS, files, gate_errors, validate


class RecoveryEvidenceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.directory = tempfile.TemporaryDirectory(prefix="bh05-recovery-test-")
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
            elif target.is_file(): target.unlink()

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
        for path in [TARGET, "docs/research/assets/bh-05-baseline/scope-completion-v0.1.0.json"]:
            self.mutate(path, lambda data: data.replace(b"unsupported", b"supported"))

    def test_inherited_kernel_dependencies_and_tools_immutable(self):
        for path in ["packages/blazex_core/lib/blazex/core/authoring.ex", "packages/blazex_ui_tree/mix.exs", "docs/research/70-tools/validate_bh05_roots.py"]:
            self.mutate(path, lambda data: data + b"\n# drift\n")

    def test_missing_changed_fixture_and_private_import(self):
        path = "integration/bh-05/recovery-fixtures.exs"
        self.mutate(path, None)
        self.mutate(path, lambda data: data + b"\nBlazeX.UITree.CompositionPlan.build()\n")

    def test_unknown_surface_and_future_completion(self):
        self.mutate("packages/blazex_core/lib/blazex/component/process.ex", lambda _: b"defmodule Rogue do end\n")
        self.mutate(PLAN + "phase-11-erts-browser-atomvm-and-cross-backend-conformance.md", lambda data: data.replace(b"[ ]", b"[x]", 1))

    def test_inventory_rejects_unsupported_credit(self):
        self.mutate("integration/bh-05/recovery-index-v0.1.0.json", lambda data: data.replace(b'"runtime_parity": false', b'"runtime_parity": true'))

    def test_gate_failure_missing_duplicate_stale_and_digest_tampering(self):
        record = {"phase": 10, "source_hashes": {"fixture": "hash"}, "final_source_hashes": {"fixture": "hash"}, "predecessor_revision": BASE,
                  "results": [{"name": name, "exit_code": 0, "error": None, "command": [name], "stdout": "\n".join(k + " " + v for k, v in {**DIGESTS, **RAW_MARKERS, "RECOVERY_CLEANUP_MS": "1,101", "RECOVERY_RETRY_MS": "100,200,300,400"}.items()) if name == "packages" else ""} for name in GATES]}
        self.assertEqual(gate_errors(record, {"fixture": "hash"}), [])
        self.assertTrue(gate_errors(record, {"fixture": "new"}))
        for change in [lambda r: r["results"].pop(), lambda r: r["results"].append(r["results"][0]),
                       lambda r: r["results"][0].update(exit_code=1), lambda r: r.update(predecessor_revision="bad"),
                       lambda r: r.update(final_source_hashes={}), lambda r: r["results"][0].update(stdout=""),
                       lambda r: r.update(phase=7),
                       lambda r: r["results"][0].update(stdout=r["results"][0]["stdout"].replace("1,101", "1,1001")),
                       lambda r: r["results"][0].update(stdout=r["results"][0]["stdout"].replace("256:coalesced", "256:committed")),
                       lambda r: r["results"][0].update(stdout=r["results"][0]["stdout"].replace("active=0", "active=1"))]:
            mutated = copy.deepcopy(record); change(mutated)
            self.assertTrue(gate_errors(mutated, {"fixture": "hash"}))


if __name__ == "__main__":
    unittest.main()
