#!/usr/bin/env python3
"""Run every research test, validator, and generator check without recording acceptance."""

import argparse
import ast
import json
from pathlib import Path
import subprocess
import sys
import time

from research_paths import REPO_ROOT, TOOLS_ROOT


def commands():
    yield "tests", [sys.executable, "-m", "unittest", "discover",
                    "-s", str(TOOLS_ROOT), "-p", "test_*.py"]
    for path in sorted(TOOLS_ROOT.glob("validate_*.py")):
        yield path.name, [sys.executable, str(path)]
    for path in sorted(TOOLS_ROOT.glob("generate_*.py")):
        yield path.name, [sys.executable, str(path), "--check"]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report", type=Path, help="optional JSON execution log outside immutable evidence")
    parser.add_argument("--timeout", type=float, default=600, help="seconds allowed per command")
    args = parser.parse_args()
    if args.timeout <= 0:
        parser.error("--timeout must be positive")
    if args.report and args.report.resolve().is_relative_to(REPO_ROOT / "docs/research/assets"):
        parser.error("do not overwrite immutable research evidence; use a temporary report path")
    for path in sorted(TOOLS_ROOT.glob("*.py")):
        ast.parse(path.read_text(), filename=str(path))
    results = []
    for name, command in commands():
        start = time.monotonic()
        try:
            run = subprocess.run(command, cwd=REPO_ROOT, capture_output=True,
                                 text=True, timeout=args.timeout)
            row = dict(name=name, command=command, exit_code=run.returncode,
                       stdout=run.stdout, stderr=run.stderr, error=None)
        except (OSError, subprocess.TimeoutExpired) as error:
            row = dict(name=name, command=command, exit_code=None,
                       stdout="", stderr="", error=str(error))
        row["elapsed_seconds"] = round(time.monotonic() - start, 3)
        results.append(row)
        print(f"{name}: {'PASS' if row['exit_code'] == 0 else 'FAIL'}", flush=True)
        if row["exit_code"] != 0:
            print(row["stderr"] or row["stdout"] or row["error"], flush=True)
        if args.report:
            args.report.write_text(json.dumps({"results": results}, indent=2) + "\n")
    return 0 if all(row["exit_code"] == 0 for row in results) else 1


if __name__ == "__main__":
    raise SystemExit(main())
