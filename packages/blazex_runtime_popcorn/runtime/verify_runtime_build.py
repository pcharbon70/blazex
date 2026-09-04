#!/usr/bin/env python3
"""Validate the checked-in Phase 3 runtime build and adapter contract."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any


HERE = Path(__file__).resolve().parent
PACKAGE = HERE.parent
SHA256 = re.compile(r"^[0-9a-f]{64}$")


def load(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as stream:
        return json.load(stream)


def validate(
    contract: dict[str, Any],
    patches: dict[str, Any],
    manifest: dict[str, Any] | None = None,
    classification: dict[str, Any] | None = None,
) -> list[str]:
    errors: list[str] = []
    if contract.get("status") != "phase3-executed":
        errors.append("runtime build contract is not Phase 3 executed")
    image = contract.get("image", {})
    if not re.search(r"@sha256:[0-9a-f]{64}$", image.get("reference", "")):
        errors.append("runtime image is not digest pinned")
    required_inputs = {"fissionvm", "mbedtls", "ninja", "gperf", "zlib"}
    inputs = contract.get("inputs", {})
    if set(inputs) != required_inputs:
        errors.append("runtime build inputs are incomplete")
    for name, item in inputs.items():
        if not SHA256.fullmatch(item.get("sha256", "")):
            errors.append(f"{name} lacks a valid SHA-256")
        if not item.get("license"):
            errors.append(f"{name} lacks a license disposition")
    environment = contract.get("environment", {})
    if environment.get("network_during_cache_seed_configure_compile_link_package") is not False:
        errors.append("runtime recipe permits network access")
    options = contract.get("cmake", {}).get("common_options", {})
    if options.get("FETCHCONTENT_FULLY_DISCONNECTED") != "ON" or options.get("FETCHCONTENT_SOURCE_DIR_MBEDTLS") != "/inputs/mbedtls":
        errors.append("Mbed TLS is not forced to the qualified offline source")
    modes = {mode.get("id"): mode for mode in contract.get("modes", [])}
    if set(modes) != {"debug-web", "release-web", "release-node-probe"}:
        errors.append("runtime build modes differ from the Phase 3 contract")
    if modes.get("release-node-probe", {}).get("deployable") is not False:
        errors.append("Node probe must not be deployable")
    if patches.get("patches") != []:
        for patch in patches.get("patches", []):
            if not SHA256.fullmatch(patch.get("sha256", "")):
                errors.append("runtime patch lacks a SHA-256")
    if classification is not None:
        classes = {item.get("classification"): item for item in classification.get("surfaces", [])}
        required_classes = {
            "upstream-atomvm",
            "upstream-fissionvm",
            "upstream-popcorn",
            "blazex-phase3-adaptation",
            "blazex-source-patch",
            "future-browser-host",
        }
        if set(classes) != required_classes:
            errors.append("runtime adapter classifications are incomplete")
        if classes.get("blazex-source-patch", {}).get("owns") != []:
            errors.append("adapter classification claims an unrecorded source patch")
        if classification.get("fixture_hooks") != [
            "boot_fixture",
            "dispatch_fixture_message",
            "dispose_fixture",
        ]:
            errors.append("runtime adapter fixture hooks differ from the experimental contract")
    if manifest is not None:
        if manifest.get("status") != "observed-pass":
            errors.append("runtime binary manifest has not passed")
        artifact_modes = {item.get("mode") for item in manifest.get("artifacts", []) if item.get("kind") == "wasm"}
        if artifact_modes != set(modes):
            errors.append("manifest does not account for every Wasm mode")
        for item in manifest.get("artifacts", []):
            if not SHA256.fullmatch(item.get("sha256", "")) or not item.get("bytes"):
                errors.append(f"artifact {item.get('artifact_id')} lacks identity")
        for inspection in manifest.get("wasm_inspections", []):
            if inspection.get("forbidden_embedded_strings"):
                errors.append(f"{inspection.get('mode')} embeds forbidden paths or secrets")
            allowed_modules = set(contract.get("allowed_import_modules_by_mode", {}).get(inspection.get("mode"), []))
            if set(inspection.get("import_modules", [])) != allowed_modules:
                errors.append(f"{inspection.get('mode')} has an undeclared import module")
            memories = inspection.get("memory_imports", [])
            if len(memories) != 1 or memories[0].get("limits") != {"minimum": 256, "maximum": 256, "shared": True, "memory64": False}:
                errors.append(f"{inspection.get('mode')} memory contract differs")
    source = (PACKAGE / "lib/blazex/runtime/popcorn.ex").read_text(encoding="utf-8")
    forbidden = ("Phoenix", "LiveView", "LocalLiveView", "WebAssembly.DOM", "BlazeX.Component")
    for token in forbidden:
        if token in source:
            errors.append(f"runtime adapter contains forbidden token {token}")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--contract", type=Path, default=HERE / "build-contract.json")
    parser.add_argument("--patches", type=Path, default=HERE / "patches/manifest.json")
    parser.add_argument("--manifest", type=Path, default=HERE / "runtime-binary-manifest.json")
    parser.add_argument("--classification", type=Path, default=HERE / "adapter-classification.json")
    args = parser.parse_args()
    manifest = load(args.manifest) if args.manifest.exists() else None
    errors = validate(load(args.contract), load(args.patches), manifest, load(args.classification))
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print("BH-01 Phase 3 runtime build contract: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
