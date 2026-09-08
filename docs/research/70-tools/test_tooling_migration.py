"""Regression and negative tests for the explicit tooling relocation."""

import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

import tooling_migration as migration
from research_paths import REPO_ROOT, RESEARCH_ROOT, TOOLS_ROOT, tool_path


class ResearchPathsTests(unittest.TestCase):
    def test_roots_do_not_depend_on_working_directory(self):
        self.assertEqual(TOOLS_ROOT.parent, RESEARCH_ROOT)
        self.assertEqual(RESEARCH_ROOT, REPO_ROOT / "docs/research")
        for cwd in (REPO_ROOT, RESEARCH_ROOT, Path(tempfile.gettempdir())):
            result = subprocess.run(
                [sys.executable, str(TOOLS_ROOT / "validate_browser_product_envelope.py")],
                cwd=cwd, capture_output=True, text=True,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_resolver_handles_current_and_original_snapshot_layouts(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            old = root / "docs/research/check.py"
            new = old.parent / "70-tools/check.py"
            old.parent.mkdir(parents=True)
            old.write_text("# historical\n")
            self.assertEqual(tool_path(root, "check.py"), old)
            new.parent.mkdir()
            new.write_text("# current\n")
            self.assertEqual(tool_path(root, "check.py"), new)
            with self.assertRaises(ValueError):
                tool_path(root, "../check.py")


class MigrationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="blazex-tool-migration-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        shutil.copytree(TOOLS_ROOT, self.root / "docs/research/70-tools",
                        ignore=shutil.ignore_patterns("__pycache__"))
        # Tests only read objects/ancestry through the original Git directory.
        gitdir = subprocess.check_output(
            ["git", "-C", str(REPO_ROOT), "rev-parse", "--absolute-git-dir"], text=True
        ).strip()
        (self.root / ".git").write_text("gitdir: " + gitdir + "\n")
        for relative in migration.CALLERS:
            target = self.root / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(REPO_ROOT / relative, target)
        self.data = migration.load_manifest(self.root)
        self.row = next(r for r in self.data["moves"]
                        if r["old_path"].endswith("/validate_archive.py"))

    def test_complete_inventory_and_both_source_hashes(self):
        self.assertEqual(migration.validate_migration(self.root),
                         {"moved_tools": 82, "updated_callers": 4})
        old_bytes = migration.historical_binding_bytes(self.root, self.row["old_path"])
        new_bytes = (self.root / self.row["new_path"]).read_bytes()
        self.assertEqual(migration.sha(old_bytes), self.row["old_sha256"])
        self.assertEqual(migration.sha(new_bytes), self.row["new_sha256"])
        self.assertNotEqual(old_bytes, new_bytes)

    def test_relocated_evidence_reference_is_checked(self):
        self.assertEqual(
            migration.relocated_evidence_path(self.root, self.row["old_path"]),
            self.root / self.row["new_path"],
        )

    def test_rejects_modified_or_missing_tool(self):
        target = self.root / self.row["new_path"]
        target.write_bytes(target.read_bytes() + b"\n# drift\n")
        with self.assertRaisesRegex(ValueError, "differs from migration"):
            migration.historical_binding_bytes(self.root, self.row["old_path"])
        target.unlink()
        with self.assertRaises(ValueError):
            migration.verify_row(self.root, self.row)

    def test_rejects_legacy_shadow(self):
        (self.root / self.row["old_path"]).write_text("# duplicate\n")
        with self.assertRaisesRegex(ValueError, "shadows"):
            migration.verify_row(self.root, self.row)
        with self.assertRaisesRegex(ValueError, "shadows"):
            migration.relocated_evidence_path(self.root, self.row["old_path"])

    def test_rejects_manifest_change_even_when_target_hash_is_rewritten(self):
        self.data["moves"][0]["new_sha256"] = "0" * 64
        (self.root / migration.MANIFEST).write_text(json.dumps(self.data))
        with self.assertRaisesRegex(ValueError, "sealed record"):
            migration.load_manifest(self.root)

    def test_rejects_missing_or_duplicate_inventory(self):
        for mutate in (lambda d: d["moves"].pop(),
                       lambda d: d["moves"].append(d["moves"][0])):
            data = json.loads(json.dumps(self.data))
            mutate(data)
            with patch.object(migration, "load_manifest", return_value=data):
                with self.assertRaisesRegex(ValueError, "inventory"):
                    migration.validate_migration(self.root)

    def test_rejects_widened_caller_exception(self):
        self.assertFalse(migration.is_migrated_caller(self.root, "js/runtime.js"))
        data = json.loads(json.dumps(self.data))
        data["callers"][0]["old_path"] = "js/runtime.js"
        with patch.object(migration, "load_manifest", return_value=data):
            with self.assertRaisesRegex(ValueError, "caller exception"):
                migration.validate_migration(self.root)

    def test_rejects_caller_drift(self):
        path = sorted(migration.CALLERS)[0]
        target = self.root / path
        target.write_bytes(target.read_bytes() + b"\n")
        with self.assertRaisesRegex(ValueError, "differs from migration"):
            migration.is_migrated_caller(self.root, path)

    def test_non_tool_bindings_read_current_bytes_without_exceptions(self):
        relative = "js/runtime.js"
        target = self.root / relative
        target.parent.mkdir()
        target.write_bytes(b"changed implementation")
        self.assertEqual(migration.historical_binding_bytes(self.root, relative),
                         b"changed implementation")

    def test_rejects_wrong_original_hash(self):
        row = dict(self.row, old_sha256="0" * 64)
        with self.assertRaisesRegex(ValueError, "original source changed"):
            migration.verify_row(self.root, row)

    def test_rejects_traversal_and_symlink(self):
        with self.assertRaises(ValueError):
            migration.safe_file(self.root, "../outside.py")
        target = self.root / self.row["new_path"]
        target.unlink()
        target.symlink_to(TOOLS_ROOT / "validate_archive.py")
        with self.assertRaises(ValueError):
            migration.verify_row(self.root, self.row)

    def test_historical_gate_inventory_excludes_new_migration_gate(self):
        names = migration.historical_gate_names(self.root)
        self.assertIn("validate_archive.py", names)
        self.assertNotIn("validate_tooling_migration.py", names)
        self.assertNotIn("validate_bh04_acceptance.py", names)


if __name__ == "__main__":
    unittest.main()
