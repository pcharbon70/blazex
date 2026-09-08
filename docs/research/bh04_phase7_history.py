"""Explicit Phase 7 supersession: reproduce immutable Phase 6 on accepted Git."""
import contextlib
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile

BASE = "e924d1cff826515d9a689091b8873180e39cc55f"
AUTH = "docs/research/assets/bh-04-baseline/blazex-bh-04-phase-07-authorization-v0.1.0.json"
AUTH_SHA256 = "b375a5a175e7d2b0f8ef06700be3b9615496308caf7762a16be974d762e77b4d"

def enabled(root):
    path = Path(root) / AUTH
    if not path.exists():
        return False
    raw = path.read_bytes()
    if hashlib.sha256(raw).hexdigest() != AUTH_SHA256:
        raise ValueError("BH-04 Phase 7 authority is not the exact authorized record")
    return json.loads(raw)["phase"] == 7

@contextlib.contextmanager
def snapshot(root):
    root = Path(root)
    if not enabled(root):
        yield root
        return
    subprocess.run(["git", "-C", str(root), "merge-base", "--is-ancestor", BASE, "HEAD"],
                   check=True, capture_output=True)
    with tempfile.TemporaryDirectory(prefix="bh04-phase6-history-") as directory:
        target = Path(directory)
        env = dict(os.environ)
        env.pop("GIT_WORK_TREE", None)
        env.pop("GIT_DIR", None)
        subprocess.run(["git", "clone", "--shared", "--no-checkout", str(root), str(target)],
                       check=True, capture_output=True, env=env)
        subprocess.run(["git", "-C", str(target), "checkout", "--detach", BASE],
                       check=True, capture_output=True, env=env)
        yield target

def run_phase6(root):
    with snapshot(root) as historical:
        env = dict(os.environ)
        env.pop("GIT_WORK_TREE", None)
        env.pop("GIT_DIR", None)
        result = subprocess.run(
            ["python3", "docs/research/validate_bh04_continuity.py"],
            cwd=historical, env=env)
        if result.returncode:
            raise ValueError("Historical BH-04 Phase 6 gate failed")
    print("BH-04 Phase 6 reproduced on accepted snapshot; current Phase 7 requires validate_bh04_lifecycle.py.")
