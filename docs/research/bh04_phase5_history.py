"""Explicit Phase 5 supersession: reproduce immutable Phase 4 on accepted Git."""
import contextlib
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile

BASE = "f00a9352beb4bc103e8c5ca4e7fc12099f9223fe"
AUTH = "docs/research/assets/bh-04-baseline/blazex-bh-04-phase-05-authorization-v0.1.0.json"
AUTH_SHA256 = "acf37316c80a944fe7145af58e00363382f2b6291cb706b9c7d02d816be913f7"

def enabled(root):
    path = Path(root) / AUTH
    if not path.exists():
        return False
    raw = path.read_bytes()
    if hashlib.sha256(raw).hexdigest() != AUTH_SHA256:
        raise ValueError("BH-04 Phase 5 authority is not the exact authorized record")
    return json.loads(raw)["phase"] == 5

@contextlib.contextmanager
def snapshot(root):
    root = Path(root)
    if not enabled(root):
        yield root
        return
    subprocess.run(["git", "-C", str(root), "merge-base", "--is-ancestor", BASE, "HEAD"],
                   check=True, capture_output=True)
    with tempfile.TemporaryDirectory(prefix="bh04-phase4-history-") as directory:
        target = Path(directory)
        env = dict(os.environ)
        env.pop("GIT_WORK_TREE", None)
        env.pop("GIT_DIR", None)
        subprocess.run(["git", "clone", "--shared", "--no-checkout", str(root), str(target)],
                       check=True, capture_output=True, env=env)
        subprocess.run(["git", "-C", str(target), "checkout", "--detach", BASE],
                       check=True, capture_output=True, env=env)
        yield target

def run_phase4(root):
    with snapshot(root) as historical:
        env = dict(os.environ)
        env.pop("GIT_WORK_TREE", None)
        env.pop("GIT_DIR", None)
        result = subprocess.run(
            ["python3", "docs/research/validate_bh04_dom_application.py"],
            cwd=historical, env=env)
        if result.returncode:
            raise ValueError("Historical BH-04 Phase 4 gate failed")
    print("BH-04 Phase 4 reproduced on accepted snapshot; current Phase 5 requires validate_bh04_interactions.py.")
