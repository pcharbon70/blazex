#!/usr/bin/env python3
"""Build and exercise the direct GTK 4 adapter, optionally recording evidence."""

import argparse
import json
import pathlib
import platform
import subprocess


ROOT = pathlib.Path(__file__).resolve().parent.parent


def command(*args: str) -> str:
    return subprocess.run(args, cwd=ROOT, check=True, text=True, capture_output=True).stdout.strip()


def package_version(name: str) -> str:
    return command("dpkg-query", "-W", "-f=${Version}", name)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=pathlib.Path)
    args = parser.parse_args()

    binary = command("bash", "scripts/build_gtk4.sh")
    run = subprocess.run(
        [
            "xvfb-run",
            "-a",
            binary,
            "fixtures/representative-v0.1.0.bxn1",
            "fixtures/stale-update-v0.1.0.bxn1",
        ],
        cwd=ROOT,
        check=False,
        text=True,
        capture_output=True,
    )
    lines = run.stdout.splitlines()
    controls = [line.split("\t")[1:] for line in lines if line.startswith("CONTROL\t")]
    services = [line.split("\t")[1:] for line in lines if line.startswith("SERVICE\t")]
    result = next((line for line in lines if line.startswith("RESULT\t")), "")
    passed = run.returncode == 0 and result.startswith("RESULT\tpassed\t")

    evidence = {
        "schema_version": "1.0.0",
        "experiment": "BH-02 Phase 7 direct GTK native-control spike",
        "support_state": "experimental-unsupported",
        "result": "passed" if passed else "failed",
        "environment": {
            "kernel": platform.release(),
            "architecture": platform.machine(),
            "compiler": command("cc", "--version").splitlines()[0],
            "gtk_runtime_package": package_version("libgtk-4-1"),
            "glib_runtime_package": package_version("libglib2.0-0t64"),
            "display": "xvfb-run -a",
        },
        "controls": [
            {"semantic_kind": semantic_kind, "native_type": native_type, "accessible_role": role}
            for semantic_kind, native_type, role in controls
        ],
        "services": [{"intent": intent, "native_type": native_type} for intent, native_type in services],
        "observation": result,
        "deferred": [
            "Windows compile and execution",
            "macOS compile and execution",
            "platform accessibility-tree inspection",
            "manual screen-reader behavior",
            "IME and file-dialog interaction",
            "geometry, pixels, performance, and packaging",
        ],
    }
    if args.output:
        args.output.write_text(json.dumps(evidence, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(evidence, sort_keys=True))
    if not passed:
        if run.stderr:
            print(run.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
