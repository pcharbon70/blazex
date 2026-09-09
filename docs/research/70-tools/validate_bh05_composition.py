"""Phase 4 successor boundary, public fixture inventory and source-frozen evidence."""
import argparse
import json
from pathlib import Path
import re
import subprocess
import sys
from research_paths import REPO_ROOT
from generate_bh05_composition import BASE, AREA, PLAN, TARGET, record
from validate_bh05_authoring import files, sha
from validate_bh04_correction import immutable_input_errors

TOOLS = "docs/research/70-tools/"
UI = "packages/blazex_ui_tree/"
MODULES = ["composition_plan", "pure_candidates", "composition", "semantic_acceptance"]
FIXTURES = {"integration/bh-05/composition-fixtures.exs", "integration/conformance/test/bh05_composition_test.exs"}
NEW = {UI + "lib/blazex/ui_tree/" + p + ".ex" for p in MODULES} | {
    UI + "test/blazex/" + p + ".exs" for p in ["composition_plan_test", "composition_test"]} | {
    TOOLS + p + ".py" for p in ["generate_bh05_composition", "validate_bh05_composition", "test_validate_bh05_composition", "record_bh05_phase4"]} | FIXTURES | {
    "integration/bh-05/composition-index-v0.1.0.json", TARGET,
    AREA + "composition-gates-v0.1.0.json", AREA + "composition-completion-v0.1.0.json",
    PLAN + "composition-contract.md", PLAN + "composition-evidence.md"}
DOCS = {UI + "README.md", TOOLS + "README.md", AREA + "README.md", PLAN + "README.md", "integration/bh-05/README.md", "integration/conformance/README.md"}
GATES = ["packages", "javascript", "compile-fixtures", "phase3-replay", "phase2-replay", "phase1-replay", "predecessor-replay", "historical-sweep", "composition-tests", "composition-validator", "composition-generator", "archive", "json", "hygiene"]
DIGESTS = {
    "COMPOSITION_OUTPUT_SHA256": "823c14c695f520b5838396c4c048a30ecf5a09fb9c325d636dbe0a655a038abf",
    "COMPOSITION_TRACE_SHA256": "91083cddff153acbfcadf2d08ff04b8bc6f34e20cbc70d6af8ad183bd478be49",
    "COMPOSITION_HEADLESS_SHA256": "9acb0fd7f9463c01e00db4de48255a40c8127efaca9a0afcbe21be432620182c",
    "COMPOSITION_SLOTS_OUTPUT_SHA256": "48f8b40c56de64d89a9910b4372c9763a7e4bdaa8d816aa292dd5e4edebffdf7",
    "COMPOSITION_SLOTS_TRACE_SHA256": "10d32641658cf86456d1ad349257a36cc0dd413b04bd5a58badd941795c9a323"}


def sources(root):
    paths = [p for p in files(root) if p.startswith(("packages/", "js/", "integration/", "profiles/", "experiments/", TOOLS)) and not p.endswith(".md")]
    paths += [TARGET, PLAN + "composition-contract.md"]
    return {p: sha((root / p).read_bytes()) for p in paths}


def inventory(root):
    return {"schema_version": "1.0.0", "phase": 4, "contract": "0.1.0-bh05-pure-composition",
            "support_state": "unsupported", "public": ["BlazeX.UITree.Composition.evaluate/6"],
            "semantic_kinds": ["surface", "group", "action", "field", "collection", "selection", "text"],
            "coverage": ["all-seven-kinds", "independent-headless-oracle", "root-owned-bindings", "layout-accessibility-focus-selection", "relationship-resolution", "default-named-contextual-slots", "lexical-props", "explicit-and-ordinal-keys", "host-inert-slots", "repeated-calls", "map-order", "preflight-before-callback", "invalid-props-slots", "duplicate-identity", "cycles-unreachable", "exact-depth-node-invocation-bounds", "wrong-root-relationship-target", "exception-throw-exit-rejection-redaction", "prohibited-state-actions-resources", "compile-time-process-renderer-dynamic-call-rejection"],
            "normalized_digests": DIGESTS,
            "files": {p: sha((root / p).read_bytes()) for p in sorted(NEW) if p.endswith((".ex", ".exs"))},
            "pure_execution": True, "retained_state": False, "effects_execution": False, "runtime_parity": False,
            "limits": {"depth": 12, "invocations": 128, "nodes": 256}, "later_evidence": [],
            "limitations": ["trusted static build-authored modules, not an adversarial Elixir sandbox", "one node per invocation", "bounded tree, no implicit memoization", "host slots are inert semantic scalars", "ERTS deterministic term encoding; Wasm execution parity deferred to Phase 11", "headless oracle in tests only", "no process isolation, timeout, side-effect rollback or independent child failure boundary", "no state, messages, effects, renderer or DOM execution", "LiveView and LocalLiveView deferred"]}


def gate_errors(value, current):
    errors = []
    if value.get("source_hashes") != current or value.get("final_source_hashes") != current: errors.append("stale tested source closure")
    rows = value.get("results", [])
    if [r.get("name") for r in rows] != GATES or any(r.get("exit_code") != 0 or r.get("error") is not None or not r.get("command") for r in rows): errors.append("incomplete or failed gates")
    if value.get("predecessor_revision") != BASE: errors.append("wrong Phase 3 replay")
    matches = [r for r in rows if r.get("name") == "packages"]
    for marker, digest in DIGESTS.items():
        if len(matches) != 1 or re.findall(marker + r" ([0-9a-f]{64})", matches[0].get("stdout", "")) != [digest]: errors.append("missing or different normalized digest: " + marker)
    return errors


def completion(root):
    paths = [TARGET, AREA + "composition-gates-v0.1.0.json", "integration/bh-05/composition-index-v0.1.0.json"]
    return {"schema_version": "1.0.0", "phase": 4, "decision": "pure-composition-and-atomic-semantic-evaluation-complete",
            "phase5_eligible": True, "phase5_authorized": False, "bh06_eligible": False,
            "support_state": "unsupported", "pure_execution": True, "retained_state": False, "effects_execution": False, "runtime_parity": False,
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
            check(sha((root / path).read_bytes()) == digest, "inherited authority changed: " + path)
        tree = subprocess.check_output(["git", "ls-tree", "-r", BASE], cwd=root, text=True)
        inherited = {}; old = set()
        for line in tree.splitlines():
            meta, path = line.split("\t", 1); old.add(path)
            if path not in DOCS and not path.startswith(PLAN + "phase-"): inherited[path] = meta.split()[2]
        errors.extend(immutable_input_errors(root, inherited))
        check(set(files(root)) - old <= NEW, "unapproved new surface")
        for path in sorted(old):
            if path.startswith(PLAN + "phase-"):
                before = subprocess.check_output(["git", "show", BASE + ":" + path], cwd=root).decode()
                after = (root / path).read_text()
                check(after.replace("[x]", "[ ]") == before.replace("[x]", "[ ]"), "phase plan drift")
                if not path.startswith(PLAN + "phase-04-"): check(after == before, "unapproved phase completion change")
        check(json.loads((root / "integration/bh-05/composition-index-v0.1.0.json").read_text()) == inventory(root), "composition fixture inventory drift")
        for path in FIXTURES:
            source = (root / path).read_text()
            check(not re.search(r"BlazeX\.(?:Core\.(?:Authoring|Evaluator)|UITree\.(?:CompositionPlan|PureCandidates|SemanticAcceptance)|Renderer\.Headless\.Normalizer)", source), "private application import")
        for name in MODULES:
            source = (root / UI / "lib/blazex/ui_tree" / (name + ".ex")).read_text()
            check(not re.search(r"BlazeX\.(?:Renderer|Effects)|\b(?:Process|GenServer|Phoenix|LiveView|LocalLiveView)\.", source), "composition ownership drift")
        if final:
            value = json.loads((root / AREA / "composition-gates-v0.1.0.json").read_text())
            errors.extend(gate_errors(value, sources(root)))
            check(json.loads((root / AREA / "composition-completion-v0.1.0.json").read_text()) == completion(root), "completion binding drift")
    except (OSError, ValueError, TypeError, KeyError, subprocess.CalledProcessError) as error:
        errors.append("missing/malformed composition evidence: " + type(error).__name__)
    return errors


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--final", action="store_true")
    parser.add_argument("--generate-index", action="store_true")
    args = parser.parse_args()
    if args.generate_index:
        (REPO_ROOT / "integration/bh-05/composition-index-v0.1.0.json").write_text(json.dumps(inventory(REPO_ROOT), indent=2) + "\n")
    errors = validate(final=args.final)
    print("\n".join(errors) if errors else "BH-05 composition boundary/evidence: PASS")
    sys.exit(bool(errors))
