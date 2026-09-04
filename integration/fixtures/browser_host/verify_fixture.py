#!/usr/bin/env python3
"""Validate the Phase 4 browser-host fixture and retained manifest."""

from __future__ import annotations

import gzip
import hashlib
import json
import re
from pathlib import Path

HERE = Path(__file__).resolve().parent
SHA = re.compile(r"^[0-9a-f]{64}$")

def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main() -> int:
    contract = json.loads((HERE / "build-contract.json").read_text())
    manifest = json.loads((HERE / "bundle-manifest.json").read_text())
    errors = []
    if contract.get("classification") != "disposable-non-public-fixture" or contract.get("public_api") is not False:
        errors.append("fixture ownership is not disposable/non-public")
    if contract.get("entrypoint") != "Elixir.BlazeX.BH01.BrowserHost.Boot":
        errors.append("browser fixture entrypoint changed")
    if manifest.get("build_contract_sha256") != digest(HERE / "build-contract.json"):
        errors.append("build contract hash drifted")
    for item in manifest.get("artifacts", []):
        path = HERE / item["path"]
        if not path.is_file() or digest(path) != item.get("sha256") or path.stat().st_size != item.get("bytes") or not SHA.fullmatch(item.get("sha256", "")):
            errors.append(f"artifact identity drifted: {item.get('id')}")
    raw = (HERE / "generated/bundle.avm.gz").read_bytes()
    if raw[4:8] != b"\0\0\0\0" or gzip.decompress(raw) != (HERE / "generated/bundle.avm").read_bytes():
        errors.append("gzip output is not deterministic")
    source = (HERE / "lib/blazex/bh01/browser_host.ex").read_text()
    for forbidden in ("Phoenix", "LiveView", "document", "innerHTML"):
        if forbidden in source:
            errors.append(f"browser fixture contains forbidden owner: {forbidden}")
    if errors:
        raise SystemExit("\n".join(f"ERROR: {error}" for error in errors))
    print("BH-01 Phase 4 browser-host fixture: PASS")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
