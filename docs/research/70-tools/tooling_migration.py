"""Explicit relocation bridge for immutable, pre-70-tools source bindings.

Old evidence is not rewritten. A legacy binding may be read through a moved
tool only when the original Git blob and the exact relocated bytes both match
the sealed migration. All other source reads remain strict current-file reads.
This does not grant milestone acceptance or bypass non-tool source changes.
"""

import hashlib
import json
from pathlib import Path, PurePosixPath
import subprocess

from research_paths import REPO_ROOT

BASE = "f6f338265675e14628bc221e581df51aef4d477b"
MANIFEST = "docs/research/70-tools/migration-v1.json"
# Sealed after the move and tests; changing the inventory requires review.
MANIFEST_SHA256 = "968bd6c30826aae811da2200d6f1b4565303139de48f0ad8eacbdff83c635a12"
CALLERS = {
    "profiles/browser_phoenix/toolchain/verify_phase3.py",
    "profiles/browser_phoenix/toolchain/verify_phase4.py",
    "profiles/browser_phoenix/toolchain/verify_phase5.py",
    "integration/bh-04/acceptance-gates.mjs",
}


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def safe_file(root, relative):
    root = Path(root).resolve()
    parts = PurePosixPath(relative)
    if parts.is_absolute() or ".." in parts.parts or str(parts) != relative:
        raise ValueError("noncanonical migration path: " + relative)
    path = root / relative
    if path.is_symlink() or not path.resolve().is_relative_to(root):
        raise ValueError("migration path escapes repository: " + relative)
    return path


def load_manifest(root=REPO_ROOT):
    raw = safe_file(root, MANIFEST).read_bytes()
    if sha(raw) != MANIFEST_SHA256:
        raise ValueError("tooling migration manifest is not the sealed record")
    data = json.loads(raw)
    if data["schema_version"] != "1.0.0" or data["base_revision"] != BASE:
        raise ValueError("unsupported tooling migration")
    return data


def original_blob(root, row):
    raw = subprocess.check_output(
        ["git", "-C", str(root), "show", BASE + ":" + row["old_path"]],
        stderr=subprocess.PIPE,
    )
    if sha(raw) != row["old_sha256"]:
        raise ValueError("migration original source changed: " + row["old_path"])
    return raw


def verify_row(root, row):
    old = safe_file(root, row["old_path"])
    new = safe_file(root, row["new_path"])
    if old != new and old.exists():
        raise ValueError("legacy tool shadows relocated tool: " + row["old_path"])
    if not new.is_file() or sha(new.read_bytes()) != row["new_sha256"]:
        raise ValueError("relocated source differs from migration: " + row["new_path"])
    return original_blob(root, row)


def historical_binding_bytes(root, relative):
    """Validate both sides of an explicit move; never exempt arbitrary drift."""
    data = load_manifest(root)
    for row in data["moves"] + data["callers"]:
        if row["old_path"] == relative:
            return verify_row(root, row)
    return safe_file(root, relative).read_bytes()


def relocated_evidence_path(root, relative):
    """Resolve an old implementation reference without rewriting its record."""
    path = Path(root) / relative
    legacy = PurePosixPath(relative)
    if (legacy.parent == PurePosixPath("docs/research") and legacy.suffix == ".py"
            and (Path(root) / MANIFEST).is_file()):
        for row in load_manifest(root)["moves"]:
            if row["old_path"] == relative:
                verify_row(root, row)
                return safe_file(root, row["new_path"])
    return path


def is_migrated_caller(root, relative):
    if relative not in CALLERS:
        return False
    row = next(r for r in load_manifest(root)["callers"] if r["old_path"] == relative)
    verify_row(root, row)
    return True


def historical_gate_names(root=REPO_ROOT):
    """Original inventory for a historical gate log, not current test discovery."""
    return {
        Path(row["old_path"]).name
        for row in load_manifest(root)["moves"]
        if Path(row["old_path"]).name.startswith(("validate_", "generate_"))
        and Path(row["old_path"]).name != "validate_bh04_acceptance.py"
    }


def validate_migration(root=REPO_ROOT):
    root = Path(root)
    data = load_manifest(root)
    subprocess.run(
        ["git", "-C", str(root), "merge-base", "--is-ancestor", BASE, "HEAD"],
        check=True, capture_output=True,
    )
    original_names = subprocess.check_output(
        ["git", "-C", str(root), "ls-tree", "--name-only", BASE + ":docs/research"],
        text=True,
    ).splitlines()
    expected = {"docs/research/" + name for name in original_names if name.endswith(".py")}
    moves = data["moves"]
    if len(moves) != len(expected) or {r["old_path"] for r in moves} != expected:
        raise ValueError("incomplete or duplicated migration inventory")
    for row in moves:
        if row["new_path"] != "docs/research/70-tools/" + Path(row["old_path"]).name:
            raise ValueError("unexpected relocation target")
    callers = data["callers"]
    if len(callers) != len(CALLERS) or {r["old_path"] for r in callers} != CALLERS:
        raise ValueError("unexpected caller exception inventory")
    if any(r["old_path"] != r["new_path"] for r in callers):
        raise ValueError("caller relocation is not authorized")
    for row in moves + callers:
        verify_row(root, row)
    for row in data["additional_tools"]:
        path = safe_file(root, row["path"])
        if path.parent != root.resolve() / "docs/research/70-tools":
            raise ValueError("unexpected added-tool path")
        if sha(path.read_bytes()) != row["sha256"]:
            raise ValueError("added tooling changed: " + row["path"])
    if list((root / "docs/research").glob("*.py")):
        raise ValueError("Python scripts must live in 70-tools")
    return {"moved_tools": len(moves), "updated_callers": len(callers)}
