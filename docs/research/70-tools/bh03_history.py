"""Narrow Phase 9 historical-source binding; never validates current implementation."""
import hashlib
import json
from pathlib import Path
import subprocess
from tooling_migration import relocated_evidence_path

BASE = "8db4928b9b5e8eb869617ab4bf882df3e1cde6f1"
AUTH = "docs/research/assets/bh-03-baseline/blazex-bh-03-phase-09-authorization-v0.1.0.json"
AUTH_SHA256 = "b6d598854429c2a8431b0ffb8b06540464bb68e1afde972eec1b127430c31135"


def phase9_historical_binding(repo_root, relative, expected):
    root = Path(repo_root)
    try:
        raw = (root / AUTH).read_bytes()
        if hashlib.sha256(raw).hexdigest() != AUTH_SHA256:
            return False
        auth = json.loads(raw)
        if auth["base_revision"] != BASE or relative not in auth["mutable_historical_paths"]:
            return False
        if not relocated_evidence_path(root, relative).is_file():
            return False
        blob = subprocess.check_output(["git", "show", f"{BASE}:{relative}"], cwd=root, stderr=subprocess.DEVNULL)
        return hashlib.sha256(blob).hexdigest() == expected
    except (OSError, ValueError, KeyError, subprocess.CalledProcessError):
        return False
