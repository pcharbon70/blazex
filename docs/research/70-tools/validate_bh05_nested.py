"""Phase 5 successor boundary, public fixture inventory and source-frozen evidence."""
import argparse
import json
from pathlib import Path
import re
import subprocess
import sys
from research_paths import REPO_ROOT
from generate_bh05_nested import BASE, AREA, PLAN, TARGET, PLANNER, record
from validate_bh05_authoring import files, sha
from validate_bh04_correction import immutable_input_errors

TOOLS = "docs/research/70-tools/"
UI = "packages/blazex_ui_tree/"
MODULES = ["nested_candidates", "nested"]
FIXTURES = {"integration/bh-05/nested-fixtures.exs", "integration/conformance/test/bh05_nested_test.exs"}
NEW = {UI + "lib/blazex/ui_tree/" + p + ".ex" for p in MODULES} | {
    UI + "test/blazex/" + p + ".exs" for p in ["nested_candidates_test", "nested_test"]} | {
    TOOLS + p + ".py" for p in ["generate_bh05_nested", "validate_bh05_nested", "test_validate_bh05_nested", "record_bh05_phase5"]} | FIXTURES | {"packages/blazex_core/lib/blazex/component/nested_table.ex",
    "integration/bh-05/nested-index-v0.1.0.json", TARGET,
    AREA + "nested-gates-v0.1.0.json", AREA + "nested-completion-v0.1.0.json",
    PLAN + "nested-contract.md", PLAN + "nested-evidence.md"}
DOCS = {"packages/blazex_core/README.md", UI + "README.md", TOOLS + "README.md", AREA + "README.md", PLAN + "README.md", "integration/bh-05/README.md", "integration/conformance/README.md"}
GATES = ["packages", "javascript", "compile-fixtures", "phase4-replay", "phase3-replay", "phase2-replay", "phase1-replay", "predecessor-replay", "historical-sweep", "nested-tests", "nested-validator", "nested-generator", "archive", "json", "hygiene"]
DIGESTS = {
    "NESTED_SCRIPT_SHA256": "ed90bfc7d1cbc3c485d1b99f2f90eec810bf505f02bb54a5e5c307c90dd51c17",
    "NESTED_HEADLESS_SHA256": "125fe6ba87e98d99e43b211a2019eff9c295fab9a99a7fc9f88d63918dc4aff0",
    "NESTED_FINAL_STATE_SHA256": "0e1ae9c08b27aee2981875873ef3b33536867976adf5a92b9988fb0ff2740b07"}


def sources(root):
    paths = [p for p in files(root) if p.startswith(("packages/", "js/", "integration/", "profiles/", "experiments/", TOOLS)) and not p.endswith(".md")]
    paths += [TARGET, PLAN + "nested-contract.md"]
    return {p: sha((root / p).read_bytes()) for p in paths}


def inventory(root):
    return {"schema_version": "1.0.0", "phase": 5, "contract": "0.1.0-bh05-nested-state",
            "support_state": "unsupported", "public": ["BlazeX.Component.NestedTable", "BlazeX.UITree.Nested"],
            "transitions": ["mount", "compatible-update", "no-change", "local-event-candidate", "keyed-move", "insert", "remove", "explicit-replacement", "generation-replacement", "dispose"],
            "coverage": ["parent-controlled-props", "retained-local-state", "independent-headless-oracle", "nested-pure-stateful-children", "permutation-replay", "parent-scope-removal-insertion", "module-schema-parent-generation-replacement", "deepest-first-disposal", "callback-state-output-action-failure-rollback", "stale-event-revision", "wrong-root", "duplicate-unstable-keys", "128-notifications-and-overflow", "graph-and-counter-overflow", "accepted-table-integrity"],
            "normalized_digests": DIGESTS,
            "files": {p: sha((root / p).read_bytes()) for p in sorted(NEW | {PLANNER}) if p.endswith((".ex", ".exs"))},
            "retained_state": True, "process_startup": False, "effects_execution": False, "runtime_parity": False,
            "limits": {"depth": 12, "invocations": 128, "nodes": 256, "notifications": 128, "counter": 9007199254740991},
            "later_evidence": [],
            "limitations": ["trusted opaque in-memory sessions; digests are not authentication", "no closures in retained invocations/state", "one shared future root process/failure boundary", "typed parent notifications are data only", "no external disposal side effects or rollback guarantee", "ERTS term encoding; Wasm parity remains Phase 11", "no timers, effects, renderer commits, registry/context resolution", "LiveView and LocalLiveView deferred"]}


def gate_errors(value, current):
    errors = []
    if value.get("source_hashes") != current or value.get("final_source_hashes") != current: errors.append("stale tested source closure")
    rows = value.get("results", [])
    if [r.get("name") for r in rows] != GATES or any(r.get("exit_code") != 0 or r.get("error") is not None or not r.get("command") for r in rows): errors.append("incomplete or failed gates")
    if value.get("predecessor_revision") != BASE: errors.append("wrong Phase 4 replay")
    matches = [r for r in rows if r.get("name") == "packages"]
    for marker, digest in DIGESTS.items():
        if len(matches) != 1 or re.findall(marker + r" ([0-9a-f]{64})", matches[0].get("stdout", "")) != [digest]: errors.append("missing or different normalized digest: " + marker)
    return errors


def completion(root):
    paths = [TARGET, AREA + "nested-gates-v0.1.0.json", "integration/bh-05/nested-index-v0.1.0.json"]
    return {"schema_version": "1.0.0", "phase": 5, "decision": "nested-state-and-atomic-reconciliation-complete",
            "phase6_eligible": True, "phase6_authorized": False, "bh06_eligible": False,
            "support_state": "unsupported", "retained_state": True, "process_startup": False, "effects_execution": False, "runtime_parity": False,
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
            if path != PLANNER: check(sha((root / path).read_bytes()) == digest, "inherited authority changed: " + path)
        tree = subprocess.check_output(["git", "ls-tree", "-r", BASE], cwd=root, text=True)
        inherited = {}; old = set()
        for line in tree.splitlines():
            meta, path = line.split("\t", 1); old.add(path)
            if path not in DOCS | {PLANNER} and not path.startswith(PLAN + "phase-"): inherited[path] = meta.split()[2]
        errors.extend(immutable_input_errors(root, inherited))
        check(set(files(root)) - old <= NEW, "unapproved new surface")
        for path in sorted(old):
            if path.startswith(PLAN + "phase-"):
                before = subprocess.check_output(["git", "show", BASE + ":" + path], cwd=root).decode()
                after = (root / path).read_text()
                check(after.replace("[x]", "[ ]") == before.replace("[x]", "[ ]"), "phase plan drift")
                if not path.startswith(PLAN + "phase-05-"): check(after == before, "unapproved phase completion change")
        check(json.loads((root / "integration/bh-05/nested-index-v0.1.0.json").read_text()) == inventory(root), "nested fixture inventory drift")
        for path in FIXTURES:
            source = (root / path).read_text()
            check(not re.search(r"BlazeX\.(?:Core\.(?:Authoring|Evaluator)|UITree\.(?:CompositionPlan|PureCandidates|SemanticAcceptance|NestedCandidates)|Renderer\.Headless\.Normalizer)", source), "private application import")
        for name in MODULES:
            source = (root / UI / "lib/blazex/ui_tree" / (name + ".ex")).read_text()
            check(not re.search(r"BlazeX\.(?:Renderer|Effects)|\b(?:Process|GenServer|Phoenix|LiveView|LocalLiveView)\.", source), "nested ownership drift")
        core = (root / "packages/blazex_core/lib/blazex/component/nested_table.ex").read_text()
        check(not re.search(r"BlazeX\.(?:UITree|Renderer|Effects)|\b(?:Process|GenServer|Phoenix)\.", core), "Core table ownership drift")
        if final:
            value = json.loads((root / AREA / "nested-gates-v0.1.0.json").read_text())
            errors.extend(gate_errors(value, sources(root)))
            check(json.loads((root / AREA / "nested-completion-v0.1.0.json").read_text()) == completion(root), "completion binding drift")
    except (OSError, ValueError, TypeError, KeyError, subprocess.CalledProcessError) as error:
        errors.append("missing/malformed nested evidence: " + type(error).__name__)
    return errors


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--final", action="store_true")
    parser.add_argument("--generate-index", action="store_true")
    args = parser.parse_args()
    if args.generate_index:
        (REPO_ROOT / "integration/bh-05/nested-index-v0.1.0.json").write_text(json.dumps(inventory(REPO_ROOT), indent=2) + "\n")
    errors = validate(final=args.final)
    print("\n".join(errors) if errors else "BH-05 nested boundary/evidence: PASS")
    sys.exit(bool(errors))
