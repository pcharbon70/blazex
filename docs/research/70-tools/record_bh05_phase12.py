"""Run the final BH-05 Phase 12 source-frozen meta-gates and publish revise evidence."""
import argparse
import json
import os
import platform
import subprocess
import sys
import time
from pathlib import Path

from research_paths import REPO_ROOT
from validate_bh05_acceptance import (
    AREA, COMPLETION_FILE, GATE_FILE, completion, gate_errors, sources, validate,
)


def run(args):
    log = args.output / "execution.json"
    if log.exists() or not args.output.is_dir() or args.output.resolve().is_relative_to(REPO_ROOT):
        raise ValueError("fresh external output required")
    record = {
        "schema_version": "1.0.0", "phase": 12, "decision": "revise",
        "active_product_blocker": "BH05-ACTIVE-FIREFOX-CLEANUP-DIVERGENCE",
        "environment": {"python": platform.python_version(), "node": subprocess.check_output(["node", "--version"], text=True).strip(),
                        "elixir_image": "a2386c21edd5", "active": ["ERTS/headless", "Linux Chrome AtomVM/DOM", "Linux Firefox development AtomVM/DOM", "GTK portability"]},
        "source_hashes": sources(), "results": [],
    }

    def execute(name, command, cwd=REPO_ROOT):
        started = time.monotonic()
        try:
            result = subprocess.run(command, cwd=cwd, capture_output=True, text=True, timeout=1200)
            row = {"name": name, "command": command, "cwd": str(cwd), "exit_code": result.returncode,
                   "stdout": result.stdout, "stderr": result.stderr, "error": None}
        except (OSError, subprocess.TimeoutExpired) as error:
            row = {"name": name, "command": command, "cwd": str(cwd), "exit_code": None,
                   "stdout": "", "stderr": "", "error": str(error)}
        row["elapsed_seconds"] = round(time.monotonic() - started, 3)
        record["results"].append(row)
        log.write_text(json.dumps(record, indent=2) + "\n")
        print(name + (": PASS" if row["exit_code"] == 0 else ": FAIL"), flush=True)

    docker = ["docker", "run", "--rm", "--network", "none", "--user", f"{os.getuid()}:{os.getgid()}",
              "-v", str(REPO_ROOT) + ":/workspace:ro", "-v", str(args.output) + ":/output",
              "-e", "MIX_BUILD_PATH=/tmp/bh05-phase12-final", "a2386c21edd5"]
    execute("packages", docker + ["sh", "-c", "set -e; for p in blazex_core blazex_effects blazex_ui_tree blazex_renderer blazex_renderer_headless blazex_renderer_dom blazex_test; do cd /workspace/packages/$p; mix format --check-formatted; mix test; done; cd /workspace/integration/conformance; mix format --check-formatted; mix test"])
    execute("browser-project", docker + ["sh", "-c", "cd /workspace/integration/bh-05/browser_conformance; MIX_ENV=prod MIX_BUILD_PATH=/tmp/bh05-browser mix format --check-formatted; MIX_ENV=prod MIX_BUILD_PATH=/tmp/bh05-browser mix bh05.browser_package --out-dir /output/bundle"])
    execute("javascript", ["bash", "-c", "node --test js/blazex_runtime/test/*.test.js && node packages/blazex_renderer_dom/js/test/dom-driver.test.js"])
    execute("count-evidence", [sys.executable, "docs/research/70-tools/validate_bh05_acceptance_counts.py"])
    execute("cleanup-evidence", [sys.executable, "docs/research/70-tools/validate_bh05_acceptance_cleanup.py"])
    browser = args.output / "browser-cleanup.json"
    browser_command = (
        f"node integration/bh-05/browser_conformance/run-acceptance-counts.mjs {browser} {args.output}/bundle/bundle.avm measure-cleanup; "
        "status=$?; test $status -eq 1; "
        f"python3 docs/research/70-tools/validate_bh05_acceptance_cleanup.py --browser-observation {browser}"
    )
    execute("browser-cleanup-repeat", ["bash", "-c", browser_command])
    execute("phase11-replay", ["bash", "-c", "python3 docs/research/70-tools/validate_bh05_conformance.py --final && python3 docs/research/70-tools/generate_bh05_conformance.py --check"], args.phase11)
    execute("historical-sweep", [sys.executable, "docs/research/70-tools/check_all.py", "--report", str(args.output / "historical.json")], args.historical)
    execute("release-reconciliation", ["bash", "-c", "python3 docs/research/70-tools/generate_bh05_reconciliation.py --check && python3 docs/research/70-tools/validate_bh05_reconciliation.py && python3 docs/research/70-tools/generate_bh05_release.py --check && python3 docs/research/70-tools/validate_bh05_release.py"])
    execute("archive", [sys.executable, "docs/research/70-tools/validate_archive.py"])
    execute("json", [sys.executable, "-c", "import json,pathlib,subprocess;p=[x for x in subprocess.check_output(['git','ls-files','--cached','--others','--exclude-standard'],text=True).splitlines() if x.endswith('.json')];[json.loads(pathlib.Path(x).read_text()) for x in p];print(len(p),'JSON files valid')"])
    execute("clean-repeat", docker + ["sh", "-c", "cd /workspace/packages/blazex_core; MIX_BUILD_PATH=/tmp/bh05-clean-repeat mix test; cd /workspace/integration/conformance; MIX_BUILD_PATH=/tmp/bh05-clean-repeat mix test test/bh05_recovery_test.exs"])
    execute("hygiene", ["git", "diff", "--check", "HEAD"])
    record["final_source_hashes"] = sources()
    log.write_text(json.dumps(record, indent=2) + "\n")
    return not gate_errors(record, sources())


def publish(output):
    record = json.loads((output / "execution.json").read_text())
    if validate() or gate_errors(record, sources()):
        raise ValueError("cannot publish stale or incomplete Phase 12 evidence")
    with (REPO_ROOT / GATE_FILE).open("x") as stream:
        stream.write(json.dumps(record, indent=2) + "\n")
    with (REPO_ROOT / COMPLETION_FILE).open("x") as stream:
        stream.write(json.dumps(completion(), indent=2) + "\n")
    print("BH-05 Phase 12 complete with decision REVISE; BH-06 remains ineligible and unauthorized.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--phase11", type=Path)
    parser.add_argument("--historical", type=Path)
    parser.add_argument("--publish", action="store_true")
    args = parser.parse_args()
    if args.publish:
        publish(args.output)
    elif not args.phase11 or not args.historical:
        parser.error("--phase11 and --historical replay paths are required")
    elif not run(args):
        raise SystemExit(1)
