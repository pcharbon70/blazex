"""Phase 9 successor boundary, root fixture inventory and source-frozen evidence."""
import argparse
import json
from pathlib import Path
import re
import subprocess
import sys
from research_paths import REPO_ROOT
from generate_bh05_scopes import BASE, AREA, PLAN, TARGET, CHANGES, record
from validate_bh05_authoring import files, sha
from validate_bh04_correction import immutable_input_errors

TOOLS = "docs/research/70-tools/"
CORE = "packages/blazex_core/"
UI = "packages/blazex_ui_tree/"
CORE_MODULES = ["scoped_context", "scoped_view", "component_registry"]
FIXTURES = {"integration/bh-05/scope-fixtures.exs", "integration/conformance/test/bh05_scopes_test.exs"}
NEW = {CORE + "lib/blazex/component/" + p + ".ex" for p in CORE_MODULES} | {
    CORE + "test/blazex/" + p + "_test.exs" for p in ["scoped_context", "component_registry"]} | {
    UI + "lib/blazex/ui_tree/" + p + ".ex" for p in ["scoped_plan", "scoped_evaluator", "registry_plan"]} | {
    UI + "test/blazex/" + p + "_test.exs" for p in ["scoped_evaluator", "registry_evaluator"]} | {
    TOOLS + p + ".py" for p in ["generate_bh05_scopes", "validate_bh05_scopes", "test_validate_bh05_scopes", "check_bh05_scope_subset", "record_bh05_phase9"]} | FIXTURES | {
    "integration/bh-05/scope-index-v0.1.0.json", TARGET,
    AREA + "scope-gates-v0.1.0.json", AREA + "scope-completion-v0.1.0.json",
    PLAN + "scope-contract.md", PLAN + "scope-evidence.md"}

DOCS = {CORE + "README.md", UI + "README.md", "packages/blazex_effects/README.md", TOOLS + "README.md", AREA + "README.md", PLAN + "README.md", "integration/bh-05/README.md", "integration/conformance/README.md"}
GATES = ["packages", "javascript", "compile-fixtures", "scope-subset", "phase8-replay", "phase7-replay", "phase6-replay", "phase5-replay", "phase4-replay", "phase3-replay", "phase2-replay", "phase1-replay", "predecessor-replay", "historical-sweep", "scope-tests", "scope-validator", "scope-generator", "archive", "json", "hygiene"]
DIGESTS = {
    "SCOPE_TRACE_SHA256": "f81d105271527cdefe53c1400a24ccd02dbea897f9b3db617a45e13f7c1aeefc",
    "SCOPE_FINAL_STATE_SHA256": "efbe66ec3d3e5506c78a4f92da60f79db23e8d9922b8149b0ef16ef61a81e026",
    "SCOPE_REGISTRY_SHA256": "e9aecaf638f74a9995fde721a25f6eb295926efe6d6de908dd436778498b3302",
    "ACTION_FINAL_STATE_SHA256": "61fe1070e22766c9eb2e002d5c8593d77aa0ebaec012c4e23bae83f98d0808ee",
    "ACTION_PENDING_SHA256": "14c87a8ba3714c21136dd57d6645d637ab410aa26ddf23d82efbe0f81fa1446b",
    "ACTION_LEASE_SHA256": "94809597b6e80115851b6bd5951dbaaf2bcea6ab7c39aaaa3a5349f599d4cdba",
    "ROOT_SCRIPT_SHA256": "4eacd556df14a281187e78ae51edb4a2312f4897aa0553aaacc2c150f85f9138",
    "ROOT_TRACE_SHA256": "e062e88cee0a7866964aff1fa1695577bf70660cef031c139d262afd99c9c9e7",
    "ROOT_FINAL_STATE_SHA256": "937d347b5a168a432c2a0a6eb45c1b2acaa5ae8440884617906445420aee400d",
    "SCHEDULING_SAMPLE_SHA256": "384aec1f071fbfd8e24382f908b98ea87400dcd0ca3764ea78b692f888027764",
    "SCHEDULING_TRACE_SHA256": "35cb4e2c103c987180e5a1af4949a169f194faf2efe93b4e565eb12d90b93b74",
    "SCHEDULING_FINAL_STATE_SHA256": "3b2d037102c2f2cc0924d679ed166e850eab0370808e16a2c1817a351eae78f4"}
RAW_MARKERS = {
    "SCOPE_INVALIDATION_ORDER": "root,child,pure",
    "SCOPE_SUBSCRIPTIONS": "3,3,3,3",
    "SCOPE_CLEANUP": "replaced=1,disposed=1,late_rejected=1",
    "SCHEDULING_SAMPLES": ",".join(map(str, list(range(1, 257)) + [256, 0])),
    "SCHEDULING_OUTCOMES": ",".join(["256:coalesced"] + [str(n) + ":committed" for n in list(range(1, 256)) + [257]]),
    "SCHEDULING_TIMER_INVENTORY": "active=0,canceled=1,completed=0,rejected=0,entries=0"}
RAW_MARKERS.update({"ACTION_PENDING_SAMPLES": ",".join(map(str, list(range(1, 129)) + [128])),
    "ACTION_LEASE_SAMPLES": ",".join(map(str, list(range(16, 513, 16)) + [512, 0])),
    "ACTION_TRACE": "completed=1,pending=0,leases=0,replayed=0"})


def sources(root):
    paths = [p for p in files(root) if p.startswith(("packages/", "js/", "integration/", "profiles/", "experiments/", TOOLS)) and not p.endswith(".md")]
    paths += [TARGET, PLAN + "scope-contract.md", PLAN + "root-supervision-compatibility.md"]
    return {p: sha((root / p).read_bytes()) for p in paths}


def inventory(root):
    return {"schema_version": "1.0.0", "phase": 9, "contract": "0.1.0-bh05-scopes",
            "support_state": "unsupported",
            "public": ["BlazeX.Component.ScopedContext", "BlazeX.Component.ScopedView", "BlazeX.Component.ComponentRegistry", "BlazeX.UITree.ScopedEvaluator"],
            "coverage": ["nearest-default-provider", "fixed-tracked-context", "commit-gated-canonical-invalidation", "contextual-slots", "root-generation-isolation", "provider-removal", "registry-pure-stateful-selection", "same-id-retention", "id-replacement", "declared-fallback", "redacted-rejection", "independent-headless-oracle", "bounded-subscriptions", "disposal"],
            "normalized_digests": DIGESTS,
            "files": {p: sha((root / p).read_bytes()) for p in sorted(NEW | set(CHANGES)) if p.endswith((".ex", ".exs"))},
            "bounds": {"total_work": 256, "message_work": 128, "definitions": 16, "providers": 32, "subscriptions": 128, "components": 128, "registry_entries": 128, "composition_depth": 12},
            "process_startup": True, "commit_correlated": True, "runtime_parity": False,
            "later_evidence": [],
            "limitations": ["trusted terminating callbacks and ports; not a raw VM mailbox bound or preemptive sandbox", "public advisory context is not authentication or secret storage", "ERTS scoped runtime only; Wasm parity and packaging deferred to Phase 11", "BH-06 bundle/reachability generation and concrete product providers excluded", "LiveView and LocalLiveView deferred"]}



def gate_errors(value, current):
    errors = []
    if value.get("source_hashes") != current or value.get("final_source_hashes") != current:
        errors.append("stale tested source closure")
    rows = value.get("results", [])
    if [r.get("name") for r in rows] != GATES or any(r.get("exit_code") != 0 or r.get("error") is not None or not r.get("command") for r in rows):
        errors.append("incomplete or failed gates")
    if value.get("predecessor_revision") != BASE:
        errors.append("wrong Phase 8 replay")
    if value.get("phase") != 9:
        errors.append("wrong scope phase")
    matches = [r for r in rows if r.get("name") == "packages"]
    for marker, digest in DIGESTS.items():
        if len(matches) != 1 or re.findall(marker + r" ([0-9a-f]{64})", matches[0].get("stdout", "")) != [digest]:
            errors.append("missing or different normalized digest: " + marker)
    if len(matches) == 1:
        for marker, expected in RAW_MARKERS.items():
            if re.findall(marker + r" ([^\r\n]+)", matches[0].get("stdout", "")) != [expected]:
                errors.append("missing or invalid raw evidence: " + marker)
    return errors


def completion(root):
    paths = [TARGET, AREA + "scope-gates-v0.1.0.json", "integration/bh-05/scope-index-v0.1.0.json"]
    return {"schema_version": "1.0.0", "phase": 9, "decision": "root-scoped-context-manifest-bounded-dynamic-components-complete",
            "phase10_eligible": True, "phase10_authorized": False, "bh06_eligible": False,
            "support_state": "unsupported", "process_startup": True, "commit_correlated": True, "abstract_provider_execution": True, "concrete_provider_execution": False, "runtime_parity": False,
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
                if not path.startswith(PLAN + "phase-09-"):
                    check(after == before, "unapproved phase completion change")
                elif final:
                    check("[ ]" not in after, "incomplete Phase 9 checklist")
        check(json.loads((root / "integration/bh-05/scope-index-v0.1.0.json").read_text()) == inventory(root), "scope fixture inventory drift")
        for path in FIXTURES:
            source = (root / path).read_text()
            check(not re.search(r"BlazeX\.(?:Core\.(?:Authoring|Evaluator)|Component\.(?:RootProcess|RootGuardian)|UITree\.(?:CompositionPlan|PureCandidates|SemanticAcceptance|NestedCandidates)|Renderer\.Headless\.Normalizer)", source), "private application import")
        for name in CORE_MODULES + ["local_view", "root_guardian", "root_process"]:
            source = (root / CORE / "lib/blazex/component" / (name + ".ex")).read_text()
            check(not re.search(r"BlazeX\.(?:UITree|Renderer|Effects)|\b(?:Phoenix|Popcorn|LiveView|LocalLiveView)\.", source), "Core reverse dependency")
        source = (root / UI / "lib/blazex/ui_tree/root_evaluator.ex").read_text()
        check(not re.search(r"BlazeX\.(?:Renderer|Effects)|\b(?:Process|GenServer|Phoenix|Popcorn)\.", source), "evaluator ownership drift")
        if final:
            value = json.loads((root / AREA / "scope-gates-v0.1.0.json").read_text())
            errors.extend(gate_errors(value, sources(root)))
            check(json.loads((root / AREA / "scope-completion-v0.1.0.json").read_text()) == completion(root), "completion binding drift")
    except (OSError, ValueError, TypeError, KeyError, subprocess.CalledProcessError) as error:
        errors.append("missing/malformed scope evidence: " + type(error).__name__)
    return errors


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--final", action="store_true")
    parser.add_argument("--generate-index", action="store_true")
    args = parser.parse_args()
    if args.generate_index:
        (REPO_ROOT / "integration/bh-05/scope-index-v0.1.0.json").write_text(json.dumps(inventory(REPO_ROOT), indent=2) + "\n")
    errors = validate(final=args.final)
    print("\n".join(errors) if errors else "BH-05 scope boundary/evidence: PASS")
    sys.exit(bool(errors))
