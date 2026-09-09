"""Phase 6 successor boundary, root fixture inventory and source-frozen evidence."""
import argparse
import json
from pathlib import Path
import re
import subprocess
import sys
from research_paths import REPO_ROOT
from generate_bh05_roots import BASE, AREA, PLAN, TARGET, CHANGES, record
from validate_bh05_authoring import files, sha
from validate_bh04_correction import immutable_input_errors

TOOLS = "docs/research/70-tools/"
CORE = "packages/blazex_core/"
UI = "packages/blazex_ui_tree/"
CORE_MODULES = ["root_port", "local_view", "root_guardian", "root_process"]
FIXTURES = {"integration/bh-05/root-fixtures.exs", "integration/conformance/test/bh05_root_test.exs"}
NEW = {CORE + "lib/blazex/component/" + p + ".ex" for p in CORE_MODULES} | {
    CORE + "test/blazex/" + p + "_test.exs" for p in ["root_port", "local_view"]} | {
    UI + "lib/blazex/ui_tree/root_evaluator.ex", UI + "test/blazex/root_evaluator_test.exs"} | {
    TOOLS + p + ".py" for p in ["generate_bh05_roots", "validate_bh05_roots", "test_validate_bh05_roots", "check_bh05_root_subset", "record_bh05_phase6"]} | FIXTURES | {
    "integration/bh-05/root-index-v0.1.0.json", TARGET,
    AREA + "root-gates-v0.1.0.json", AREA + "root-completion-v0.1.0.json",
    PLAN + "root-lifecycle-contract.md", PLAN + "root-lifecycle-evidence.md", PLAN + "root-supervision-compatibility.md"}
DOCS = {CORE + "README.md", UI + "README.md", TOOLS + "README.md", AREA + "README.md", PLAN + "README.md", "integration/bh-05/README.md", "integration/conformance/README.md"}
GATES = ["packages", "javascript", "compile-fixtures", "root-subset", "phase5-replay", "phase4-replay", "phase3-replay", "phase2-replay", "phase1-replay", "predecessor-replay", "historical-sweep", "root-tests", "root-validator", "root-generator", "archive", "json", "hygiene"]
DIGESTS = {
    "ROOT_SCRIPT_SHA256": "4eacd556df14a281187e78ae51edb4a2312f4897aa0553aaacc2c150f85f9138",
    "ROOT_TRACE_SHA256": "e062e88cee0a7866964aff1fa1695577bf70660cef031c139d262afd99c9c9e7",
    "ROOT_FINAL_STATE_SHA256": "937d347b5a168a432c2a0a6eb45c1b2acaa5ae8440884617906445420aee400d"}


def sources(root):
    paths = [p for p in files(root) if p.startswith(("packages/", "js/", "integration/", "profiles/", "experiments/", TOOLS)) and not p.endswith(".md")]
    paths += [TARGET, PLAN + "root-lifecycle-contract.md", PLAN + "root-supervision-compatibility.md"]
    return {p: sha((root / p).read_bytes()) for p in paths}


def inventory(root):
    return {"schema_version": "1.0.0", "phase": 6, "contract": "0.1.0-bh05-root-lifecycle",
            "support_state": "unsupported",
            "public": ["BlazeX.Component.RootPort", "BlazeX.Component.RootPort.Evaluator", "BlazeX.Component.RootPort.Renderer", "BlazeX.Component.RootPort.Host", "BlazeX.Component.LocalView", "BlazeX.Component.LocalView.Supervisor", "BlazeX.UITree.RootEvaluator"],
            "transitions": ["validated-start", "mount-candidate", "parent-update", "no-change", "renderer-commit", "confirmed-rollback", "generation-replacement", "host-removal", "renderer-disposal", "normal-stop", "explicit-remount", "terminal-crash"],
            "coverage": ["independent-headless-oracle", "no-ready-before-commit", "final-state-digest-ownership", "one-in-flight", "stale-duplicate-wrong-owner-ack", "semantic-callback-rejection", "renderer-rejection", "acknowledgement-loss-before-and-after-renderer-commit", "uncertain-rollback-fails-closed", "cleanup-after-commit-only", "idempotent-stop", "crash-before-and-after-commit", "sibling-isolation", "redacted-observations", "root-handle-not-pid", "pinned-supervision-analysis"],
            "normalized_digests": DIGESTS,
            "files": {p: sha((root / p).read_bytes()) for p in sorted(NEW | set(CHANGES)) if p.endswith((".ex", ".exs"))},
            "process_startup": True, "commit_correlated": True, "effects_execution": False, "runtime_parity": False,
            "later_evidence": [],
            "limitations": ["trusted terminating callbacks/ports, not a sandbox", "one static root-role graph per evaluator configuration", "temporary guardian retains terminal metadata; no automatic replay", "ERTS term digests are not authentication or cross-VM parity", "no application events/messages/effects/timers/context/registry execution", "standalone AtomVM 0.6.6 incompatible; Popcorn patches and upstream alpha APIs analyzed only", "runtime profile owner must qualify Wasm execution and crash-log privacy in Phase 11", "LiveView and LocalLiveView deferred"]}


def gate_errors(value, current):
    errors = []
    if value.get("source_hashes") != current or value.get("final_source_hashes") != current:
        errors.append("stale tested source closure")
    rows = value.get("results", [])
    if [r.get("name") for r in rows] != GATES or any(r.get("exit_code") != 0 or r.get("error") is not None or not r.get("command") for r in rows):
        errors.append("incomplete or failed gates")
    if value.get("predecessor_revision") != BASE:
        errors.append("wrong Phase 5 replay")
    matches = [r for r in rows if r.get("name") == "packages"]
    for marker, digest in DIGESTS.items():
        if len(matches) != 1 or re.findall(marker + r" ([0-9a-f]{64})", matches[0].get("stdout", "")) != [digest]:
            errors.append("missing or different normalized digest: " + marker)
    return errors


def completion(root):
    paths = [TARGET, AREA + "root-gates-v0.1.0.json", "integration/bh-05/root-index-v0.1.0.json"]
    return {"schema_version": "1.0.0", "phase": 6, "decision": "supervised-commit-correlated-root-lifecycle-complete",
            "phase7_eligible": True, "phase7_authorized": False, "bh06_eligible": False,
            "support_state": "unsupported", "process_startup": True, "commit_correlated": True, "effects_execution": False, "runtime_parity": False,
            "artifact_hashes": {p: sha((root / p).read_bytes()) for p in paths},
            "delivery": "Four verified section commits, one PR; merge then checkout main and sync origin before deleting feature branch. External delivery pending at record creation."}


def validate(root=REPO_ROOT, final=False):
    root = Path(root)
    errors = []
    def check(ok, message):
        if not ok:
            errors.append(message)
    try:
        expected = record(root)
        check(json.loads((root / TARGET).read_text()) == expected, "authority drift")
        for path, digest in expected["input_hashes"].items():
            if path not in CHANGES:
                check(sha((root / path).read_bytes()) == digest, "inherited authority changed: " + path)
        tree = subprocess.check_output(["git", "ls-tree", "-r", BASE], cwd=root, text=True)
        inherited = {}
        old = set()
        for line in tree.splitlines():
            meta, path = line.split("\t", 1)
            old.add(path)
            if path not in DOCS | set(CHANGES) and not path.startswith(PLAN + "phase-"):
                inherited[path] = meta.split()[2]
        errors.extend(immutable_input_errors(root, inherited))
        check(set(files(root)) - old <= NEW, "unapproved new surface")
        for path in sorted(old):
            if path.startswith(PLAN + "phase-"):
                before = subprocess.check_output(["git", "show", BASE + ":" + path], cwd=root).decode()
                after = (root / path).read_text()
                check(after.replace("[x]", "[ ]") == before.replace("[x]", "[ ]"), "phase plan drift")
                if not path.startswith(PLAN + "phase-06-"):
                    check(after == before, "unapproved phase completion change")
                elif final:
                    check("[ ]" not in after, "incomplete Phase 6 checklist")
        check(json.loads((root / "integration/bh-05/root-index-v0.1.0.json").read_text()) == inventory(root), "root fixture inventory drift")
        for path in FIXTURES:
            source = (root / path).read_text()
            check(not re.search(r"BlazeX\.(?:Core\.(?:Authoring|Evaluator)|Component\.(?:RootProcess|RootGuardian)|UITree\.(?:CompositionPlan|PureCandidates|SemanticAcceptance|NestedCandidates)|Renderer\.Headless\.Normalizer)", source), "private application import")
        for name in CORE_MODULES:
            source = (root / CORE / "lib/blazex/component" / (name + ".ex")).read_text()
            check(not re.search(r"BlazeX\.(?:UITree|Renderer|Effects)|\b(?:Phoenix|Popcorn|LiveView|LocalLiveView)\.", source), "Core reverse dependency")
        source = (root / UI / "lib/blazex/ui_tree/root_evaluator.ex").read_text()
        check(not re.search(r"BlazeX\.(?:Renderer|Effects)|\b(?:Process|GenServer|Phoenix|Popcorn)\.", source), "evaluator ownership drift")
        if final:
            value = json.loads((root / AREA / "root-gates-v0.1.0.json").read_text())
            errors.extend(gate_errors(value, sources(root)))
            check(json.loads((root / AREA / "root-completion-v0.1.0.json").read_text()) == completion(root), "completion binding drift")
    except (OSError, ValueError, TypeError, KeyError, subprocess.CalledProcessError) as error:
        errors.append("missing/malformed root evidence: " + type(error).__name__)
    return errors


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--final", action="store_true")
    parser.add_argument("--generate-index", action="store_true")
    args = parser.parse_args()
    if args.generate_index:
        (REPO_ROOT / "integration/bh-05/root-index-v0.1.0.json").write_text(json.dumps(inventory(REPO_ROOT), indent=2) + "\n")
    errors = validate(final=args.final)
    print("\n".join(errors) if errors else "BH-05 root boundary/evidence: PASS")
    sys.exit(bool(errors))
