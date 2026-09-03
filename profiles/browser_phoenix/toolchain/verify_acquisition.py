#!/usr/bin/env python3
"""Validate Phase 2 deterministic acquisition and unified inventory evidence."""

from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
SHA256 = re.compile(r"^[0-9a-f]{64}$")


def load(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as stream:
        return json.load(stream)


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def validate(
    policy: dict[str, Any],
    evidence: dict[str, Any],
    inventory: dict[str, Any],
    environment: dict[str, Any],
    runtime: dict[str, Any],
    server: dict[str, Any],
    repository_hashes: dict[str, str],
) -> list[str]:
    errors: list[str] = []

    if not policy.get("noninteractive") or policy.get("private_credentials_allowed") is not False:
        errors.append("acquisition must be noninteractive and credential-free")
    required_failures = {
        "reject_floating_ref", "reject_hash_mismatch", "reject_missing_artifact",
        "reject_unapproved_lifecycle_script", "reject_private_auth_challenge",
        "reject_lock_mutation", "reject_implicit_download"
    }
    failure_policy = policy.get("failure_policy", {})
    if any(failure_policy.get(key) is not True for key in required_failures):
        errors.append("acquisition failure policy is incomplete")
    npm = policy.get("npm", {})
    if "--ignore-scripts" not in npm.get("install_command", ""):
        errors.append("npm acquisition does not deny lifecycle scripts by default")
    allowlist = npm.get("lifecycle_allowlist", [])
    if allowlist != [{
        "package": "esbuild", "version": "0.28.2", "script": "install.js",
        "reason": "selects and validates the integrity-locked platform binary"
    }]:
        errors.append("npm lifecycle allowlist is broader than the qualified esbuild step")
    allowed_hosts = set(policy.get("registries", {}).values())
    if any(not origin.startswith("https://") for origin in allowed_hosts):
        errors.append("acquisition registry is not HTTPS")
    if not policy.get("cache", {}).get("clean_run_required") or not policy.get("cache", {}).get("cached_run_required"):
        errors.append("clean and cached acquisition are not both required")

    records = inventory.get("canonical_records", [])
    if not records:
        errors.append("unified inventory has no canonical records")
    for record in records:
        path = record.get("path", "")
        expected = record.get("sha256", "")
        if not SHA256.fullmatch(expected):
            errors.append(f"canonical record {path} has no valid SHA-256")
        elif repository_hashes.get(path) != expected:
            errors.append(f"canonical record {path} hash drifted")

    summary = inventory.get("graph_summary", {})
    actual_summary = {
        "system_packages": len(environment.get("system_packages", [])),
        "governed_tools": len(environment.get("tools", [])),
        "runtime_sources": len(runtime.get("sources", [])),
        "hex_packages": len(server.get("packages", [])),
    }
    for key, value in actual_summary.items():
        if summary.get(key) != value:
            errors.append(f"unified graph count {key} drifted")
    if inventory.get("licenses", {}).get("unknown") != []:
        errors.append("unified inventory contains unknown licenses")
    if not inventory.get("owners") or not inventory.get("vulnerability_inputs"):
        errors.append("unified inventory lacks owners or vulnerability inputs")
    if not inventory.get("forbidden_input_classes") or not inventory.get("claims_not_made"):
        errors.append("unified inventory lacks forbidden classes or claim limits")

    expected_successes = {"hex-clean-network", "hex-offline-cache", "npm-clean-network", "npm-offline-cache"}
    successes = evidence.get("successful_replays", [])
    if {run.get("id") for run in successes} != expected_successes:
        errors.append("clean/cached manager replay evidence is incomplete")
    for run in successes:
        if run.get("result") != "pass" or not run.get("duration_seconds"):
            errors.append(f"acquisition replay {run.get('id')} did not pass with duration")
        if run.get("lock_before_sha256") != run.get("lock_after_sha256"):
            errors.append(f"acquisition replay {run.get('id')} mutated its lock")
    offline = [run for run in successes if "offline" in run.get("id", "")]
    if len(offline) != 2 or any(run.get("network") is not False for run in offline):
        errors.append("offline manager replay evidence is not network-independent")

    comparison = evidence.get("independent_clean_comparison", {})
    if comparison.get("result") != "pass" or comparison.get("unexplained_variance") != []:
        errors.append("two-clean-environment comparison did not pass without unexplained variance")
    if comparison.get("hex", {}).get("lock_sha256") != successes[0].get("lock_before_sha256"):
        errors.append("second clean Hex lock differs from the canonical replay")
    if comparison.get("npm", {}).get("lock_sha256") != successes[2].get("lock_before_sha256"):
        errors.append("second clean npm lock differs from the canonical replay")
    if not comparison.get("hex", {}).get("graph_comparison") or len(comparison.get("npm", {}).get("installed_identities", [])) != 3:
        errors.append("second clean manager graph comparison is incomplete")

    runtime_hashes = {item.get("id"): item.get("sha256") for item in runtime.get("sources", [])}
    source_replays = evidence.get("source_replays", [])
    expected_source_ids = {"popcorn-source", "fissionvm-source", "mbedtls-source", "emsdk-source"}
    if {item.get("id") for item in source_replays} != expected_source_ids:
        errors.append("runtime source replay evidence is incomplete")
    for replay in source_replays:
        if replay.get("result") != "pass" or replay.get("sha256") != runtime_hashes.get(replay.get("id")):
            errors.append(f"runtime source replay {replay.get('id')} does not match its lock")
        if not replay.get("seconds") or not replay.get("bytes"):
            errors.append(f"runtime source replay {replay.get('id')} lacks timing or size")

    failures = evidence.get("failure_replays", [])
    expected_failure_ids = {
        "empty-cache-offline", "hash-mismatch", "floating-or-moved-ref",
        "missing-or-unavailable-binary", "unrecorded-registry-or-private-auth",
        "revoked-or-missing-ca", "unapproved-lifecycle-script", "lock-mutation"
    }
    if {item.get("id") for item in failures} != expected_failure_ids:
        errors.append("negative acquisition evidence is incomplete")
    for failure in failures:
        if failure.get("expected") != "reject" or failure.get("observed") != "reject" or not failure.get("evidence"):
            errors.append(f"failure replay {failure.get('id')} was not safely rejected")

    if evidence.get("manual_steps") != [] or evidence.get("private_credentials_used") is not False:
        errors.append("acquisition evidence contains manual steps or private credentials")
    for dependency in evidence.get("platform_dependencies", []):
        if dependency.get("vendored") is not False or not dependency.get("policy"):
            errors.append(f"non-vendored platform dependency {dependency.get('id')} lacks a drift policy")

    return errors


def inputs() -> tuple[Any, ...]:
    inventory = load(HERE / "unified-dependency-inventory.json")
    repository_hashes = {
        record["path"]: file_sha256(ROOT / record["path"])
        for record in inventory.get("canonical_records", [])
        if (ROOT / record["path"]).is_file()
    }
    return (
        load(HERE / "acquisition-policy.json"),
        load(HERE / "acquisition-evidence.json"),
        inventory,
        load(HERE / "environment.lock.json"),
        load(HERE / "runtime.lock.json"),
        load(HERE / "server-dependencies.json"),
        repository_hashes,
    )


def main() -> int:
    errors = validate(*inputs())
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print("BH-01 Phase 2 deterministic acquisition qualification: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
