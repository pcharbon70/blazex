"""Record all Phase 9 gates against an unchanged source closure; publish only passes."""
import argparse
import json
import os
from pathlib import Path
import platform
import subprocess
import sys
import time
from research_paths import REPO_ROOT
from generate_bh05_scopes import BASE, AREA
from validate_bh05_scopes import completion, gate_errors, sources, validate


def run(args):
    revisions = [(args.phase8, BASE), (args.phase7, "08dec098fde98b506d554bf8c3ff64bc65de6add"), (args.phase6, "e373e96891207ea4b6c2fdfae9533181334b3cab"), (args.phase5, "f2fdc745118f0ad84e5b3ab53ea9e5221310f957"), (args.phase4, "ea09d05a2709a163ff0c8776c4039f1a712a95de"), (args.phase3, "fc5048d4db7cc80fd21b492e0638182abceda1af"), (args.phase2, "5cd382c23c5589404efc8dd7121432dd24c4cd96"),
                 (args.phase1, "968013b9794664fc454619ee08788c3d0c39551f"),
                 (args.predecessor, "506c254ddd4a14dd8d1d4cbdba8fcf9556bd15cb"),
                 (args.historical, "d61e103b14595acca182611524eb4c7245906f20")]
    for root, revision in revisions:
        if subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True).strip() != revision: raise ValueError("wrong replay checkout")
        subprocess.run(["git", "diff", "--exit-code", "HEAD"], cwd=root, capture_output=True, check=True)
    log = args.output / "execution.json"
    if log.exists() or not args.output.is_dir() or args.output.resolve().is_relative_to(REPO_ROOT): raise ValueError("use a fresh external temporary output directory")
    record = {"schema_version": "1.0.0", "phase": 9, "predecessor_revision": BASE,
              "environment": {"python": platform.python_version(), "node": subprocess.check_output(["node", "--version"], text=True).strip(), "elixir_image": "a2386c21edd5", "elixir": "1.17.3", "otp": "26.0.2", "scope": "ERTS scoped context and bounded registry and independent headless oracle; AtomVM API/patch analysis only, no execution parity"},
              "source_hashes": sources(REPO_ROOT), "results": []}
    def execute(name, command, cwd=REPO_ROOT):
        start = time.monotonic()
        try:
            result = subprocess.run(command, cwd=cwd, capture_output=True, text=True, timeout=600)
            row = {"name": name, "command": command, "cwd": str(cwd), "exit_code": result.returncode, "stdout": result.stdout, "stderr": result.stderr, "error": None}
        except (OSError, subprocess.TimeoutExpired) as error:
            row = {"name": name, "command": command, "cwd": str(cwd), "exit_code": None, "stdout": "", "stderr": "", "error": str(error)}
        row["elapsed_seconds"] = round(time.monotonic() - start, 3)
        record["results"].append(row)
        log.write_text(json.dumps(record, indent=2) + "\n")
        print(name + (": PASS" if row["exit_code"] == 0 else ": FAIL"), flush=True)
        if row["exit_code"] != 0: print(row["stderr"] or row["stdout"], flush=True)
    docker = ["docker", "run", "--rm", "--network", "none", "--user", f"{os.getuid()}:{os.getgid()}", "-v", str(REPO_ROOT) + ":/workspace:ro", "-w", "/workspace", "-e", "MIX_BUILD_PATH=/tmp/bh05-phase9", "a2386c21edd5"]
    mix = "set -e; for package in blazex_core blazex_effects blazex_ui_tree blazex_renderer blazex_renderer_headless blazex_renderer_dom blazex_test; do cd /workspace/packages/$package; mix format --check-formatted; mix test; done; cd /workspace/integration/conformance; mix format --check-formatted; mix test"
    execute("packages", docker + ["sh", "-c", mix])
    execute("javascript", ["bash", "-c", "node --test js/blazex_runtime/test/*.test.js && node packages/blazex_renderer_dom/js/test/dom-driver.test.js"])
    execute("compile-fixtures", docker + ["sh", "-c", "mix format --check-formatted integration/bh-05/*.exs && elixir integration/bh-05/authoring-check.exs && elixir integration/bh-05/schema-check.exs"])
    execute("scope-subset", [sys.executable, "docs/research/70-tools/check_bh05_scope_subset.py"])
    execute("phase8-replay", ["bash", "-c", "python3 docs/research/70-tools/validate_bh05_actions.py --final && python3 docs/research/70-tools/generate_bh05_actions.py --check && python3 -m unittest discover -s docs/research/70-tools -p test_validate_bh05_actions.py"], args.phase8)
    execute("phase7-replay", ["bash", "-c", "python3 docs/research/70-tools/validate_bh05_scheduling.py --final && python3 docs/research/70-tools/generate_bh05_scheduling.py --check && python3 -m unittest discover -s docs/research/70-tools -p test_validate_bh05_scheduling.py"], args.phase7)
    execute("phase6-replay", ["bash", "-c", "python3 docs/research/70-tools/validate_bh05_roots.py --final && python3 docs/research/70-tools/generate_bh05_roots.py --check && python3 -m unittest discover -s docs/research/70-tools -p test_validate_bh05_roots.py"], args.phase6)
    execute("phase5-replay", ["bash", "-c", "python3 docs/research/70-tools/validate_bh05_nested.py --final && python3 docs/research/70-tools/generate_bh05_nested.py --check && python3 -m unittest discover -s docs/research/70-tools -p test_validate_bh05_nested.py"], args.phase5)
    execute("phase4-replay", ["bash", "-c", "python3 docs/research/70-tools/validate_bh05_composition.py --final && python3 docs/research/70-tools/generate_bh05_composition.py --check && python3 -m unittest discover -s docs/research/70-tools -p test_validate_bh05_composition.py"], args.phase4)
    execute("phase3-replay", ["bash", "-c", "python3 docs/research/70-tools/validate_bh05_schema.py --final && python3 docs/research/70-tools/generate_bh05_schema.py --check && python3 -m unittest discover -s docs/research/70-tools -p test_validate_bh05_schema.py"], args.phase3)
    execute("phase2-replay", ["bash", "-c", "python3 docs/research/70-tools/validate_bh05_authoring.py --final && python3 docs/research/70-tools/generate_bh05_authoring.py --check && python3 -m unittest discover -s docs/research/70-tools -p test_validate_bh05_authoring.py"], args.phase2)
    execute("phase1-replay", ["bash", "-c", "python3 docs/research/70-tools/validate_bh05_activation.py --final && python3 docs/research/70-tools/generate_bh05_activation.py --check && python3 docs/research/70-tools/generate_bh05_boundary.py --check && python3 -m unittest discover -s docs/research/70-tools -p test_validate_bh05_activation.py"], args.phase1)
    execute("predecessor-replay", ["bash", "-c", "python3 docs/research/70-tools/validate_bh04_correction.py && python3 docs/research/70-tools/generate_bh04_correction.py --check"], args.predecessor)
    execute("historical-sweep", [sys.executable, "docs/research/70-tools/check_all.py", "--report", str(args.output / "historical-detail.json")], args.historical)
    execute("scope-tests", [sys.executable, "-m", "unittest", "discover", "-s", "docs/research/70-tools", "-p", "test_validate_bh05_scopes.py"])
    execute("scope-validator", [sys.executable, "docs/research/70-tools/validate_bh05_scopes.py"])
    execute("scope-generator", [sys.executable, "docs/research/70-tools/generate_bh05_scopes.py", "--check"])
    execute("archive", [sys.executable, "docs/research/70-tools/validate_archive.py"])
    execute("json", [sys.executable, "-c", "import json,pathlib,subprocess; paths=sorted(set(subprocess.check_output(['git','ls-files','--cached','--others','--exclude-standard'],text=True).splitlines())); paths=[p for p in paths if p.endswith('.json')]; [json.loads(pathlib.Path(p).read_text()) for p in paths]; print(len(paths),'JSON files valid')"])
    execute("hygiene", ["git", "diff", "--check", "HEAD"])
    record["final_source_hashes"] = sources(REPO_ROOT)
    detail = args.output / "historical-detail.json"
    record["historical_detail"] = json.loads(detail.read_text()) if detail.exists() else None
    log.write_text(json.dumps(record, indent=2) + "\n")
    return not gate_errors(record, sources(REPO_ROOT))


def publish(output):
    record = json.loads((output / "execution.json").read_text())
    if validate() or gate_errors(record, sources(REPO_ROOT)): raise ValueError("cannot publish failed/incomplete/stale evidence")
    for name, data in [("scope-gates-v0.1.0.json", record), ("scope-completion-v0.1.0.json", None)]:
        data = completion(REPO_ROOT) if data is None else data
        with (REPO_ROOT / AREA / name).open("x") as target: target.write(json.dumps(data, indent=2) + "\n")
    errors = validate(final=True)
    if errors: raise ValueError("\n".join(errors))
    print("Phase 9 scoped context/registry complete; Phase 10 eligible, unauthorized.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ["output", "phase8", "phase7", "phase6", "phase5", "phase4", "phase3", "phase2", "phase1", "predecessor", "historical"]:
        parser.add_argument("--" + name, type=Path, required=name == "output")
    parser.add_argument("--publish", action="store_true")
    args = parser.parse_args()
    if args.publish: publish(args.output)
    elif not all([args.phase8, args.phase7, args.phase6, args.phase5, args.phase4, args.phase3, args.phase2, args.phase1, args.predecessor, args.historical]): parser.error("all replay paths required")
    elif not run(args): raise SystemExit(1)
