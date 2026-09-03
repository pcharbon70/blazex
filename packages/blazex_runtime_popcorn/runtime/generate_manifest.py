#!/usr/bin/env python3
"""Generate the stable Phase 3 runtime artifact and binary manifest."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Any

from inspect_wasm import inspect


HERE = Path(__file__).resolve().parent


def load(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as stream:
        return json.load(stream)


def digest(path: Path) -> str:
    value = hashlib.sha256()
    value.update(path.read_bytes())
    return value.hexdigest()


def artifact(mode: dict[str, Any], root: Path, name: str) -> dict[str, Any]:
    is_log = name == "build.log"
    path = root / mode["id"] / (name if is_log else f"artifacts/{name}")
    suffix = ".wasm" if ".wasm" in name else ".mjs"
    kind = (
        "build-log"
        if is_log
        else "wasm"
        if name == "AtomVM.wasm"
        else "javascript"
        if name == "AtomVM.mjs"
        else "compressed"
    )
    mime = "text/plain" if is_log else "application/wasm" if suffix == ".wasm" else "text/javascript"
    item = {
        "artifact_id": f"BX-BH01-RUNTIME-{mode['id'].upper()}-{name.upper().replace('.', '-')}",
        "mode": mode["id"],
        "kind": kind,
        "path": f"generated/{mode['id']}/{name if is_log else f'artifacts/{name}'}",
        "sha256": digest(path),
        "bytes": path.stat().st_size,
        "mime": mime,
        "content_encoding": "gzip" if name.endswith(".gz") else None,
        "owner": "packages/blazex_runtime_popcorn/runtime",
        "reachability_root": "build-evidence" if is_log else "browser-runtime" if mode["deployable"] else "phase3-node-probe",
        "deployable": mode["deployable"] and not is_log,
        "build_lineage": "BX-BH01-RUNTIME-BUILD-0.1",
        "provenance": "checksum-qualified FissionVM/Mbed TLS sources built in the digest-pinned Emscripten image with networking disabled",
        "source_map_policy": "not-applicable build log" if is_log else mode["id"],
        "license_record_ids": [
            "BX-BH01-LICENSE-FISSIONVM",
            "BX-BH01-LICENSE-MBEDTLS",
            "BX-BH01-LICENSE-EMSCRIPTEN",
            "BX-BH01-LICENSE-NINJA",
            "BX-BH01-LICENSE-GPERF",
            "BX-BH01-LICENSE-ZLIB",
        ],
    }
    if name.endswith(".gz"):
        raw_name = name[:-3]
        item["uncompressed_artifact_id"] = (
            f"BX-BH01-RUNTIME-{mode['id'].upper()}-{raw_name.upper().replace('.', '-')}"
        )
        item["uncompressed_bytes"] = (path.parent / raw_name).stat().st_size
    return item


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--artifacts", type=Path, required=True)
    parser.add_argument("--output", type=Path, default=HERE / "runtime-binary-manifest.json")
    args = parser.parse_args()
    root = args.artifacts.resolve()
    contract_path = HERE / "build-contract.json"
    contract = load(contract_path)
    artifacts = []
    inspections = []
    glue = []
    for mode in contract["modes"]:
        artifacts.extend(
            artifact(mode, root, name)
            for name in ("AtomVM.wasm", "AtomVM.mjs", "AtomVM.wasm.gz", "AtomVM.mjs.gz", "build.log")
        )
        wasm = root / mode["id"] / "artifacts/AtomVM.wasm"
        wasm_inspection = inspect(wasm)
        wasm_inspection["mode"] = mode["id"]
        inspections.append(wasm_inspection)
        mjs = root / mode["id"] / "artifacts/AtomVM.mjs"
        data = mjs.read_bytes()
        forbidden = [needle.decode() for needle in (b"/home/", b"/tmp/", b"/inputs/", b"/outputs/", b"BEGIN PRIVATE KEY", b"AWS_SECRET_ACCESS_KEY") if needle in data]
        glue.append({
            "mode": mode["id"],
            "sha256": digest(mjs),
            "bytes": len(data),
            "forbidden_embedded_strings": forbidden,
            "uses_worker": b"Worker" in data,
            "uses_shared_array_buffer": b"SharedArrayBuffer" in data,
            "uses_indirect_eval": b"indirectEval" in data,
            "external_source_map_reference": b"sourceMappingURL=" in data,
        })
    manifest = {
        "schema_version": "1.0.0",
        "manifest_id": "BX-BH01-RUNTIME-BINARY-MANIFEST-0.1",
        "status": "observed-pass",
        "build_contract": "build-contract.json",
        "build_contract_sha256": digest(contract_path),
        "source_revision": contract["inputs"]["fissionvm"]["commit"],
        "artifacts": artifacts,
        "embedded_artifacts": [
            {
                "artifact_id": "BX-BH01-RUNTIME-DEBUG-WEB-EMBEDDED-DEBUG-SECTIONS",
                "kind": "embedded-debug-symbols",
                "carrier_artifact_id": "BX-BH01-RUNTIME-DEBUG-WEB-ATOMVM-WASM",
                "sections": ["name", ".debug_loc", ".debug_abbrev", ".debug_info", ".debug_ranges", ".debug_str", ".debug_line", ".debug_aranges"],
                "source_map_policy": "embedded DWARF/name sections only; no external source map",
            }
        ],
        "omission_records": [
            {
                "artifact_id": "BX-BH01-RUNTIME-EXTERNAL-SOURCE-MAPS-NOT-EMITTED",
                "kind": "source-map-omission",
                "applies_to_modes": [mode["id"] for mode in contract["modes"]],
                "reason": "The pinned Emscripten commands emit no external source map; debug information is embedded only in debug-web.",
            }
        ],
        "wasm_inspections": inspections,
        "javascript_inspections": glue,
        "source_map_policy": {
            "debug-web": "DWARF custom sections and names are embedded with canonical relative prefixes; no external map is emitted.",
            "release-web": "Names and DWARF are stripped; no external map is emitted.",
            "release-node-probe": "Names and DWARF are stripped; no external map is emitted; artifact is not deployable."
        },
        "abi_interpretation": {
            "target": "emscripten-js",
            "wasi_target": False,
            "wasi_snapshot_preview1_imports": "Emscripten-generated JavaScript ABI shims",
            "component_model": False,
            "shared_memory": "one imported 256-page minimum/maximum shared memory",
            "threads": True,
        },
        "limitations": [
            "A successful build and binary inspection do not prove browser boot.",
            "The Node mode is a non-deployable semantic probe harness.",
            "The Emscripten glue retains upstream indirect-eval behavior for later CSP testing.",
            "Payload observations are preliminary and do not pass any proposed budget."
        ],
    }
    args.output.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"BH-01 runtime manifest: PASS ({len(artifacts)} artifacts, {len(inspections)} Wasm inspections)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
