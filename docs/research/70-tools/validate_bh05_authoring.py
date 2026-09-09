"""Validate Phase 2 boundaries and source-frozen evidence without rewriting Phase 1."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys
from research_paths import REPO_ROOT
from generate_bh05_authoring import BASE, AREA, PLAN, TARGET, authority
from validate_bh04_correction import immutable_input_errors

CORE = "packages/blazex_core/"
TOOLS = "docs/research/70-tools/"
NEW = {CORE + "lib/blazex/component.ex", CORE + "lib/blazex/core/authoring.ex"} | {
    CORE + "lib/blazex/component/" + p + ".ex" for p in ["contract", "pure", "stateful", "root", "input", "result"]} | {
    CORE + "test/blazex/" + p + ".exs" for p in ["component_contract_test", "authoring_test"]} | {
    TOOLS + p + ".py" for p in ["generate_bh05_authoring", "check_bh05_subset", "validate_bh05_authoring", "test_validate_bh05_authoring", "record_bh05_phase2"]} | {
    "integration/bh-05/" + p for p in ["authoring-fixtures.exs", "authoring-check.exs", "authoring-subset.exs", "authoring-index-v0.1.0.json"]} | {
    TARGET, AREA + "authoring-gates-v0.1.0.json", AREA + "authoring-completion-v0.1.0.json",
    PLAN + "authoring-contract.md", PLAN + "authoring-evidence.md"}
DOCS = {CORE + "README.md", TOOLS + "README.md", AREA + "README.md", PLAN + "README.md", "integration/bh-05/README.md"}
GATES = ["packages", "javascript", "compile-fixtures", "atomvm-subset", "phase1-replay", "predecessor-replay", "historical-sweep", "authoring-tests", "authoring-validator", "authoring-generator", "archive", "json", "hygiene"]
RUNTIME = ["BlazeX.Component." + p for p in ["Contract", "Input", "Result", "Pure", "Stateful", "Root"]]


def sha(data):
    return hashlib.sha256(data).hexdigest()


def files(root):
    return sorted(set(subprocess.check_output(["git", "ls-files", "--cached", "--others", "--exclude-standard"], cwd=root, text=True).splitlines()))


def sources(root):
    paths = [p for p in files(root) if p.startswith(("packages/", "js/", "integration/", "profiles/", "experiments/", TOOLS))]
    paths += [TARGET, PLAN + "authoring-contract.md"]
    return {p: sha((root / p).read_bytes()) for p in paths if not p.endswith(".md") or p == PLAN + "authoring-contract.md"}


def inventory(root):
    return {"schema_version": "1.0.0", "phase": 2, "status": "candidate-contract-only",
            "support_state": "unsupported", "version": "0.1.0-bh05-candidate",
            "public": ["BlazeX.Component"] + RUNTIME, "private_build": ["BlazeX.Core.Authoring"],
            "roles": {"pure": {"required": ["render"], "optional": []},
                      "stateful": {"required": ["init", "render"], "optional": ["update", "handle_event", "handle_info", "replace", "dispose"]},
                      "root": {"required": ["mount", "render"], "optional": ["update", "handle_event", "handle_info", "commit_ack", "effect_result", "failure", "retry", "replace", "terminate"]}},
            "files": {p: sha((root / p).read_bytes()) for p in sorted(NEW) if p.endswith((".ex", ".exs"))},
            "runtime_execution": False, "schema_execution": False, "effect_execution": False,
            "later_evidence": [], "limits": ["128 candidate actions", "portable shape is not a semantic tree or schema pass", "compiler/analyzer is not AtomVM execution parity", "compile-time macros are trusted build code", "LiveView and LocalLiveView deferred"]}


def gate_errors(record, current):
    errors = []
    if record.get("source_hashes") != current or record.get("final_source_hashes") != current:
        errors.append("stale or changed tested sources")
    rows = record.get("results", [])
    if [r.get("name") for r in rows] != GATES or any(r.get("exit_code") != 0 or r.get("error") is not None or not r.get("command") for r in rows):
        errors.append("failed, missing, duplicate or reordered gates")
    if record.get("predecessor_revision") != BASE:
        errors.append("wrong predecessor replay")
    return errors


def validate(root=REPO_ROOT, final=False):
    root = Path(root)
    errors = []
    def check(ok, message):
        if not ok: errors.append(message)
    try:
        expected = authority(root)
        check(json.loads((root / TARGET).read_text()) == expected, "authority drift")
        for path, digest in expected["input_hashes"].items():
            check(sha((root / path).read_bytes()) == digest, "inherited authority input changed: " + path)
        tree = subprocess.check_output(["git", "ls-tree", "-r", BASE], cwd=root, text=True)
        inherited = {}
        for line in tree.splitlines():
            meta, path = line.split("\t", 1)
            if path not in DOCS and not path.startswith(PLAN + "phase-"):
                inherited[path] = meta.split()[2]
        errors.extend(immutable_input_errors(root, inherited))
        old = {line.split("\t", 1)[1] for line in tree.splitlines()}
        check(set(files(root)) - old <= NEW, "unapproved new file outside Phase 2 surface")
        for path in sorted(old):
            if path.startswith(PLAN + "phase-"):
                baseline = subprocess.check_output(["git", "show", BASE + ":" + path], cwd=root).decode()
                current = (root / path).read_text()
                check(current.replace("[x]", "[ ]") == baseline.replace("[x]", "[ ]"), "phase plan content drift")
                if not path.startswith(PLAN + "phase-01-") and not path.startswith(PLAN + "phase-02-"):
                    check(current == baseline, "unauthorized later phase completion")
        check(json.loads((root / "integration/bh-05/authoring-index-v0.1.0.json").read_text()) == inventory(root), "API or fixture inventory drift")
        check({p.name for p in (root / CORE / "lib/blazex/component").glob("*.ex")} == {"contract.ex", "pure.ex", "stateful.ex", "root.ex", "input.ex", "result.ex"}, "unexpected facade modules")
        if final:
            record = json.loads((root / AREA / "authoring-gates-v0.1.0.json").read_text())
            errors.extend(gate_errors(record, sources(root)))
            complete = json.loads((root / AREA / "authoring-completion-v0.1.0.json").read_text())
            check(complete == completion(root), "completion or artifact bindings drift")
    except (OSError, ValueError, KeyError, TypeError, subprocess.CalledProcessError) as error:
        errors.append("missing/malformed authoring evidence: " + type(error).__name__)
    return errors


def completion(root):
    paths = [TARGET, AREA + "authoring-gates-v0.1.0.json", "integration/bh-05/authoring-index-v0.1.0.json"]
    return {"schema_version": "1.0.0", "phase": 2, "decision": "candidate-authoring-contract-complete",
            "phase3_eligible": True, "phase3_authorized": False, "bh06_eligible": False,
            "support_state": "unsupported", "runtime_execution": False,
            "artifact_hashes": {p: sha((root / p).read_bytes()) for p in paths},
            "delivery": "2.1, 2.2, 2.3, 2.4 separate commits; one PR; merge then main sync before branch deletion. External delivery pending at record creation."}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--final", action="store_true")
    parser.add_argument("--generate-index", action="store_true")
    args = parser.parse_args()
    if args.generate_index:
        (REPO_ROOT / "integration/bh-05/authoring-index-v0.1.0.json").write_text(json.dumps(inventory(REPO_ROOT), indent=2) + "\n")
    errors = validate(final=args.final)
    print("\n".join(errors) if errors else "BH-05 authoring boundary/evidence: PASS")
    sys.exit(bool(errors))
