"""Phase 7 successor boundary, root fixture inventory and source-frozen evidence."""
import argparse
import json
from pathlib import Path
import re
import subprocess
import sys
from research_paths import REPO_ROOT
from generate_bh05_scheduling import BASE, AREA, PLAN, TARGET, CHANGES, record
from validate_bh05_authoring import files, sha
from validate_bh04_correction import immutable_input_errors

TOOLS = "docs/research/70-tools/"
CORE = "packages/blazex_core/"
UI = "packages/blazex_ui_tree/"
CORE_MODULES = ["root_schedule", "scheduled_view", "root_timers", "scheduling_intents"]
FIXTURES = {"integration/bh-05/scheduling-fixtures.exs", "integration/conformance/test/bh05_scheduling_test.exs"}
NEW = {CORE + "lib/blazex/component/" + p + ".ex" for p in CORE_MODULES} | {
    CORE + "test/blazex/" + p + "_test.exs" for p in ["root_schedule"]} | {
    UI + "test/blazex/scheduled_evaluator_test.exs"} | {
    TOOLS + p + ".py" for p in ["generate_bh05_scheduling", "validate_bh05_scheduling", "test_validate_bh05_scheduling", "check_bh05_scheduling_subset", "record_bh05_phase7"]} | FIXTURES | {
    "integration/bh-05/scheduling-index-v0.1.0.json", TARGET,
    AREA + "scheduling-gates-v0.1.0.json", AREA + "scheduling-completion-v0.1.0.json",
    PLAN + "scheduling-contract.md", PLAN + "scheduling-evidence.md"}
DOCS = {CORE + "README.md", UI + "README.md", TOOLS + "README.md", AREA + "README.md", PLAN + "README.md", "integration/bh-05/README.md", "integration/conformance/README.md"}
GATES = ["packages", "javascript", "compile-fixtures", "scheduling-subset", "phase6-replay", "phase5-replay", "phase4-replay", "phase3-replay", "phase2-replay", "phase1-replay", "predecessor-replay", "historical-sweep", "scheduling-tests", "scheduling-validator", "scheduling-generator", "archive", "json", "hygiene"]
DIGESTS = {
    "ROOT_SCRIPT_SHA256": "4eacd556df14a281187e78ae51edb4a2312f4897aa0553aaacc2c150f85f9138",
    "ROOT_TRACE_SHA256": "e062e88cee0a7866964aff1fa1695577bf70660cef031c139d262afd99c9c9e7",
    "ROOT_FINAL_STATE_SHA256": "937d347b5a168a432c2a0a6eb45c1b2acaa5ae8440884617906445420aee400d",
    "SCHEDULING_SAMPLE_SHA256": "384aec1f071fbfd8e24382f908b98ea87400dcd0ca3764ea78b692f888027764",
    "SCHEDULING_TRACE_SHA256": "35cb4e2c103c987180e5a1af4949a169f194faf2efe93b4e565eb12d90b93b74",
    "SCHEDULING_FINAL_STATE_SHA256": "3b2d037102c2f2cc0924d679ed166e850eab0370808e16a2c1817a351eae78f4"}
RAW_MARKERS = {
    "SCHEDULING_SAMPLES": ",".join(map(str, list(range(1, 257)) + [256, 0])),
    "SCHEDULING_OUTCOMES": ",".join(["256:coalesced"] + [str(n) + ":committed" for n in list(range(1, 256)) + [257]]),
    "SCHEDULING_TIMER_INVENTORY": "active=0,canceled=1,completed=0,rejected=0,entries=0"}


def sources(root):
    paths = [p for p in files(root) if p.startswith(("packages/", "js/", "integration/", "profiles/", "experiments/", TOOLS)) and not p.endswith(".md")]
    paths += [TARGET, PLAN + "scheduling-contract.md", PLAN + "root-supervision-compatibility.md"]
    return {p: sha((root / p).read_bytes()) for p in paths}


def inventory(root):
    return {"schema_version": "1.0.0", "phase": 7, "contract": "0.1.0-bh05-scheduling",
            "support_state": "unsupported",
            "public": ["BlazeX.Component.ScheduledView", "BlazeX.Component.LocalView", "BlazeX.Component.SchedulingPort", "BlazeX.UITree.RootEvaluator"],
            "coverage": ["typed-event-bindings", "self-child-parent-root-messages", "commit-bound-actions", "owned-one-shot-and-repeating-timers", "priority-cancellation", "replay-and-schema-rejection", "256-work-overload", "tail-coalescing", "nested-removal", "replacement", "shutdown", "runtime-loss", "unknown-mailbox", "guardian-crash-accounting", "multi-root-independence", "independent-headless-oracle"],
            "normalized_digests": DIGESTS,
            "files": {p: sha((root / p).read_bytes()) for p in sorted(NEW | set(CHANGES)) if p.endswith((".ex", ".exs"))},
            "bounds": {"total_work": 256, "events": 256, "updates": 64, "messages": 128, "timer_work": 32, "owned_timers": 32, "in_flight": 1, "callback_intents": 16},
            "raw_samples": list(range(1, 257)) + [256, 0],
            "outcomes": {"admitted": 257, "committed": 256, "coalesced": 1, "overload_rejected": 1},
            "process_startup": True, "commit_correlated": True, "effects_execution": False, "runtime_parity": False,
            "later_evidence": [],
            "limitations": ["trusted terminating callbacks and ports; not a raw VM mailbox bound or preemptive sandbox", "static runtime policy is not browser authentication", "ERTS scheduling only; Wasm parity and packaging deferred to Phase 11", "effects/provider results and remote commands excluded", "LiveView and LocalLiveView deferred"]}


def gate_errors(value, current):
    errors = []
    if value.get("source_hashes") != current or value.get("final_source_hashes") != current:
        errors.append("stale tested source closure")
    rows = value.get("results", [])
    if [r.get("name") for r in rows] != GATES or any(r.get("exit_code") != 0 or r.get("error") is not None or not r.get("command") for r in rows):
        errors.append("incomplete or failed gates")
    if value.get("predecessor_revision") != BASE:
        errors.append("wrong Phase 6 replay")
    if value.get("phase") != 7:
        errors.append("wrong scheduling phase")
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
    paths = [TARGET, AREA + "scheduling-gates-v0.1.0.json", "integration/bh-05/scheduling-index-v0.1.0.json"]
    return {"schema_version": "1.0.0", "phase": 7, "decision": "bounded-local-event-message-timer-scheduling-complete",
            "phase8_eligible": True, "phase8_authorized": False, "bh06_eligible": False,
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
                if not path.startswith(PLAN + "phase-07-"):
                    check(after == before, "unapproved phase completion change")
                elif final:
                    check("[ ]" not in after, "incomplete Phase 7 checklist")
        check(json.loads((root / "integration/bh-05/scheduling-index-v0.1.0.json").read_text()) == inventory(root), "scheduling fixture inventory drift")
        for path in FIXTURES:
            source = (root / path).read_text()
            check(not re.search(r"BlazeX\.(?:Core\.(?:Authoring|Evaluator)|Component\.(?:RootProcess|RootGuardian)|UITree\.(?:CompositionPlan|PureCandidates|SemanticAcceptance|NestedCandidates)|Renderer\.Headless\.Normalizer)", source), "private application import")
        for name in CORE_MODULES + ["local_view", "root_guardian", "root_process"]:
            source = (root / CORE / "lib/blazex/component" / (name + ".ex")).read_text()
            check(not re.search(r"BlazeX\.(?:UITree|Renderer|Effects)|\b(?:Phoenix|Popcorn|LiveView|LocalLiveView)\.", source), "Core reverse dependency")
        source = (root / UI / "lib/blazex/ui_tree/root_evaluator.ex").read_text()
        check(not re.search(r"BlazeX\.(?:Renderer|Effects)|\b(?:Process|GenServer|Phoenix|Popcorn)\.", source), "evaluator ownership drift")
        if final:
            value = json.loads((root / AREA / "scheduling-gates-v0.1.0.json").read_text())
            errors.extend(gate_errors(value, sources(root)))
            check(json.loads((root / AREA / "scheduling-completion-v0.1.0.json").read_text()) == completion(root), "completion binding drift")
    except (OSError, ValueError, TypeError, KeyError, subprocess.CalledProcessError) as error:
        errors.append("missing/malformed scheduling evidence: " + type(error).__name__)
    return errors


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--final", action="store_true")
    parser.add_argument("--generate-index", action="store_true")
    args = parser.parse_args()
    if args.generate_index:
        (REPO_ROOT / "integration/bh-05/scheduling-index-v0.1.0.json").write_text(json.dumps(inventory(REPO_ROOT), indent=2) + "\n")
    errors = validate(final=args.final)
    print("\n".join(errors) if errors else "BH-05 scheduling boundary/evidence: PASS")
    sys.exit(bool(errors))
