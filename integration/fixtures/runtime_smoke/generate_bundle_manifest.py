#!/usr/bin/env python3
"""Generate retained identities for ignored BH-01 AVM bundle outputs."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Any


HERE = Path(__file__).resolve().parent


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as stream:
        return json.load(stream)


def source_inputs() -> list[dict[str, Any]]:
    paths = [
        HERE / "mix.exs",
        HERE / "mix.lock",
        HERE / "config/config.exs",
        HERE / "lib/blazex/bh01/runtime_smoke.ex",
        HERE / "lib/blazex/bh01/runtime_smoke/protocol.ex",
        HERE / "lib/blazex/bh01/runtime_smoke/worker.ex",
        HERE / "lib/mix/tasks/bh01.package.ex",
    ]
    return [
        {"path": path.relative_to(HERE).as_posix(), "sha256": digest(path)}
        for path in paths
    ]


def artifact(mode: str, kind: str, path: Path) -> dict[str, Any]:
    mime = "application/vnd.atomvm.avm" if kind in {"avm", "avm-gzip"} else "application/json"
    item = {
        "artifact_id": f"BX-BH01-FIXTURE-{mode.upper()}-{kind.upper()}",
        "mode": mode,
        "kind": kind,
        "path": path.relative_to(HERE).as_posix(),
        "sha256": digest(path),
        "bytes": path.stat().st_size,
        "retained": False,
        "owner": "integration/fixtures/runtime_smoke",
        "reachability_root": "Elixir.BlazeX.BH01.RuntimeSmoke.Boot",
        "mime": mime,
        "content_encoding": "gzip" if kind == "avm-gzip" else None,
        "build_lineage": "BX-BH01-FIXTURE-BUILD-0.1",
        "provenance": "exact locked Elixir/OTP container build with deterministic module ordering and fixed boot identity",
        "source_map_policy": f"fixture-{mode}",
        "license_record_ids": ["BX-BH01-LICENSE-POPCORN", "BX-BH01-LICENSE-JASON"],
    }
    if kind == "avm-gzip":
        item["uncompressed_artifact_id"] = f"BX-BH01-FIXTURE-{mode.upper()}-AVM"
        item["uncompressed_bytes"] = path.with_suffix("").stat().st_size
    return item


def generate(generated: Path) -> dict[str, Any]:
    artifacts: list[dict[str, Any]] = []
    inventories: list[dict[str, Any]] = []
    source_markers = (b"/workspace", b"/home/runner", b"/tmp", b"/home/ducky")

    for mode in ("debug", "release"):
        directory = generated / mode
        bundle = directory / "bundle.avm"
        compressed = directory / "bundle.avm.gz"
        inventory_path = directory / "module-inventory.json"
        inventory = load(inventory_path)
        data = bundle.read_bytes()
        artifacts.extend(
            [
                artifact(mode, "avm", bundle),
                artifact(mode, "avm-gzip", compressed),
                artifact(mode, "module-inventory", inventory_path),
            ]
        )
        inventories.append(
            {
                "mode": mode,
                "module_count": len(inventory["modules"]),
                "modules_sha256": hashlib.sha256("\n".join(inventory["modules"]).encode()).hexdigest(),
                "include_lines": inventory["include_lines"],
                "resource_count": len(inventory["resources"]),
                "embedded_path_markers": {
                    marker.decode(): data.count(marker) for marker in source_markers
                },
            }
        )

    return {
        "schema_version": "1.0.0",
        "manifest_id": "BX-BH01-RUNTIME-SMOKE-BUNDLES-0.1",
        "status": "observed-packaged",
        "build_contract_sha256": digest(HERE / "build-contract.json"),
        "source_inputs": source_inputs(),
        "artifacts": artifacts,
        "module_inventories": inventories,
        "reviewed_nondeterministic_fields": [],
        "normalization": [
            "A fixed generated boot-module name replaces Popcorn.cook's unique boot name.",
            "The temporary generated boot BEAM is deleted after it is embedded and is not a deployable output.",
            "Bundle inputs are sorted by unique BEAM basename with the entrypoint first.",
            "The gzip writer emits an all-zero MTIME field.",
            "The container mount and generated boot source paths are fixed at /workspace.",
        ],
        "source_exposure": {
            "debug": "line information retained; pinned upstream BEAM source paths remain visible",
            "release": "line chunks removed by packbeam; compile metadata in pinned upstream BEAMs can remain visible",
            "secret_scan": "no /home/ducky marker; no credential material is an input",
        },
        "limitations": [
            "Release packaging drops line chunks but does not scrub compile metadata inherited from upstream BEAM files.",
            "The unpruned bundle establishes a correctness baseline; payload reduction is deferred until reachability can be proven.",
            "Browser boot and host-call behavior are outside Section 3.2.",
        ],
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--generated", type=Path, required=True)
    parser.add_argument("--output", type=Path, default=HERE / "bundle-manifest.json")
    args = parser.parse_args()
    args.output.write_text(json.dumps(generate(args.generated.resolve()), indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
