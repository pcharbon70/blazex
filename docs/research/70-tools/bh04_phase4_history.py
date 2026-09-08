"""Explicit Phase 4 supersession: reproduce immutable Phase 3 on accepted Git."""
import contextlib
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile

BASE = "781e6c4ff870ad89ab803d84d488a2271c9e521c"
AUTH = "docs/research/assets/bh-04-baseline/blazex-bh-04-phase-04-authorization-v0.1.0.json"
AUTH_SHA256 = "9cc176df06c8bc8db9168f12737fdf7e3c637f1b7a2aeb10556ba271135e3b0b"

def enabled(root):
    path = Path(root) / AUTH
    if not path.exists():
        return False
    raw = path.read_bytes()
    if hashlib.sha256(raw).hexdigest() != AUTH_SHA256:
        raise ValueError("BH-04 Phase 4 authority is not the exact authorized record")
    return json.loads(raw)["phase"] == 4

@contextlib.contextmanager
def snapshot(root):
    root = Path(root)
    if not enabled(root):
        yield root
        return
    subprocess.run(["git", "-C", str(root), "merge-base", "--is-ancestor", BASE, "HEAD"],
                   check=True, capture_output=True)
    with tempfile.TemporaryDirectory(prefix="bh04-phase3-history-") as directory:
        target = Path(directory)
        env = dict(os.environ)
        env.pop("GIT_WORK_TREE", None)
        env.pop("GIT_DIR", None)
        subprocess.run(["git", "clone", "--shared", "--no-checkout", str(root), str(target)],
                       check=True, capture_output=True, env=env)
        subprocess.run(["git", "-C", str(target), "checkout", "--detach", BASE],
                       check=True, capture_output=True, env=env)
        yield target

def run_phase3(root):
    with snapshot(root) as historical:
        env = dict(os.environ)
        env.pop("GIT_WORK_TREE", None)
        env.pop("GIT_DIR", None)
        result = subprocess.run(
            ["python3", "docs/research/validate_bh04_reconciliation.py"],
            cwd=historical, env=env)
        if result.returncode:
            raise ValueError("Historical BH-04 Phase 3 gate failed")
    print("BH-04 Phase 3 reproduced on accepted snapshot; current Phase 4 requires validate_bh04_dom_application.py.")
