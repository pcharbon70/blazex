#!/usr/bin/env python3
"""Build the deterministic BH-01 Phase 4 static browser profile."""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import mimetypes
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]

def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    output = args.output.resolve()
    template = json.loads((HERE / "runtime-manifest.template.json").read_text(encoding="utf-8"))
    if output.exists():
        shutil.rmtree(output)
    output.mkdir(parents=True)
    for item in template["artifacts"]:
        source = ROOT / item.pop("source")
        if not source.is_file():
            raise SystemExit(f"missing governed Phase 3 artifact: {source.relative_to(ROOT)}")
        destination = output / item["path"]
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, destination)
        item["bytes"] = destination.stat().st_size
        item["sha256"] = digest(destination)
    for name in ("runtime-frame.html", "runtime-frame.js"):
        shutil.copyfile(HERE / name, output / name)
    (output / "runtime-manifest.json").write_text(json.dumps(template, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    for name in ("index.html", "host.js", "deployment-contract.json"):
        shutil.copyfile(HERE / name, output / name)
    shutil.copytree(ROOT / "js/blazex_runtime/src", output / "js")
    records = []
    for path in sorted(item for item in output.rglob("*") if item.is_file()):
        relative = path.relative_to(output).as_posix()
        mime = mimetypes.guess_type(path.name)[0] or "application/octet-stream"
        if path.suffix == ".avm":
            mime = "application/vnd.atomvm.avm"
        elif path.suffix in (".js", ".mjs"):
            mime = "text/javascript"
        records.append({
            "path": relative,
            "bytes": path.stat().st_size,
            "sha256": digest(path),
            "mime": mime,
            "cache": "no-store" if relative in ("index.html", "runtime-manifest.json") else "immutable",
        })
    profile_manifest = {
        "schema_version": "1.0.0",
        "manifest_id": "BX-BH01-PHASE-04-PROFILE-ASSETS-0.1",
        "artifacts": records,
        "source_maps": [],
        "network_policy": "same-origin declared profile assets only",
    }
    (output / "profile-assets-manifest.json").write_text(json.dumps(profile_manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"BH-01 Phase 4 browser profile: PASS ({len(records)} governed files; {len(template['artifacts'])} runtime artifacts)")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
