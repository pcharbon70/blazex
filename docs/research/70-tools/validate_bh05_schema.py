"""Phase 3 successor boundary and source-frozen completion validation."""
import argparse
import json
from pathlib import Path
import re
import subprocess
import sys
from research_paths import REPO_ROOT
from generate_bh05_schema import BASE, AREA, PLAN, TARGET, record
from validate_bh05_authoring import files, sha
from validate_bh04_correction import immutable_input_errors

CORE = "packages/blazex_core/"
TOOLS = "docs/research/70-tools/"
AUTHORING = CORE + "lib/blazex/core/authoring.ex"
NEW = {CORE + "lib/blazex/component/" + p + ".ex" for p in ["schema", "props", "slots", "invocation"]} | {
    CORE + "test/blazex/" + p + ".exs" for p in ["schema_test", "slots_test"]} | {
    TOOLS + p + ".py" for p in ["generate_bh05_schema", "check_bh05_schema_subset", "validate_bh05_schema", "test_validate_bh05_schema", "record_bh05_phase3"]} | {
    "integration/bh-05/schema-" + p for p in ["fixtures.exs", "check.exs", "subset.exs", "index-v0.1.0.json"]} | {
    TARGET, AREA + "schema-gates-v0.1.0.json", AREA + "schema-completion-v0.1.0.json", PLAN + "schema-contract.md", PLAN + "schema-evidence.md"}
DOCS = {CORE + "README.md", TOOLS + "README.md", AREA + "README.md", PLAN + "README.md", "integration/bh-05/README.md"}
GATES = ["packages", "javascript", "compile-fixtures", "schema-subset", "phase2-replay", "phase1-replay", "predecessor-replay", "historical-sweep", "schema-tests", "schema-validator", "schema-generator", "archive", "json", "hygiene"]
NORMALIZED = "65d528b4de5a0ec3b7256d80d2dfc363cfbd7c7b588ab21dcfeb4f73c561eb3c"


def sources(root):
    paths = [p for p in files(root) if p.startswith(("packages/", "js/", "integration/", "profiles/", "experiments/", TOOLS)) and not p.endswith(".md")]
    paths += [TARGET, PLAN + "schema-contract.md"]
    return {p: sha((root / p).read_bytes()) for p in paths}


def inventory(root):
    return {"schema_version": "1.0.0", "phase": 3, "contract": "0.2.0-bh05-schema-candidate", "support_state": "unsupported",
            "schema_forms": ["boolean", "integer", "float", "string", "opaque_id", "integer-range", "bounded-string", "enum", "tuple", "list", "map", "record", "nullable", "semantic-v1", "local-callable", "custom-versioned-alias"],
            "public": ["BlazeX.Component." + p for p in ["Schema", "Props", "Slots", "Invocation"]],
            "boundaries": ["local-same-root", "host", "persistence", "command", "renderer"],
            "normalized_fixture_sha256": NORMALIZED,
            "files": {p: sha((root / p).read_bytes()) for p in sorted(NEW | {AUTHORING}) if p.endswith((".ex", ".exs"))},
            "component_execution": False, "runtime_parity": False, "schema_execution": True,
            "later_evidence": [], "limits": ["depth 8", "64 declarations", "256 collection entries", "4096 binary bytes", "local uncaptured external callable only", "JSON-compatible wire terms, not JSON bytes", "no component or slot body execution", "ERTS compiler roundtrip, not AtomVM execution", "LiveView and LocalLiveView deferred"]}


def gate_errors(value, current):
    errors = []
    if value.get("source_hashes") != current or value.get("final_source_hashes") != current: errors.append("stale tested source closure")
    rows = value.get("results", [])
    if [r.get("name") for r in rows] != GATES or any(r.get("exit_code") != 0 or r.get("error") is not None or not r.get("command") for r in rows): errors.append("incomplete or failed gates")
    if value.get("predecessor_revision") != BASE: errors.append("wrong Phase 2 replay")
    for name in ["compile-fixtures", "schema-subset"]:
        matches = [r for r in rows if r.get("name") == name]
        if len(matches) != 1 or re.findall(r"NORMALIZED_SCHEMA_FIXTURE_SHA256 ([0-9a-f]{64})", matches[0].get("stdout", "")) != [NORMALIZED]:
            errors.append("missing or different normalized fixture hash: " + name)
    return errors


def completion(root):
    paths = [TARGET, AREA + "schema-gates-v0.1.0.json", "integration/bh-05/schema-index-v0.1.0.json"]
    return {"schema_version": "1.0.0", "phase": 3, "decision": "schema-and-invocation-contract-complete",
            "phase4_eligible": True, "phase4_authorized": False, "bh06_eligible": False, "support_state": "unsupported",
            "component_execution": False, "runtime_parity": False,
            "artifact_hashes": {p: sha((root / p).read_bytes()) for p in paths},
            "delivery": "Four verified section commits, one PR; merge then checkout main and sync origin before deleting feature branch. External delivery pending at record creation."}


def validate(root=REPO_ROOT, final=False):
    root = Path(root); errors = []
    def check(ok, message):
        if not ok: errors.append(message)
    try:
        expected = record(root)
        check(json.loads((root / TARGET).read_text()) == expected, "authority drift")
        for path, digest in expected["input_hashes"].items():
            if path != AUTHORING: check(sha((root / path).read_bytes()) == digest, "inherited authority changed: " + path)
        tree = subprocess.check_output(["git", "ls-tree", "-r", BASE], cwd=root, text=True)
        inherited = {}
        old = set()
        for line in tree.splitlines():
            meta, path = line.split("\t", 1); old.add(path)
            if path not in DOCS | {AUTHORING} and not path.startswith(PLAN + "phase-"):
                inherited[path] = meta.split()[2]
        errors.extend(immutable_input_errors(root, inherited))
        check(set(files(root)) - old <= NEW, "unapproved new surface")
        for path in sorted(old):
            if path.startswith(PLAN + "phase-"):
                before = subprocess.check_output(["git", "show", BASE + ":" + path], cwd=root).decode()
                after = (root / path).read_text()
                check(after.replace("[x]", "[ ]") == before.replace("[x]", "[ ]"), "phase plan drift")
                if not path.startswith(PLAN + "phase-03-"): check(after == before, "unapproved phase completion change")
        check(json.loads((root / "integration/bh-05/schema-index-v0.1.0.json").read_text()) == inventory(root), "schema or fixture inventory drift")
        if final:
            value = json.loads((root / AREA / "schema-gates-v0.1.0.json").read_text())
            errors.extend(gate_errors(value, sources(root)))
            check(json.loads((root / AREA / "schema-completion-v0.1.0.json").read_text()) == completion(root), "completion binding drift")
    except (OSError, ValueError, TypeError, KeyError, subprocess.CalledProcessError) as error:
        errors.append("missing/malformed schema evidence: " + type(error).__name__)
    return errors


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--final", action="store_true")
    parser.add_argument("--generate-index", action="store_true")
    args = parser.parse_args()
    if args.generate_index:
        (REPO_ROOT / "integration/bh-05/schema-index-v0.1.0.json").write_text(json.dumps(inventory(REPO_ROOT), indent=2) + "\n")
    errors = validate(final=args.final)
    print("\n".join(errors) if errors else "BH-05 schema boundary/evidence: PASS")
    sys.exit(bool(errors))
