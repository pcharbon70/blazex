"""Record or publish source-frozen Phase 1 gates, retaining every failure."""
import argparse
import json
from pathlib import Path
import platform
import subprocess
import sys
import time
from research_paths import REPO_ROOT
from generate_bh05_activation import AREA, BASE
from validate_bh05_activation import validate, execution_sources, GATES
from validate_bh04_correction import bindings, execution_source_errors

HISTORICAL = "d61e103b14595acca182611524eb4c7245906f20"


def run(predecessor, historical, output):
    if output.resolve().is_relative_to(REPO_ROOT / "docs/research/assets") or not output.is_dir():
        raise ValueError("use an existing temporary output directory")
    for root, revision in [(predecessor, BASE), (historical, HISTORICAL)]:
        actual = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True).strip()
        if actual != revision:
            raise ValueError("wrong replay revision")
        subprocess.run(["git", "diff", "--exit-code", "HEAD"], cwd=root, check=True, capture_output=True)
    record = {"schema_version": "1.0.0", "phase": 1, "predecessor_revision": BASE, "historical_revision": HISTORICAL,
              "environment": {"platform": platform.platform(), "python": platform.python_version(), "node": subprocess.check_output(["node", "--version"], text=True).strip(), "elixir_image": "a2386c21edd5", "runtime_scope": "unchanged inherited packages; no BH-05 behavior"},
              "source_hashes": execution_sources(REPO_ROOT), "results": []}
    log = output / "execution.json"
    if log.exists():
        raise ValueError("do not overwrite an earlier run")
    def execute(name, command, cwd=REPO_ROOT):
        start = time.monotonic()
        try:
            r = subprocess.run(command, cwd=cwd, capture_output=True, text=True, timeout=600)
            row = {"name": name, "command": command, "cwd": str(cwd), "exit_code": r.returncode, "stdout": r.stdout, "stderr": r.stderr, "error": None}
        except (OSError, subprocess.TimeoutExpired) as error:
            row = {"name": name, "command": command, "cwd": str(cwd), "exit_code": None, "stdout": "", "stderr": "", "error": str(error)}
        row["elapsed_seconds"] = round(time.monotonic() - start, 3)
        record["results"].append(row); log.write_text(json.dumps(record, indent=2) + "\n")
        print(name + ": " + ("PASS" if row["exit_code"] == 0 else "FAIL"), flush=True)
        if row["exit_code"] != 0:
            print(row["stderr"] or row["stdout"] or row["error"], flush=True)
    mix = "set -e; for package in blazex_core blazex_effects blazex_ui_tree blazex_renderer blazex_renderer_headless blazex_renderer_dom blazex_test; do cd /workspace/packages/$package; mix format --check-formatted; mix test; done; cd /workspace/integration/conformance; mix format --check-formatted; mix test"
    execute("packages", ["docker", "run", "--rm", "--network", "none", "-v", str(REPO_ROOT) + ":/workspace", "-e", "MIX_BUILD_PATH=/tmp/bh05-phase1", "a2386c21edd5", "sh", "-c", mix])
    execute("javascript", ["bash", "-c", "node --test js/blazex_runtime/test/*.test.js && node packages/blazex_renderer_dom/js/test/dom-driver.test.js"])
    execute("predecessor-acceptance", [sys.executable, "docs/research/70-tools/validate_bh04_correction.py"], predecessor)
    execute("predecessor-generator", [sys.executable, "docs/research/70-tools/generate_bh04_correction.py", "--check"], predecessor)
    execute("historical-sweep", [sys.executable, "docs/research/70-tools/check_all.py", "--report", str(output / "historical-detail.json")], historical)
    execute("activation-tests", [sys.executable, "-m", "unittest", "discover", "-s", "docs/research/70-tools", "-p", "test_validate_bh05_activation.py"])
    execute("activation-validator", [sys.executable, "docs/research/70-tools/validate_bh05_activation.py"])
    execute("activation-generators", ["bash", "-c", "python3 docs/research/70-tools/generate_bh05_activation.py --check && python3 docs/research/70-tools/generate_bh05_boundary.py --check"])
    execute("archive", [sys.executable, "docs/research/70-tools/validate_archive.py"])
    execute("json", [sys.executable, "-c", "import json,subprocess,pathlib; files=subprocess.check_output(['git','ls-files','--cached','--others','--exclude-standard'],text=True).splitlines(); files=sorted(set(p for p in files if p.endswith('.json'))); [json.loads(pathlib.Path(p).read_text()) for p in files]; print(str(len(files))+' JSON files valid')"])
    execute("hygiene", ["git", "diff", "--check"])
    record["final_source_hashes"] = execution_sources(REPO_ROOT)
    record["historical_detail"] = json.loads((output / "historical-detail.json").read_text()) if (output / "historical-detail.json").is_file() else None
    log.write_text(json.dumps(record, indent=2) + "\n")
    return not (any(r["exit_code"] != 0 for r in record["results"]) or execution_source_errors(record, execution_sources(REPO_ROOT)))


def publish(output):
    record = json.loads((output / "execution.json").read_text())
    if validate() or execution_source_errors(record, execution_sources(REPO_ROOT)) or len(record["results"]) != len(GATES) or {r["name"] for r in record["results"]} != GATES or any(r["exit_code"] != 0 or r["error"] is not None for r in record["results"]):
        raise ValueError("cannot publish failed, incomplete or stale execution")
    target = REPO_ROOT / AREA
    with (target / "phase-01-gates-v0.1.0.json").open("x") as f:
        f.write(json.dumps(record, indent=2) + "\n")
    artifacts = [AREA + p for p in ["authorization-v0.1.0.json", "entry-ledger-v0.1.0.json", "ownership-v0.1.0.json", "phase-01-gates-v0.1.0.json"]] + ["integration/bh-05/index-v0.1.0.json", "integration/bh-05/index.schema.json"]
    completion = {"schema_version": "1.0.0", "phase": 1, "decision": "phase-1-complete-governance-only", "phase2_eligible": True, "phase2_authorized": False, "bh06_eligible": False,
                  "support_state": "unsupported", "behavior_implemented": False, "runtime_results": [], "artifact_hashes": bindings(REPO_ROOT, artifacts),
                  "delivery": "One commit per section; one PR after the gate, merge, checkout main, sync origin, then delete feature branch. External delivery remains pending at record creation."}
    with (target / "phase-01-completion-v0.1.0.json").open("x") as f:
        f.write(json.dumps(completion, indent=2) + "\n")
    errors = validate(final=True)
    if errors:
        raise ValueError("\n".join(errors))
    print("Phase 1 completion recorded; Phase 2 eligible but unauthorized.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--predecessor", type=Path)
    parser.add_argument("--historical", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--publish", action="store_true")
    args = parser.parse_args()
    if args.publish:
        publish(args.output)
    elif not args.predecessor or not args.historical:
        parser.error("replay checkout paths required")
    elif not run(args.predecessor, args.historical, args.output):
        raise SystemExit(1)
