"""Explicit Phase 9 supersession: reproduce immutable Phase 7 on accepted Git."""
import contextlib
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile

BASE = "644055f646392e9daabb396a636249433f09a991"
AUTH = "docs/research/assets/bh-04-baseline/blazex-bh-04-phase-09-authorization-v0.1.0.json"
AUTH_SHA256 = "c5af1ffa57a10e1ec3003a018a38aab8d1efe4d212a9c2ae00b1f62463abcbc3"

def enabled(root):
    path = Path(root) / AUTH
    if not path.exists():
        return False
    raw = path.read_bytes()
    if hashlib.sha256(raw).hexdigest() != AUTH_SHA256:
        raise ValueError("BH-04 Phase 9 authority is not the exact authorized record")
    return json.loads(raw)["phase"] == 9

@contextlib.contextmanager
def snapshot(root):
    root = Path(root)
    if not enabled(root):
        yield root
        return
    subprocess.run(["git", "-C", str(root), "merge-base", "--is-ancestor", BASE, "HEAD"],
                   check=True, capture_output=True)
    with tempfile.TemporaryDirectory(prefix="bh04-phase7-history-") as directory:
        target = Path(directory)
        env = dict(os.environ)
        env.pop("GIT_WORK_TREE", None)
        env.pop("GIT_DIR", None)
        subprocess.run(["git", "clone", "--shared", "--no-checkout", str(root), str(target)],
                       check=True, capture_output=True, env=env)
        subprocess.run(["git", "-C", str(target), "checkout", "--detach", BASE],
                       check=True, capture_output=True, env=env)
        yield target

def run_phase7(root):
    with snapshot(root) as historical:
        env = dict(os.environ)
        env.pop("GIT_WORK_TREE", None)
        env.pop("GIT_DIR", None)
        result = subprocess.run(
            ["python3", "docs/research/validate_bh04_lifecycle.py"],
            cwd=historical, env=env)
        if result.returncode:
            raise ValueError("Historical BH-04 Phase 7 gate failed")
    print("BH-04 Phase 7 reproduced on accepted snapshot; current Phase 9 requires validate_bh04_conformance.py.")
