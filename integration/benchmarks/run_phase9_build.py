#!/usr/bin/env python3
"""Measure deterministic Phase 9 profile packaging from declared inputs."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
import tempfile
import time
from datetime import datetime, timezone
from pathlib import Path

from phase9_metrics import sha256


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
BUILDER = ROOT / "profiles/browser_phoenix/assets/phase4/build_profile.py"


def build_once(output: Path) -> tuple[float, str]:
    command = [sys.executable, str(BUILDER), "--output", str(output)]
    started = time.perf_counter()
    result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, check=False)
    duration = time.perf_counter() - started
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or result.stdout.strip() or "profile build failed")
    manifest = output / "profile-assets-manifest.json"
    if not manifest.is_file():
        raise RuntimeError("profile build omitted its canonical asset manifest")
    return duration, sha256(manifest)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--revision", required=True)
    parser.add_argument("--environment-id", required=True)
    parser.add_argument("--samples", type=int, default=10)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if len(args.revision) != 40 or any(char not in "0123456789abcdef" for char in args.revision):
        raise SystemExit("--revision must be an exact lowercase commit")
    if args.samples < 10:
        raise SystemExit("--samples must satisfy the governed minimum of ten")

    samples = []
    with tempfile.TemporaryDirectory(prefix="blazex-phase9-build-") as directory:
        root = Path(directory)
        build_once(root / "warmup")
        for iteration in range(1, args.samples + 1):
            duration, digest = build_once(root / f"sample-{iteration:02d}")
            samples.append({
                "iteration": iteration,
                "seconds": round(duration, 9),
                "manifest_sha256": digest,
                "status": "passed",
            })
    digests = {sample["manifest_sha256"] for sample in samples}
    if len(digests) != 1:
        raise SystemExit("profile packaging output is not byte-stable")

    record = {
        "schema_version": "1.0.0",
        "run_id": "BX-BH01-PHASE9-RUN-BUILD-LINUX-0.1",
        "status": "observed",
        "captured_at": datetime.now(timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z"),
        "source_revision": args.revision,
        "environment_id": args.environment_id,
        "command": ["python3", "profiles/browser_phoenix/assets/phase4/build_profile.py", "--output", "<isolated-temporary-directory>"],
        "clock": "python-time-perf-counter-monotonic",
        "discarded_warmups": 1,
        "samples": samples,
        "output_manifest_sha256": next(iter(digests)),
        "failures": [],
        "limitations": [
            "This measures dependency-cached deterministic profile packaging, not a clean AtomVM/Popcorn source rebuild.",
            "The local workstation exceeds the minimum CI reference hardware and is development evidence only."
        ]
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
    print(f"BH-01 Phase 9 build measurement: OBSERVED ({len(samples)} samples)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
