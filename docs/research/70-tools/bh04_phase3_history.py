"""Explicit Phase 3 supersession: reproduce immutable Phase 2 on accepted Git."""
import contextlib
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile

BASE = "980836b8bc34383bde2e1f24a5a9e7d65908d347"
AUTH = "docs/research/assets/bh-04-baseline/blazex-bh-04-phase-03-authorization-v0.1.0.json"
AUTH_SHA256 = "498ec5b5d40f538d2665d3ee1dd987056724887388d05a4dd764d0a4e65b090b"

def enabled(root):
    path = Path(root) / AUTH
    if not path.exists():
        return False
    raw = path.read_bytes()
    if hashlib.sha256(raw).hexdigest() != AUTH_SHA256:
        raise ValueError("BH-04 Phase 3 authority is not the exact authorized record")
    return json.loads(raw)["phase"] == 3

@contextlib.contextmanager
def snapshot(root):
    root = Path(root)
    if not enabled(root):
        yield root
        return
    subprocess.run(["git", "-C", str(root), "merge-base", "--is-ancestor", BASE, "HEAD"],
                   check=True, capture_output=True)
    with tempfile.TemporaryDirectory(prefix="bh04-phase2-history-") as directory:
        target = Path(directory)
        env = dict(os.environ)
        env.pop("GIT_WORK_TREE", None)
        env.pop("GIT_DIR", None)
        subprocess.run(["git", "clone", "--shared", "--no-checkout", str(root), str(target)],
                       check=True, capture_output=True, env=env)
        subprocess.run(["git", "-C", str(target), "checkout", "--detach", BASE],
                       check=True, capture_output=True, env=env)
        yield target

def run_phase2(root):
    with snapshot(root) as historical:
        env = dict(os.environ)
        env.pop("GIT_WORK_TREE", None)
        env.pop("GIT_DIR", None)
        result = subprocess.run(
            ["python3", "docs/research/validate_bh04_protocol.py"],
            cwd=historical, env=env)
        if result.returncode:
            raise ValueError("Historical BH-04 Phase 2 gate failed")
    print("BH-04 Phase 2 reproduced on accepted snapshot; current Phase 3 requires validate_bh04_reconciliation.py.")
