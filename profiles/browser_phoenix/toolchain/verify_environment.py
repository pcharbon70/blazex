#!/usr/bin/env python3
"""Validate the BH-01 pinned host, tool, browser, and acquisition inputs."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[3]
TOOLCHAIN = Path(__file__).resolve().parent
SHA256 = re.compile(r"^[0-9a-f]{64}$")
SHA512 = re.compile(r"^[0-9a-f]{128}$")
FLOATING = re.compile(r"(^|[/#:@._-])(latest|main|master|head|stable|swm)(?=$|[/#:@._-])", re.I)


def load(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as stream:
        return json.load(stream)


def require_exact(value: str, field: str, errors: list[str]) -> None:
    if not value or FLOATING.search(value) or any(token in value for token in (">=", "<=", "~>", "^", "*")):
        errors.append(f"{field} is not exact: {value!r}")


def validate_all(
    environment: dict[str, Any],
    browsers: dict[str, Any],
    policy: dict[str, Any],
    package: dict[str, Any],
    package_lock: dict[str, Any],
) -> list[str]:
    errors: list[str] = []

    if environment.get("status") != "pinned_inputs_unbuilt":
        errors.append("environment status must remain pinned_inputs_unbuilt during Phase 2")
    if environment.get("platform", {}).get("timezone") != "UTC":
        errors.append("toolchain timezone must be UTC")
    if environment.get("platform", {}).get("locale") != "C.UTF-8":
        errors.append("toolchain locale must be C.UTF-8")

    image_ids = set()
    for image in environment.get("images", []):
        image_ids.add(image.get("id"))
        reference = image.get("reference", "")
        if not re.search(r"@sha256:[0-9a-f]{64}$", reference):
            errors.append(f"image is not digest-pinned: {reference!r}")
        require_exact(image.get("architecture", ""), f"image {image.get('id')} architecture", errors)

    tool_ids = set()
    for tool in environment.get("tools", []):
        tool_id = tool.get("id", "<missing>")
        tool_ids.add(tool_id)
        require_exact(str(tool.get("version", "")), f"tool {tool_id} version", errors)
        provider = tool.get("provided_by")
        if provider and provider not in image_ids and provider not in tool_ids:
            # Forward tool references are checked once all IDs are known below.
            pass
        source_url = tool.get("source_url")
        if source_url:
            if not source_url.startswith("https://"):
                errors.append(f"tool {tool_id} source must use HTTPS")
            if "integrity" not in tool and not SHA256.fullmatch(tool.get("sha256", "")):
                errors.append(f"tool {tool_id} lacks a SHA-256 or npm integrity")
            if "sha512" in tool and not SHA512.fullmatch(tool["sha512"]):
                errors.append(f"tool {tool_id} has an invalid SHA-512")
        if not tool.get("owner"):
            errors.append(f"tool {tool_id} has no owner")

    providers = image_ids | tool_ids
    for tool in environment.get("tools", []):
        if tool.get("provided_by") and tool["provided_by"] not in providers:
            errors.append(f"tool {tool.get('id')} has unknown provider {tool['provided_by']}")

    if package.get("packageManager") != "npm@11.19.0":
        errors.append("packageManager must match the npm tool pin")
    expected_js = {"esbuild": "0.28.2", "playwright-core": "1.62.1"}
    if package.get("devDependencies") != expected_js:
        errors.append("JavaScript direct tooling dependencies differ from the qualification lock")
    if package_lock.get("lockfileVersion") != policy.get("npm", {}).get("lockfile_version"):
        errors.append("npm lockfile version differs from acquisition policy")
    root_package = package_lock.get("packages", {}).get("", {})
    if root_package.get("devDependencies") != expected_js:
        errors.append("npm lock root dependencies are stale")

    local_ids = set()
    for browser in browsers.get("local_binaries", []):
        local_ids.add(browser.get("id"))
        require_exact(browser.get("product_version", ""), f"browser {browser.get('id')} version", errors)
        if not SHA256.fullmatch(browser.get("sha256", "")):
            errors.append(f"browser {browser.get('id')} lacks a SHA-256")
        if not browser.get("source_url", "").startswith("https://"):
            errors.append(f"browser {browser.get('id')} source must use HTTPS")
    if len(local_ids) != len(browsers.get("local_binaries", [])):
        errors.append("duplicate local browser IDs")

    required_fingerprint_fields = {"product", "product_version", "engine_version", "os_name", "os_build", "architecture", "captured_at"}
    for profile in browsers.get("managed_fingerprint_profiles", []):
        missing = required_fingerprint_fields - set(profile.get("required_per_run", []))
        if missing:
            errors.append(f"browser profile {profile.get('id')} misses fingerprint fields: {sorted(missing)}")
    gate = browsers.get("drift_gate", {})
    if not gate.get("reject_version_change_without_requalification") or gate.get("allow_symbolic_versions_in_results"):
        errors.append("browser drift gate is permissive")

    for name, url in policy.get("registries", {}).items():
        if not url.startswith("https://") or FLOATING.search(url):
            errors.append(f"registry {name} is not an immutable HTTPS origin")
    if policy.get("private_credentials_allowed") is not False:
        errors.append("private credentials must be forbidden")
    if policy.get("npm", {}).get("lifecycle_default") != "deny":
        errors.append("npm lifecycle default must be deny")
    allowlist = {(entry.get("package"), entry.get("version")) for entry in policy.get("npm", {}).get("lifecycle_allowlist", [])}
    if allowlist != {("esbuild", "0.28.2")}:
        errors.append("npm lifecycle allowlist must contain only exact esbuild 0.28.2")
    for enabled in policy.get("failure_policy", {}).values():
        if enabled is not True:
            errors.append("every acquisition failure policy must be enabled")
            break

    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--environment", type=Path, default=TOOLCHAIN / "environment.lock.json")
    parser.add_argument("--browsers", type=Path, default=TOOLCHAIN / "browser.lock.json")
    parser.add_argument("--policy", type=Path, default=TOOLCHAIN / "acquisition-policy.json")
    parser.add_argument("--package", type=Path, default=ROOT / "js/blazex_runtime/package.json")
    parser.add_argument("--package-lock", type=Path, default=ROOT / "js/blazex_runtime/package-lock.json")
    args = parser.parse_args()
    errors = validate_all(*(load(path) for path in (args.environment, args.browsers, args.policy, args.package, args.package_lock)))
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print("BH-01 Phase 2 environment qualification: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
