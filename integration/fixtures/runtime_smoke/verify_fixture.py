#!/usr/bin/env python3
"""Validate the BH-01 disposable runtime-smoke source and generated bundles."""

from __future__ import annotations

import argparse
import gzip
import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any


HERE = Path(__file__).resolve().parent
SHA256 = re.compile(r"^[0-9a-f]{64}$")
EXPECTED_SOURCES = {
    "lib/blazex/bh01/runtime_smoke.ex",
    "lib/blazex/bh01/runtime_smoke/worker.ex",
    "lib/mix/tasks/bh01.package.ex",
}
FORBIDDEN_SOURCE = (
    "Code.eval",
    "Code.require_file",
    "File.read",
    "File.write",
    "System.get_env",
    "Phoenix",
    "LiveView",
    "BlazeX.Component",
)


def load(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as stream:
        return json.load(stream)


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def validate(
    contract: dict[str, Any],
    generated: Path | None = None,
    manifest: dict[str, Any] | None = None,
) -> list[str]:
    errors: list[str] = []
    if contract.get("classification") != "disposable-non-public-fixture" or contract.get("public_api") is not False:
        errors.append("fixture is not explicitly disposable and non-public")
    if {item.get("id") for item in contract.get("modes", [])} != {"debug", "release"}:
        errors.append("debug and release bundle modes are required")
    if contract.get("resources") != [] or contract.get("startup_arguments") != []:
        errors.append("fixture resources or startup arguments are not empty")
    if contract.get("trace_fields") != ["generation", "scenario", "process", "sequence", "result", "error", "cleanup"]:
        errors.append("structured trace fields differ")

    source_paths = {
        path.relative_to(HERE).as_posix()
        for path in (HERE / "lib").rglob("*.ex")
    }
    if source_paths != EXPECTED_SOURCES:
        errors.append("fixture contains an undeclared source module")
    for relative in sorted(source_paths):
        text = (HERE / relative).read_text(encoding="utf-8")
        for token in FORBIDDEN_SOURCE:
            if token in text and relative != "lib/mix/tasks/bh01.package.ex":
                errors.append(f"runtime fixture source contains forbidden token {token}")

    if manifest is not None:
        if manifest.get("status") != "observed-packaged":
            errors.append("fixture bundle manifest is not an observed package result")
        if manifest.get("build_contract_sha256") != digest(HERE / "build-contract.json"):
            errors.append("fixture build contract hash drifted")
        modes = {item.get("mode") for item in manifest.get("module_inventories", [])}
        if modes != {"debug", "release"}:
            errors.append("fixture manifest module inventories are incomplete")
        artifact_kinds = {(item.get("mode"), item.get("kind")) for item in manifest.get("artifacts", [])}
        expected_artifacts = {(mode, kind) for mode in ("debug", "release") for kind in ("avm", "avm-gzip", "module-inventory")}
        if artifact_kinds != expected_artifacts:
            errors.append("fixture manifest artifact accounting is incomplete")
        for item in manifest.get("artifacts", []):
            if not SHA256.fullmatch(item.get("sha256", "")) or not item.get("bytes"):
                errors.append(f"fixture artifact {item.get('artifact_id')} lacks identity")
        if manifest.get("reviewed_nondeterministic_fields") != []:
            errors.append("fixture manifest accepts unexplained nondeterministic fields")

    if generated is not None:
        inventories: dict[str, dict[str, Any]] = {}
        for mode in ("debug", "release"):
            mode_dir = generated / mode
            bundle = mode_dir / "bundle.avm"
            compressed = mode_dir / "bundle.avm.gz"
            inventory_path = mode_dir / "module-inventory.json"
            if not all(path.is_file() for path in (bundle, compressed, inventory_path)):
                errors.append(f"{mode} generated output is incomplete")
                continue
            inventory = load(inventory_path)
            inventories[mode] = inventory
            modules = inventory.get("modules", [])
            if len(modules) != len(set(modules)) or inventory.get("start_module") != "BlazeX.BH01.RuntimeSmoke.Boot":
                errors.append(f"{mode} inventory is duplicated or has the wrong entrypoint")
            if any("Mix.Tasks.Bh01" in module for module in modules):
                errors.append(f"{mode} bundle includes its host-only packaging task")
            raw_gzip = compressed.read_bytes()
            if len(raw_gzip) < 10 or raw_gzip[4:8] != b"\x00\x00\x00\x00":
                errors.append(f"{mode} gzip header has a non-zero timestamp")
            elif gzip.decompress(raw_gzip) != bundle.read_bytes():
                errors.append(f"{mode} gzip content differs from the AVM bundle")
            if not SHA256.fullmatch(digest(bundle)):
                errors.append(f"{mode} bundle lacks a valid digest")
        if set(inventories) == {"debug", "release"}:
            if inventories["debug"].get("modules") != inventories["release"].get("modules"):
                errors.append("debug and release module inventories differ")
            if inventories["debug"].get("include_lines") is not True or inventories["release"].get("include_lines") is not False:
                errors.append("bundle line policies differ from the contract")
        if manifest is not None:
            for item in manifest.get("artifacts", []):
                path = HERE / item["path"]
                if not path.is_file() or digest(path) != item["sha256"] or path.stat().st_size != item["bytes"]:
                    errors.append(f"fixture artifact {item.get('artifact_id')} differs from its manifest")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--generated", type=Path)
    parser.add_argument("--manifest", type=Path, default=HERE / "bundle-manifest.json")
    args = parser.parse_args()
    manifest = load(args.manifest) if args.manifest.exists() else None
    errors = validate(load(HERE / "build-contract.json"), args.generated, manifest)
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print("BH-01 Phase 3 runtime smoke fixture: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
