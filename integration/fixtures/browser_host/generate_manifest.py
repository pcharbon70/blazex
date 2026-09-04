#!/usr/bin/env python3
"""Generate the retained identity for the ignored current browser AVM."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent

def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--generated", type=Path, required=True)
    parser.add_argument("--output", type=Path, default=HERE / "bundle-manifest.json")
    args = parser.parse_args()
    generated = args.generated.resolve()
    records = []
    for name, kind, mime, encoding in (
        ("bundle.avm", "avm", "application/vnd.atomvm.avm", None),
        ("bundle.avm.gz", "avm-gzip", "application/vnd.atomvm.avm", "gzip"),
        ("module-inventory.json", "module-inventory", "application/json", None),
    ):
        path = generated / name
        records.append({"id": f"BX-BH01-BROWSER-HOST-{kind.upper()}", "kind": kind, "path": f"generated/{name}", "sha256": sha(path), "bytes": path.stat().st_size, "mime": mime, "content_encoding": encoding})
    manifest = {
      "schema_version": "1.0.0",
      "manifest_id": "BX-BH01-BROWSER-HOST-BUNDLE-MANIFEST-0.1",
      "status": "observed-packaged",
      "build_contract_sha256": sha(HERE / "build-contract.json"),
      "artifacts": records,
      "source_inputs": [
        {"path": str(path.relative_to(HERE)), "sha256": sha(path)}
        for path in sorted([
          HERE / "mix.exs",
          HERE / "mix.lock",
          HERE / "config/config.exs",
          HERE / "lib/blazex/bh01/browser_host.ex",
          HERE / "lib/blazex/bh01/browser_host/protocol.ex",
          HERE / "lib/blazex/bh01/local_behavior.ex",
          HERE / "lib/mix/tasks/bh01.browser_package.ex",
        ])
      ],
      "normalization": ["fixed boot module identity", "sorted unique BEAM basenames", "zero gzip MTIME"],
      "limitations": ["Phase 5 behavior is a disposable fixture, not a public component contract", "unpruned AVM size is not a passed budget"]
    }
    args.output.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
