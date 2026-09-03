#!/usr/bin/env python3
"""Validate the BH-01 Phase 3 artifact manifest and retained repeat evidence."""

from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any


HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]
RUNTIME = REPO / "packages/blazex_runtime_popcorn/runtime"
MANIFEST_PATH = REPO / "docs/research/assets/bh-01-baseline/blazex-bh-01-phase-03-artifact-manifest-v0.1.0.json"
EVIDENCE_PATH = REPO / "integration/fixtures/raw-evidence/bh01-phase3-artifact-reproducibility.json"
SHA256 = re.compile(r"^[0-9a-f]{64}$")


def load(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as stream:
        return json.load(stream)


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def generated_inventory(root: Path, modes: list[str], excluded_prefixes: tuple[str, ...] = ()) -> set[str]:
    files: set[str] = set()
    for mode in modes:
        mode_root = root / mode
        for path in mode_root.rglob("*"):
            if not path.is_file():
                continue
            relative = path.relative_to(mode_root).as_posix()
            if any(relative == prefix or relative.startswith(prefix + "/") for prefix in excluded_prefixes):
                continue
            files.add(f"{mode}/{relative}")
    return files


def validate(
    manifest: dict[str, Any],
    evidence: dict[str, Any],
    contract: dict[str, Any],
    check_files: bool = True,
) -> list[str]:
    errors: list[str] = []
    if manifest.get("status") != "observed-byte-identical":
        errors.append("artifact manifest is not an observed byte-identical result")
    if evidence.get("status") != "passed" or evidence.get("run_count") != 2:
        errors.append("artifact evidence does not contain two passing clean runs")

    artifacts = manifest.get("artifacts", [])
    ids = [item.get("artifact_id") for item in artifacts]
    if len(ids) != len(set(ids)):
        errors.append("artifact IDs are duplicated")
    paths = [item.get("path") for item in artifacts]
    if len(paths) != len(set(paths)):
        errors.append("artifact paths are duplicated")

    required_fields = set(contract.get("required_artifact_fields", []))
    license_ids = {item.get("artifact_id") for item in manifest.get("license_records", [])}
    for item in artifacts:
        missing = required_fields - set(item)
        if missing:
            errors.append(f"artifact {item.get('artifact_id')} lacks fields {sorted(missing)}")
        if not SHA256.fullmatch(item.get("sha256", "")) or not item.get("bytes"):
            errors.append(f"artifact {item.get('artifact_id')} is unhashed or empty")
        if not item.get("owner") or not item.get("reachability_root"):
            errors.append(f"artifact {item.get('artifact_id')} is ownerless or unreachable")
        unknown = set(item.get("license_record_ids", [])) - license_ids
        if unknown:
            errors.append(f"artifact {item.get('artifact_id')} has unknown licenses {sorted(unknown)}")
        if check_files and item.get("path"):
            path = REPO / item["path"]
            if not path.is_file():
                errors.append(f"artifact {item.get('artifact_id')} is missing")
            elif digest(path) != item.get("sha256") or path.stat().st_size != item.get("bytes"):
                errors.append(f"artifact {item.get('artifact_id')} differs from its identity")

    inputs = manifest.get("build_inputs", [])
    input_names = {item.get("name") for item in inputs}
    if input_names != set(contract.get("required_license_inputs", [])):
        errors.append("build-input license accounting is incomplete")
    input_ids = {item.get("artifact_id") for item in inputs}
    for item in inputs:
        if not SHA256.fullmatch(item.get("sha256", "")):
            errors.append(f"build input {item.get('artifact_id')} is unhashed")
        if not item.get("origin") or not item.get("owner") or not item.get("reachability"):
            errors.append(f"build input {item.get('artifact_id')} lacks provenance or reachability")
        if item.get("license_record_id") not in license_ids:
            errors.append(f"build input {item.get('artifact_id')} has an unknown license")
    for item in manifest.get("license_records", []):
        if item.get("input_id") not in input_ids or item.get("status") != "known-retention-required":
            errors.append(f"license record {item.get('artifact_id')} is unknown or detached")
        notice = REPO / item.get("notice_path", "")
        if check_files and (not notice.is_file() or digest(notice) != item.get("notice_sha256")):
            errors.append(f"license record {item.get('artifact_id')} has invalid notice evidence")
    if manifest.get("license_unknown") != []:
        errors.append("unknown license entries remain")

    lineages = {item.get("id") for item in manifest.get("build_lineages", [])}
    producer_ids: list[str] = []
    for item in manifest.get("producer_records", []):
        producer_ids.append(item.get("artifact_id"))
        if item.get("build_lineage") not in lineages or not SHA256.fullmatch(item.get("sha256", "")):
            errors.append(f"producer {item.get('artifact_id')} lacks lineage or identity")
        path = REPO / item.get("path", "")
        if check_files and (not path.is_file() or digest(path) != item.get("sha256")):
            errors.append(f"producer {item.get('artifact_id')} differs from its identity")
    if len(producer_ids) != len(set(producer_ids)) or len(producer_ids) != 6:
        errors.append("producer accounting is duplicated or incomplete")

    comparisons = evidence.get("comparisons", [])
    compared_ids = [item.get("artifact_id") for item in comparisons]
    generated_ids = {
        item["artifact_id"]
        for item in artifacts
        if "/generated/" in item.get("path", "")
    }
    if len(compared_ids) != len(set(compared_ids)) or set(compared_ids) != generated_ids:
        errors.append("repeat evidence omits or duplicates a generated artifact")
    for item in comparisons:
        if not item.get("byte_identical") or item.get("primary_sha256") != item.get("repeat_sha256"):
            errors.append(f"artifact {item.get('artifact_id')} is not byte-identical")
    summary = evidence.get("summary", {})
    if summary.get("compared_artifacts") != len(comparisons) or summary.get("unexplained_differences") != 0:
        errors.append("repeat evidence summary is inconsistent")

    if check_files:
        runtime_policy = contract["output_roots"]["runtime"]
        fixture_policy = contract["output_roots"]["fixture"]
        actual_runtime = generated_inventory(RUNTIME / "generated", runtime_policy["modes"], ("cmake",))
        expected_runtime = {
            f"{mode}/{path}"
            for mode in runtime_policy["modes"]
            for path in runtime_policy["declared_files"]
        }
        actual_fixture = generated_inventory(HERE / "generated", fixture_policy["modes"])
        expected_fixture = {
            f"{mode}/{path}"
            for mode in fixture_policy["modes"]
            for path in fixture_policy["declared_files"]
        }
        if actual_runtime != expected_runtime:
            errors.append(f"runtime output contains orphaned or missing artifacts: {sorted(actual_runtime ^ expected_runtime)}")
        if actual_fixture != expected_fixture:
            errors.append(f"fixture output contains orphaned or missing artifacts: {sorted(actual_fixture ^ expected_fixture)}")

    embedded = {item.get("artifact_id"): item for item in manifest.get("embedded_artifacts", [])}
    if embedded.get("BX-BH01-RUNTIME-DEBUG-WEB-EMBEDDED-DEBUG-SECTIONS", {}).get("carrier_artifact_id") not in ids:
        errors.append("embedded debug symbols are not tied to a carrier artifact")
    omissions = {item.get("artifact_id") for item in manifest.get("omission_records", [])}
    if "BX-BH01-RUNTIME-EXTERNAL-SOURCE-MAPS-NOT-EMITTED" not in omissions:
        errors.append("external source-map disposition is missing")
    if manifest.get("accounting") != {
        "duplicate_artifact_ids": [],
        "orphaned_artifacts": [],
        "unhashed_artifacts": [],
        "unreachable_artifacts": [],
        "undeclared_artifacts": [],
        "unexpected_external_source_maps": [],
    }:
        errors.append("artifact accounting contains unresolved findings")
    payload = manifest.get("payload_observations", {})
    if payload.get("status") != "preliminary-not-a-budget-pass" or payload.get("budget_gate") != "not-evaluated":
        errors.append("preliminary payload observations improperly pass a budget")
    return errors


def inputs() -> tuple[dict[str, Any], ...]:
    return load(MANIFEST_PATH), load(EVIDENCE_PATH), load(HERE / "artifact-accounting-contract.json")


def main() -> int:
    errors = validate(*inputs())
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print("BH-01 Phase 3 retained artifact accounting: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
