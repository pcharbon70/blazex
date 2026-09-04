#!/usr/bin/env python3
"""Verify a generated BH-01 Phase 4 browser profile before activation."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("profile", type=Path)
    args = parser.parse_args()
    profile = args.profile.resolve()
    errors: list[str] = []
    assets = json.loads((profile / "profile-assets-manifest.json").read_text(encoding="utf-8"))
    runtime = json.loads((profile / "runtime-manifest.json").read_text(encoding="utf-8"))
    deployment = json.loads((profile / "deployment-contract.json").read_text(encoding="utf-8"))
    records = {item["path"]: item for item in assets["artifacts"]}
    for relative, record in records.items():
        path = profile / relative
        if not path.is_file():
            errors.append(f"missing profile artifact: {relative}")
        elif path.stat().st_size != record["bytes"] or sha(path) != record["sha256"]:
            errors.append(f"profile artifact identity drifted: {relative}")
    observed = {
        path.relative_to(profile).as_posix()
        for path in profile.rglob("*")
        if path.is_file() and path.name != "profile-assets-manifest.json"
    }
    if observed != set(records):
        errors.append("profile asset inventory is incomplete or contains unexplained output")
    for artifact in runtime["artifacts"]:
        relative = artifact["path"].removeprefix("./")
        path = profile / relative
        if relative not in records or path.stat().st_size != artifact["bytes"] or sha(path) != artifact["sha256"]:
            errors.append(f"runtime manifest mismatch: {relative}")
        if "://" in artifact["path"] or artifact["path"].startswith("/"):
            errors.append(f"runtime artifact is not same-origin relative: {relative}")
    if records["runtime-manifest.json"]["cache"] != "no-store" or records["index.html"]["cache"] != "no-store":
        errors.append("volatile profile entry points are not classified no-store")
    if assets["source_maps"] != [] or deployment["source_maps"] != "none are emitted for the Phase 4 feasibility loader":
        errors.append("source map policy drifted")
    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        return 1
    print(f"BH-01 Phase 4 generated profile: PASS ({len(records)} governed files)")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
