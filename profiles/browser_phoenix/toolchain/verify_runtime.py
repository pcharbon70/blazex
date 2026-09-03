#!/usr/bin/env python3
"""Validate the immutable AtomVM/Popcorn qualification contract."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any


HERE = Path(__file__).resolve().parent
SHA256 = re.compile(r"^[0-9a-f]{64}$")
COMMIT = re.compile(r"^[0-9a-f]{40}$")


def load(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as stream:
        return json.load(stream)


def validate(runtime: dict[str, Any], provenance: dict[str, Any], environment: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    if runtime.get("candidate_status") != "pinned_unbuilt":
        errors.append("runtime must remain pinned_unbuilt in Phase 2")

    source_ids = set()
    for source in runtime.get("sources", []):
        source_id = source.get("id", "<missing>")
        source_ids.add(source_id)
        if not SHA256.fullmatch(source.get("sha256", "")):
            errors.append(f"source {source_id} has no valid SHA-256")
        if not source.get("origin", "").startswith("https://"):
            errors.append(f"source {source_id} does not use HTTPS")
        if source.get("commit") and not COMMIT.fullmatch(source["commit"]):
            errors.append(f"source {source_id} commit is not exact")
        if not source.get("license") and not source.get("licenses"):
            errors.append(f"source {source_id} has no license")
        if not source.get("owner") or not source.get("reachability"):
            errors.append(f"source {source_id} lacks ownership/reachability")
    expected_sources = {"popcorn-hex", "popcorn-source", "fissionvm-source", "mbedtls-source", "emsdk-source"}
    if source_ids != expected_sources:
        errors.append("runtime source inventory is incomplete or has unexpected entries")

    for asset in runtime.get("packaged_runtime_assets", []):
        if not SHA256.fullmatch(asset.get("sha256", "")) or not asset.get("bytes"):
            errors.append(f"packaged asset {asset.get('path')} lacks identity")
        if asset.get("provenance_status") not in {"source_commit_not_embedded", "package_hash_only"}:
            errors.append(f"packaged asset {asset.get('path')} overclaims provenance")

    contract = runtime.get("build_contract", {})
    options = contract.get("cmake_options", {})
    required_options = {
        "AVM_BUILD_RUNTIME_ONLY": "1",
        "AVM_EMSCRIPTEN_ENV": "web",
        "CMAKE_BUILD_TYPE": "Release",
        "FETCHCONTENT_FULLY_DISCONNECTED": "ON",
        "FETCHCONTENT_SOURCE_DIR_MBEDTLS": "/inputs/mbedtls",
    }
    if options != required_options:
        errors.append("runtime CMake options do not enforce the qualified offline build")
    if contract.get("network_during_configure_or_build") is not False:
        errors.append("runtime build must forbid configure/build network access")
    if "/emsdk/upstream/bin" not in contract.get("path_prefixes", []):
        errors.append("runtime PATH omits the pinned LLVM/Binaryen directory")

    wasm = runtime.get("wasm_requirements", {})
    for requirement in ("shared_memory", "atomics", "threads", "cross_origin_isolation_required"):
        if wasm.get(requirement) is not True:
            errors.append(f"Wasm requirement {requirement} is missing")
    if wasm.get("component_model") is not False or wasm.get("wasi") is not False:
        errors.append("browser runtime must not claim Component Model or WASI")

    dispositions = {item.get("id"): item.get("disposition") for item in runtime.get("forbidden_defaults", [])}
    if set(dispositions) != {"mutable-fissionvm-branch", "insecure-mbedtls-fetch", "implicit-ninja"}:
        errors.append("forbidden runtime defaults are incomplete")
    if any(not value for value in dispositions.values()):
        errors.append("forbidden runtime default lacks a disposition")
    if runtime.get("manual_steps") != [] or runtime.get("private_credentials_required") is not False:
        errors.append("runtime acquisition depends on manual steps or private credentials")

    tool_versions = {tool.get("id"): tool.get("version") for tool in environment.get("tools", [])}
    for tool_id in ("emscripten", "clang-llvm", "binaryen", "cmake", "ninja"):
        if not tool_versions.get(tool_id):
            errors.append(f"environment omits runtime tool {tool_id}")

    if provenance.get("license_disposition", {}).get("unknown_licenses") != []:
        errors.append("runtime provenance contains unknown licenses")
    if not provenance.get("risks") or not provenance.get("update_triggers"):
        errors.append("runtime risks/update triggers are absent")
    for advisory in provenance.get("advisory_inputs", []):
        if not advisory.get("url", "").startswith("https://") or not advisory.get("owner") or not advisory.get("review_trigger"):
            errors.append(f"advisory input {advisory.get('id')} is incomplete")

    return errors


def main() -> int:
    errors = validate(load(HERE / "runtime.lock.json"), load(HERE / "runtime-provenance.json"), load(HERE / "environment.lock.json"))
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print("BH-01 Phase 2 AtomVM/Popcorn qualification: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
