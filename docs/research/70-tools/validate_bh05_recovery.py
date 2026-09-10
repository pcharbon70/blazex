"""Phase 10 successor boundary, root fixture inventory and source-frozen evidence."""
import argparse
import json
from pathlib import Path
import re
import subprocess
import sys
from research_paths import REPO_ROOT
from generate_bh05_recovery import BASE, AREA, PLAN, TARGET, CHANGES, record
from validate_bh05_authoring import files, sha
from validate_bh04_correction import immutable_input_errors

TOOLS = "docs/research/70-tools/"
CORE = "packages/blazex_core/"
UI = "packages/blazex_ui_tree/"
CORE_MODULES = ["recovery_policy", "recovery_port", "recovery_runtime", "recovery_guardian", "recovery_cleanup", "recovery_view"]
FIXTURES = {"integration/bh-05/recovery-fixtures.exs", "integration/conformance/test/bh05_recovery_test.exs"}
NEW = {CORE + "lib/blazex/component/" + p + ".ex" for p in CORE_MODULES} | {
    CORE + "test/blazex/" + p + "_test.exs" for p in ["recovery_policy", "recovery_cleanup"]} | {
    UI + "lib/blazex/ui_tree/" + p + ".ex" for p in ["recovery_evaluator"]} | {
    UI + "test/blazex/" + p + "_test.exs" for p in ["recovery_evaluator"]} | {
    TOOLS + p + ".py" for p in ["generate_bh05_recovery", "validate_bh05_recovery", "test_validate_bh05_recovery", "check_bh05_recovery_subset", "record_bh05_phase10"]} | FIXTURES | {
    "integration/bh-05/recovery-index-v0.1.0.json", TARGET,
    AREA + "recovery-gates-v0.1.0.json", AREA + "recovery-completion-v0.1.0.json",
    PLAN + "recovery-contract.md", PLAN + "recovery-evidence.md"}

DOCS = {CORE + "README.md", UI + "README.md", "packages/blazex_effects/README.md", TOOLS + "README.md", AREA + "README.md", PLAN + "README.md", "integration/bh-05/README.md", "integration/conformance/README.md"}
GATES = ["packages", "javascript", "compile-fixtures", "recovery-subset", "phase9-replay", "phase8-replay", "phase7-replay", "phase6-replay", "phase5-replay", "phase4-replay", "phase3-replay", "phase2-replay", "phase1-replay", "predecessor-replay", "historical-sweep", "recovery-tests", "recovery-validator", "recovery-generator", "archive", "json", "hygiene"]
DIGESTS = {
    "RECOVERY_FAILURE_SHA256": "409705856eb8c7c2b582d97aa929f08ea9a00340885c546e7d97003042459823",
    "RECOVERY_CLEANUP_SHA256": "fa6b0448de866fb9f62c8687e69f3e23a4e3df2a1937efeac3a09667b9f3ff27",
    "RECOVERY_RESTART_SHA256": "119b730d4bd88005672d994ef736ebd314b9c561cdbf39f79f5ebfbf6f3f20cc",
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
    "RECOVERY_FAILURE_CASES": "17",
    "RECOVERY_RESTART_COUNTS": "0,1,2,3,3",
    "RECOVERY_CLEANUP_CASES": "removal,replacement,crash,runtime_loss,callback_error",
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
    paths += [TARGET, PLAN + "recovery-contract.md", PLAN + "root-supervision-compatibility.md"]
    return {p: sha((root / p).read_bytes()) for p in paths}


def inventory(root):
    return {"schema_version": "1.0.0", "phase": 10, "contract": "0.1.0-bh05-recovery",
            "support_state": "unsupported",
            "public": ["BlazeX.Component.RecoveryView", "BlazeX.Component.RecoveryPolicy", "BlazeX.Component.RecoveryCleanup", "BlazeX.UITree.RecoveryEvaluator"],
            "coverage": ["callback-failure-matrix", "sibling-root-isolation", "callback-independent-semantic-fallback", "static-fallback", "redacted-diagnostics", "generation-bound-retry", "three-restarts-five-seconds", "no-action-replay", "deepest-first-disposal", "512-lease-cleanup", "forced-timeout-cleanup", "unresolved-leak-detection", "late-work-rejection"],
            "normalized_digests": DIGESTS,
            "files": {p: sha((root / p).read_bytes()) for p in sorted(NEW | set(CHANGES)) if p.endswith((".ex", ".exs"))},
            "bounds": {"automatic_restarts": 3, "window_ms": 5000, "backoff_min_ms": 100, "cleanup_ms": 1000, "owners": 128, "pending_requests": 128, "leases": 512, "diagnostic_page_size": 128},
            "failure_acceptance": ["BX-ACC-FAILURE-BX-FAIL-COMPONENT", "BX-ACC-FAILURE-BX-FAIL-RESOURCE-CLEANUP"],
            "process_startup": True, "commit_correlated": True, "runtime_parity": False,
            "later_evidence": [],
            "limitations": ["ERTS/headless execution; AtomVM/Wasm and cross-backend qualification remain Phase 11", "trusted runtime configuration and declared idempotent cleanup ports", "whole-VM recovery, offline persistence and command replay excluded", "failed forced cleanup remains an unresolved leak, never a support claim", "LiveView and LocalLiveView deferred"]}



def gate_errors(value, current):
    errors = []
    if value.get("source_hashes") != current or value.get("final_source_hashes") != current:
        errors.append("stale tested source closure")
    rows = value.get("results", [])
    if [r.get("name") for r in rows] != GATES or any(r.get("exit_code") != 0 or r.get("error") is not None or not r.get("command") for r in rows):
        errors.append("incomplete or failed gates")
    if value.get("predecessor_revision") != BASE:
        errors.append("wrong Phase 9 replay")
    if value.get("phase") != 10:
        errors.append("wrong recovery phase")
    matches = [r for r in rows if r.get("name") == "packages"]
    for marker, digest in DIGESTS.items():
        if len(matches) != 1 or re.findall(marker + r" ([0-9a-f]{64})", matches[0].get("stdout", "")) != [digest]:
            errors.append("missing or different normalized digest: " + marker)
    if len(matches) == 1:
        for marker, count, lower, upper in [("RECOVERY_CLEANUP_MS", 2, 0, 1000), ("RECOVERY_RETRY_MS", 4, None, None)]:
            raw = re.findall(marker + r" ([^\r\n]+)", matches[0].get("stdout", ""))
            try:
                samples = [int(x) for x in raw[0].split(",")] if len(raw) == 1 else []
                valid = len(samples) == count
                if lower is not None:
                    valid = valid and all(lower <= n < upper for n in samples)
                else:
                    valid = valid and samples == sorted(samples) and samples[-1] - samples[0] < 5000
                if not valid: errors.append("invalid timing evidence: " + marker)
            except (ValueError, IndexError):
                errors.append("malformed timing evidence: " + marker)
        for marker, expected in RAW_MARKERS.items():
            if re.findall(marker + r" ([^\r\n]+)", matches[0].get("stdout", "")) != [expected]:
                errors.append("missing or invalid raw evidence: " + marker)
    return errors


def completion(root):
    paths = [TARGET, AREA + "recovery-gates-v0.1.0.json", "integration/bh-05/recovery-index-v0.1.0.json"]
    return {"schema_version": "1.0.0", "phase": 10, "decision": "root-failure-retry-generation-and-bounded-cleanup-complete",
            "phase11_eligible": True, "phase11_authorized": False, "bh06_eligible": False,
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
                if not path.startswith(PLAN + "phase-10-"):
                    check(after == before, "unapproved phase completion change")
                elif final:
                    check("[ ]" not in after, "incomplete Phase 10 checklist")
        check(json.loads((root / "integration/bh-05/recovery-index-v0.1.0.json").read_text()) == inventory(root), "recovery fixture inventory drift")
        for path in FIXTURES:
            source = (root / path).read_text()
            check(not re.search(r"BlazeX\.(?:Core\.(?:Authoring|Evaluator)|Component\.(?:RootProcess|RootGuardian)|UITree\.(?:CompositionPlan|PureCandidates|SemanticAcceptance|NestedCandidates)|Renderer\.Headless\.Normalizer)", source), "private application import")
        for name in CORE_MODULES + ["local_view", "root_guardian", "root_process"]:
            source = (root / CORE / "lib/blazex/component" / (name + ".ex")).read_text()
            check(not re.search(r"BlazeX\.(?:UITree|Renderer|Effects)|\b(?:Phoenix|Popcorn|LiveView|LocalLiveView)\.", source), "Core reverse dependency")
        source = (root / UI / "lib/blazex/ui_tree/root_evaluator.ex").read_text()
        check(not re.search(r"BlazeX\.(?:Renderer|Effects)|\b(?:Process|GenServer|Phoenix|Popcorn)\.", source), "evaluator ownership drift")
        if final:
            value = json.loads((root / AREA / "recovery-gates-v0.1.0.json").read_text())
            errors.extend(gate_errors(value, sources(root)))
            check(json.loads((root / AREA / "recovery-completion-v0.1.0.json").read_text()) == completion(root), "completion binding drift")
    except (OSError, ValueError, TypeError, KeyError, subprocess.CalledProcessError) as error:
        errors.append("missing/malformed recovery evidence: " + type(error).__name__)
    return errors


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--final", action="store_true")
    parser.add_argument("--generate-index", action="store_true")
    args = parser.parse_args()
    if args.generate_index:
        (REPO_ROOT / "integration/bh-05/recovery-index-v0.1.0.json").write_text(json.dumps(inventory(REPO_ROOT), indent=2) + "\n")
    errors = validate(final=args.final)
    print("\n".join(errors) if errors else "BH-05 recovery boundary/evidence: PASS")
    sys.exit(bool(errors))
