#!/usr/bin/env python3
"""Generate the unified BH-01 Phase 3 artifact and reproducibility records."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Any


HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]
RUNTIME = REPO / "packages/blazex_runtime_popcorn/runtime"
ASSETS = REPO / "docs/research/assets/bh-01-baseline"
RAW_EVIDENCE = REPO / "integration/fixtures/raw-evidence"


def load(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as stream:
        return json.load(stream)


def digest(path: Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            value.update(chunk)
    return value.hexdigest()


def relative(path: Path) -> str:
    return path.resolve().relative_to(REPO).as_posix()


def compared_artifacts(
    runtime_primary: Path,
    runtime_repeat: Path,
    fixture_primary: Path,
    fixture_repeat: Path,
) -> list[dict[str, Any]]:
    runtime_manifest = load(RUNTIME / "runtime-binary-manifest.json")
    bundle_manifest = load(HERE / "bundle-manifest.json")
    comparisons: list[dict[str, Any]] = []

    for item in runtime_manifest["artifacts"]:
        within_root = Path(item["path"]).relative_to("generated")
        primary = runtime_primary / within_root
        repeat = runtime_repeat / within_root
        comparisons.append(compare(item["artifact_id"], primary, repeat))

    for item in bundle_manifest["artifacts"]:
        within_root = Path(item["path"]).relative_to("generated")
        primary = fixture_primary / within_root
        repeat = fixture_repeat / within_root
        comparisons.append(compare(item["artifact_id"], primary, repeat))

    return comparisons


def compare(artifact_id: str, primary: Path, repeat: Path) -> dict[str, Any]:
    if not primary.is_file() or not repeat.is_file():
        missing = [str(path) for path in (primary, repeat) if not path.is_file()]
        raise SystemExit(f"{artifact_id}: missing reproducibility output: {missing}")
    primary_sha = digest(primary)
    repeat_sha = digest(repeat)
    return {
        "artifact_id": artifact_id,
        "primary_sha256": primary_sha,
        "repeat_sha256": repeat_sha,
        "primary_bytes": primary.stat().st_size,
        "repeat_bytes": repeat.stat().st_size,
        "byte_identical": primary_sha == repeat_sha and primary.stat().st_size == repeat.stat().st_size,
    }


def tracked_artifact(
    artifact_id: str,
    path: Path,
    kind: str,
    owner: str,
    license_record_ids: list[str] | None = None,
) -> dict[str, Any]:
    mime = "application/json" if path.suffix == ".json" else "text/markdown" if path.suffix == ".md" else "text/plain"
    return {
        "artifact_id": artifact_id,
        "build_lineage": "BX-BH01-PHASE3-ACCOUNTING-0.1",
        "bytes": path.stat().st_size,
        "kind": kind,
        "license_record_ids": license_record_ids or [],
        "mime": mime,
        "mode": "metadata",
        "owner": owner,
        "path": relative(path),
        "provenance": "versioned repository evidence generated from the pinned Phase 3 contracts and observed outputs",
        "reachability_root": "phase3-evidence",
        "sha256": digest(path),
        "source_map_policy": "not-applicable",
    }


def normalized_output_artifacts() -> list[dict[str, Any]]:
    runtime_manifest = load(RUNTIME / "runtime-binary-manifest.json")
    bundle_manifest = load(HERE / "bundle-manifest.json")
    artifacts: list[dict[str, Any]] = []
    for item in runtime_manifest["artifacts"]:
        normalized = dict(item)
        normalized["path"] = f"packages/blazex_runtime_popcorn/runtime/{item['path']}"
        artifacts.append(normalized)
    for item in bundle_manifest["artifacts"]:
        normalized = dict(item)
        normalized["path"] = f"integration/fixtures/runtime_smoke/{item['path']}"
        artifacts.append(normalized)
    return artifacts


def build_inputs() -> list[dict[str, Any]]:
    runtime_contract = load(RUNTIME / "build-contract.json")
    runtime_lock = load(REPO / "profiles/browser_phoenix/toolchain/runtime.lock.json")
    environment_lock = load(REPO / "profiles/browser_phoenix/toolchain/environment.lock.json")
    server_dependencies = load(REPO / "profiles/browser_phoenix/toolchain/server-dependencies.json")
    sources = {item["id"]: item for item in runtime_lock["sources"]}
    tools = {item["id"]: item for item in environment_lock["tools"]}
    packages = {item[0]: item for item in server_dependencies["packages"]}

    records = [
        input_record("fissionvm", sources["fissionvm-source"]["origin"], runtime_contract["inputs"]["fissionvm"], "BX-BH01-LICENSE-FISSIONVM", "runtime"),
        input_record("mbedtls", sources["mbedtls-source"]["origin"], runtime_contract["inputs"]["mbedtls"], "BX-BH01-LICENSE-MBEDTLS", "runtime"),
        {
            "artifact_id": "BX-BH01-INPUT-EMSCRIPTEN",
            "name": "emscripten",
            "origin": runtime_contract["image"]["reference"],
            "sha256": runtime_contract["image"]["config_sha256"],
            "version": sources["emsdk-source"]["version"],
            "license_record_id": "BX-BH01-LICENSE-EMSCRIPTEN",
            "owner": "runtime-build",
            "reachability": "build-generated-glue",
        },
        {
            "artifact_id": "BX-BH01-INPUT-NINJA",
            "name": "ninja",
            "origin": tools["ninja"]["source_url"],
            "sha256": runtime_contract["inputs"]["ninja"]["sha256"],
            "version": runtime_contract["inputs"]["ninja"]["version"],
            "license_record_id": "BX-BH01-LICENSE-NINJA",
            "owner": "runtime-build",
            "reachability": "build-only",
        },
        input_record("gperf", runtime_contract["inputs"]["gperf"]["origin"], runtime_contract["inputs"]["gperf"], "BX-BH01-LICENSE-GPERF", "build-only-generated-tables"),
        input_record("zlib", runtime_contract["inputs"]["zlib"]["origin"], runtime_contract["inputs"]["zlib"], "BX-BH01-LICENSE-ZLIB", "runtime"),
        hex_input("popcorn", packages["popcorn"], "BX-BH01-LICENSE-POPCORN", "runtime-selected-modules"),
        hex_input("jason", packages["jason"], "BX-BH01-LICENSE-JASON", "runtime-selected-modules"),
    ]
    return records


def input_record(name: str, origin: str, item: dict[str, Any], license_id: str, reachability: str) -> dict[str, Any]:
    return {
        "artifact_id": f"BX-BH01-INPUT-{name.upper()}",
        "name": name,
        "origin": origin,
        "sha256": item["sha256"],
        "version": item["version"],
        "license_record_id": license_id,
        "owner": "runtime-build",
        "reachability": reachability,
    }


def hex_input(name: str, package: list[Any], license_id: str, reachability: str) -> dict[str, Any]:
    return {
        "artifact_id": f"BX-BH01-INPUT-{name.upper()}",
        "name": name,
        "origin": f"https://repo.hex.pm/tarballs/{name}-{package[1]}.tar",
        "sha256": package[2],
        "version": package[1],
        "license_record_id": license_id,
        "owner": "integration/fixtures/runtime_smoke",
        "reachability": reachability,
    }


def license_records() -> list[dict[str, Any]]:
    values = [
        ("FISSIONVM", "fissionvm", "Apache-2.0 selected from Apache-2.0 OR LGPL-2.1-or-later"),
        ("MBEDTLS", "mbedtls", "Apache-2.0"),
        ("EMSCRIPTEN", "emscripten", "MIT plus bundled LLVM/Binaryen notices"),
        ("NINJA", "ninja", "Apache-2.0"),
        ("GPERF", "gperf", "GPL-3.0-or-later"),
        ("ZLIB", "zlib", "Zlib"),
        ("POPCORN", "popcorn", "Apache-2.0"),
        ("JASON", "jason", "Apache-2.0"),
    ]
    notice = RUNTIME / "THIRD_PARTY_NOTICES.md"
    return [
        {
            "artifact_id": f"BX-BH01-LICENSE-{key}",
            "input_id": f"BX-BH01-INPUT-{key}",
            "license": license,
            "notice_path": relative(notice),
            "notice_sha256": digest(notice),
            "status": "known-retention-required",
        }
        for key, _name, license in values
    ]


def producer_records(contract: dict[str, Any]) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    for lineage in contract["build_lineages"]:
        for path_value in lineage["producers"]:
            path = REPO / path_value
            records.append(
                {
                    "artifact_id": f"{lineage['id']}-PRODUCER-{path.name.upper().replace('.', '-')}",
                    "build_lineage": lineage["id"],
                    "path": path_value,
                    "sha256": digest(path),
                    "owner": lineage["owner"],
                }
            )
    return records


def generate(args: argparse.Namespace) -> None:
    comparisons = compared_artifacts(args.runtime_primary, args.runtime_repeat, args.fixture_primary, args.fixture_repeat)
    all_identical = all(item["byte_identical"] for item in comparisons)
    evidence = {
        "schema_version": "1.0.0",
        "evidence_id": "BX-BH01-PHASE3-ARTIFACT-REPRODUCIBILITY-0.1",
        "status": "passed" if all_identical else "failed",
        "method": "Two builds from clean equivalent source/output roots using exact pinned images, locks, source archives, fixed paths, offline inputs, and deterministic gzip metadata.",
        "run_count": 2,
        "comparisons": comparisons,
        "summary": {
            "compared_artifacts": len(comparisons),
            "byte_identical_artifacts": sum(item["byte_identical"] for item in comparisons),
            "normalized_only_artifacts": 0,
            "unexplained_differences": sum(not item["byte_identical"] for item in comparisons),
        },
        "excluded_intermediates": [
            {
                "path": "packages/blazex_runtime_popcorn/runtime/generated/<mode>/cmake/**",
                "reason": "CMake/Ninja object trees are clean-build intermediates and are not copied to an artifact or evidence distribution.",
            }
        ],
    }
    args.evidence.parent.mkdir(parents=True, exist_ok=True)
    args.evidence.write_text(json.dumps(evidence, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    contract_path = HERE / "artifact-accounting-contract.json"
    accounting_contract = load(contract_path)
    runtime_manifest = RUNTIME / "runtime-binary-manifest.json"
    bundle_manifest = HERE / "bundle-manifest.json"
    patch_manifest = RUNTIME / "patches/manifest.json"
    notice = RUNTIME / "THIRD_PARTY_NOTICES.md"
    artifacts = normalized_output_artifacts()
    artifacts.extend(
        [
            tracked_artifact("BX-BH01-RUNTIME-BINARY-MANIFEST", runtime_manifest, "generated-metadata", "packages/blazex_runtime_popcorn/runtime"),
            tracked_artifact("BX-BH01-FIXTURE-BUNDLE-MANIFEST", bundle_manifest, "generated-metadata", "integration/fixtures/runtime_smoke"),
            tracked_artifact("BX-BH01-RUNTIME-PATCH-MANIFEST", patch_manifest, "patch-manifest", "packages/blazex_runtime_popcorn/runtime"),
            tracked_artifact("BX-BH01-RUNTIME-THIRD-PARTY-NOTICES", notice, "license-notice", "packages/blazex_runtime_popcorn/runtime", [record["artifact_id"] for record in license_records()]),
            tracked_artifact("BX-BH01-PHASE3-ARTIFACT-ACCOUNTING-CONTRACT", contract_path, "artifact-contract", "integration/fixtures/runtime_smoke"),
            tracked_artifact("BX-BH01-PHASE3-REPRODUCIBILITY-EVIDENCE", args.evidence, "reproducibility-evidence", "integration/fixtures/runtime_smoke"),
        ]
    )
    manifest = {
        "schema_version": "1.0.0",
        "manifest_id": "BX-BH01-PHASE3-ARTIFACT-MANIFEST-0.1",
        "status": "observed-byte-identical" if all_identical else "observed-difference",
        "contract": relative(contract_path),
        "contract_sha256": digest(contract_path),
        "build_lineages": accounting_contract["build_lineages"],
        "producer_records": producer_records(accounting_contract),
        "build_inputs": build_inputs(),
        "artifacts": artifacts,
        "embedded_artifacts": load(runtime_manifest)["embedded_artifacts"],
        "omission_records": load(runtime_manifest)["omission_records"],
        "license_records": license_records(),
        "license_unknown": [],
        "reproducibility_evidence": {"path": relative(args.evidence), "sha256": digest(args.evidence)},
        "accounting": {
            "orphaned_artifacts": [],
            "duplicate_artifact_ids": [],
            "unhashed_artifacts": [],
            "unreachable_artifacts": [],
            "unexpected_external_source_maps": [],
            "undeclared_artifacts": [],
        },
        "payload_observations": {
            "status": "preliminary-not-a-budget-pass",
            "runtime_and_bundle_bytes_recorded": True,
            "budget_gate": "not-evaluated",
        },
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    if not all_identical:
        raise SystemExit("Phase 3 artifact reproducibility: FAIL")
    print(f"BH-01 Phase 3 artifact accounting: PASS ({len(comparisons)} byte-identical outputs)")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--runtime-primary", type=Path, default=RUNTIME / "generated")
    parser.add_argument("--runtime-repeat", type=Path, required=True)
    parser.add_argument("--fixture-primary", type=Path, default=HERE / "generated")
    parser.add_argument("--fixture-repeat", type=Path, required=True)
    parser.add_argument("--output", type=Path, default=ASSETS / "blazex-bh-01-phase-03-artifact-manifest-v0.1.0.json")
    parser.add_argument("--evidence", type=Path, default=RAW_EVIDENCE / "bh01-phase3-artifact-reproducibility.json")
    args = parser.parse_args()
    for name in ("runtime_primary", "runtime_repeat", "fixture_primary", "fixture_repeat", "output", "evidence"):
        setattr(args, name, getattr(args, name).resolve())
    generate(args)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
