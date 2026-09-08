"""Phase 10 reproduces the immutable Phase 9 gate on its accepted merge."""
import contextlib
import hashlib
import os
from pathlib import Path
import subprocess
import tempfile

BASE = "23176db2ff608084e9f779943eadcd0eed1926af"
AUTH = "docs/research/assets/bh-04-baseline/blazex-bh-04-phase-10-authorization-v0.1.0.json"
AUTH_SHA256 = "69057e3eb97b98437a391cb3f6e403502a1f53b27e32f52d84c162f4ecd953ec"

def enabled(root):
    path = Path(root) / AUTH
    if not path.exists():
        return False
    if hashlib.sha256(path.read_bytes()).hexdigest() != AUTH_SHA256:
        raise ValueError("Phase 10 authority changed")
    return True

@contextlib.contextmanager
def snapshot(root):
    subprocess.run(["git", "merge-base", "--is-ancestor", BASE, "HEAD"], cwd=root, check=True, capture_output=True)
    env = dict(os.environ)
    env.pop("GIT_DIR", None)
    env.pop("GIT_WORK_TREE", None)
    with tempfile.TemporaryDirectory(prefix="bh04-phase9-history-") as directory:
        subprocess.run(["git", "clone", "--shared", "--no-checkout", str(root), directory], check=True, capture_output=True, env=env)
        subprocess.run(["git", "checkout", "--detach", BASE], cwd=directory, check=True, capture_output=True, env=env)
        yield Path(directory)

def run_phase9(root):
    if not enabled(root):
        raise ValueError("Missing exact Phase 10 authority")
    with snapshot(root) as historical:
        subprocess.run(["python3", "docs/research/validate_bh04_conformance.py"], cwd=historical, check=True)
    print("Phase 9 reproduced on accepted merge; current Phase 10 requires validate_bh04_acceptance.py.")
