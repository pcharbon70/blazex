#!/usr/bin/env python3
"""Build the pinned BH-01 FissionVM Wasm artifacts without network access."""

from __future__ import annotations

import argparse
import gzip
import hashlib
import json
import os
import re
import shutil
import subprocess
import tarfile
import tempfile
import zipfile
from pathlib import Path
from typing import Any


HERE = Path(__file__).resolve().parent
CONTRACT = HERE / "build-contract.json"


def load(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as stream:
        return json.load(stream)


def digest(path: Path, algorithm: str = "sha256") -> str:
    value = hashlib.new(algorithm)
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            value.update(chunk)
    return value.hexdigest()


def require_hash(path: Path, expected: str, algorithm: str = "sha256") -> None:
    observed = digest(path, algorithm)
    if observed != expected:
        raise SystemExit(f"{path}: expected {algorithm} {expected}, observed {observed}")


def safe_tar_extract(archive: Path, destination: Path) -> None:
    destination = destination.resolve()
    with tarfile.open(archive) as bundle:
        members = bundle.getmembers()
        roots = {Path(member.name).parts[0] for member in members if Path(member.name).parts}
        if len(roots) != 1:
            raise SystemExit(f"{archive}: expected exactly one archive root")
        root = next(iter(roots))
        for member in members:
            parts = Path(member.name).parts
            relative = Path(*parts[1:]) if parts and parts[0] == root else Path(member.name)
            target = (destination / relative).resolve()
            if destination != target and destination not in target.parents:
                raise SystemExit(f"{archive}: unsafe member {member.name}")
            member.name = str(relative)
        bundle.extractall(destination, members=members, filter="data")


def safe_tar_extract_with_root(archive: Path, destination: Path) -> None:
    destination = destination.resolve()
    with tarfile.open(archive) as bundle:
        members = bundle.getmembers()
        for member in members:
            target = (destination / member.name).resolve()
            if destination != target and destination not in target.parents:
                raise SystemExit(f"{archive}: unsafe member {member.name}")
        bundle.extractall(destination, members=members, filter="data")


def run(command: list[str], log: Path | None = None) -> None:
    result = subprocess.run(command, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    if log:
        log.write_text(result.stdout, encoding="utf-8")
    else:
        print(result.stdout, end="")
    if result.returncode:
        if log:
            print(result.stdout, end="")
        raise SystemExit(result.returncode)


def docker_base(contract: dict[str, Any]) -> list[str]:
    return ["docker", "run", "--rm", "--network", "none", "--user", f"{os.getuid()}:{os.getgid()}"]


def deterministic_gzip(source: Path, target: Path) -> None:
    with source.open("rb") as input_stream, target.open("wb") as output_stream:
        with gzip.GzipFile(filename="", mode="wb", compresslevel=9, fileobj=output_stream, mtime=0) as zipped:
            shutil.copyfileobj(input_stream, zipped)


def normalize_build_log(path: Path) -> None:
    """Remove parallel scheduling order while retaining the complete transcript."""
    lines = path.read_text(encoding="utf-8").splitlines()
    normalized = [re.sub(r"^\[\d+/(\d+)\]", r"[*/\1]", line) for line in lines]
    path.write_text("\n".join(sorted(normalized)) + "\n", encoding="utf-8")


def prepare_cache(contract: dict[str, Any], workspace: Path, zlib_archive: Path) -> Path:
    cache = workspace / "emscripten-cache"
    cache.mkdir()
    image = contract["image"]["reference"]
    run(docker_base(contract) + ["-v", f"{cache}:/cache", image, "bash", "-lc", "cp -a /emsdk/upstream/emscripten/cache/. /cache/"])
    ports = cache / "ports"
    ports.mkdir(exist_ok=True)
    shutil.copyfile(zlib_archive, ports / "zlib.3.1.tar.gz")
    zlib_source = ports / "zlib"
    zlib_source.mkdir()
    safe_tar_extract_with_root(zlib_archive, zlib_source)
    (zlib_source / ".emscripten_url").write_text(contract["inputs"]["zlib"]["origin"] + "\n", encoding="utf-8")
    run(docker_base(contract) + ["-v", f"{cache}:/emsdk/upstream/emscripten/cache", image, "bash", "-lc", "embuilder build zlib"])
    if not (cache / "sysroot/lib/wasm32-emscripten/libz.a").is_file():
        raise SystemExit("offline Emscripten zlib cache build produced no libz.a")
    return cache


def build_mode(
    contract: dict[str, Any],
    workspace: Path,
    output: Path,
    mode: dict[str, Any],
    fissionvm_archive: Path,
    mbedtls_archive: Path,
    ninja_archive: Path,
    gperf_archive: Path,
    cache: Path,
) -> None:
    mode_id = mode["id"]
    mode_root = workspace / mode_id
    source = mode_root / "fissionvm"
    mbedtls = mode_root / "mbedtls"
    ninja = mode_root / "ninja"
    gperf = mode_root / "gperf"
    for directory in (source, mbedtls, ninja, gperf):
        directory.mkdir(parents=True)
    safe_tar_extract(fissionvm_archive, source)
    safe_tar_extract(mbedtls_archive, mbedtls)
    with zipfile.ZipFile(ninja_archive) as bundle:
        if bundle.namelist() != ["ninja"]:
            raise SystemExit("Ninja archive inventory differs from the qualified input")
        bundle.extractall(ninja)
    (ninja / "ninja").chmod(0o555)
    run(["dpkg-deb", "-x", str(gperf_archive), str(gperf)])
    require_hash(ninja / "ninja", contract["inputs"]["ninja"]["binary_sha256"])
    require_hash(gperf / "usr/bin/gperf", contract["inputs"]["gperf"]["binary_sha256"])

    destination = output / mode_id
    if destination.exists() and any(destination.iterdir()):
        raise SystemExit(f"refusing dirty output directory: {destination}")
    (destination / "cmake").mkdir(parents=True, exist_ok=True)
    (destination / "artifacts").mkdir()

    prefix_flags = " ".join(contract["cmake"]["prefix_maps"])
    configure = [
        "emcmake", "cmake", "-G", "Ninja",
        f"-DCMAKE_BUILD_TYPE={mode['cmake_build_type']}",
        "-DAVM_BUILD_RUNTIME_ONLY=1",
        f"-DAVM_EMSCRIPTEN_ENV={mode['emscripten_environment']}",
        "-DFETCHCONTENT_FULLY_DISCONNECTED=ON",
        "-DFETCHCONTENT_SOURCE_DIR_MBEDTLS=/inputs/mbedtls",
        f"-DCMAKE_C_FLAGS={prefix_flags}",
        f"-DCMAKE_CXX_FLAGS={prefix_flags}",
        "/inputs/fissionvm/src/platforms/emscripten",
    ]
    quoted_configure = " ".join(subprocess.list2cmdline([item]) for item in configure)
    shell = (
        "export PATH=/opt/ninja:/opt/gperf:/emsdk/upstream/bin:/emsdk/upstream/emscripten:$PATH; "
        "cd /outputs/cmake; " + quoted_configure + "; "
        f"ninja -j{contract['environment']['jobs']} AtomVM; "
        "cp src/AtomVM.wasm src/AtomVM.mjs /outputs/artifacts/"
    )
    image = contract["image"]["reference"]
    command = docker_base(contract) + [
        "-e", "SOURCE_DATE_EPOCH=0", "-e", "TZ=UTC", "-e", "LC_ALL=C", "-e", "PYTHONHASHSEED=0",
        "-v", f"{ninja}:/opt/ninja:ro",
        "-v", f"{gperf / 'usr/bin'}:/opt/gperf:ro",
        "-v", f"{cache}:/emsdk/upstream/emscripten/cache",
        "-v", f"{source}:/inputs/fissionvm:ro",
        "-v", f"{mbedtls}:/inputs/mbedtls:ro",
        "-v", f"{destination}:/outputs",
        image, "bash", "-lc", shell,
    ]
    build_log = destination / "build.log"
    run(command, build_log)
    normalize_build_log(build_log)
    for name in ("AtomVM.wasm", "AtomVM.mjs"):
        artifact = destination / "artifacts" / name
        if not artifact.is_file():
            raise SystemExit(f"{mode_id}: missing {name}")
        deterministic_gzip(artifact, artifact.with_suffix(artifact.suffix + ".gz"))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--contract", type=Path, default=CONTRACT)
    parser.add_argument("--fissionvm", type=Path, required=True)
    parser.add_argument("--mbedtls", type=Path, required=True)
    parser.add_argument("--ninja", type=Path, required=True)
    parser.add_argument("--gperf", type=Path, required=True)
    parser.add_argument("--zlib", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--mode", action="append", dest="modes")
    args = parser.parse_args()
    args.contract = args.contract.resolve()
    args.fissionvm = args.fissionvm.resolve()
    args.mbedtls = args.mbedtls.resolve()
    args.ninja = args.ninja.resolve()
    args.gperf = args.gperf.resolve()
    args.zlib = args.zlib.resolve()
    args.output = args.output.resolve()
    contract = load(args.contract)
    paths = {
        "fissionvm": args.fissionvm,
        "mbedtls": args.mbedtls,
        "ninja": args.ninja,
        "gperf": args.gperf,
        "zlib": args.zlib,
    }
    for name, path in paths.items():
        require_hash(path, contract["inputs"][name]["sha256"])
    selected = args.modes or [mode["id"] for mode in contract["modes"]]
    modes = {mode["id"]: mode for mode in contract["modes"]}
    unknown = set(selected) - set(modes)
    if unknown:
        raise SystemExit(f"unknown modes: {sorted(unknown)}")
    args.output.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="blazex-bh01-runtime-") as temporary:
        workspace = Path(temporary)
        cache = prepare_cache(contract, workspace, args.zlib)
        for mode_id in selected:
            build_mode(
                contract, workspace, args.output, modes[mode_id],
                args.fissionvm, args.mbedtls, args.ninja, args.gperf, cache,
            )
    print(f"BH-01 runtime build: PASS ({', '.join(selected)})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
