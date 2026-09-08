#!/usr/bin/env python3
"""Validate BH-03 Phase 1 authorization, handoff, contracts, and activation."""

from __future__ import annotations

import planning_policy
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any


from research_paths import RESEARCH_ROOT
REPO_ROOT = RESEARCH_ROOT.parent.parent
BASELINE_ROOT = RESEARCH_ROOT / "assets/bh-03-baseline"
AUTHORIZATION = BASELINE_ROOT / "blazex-bh-03-phase-01-authorization-v0.1.0.json"
LEDGER = BASELINE_ROOT / "blazex-bh-03-entry-ledger-v0.1.0.json"
CONTRACT = BASELINE_ROOT / "blazex-bh-03-phase-01-contract-v0.1.0.json"
ACTIVATION = BASELINE_ROOT / "blazex-bh-03-repository-activation-v0.1.0.json"
INTEGRATION_INDEX = REPO_ROOT / "integration/bh-03/integration-index-v0.1.0.json"
COMPLETION = BASELINE_ROOT / "blazex-bh-03-phase-01-completion-v0.1.0.json"
PHASE2_AUTHORIZATION = BASELINE_ROOT / "blazex-bh-03-phase-02-authorization-v0.1.0.json"
PHASE3_AUTHORIZATION = BASELINE_ROOT / "blazex-bh-03-phase-03-authorization-v0.1.0.json"
PHASE4_AUTHORIZATION = BASELINE_ROOT / "blazex-bh-03-phase-04-authorization-v0.1.0.json"
PHASE5_AUTHORIZATION = BASELINE_ROOT / "blazex-bh-03-phase-05-authorization-v0.1.0.json"
PHASE6_AUTHORIZATION = BASELINE_ROOT / "blazex-bh-03-phase-06-authorization-v0.1.0.json"
PHASE7_AUTHORIZATION = BASELINE_ROOT / "blazex-bh-03-phase-07-authorization-v0.1.0.json"
REGISTRY = RESEARCH_ROOT / "assets/quality-acceptance/blazex-acceptance-registry-v0.1.0.json"
BH02_DECISION = RESEARCH_ROOT / "assets/bh-02-baseline/blazex-bh-02-acceptance-decision-v0.1.0.json"
BH02_RECONCILIATION = RESEARCH_ROOT / "assets/bh-02-baseline/blazex-bh-02-reconciliation-v0.1.0.json"

OUTPUT_IDS = [
    "runtime-host-compatibility-identities",
    "runtime-discovery-prerequisite-and-manifest-validation",
    "artifact-acquisition-bundle-load-startup-and-readiness",
    "shared-compatible-runtime-instance-registry",
    "independent-root-register-mount-update-move-dispose-remount",
    "deterministic-shutdown-runtime-loss-and-cleanup",
    "mismatch-unsupported-and-fallback-diagnostics",
    "active-browser-profile-integration",
    "root-readiness-memory-growth-and-reliability-evidence",
]
BOUNDARY_IDS = ["blazex_runtime_popcorn", "blazex_host_browser", "js/blazex_runtime", "profiles/browser_phoenix", "integration/bh-03"]
COMPATIBILITY_IDS = ["blazex.browser-host/1", "blazex.popcorn-runtime-adapter/1", "blazex.browser-runtime-loader/1", "blazex.browser-profile-manifest/1", "blazex.browser-root-lifecycle/1"]
HOST_STATES = ["inactive", "discovering", "validating", "acquiring", "starting", "ready", "stopping", "stopped", "failed"]
ROOT_STATES = ["unregistered", "registered", "mounting", "ready", "moving", "disposing", "disposed", "failed"]
FAILURE_CLASSES = ["unsupported-prerequisite", "manifest-invalid", "identity-mismatch", "artifact-integrity", "artifact-unavailable", "runtime-startup", "bundle-load", "readiness-timeout", "duplicate-root", "stale-generation", "runtime-loss", "shutdown-timeout", "ownership-violation"]
EMPTY_EVIDENCE_FIELDS = ["fixture_sets", "scenarios", "browser_results", "runtime_results", "root_results", "failure_results", "measurements", "acceptance_evidence"]
SECTION_COMMITS = [
    {"section": "1.1", "commit": "fa68b22"},
    {"section": "1.2", "commit": "5252f8b"},
    {"section": "1.3", "commit": "334f047"},
    {"section": "1.4", "commit": "resolve-from-this-records-git-commit"},
]
PHASE2_STATUSES = {
    "blazex_runtime_popcorn": "experimental-bh03-phase2-compatibility-identity",
    "blazex_host_browser": "experimental-bh03-phase2-identity-negotiation",
    "js/blazex_runtime": "experimental-bh03-phase2-identity-negotiation",
    "profiles/browser_phoenix": "experimental-bh03-phase2-profile-manifest",
}
PHASE3_STATUSES = {
    "blazex_runtime_popcorn": "experimental-bh03-phase3-startup-descriptor",
    "blazex_host_browser": "experimental-bh03-phase3-isolated-startup-boundary",
    "js/blazex_runtime": "experimental-bh03-phase3-acquisition-startup-readiness",
}
PHASE4_STATUSES = {
    "blazex_host_browser": "experimental-bh03-phase4-shared-runtime-roots",
    "js/blazex_runtime": "experimental-bh03-phase4-shared-runtime-roots",
}
PHASE5_STATUSES = {
    "blazex_host_browser": "experimental-bh03-phase5-recovery-fallback",
    "js/blazex_runtime": "experimental-bh03-phase5-recovery-fallback",
}
PHASE6_STATUSES = {
    "js/blazex_runtime": "experimental-bh03-phase6-browser-profile",
    "profiles/browser_phoenix": "experimental-bh03-phase6-browser-profile",
}
PHASE7_STATUSES = {
    "js/blazex_runtime": "experimental-bh03-phase7-measurements",
    "profiles/browser_phoenix": "experimental-bh03-phase7-measurements",
}


class ValidationError(Exception):
    """Raised when BH-03 activation must fail closed."""


def _load(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ValidationError(f"cannot load {path}: {exc}") from exc
    if not isinstance(value, dict):
        raise ValidationError(f"{path} must contain an object")
    return value


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _require(condition: bool, message: str) -> None:
    if not condition:
        raise ValidationError(message)


def validate_authorization(auth: dict[str, Any], repo_root: Path = REPO_ROOT) -> None:
    _require(auth.get("authorization_id") == "BX-BH03-PHASE-01-AUTHORIZATION-0.1", "authorization ID is missing")
    _require(auth.get("status") == "approved-phase-1-only", "BH-03 Phase 1 lacks explicit approval")
    approver = auth.get("approved_by", {})
    _require(approver.get("identity") and approver.get("role") == "repository-owner", "repository-owner approval is incomplete")
    activation = auth.get("activation", {})
    base = str(activation.get("base_revision", ""))
    _require(len(base) == 40 and base == activation.get("base_remote_revision"), "synchronized base is invalid")
    _require(activation.get("main_synchronized_before_branch") is True, "main synchronization is not recorded")
    _require(activation.get("working_branch") == "codex/bh-03-phase-01-activation", "working branch is invalid")
    rules = auth.get("delivery_rules", {})
    for key in ("sections_in_order", "commit_per_section", "single_pull_request", "merge_pull_request", "return_to_synchronized_main_after_delivery", "delete_local_feature_branch_after_delivery", "delete_remote_feature_branch_after_delivery"):
        _require(rules.get(key) is True, f"delivery rule is missing: {key}")
    _require(rules.get("section_count") == 4, "Phase 1 must have four section commits")
    for binding in auth.get("approval_basis", []):
        path = repo_root / str(binding.get("path", ""))
        _require(path.is_file(), f"authorization input is missing: {path}")
        _require(_sha256(path) == binding.get("sha256") or planning_policy.source_amendment_is_bound(path, binding.get("sha256")), f"authorization input is stale: {path}")
    excluded = " ".join(auth.get("not_authorized", [])).lower()
    for phrase in ("phase 2", "runtime discovery", "public api stability", "support claims", "canonical generated acceptance registry"):
        _require(phrase in excluded, f"authorization does not exclude {phrase}")
    result = subprocess.run(["git", "merge-base", "--is-ancestor", base, "HEAD"], cwd=repo_root, capture_output=True, text=True, check=False)
    _require(result.returncode == 0, "current work does not descend from the authorized base")


def validate_ledger(ledger: dict[str, Any], registry: dict[str, Any], decision: dict[str, Any], reconciliation: dict[str, Any]) -> None:
    _require(ledger.get("authorization_ref") == "BX-BH03-PHASE-01-AUTHORIZATION-0.1", "ledger authorization is missing")
    outputs = ledger.get("required_outputs", [])
    _require([row.get("id") for row in outputs] == OUTPUT_IDS, "required outputs are incomplete or reordered")
    _require(all(row.get("state") == "planned-unimplemented" for row in outputs), "required output overclaims implementation")
    expected_acceptance = [row["id"] for row in registry.get("acceptance_conditions", []) if row.get("responsible_milestone") == "BH-03"]
    _require(ledger.get("first_responsible_acceptance_ids") == expected_acceptance and len(expected_acceptance) == 10, "BH-03 acceptance handoff diverges")
    expected_conditions = [row["id"] for row in decision.get("conditions", []) if row.get("disposition") == "preserved"]
    _require(ledger.get("inherited_condition_ids") == expected_conditions, "inherited conditions diverge")
    _require(ledger.get("satisfied_predecessor_condition") == "BX-BH01-CONDITION-FIXTURE-DISPOSABILITY", "satisfied predecessor condition is missing")
    _require(ledger.get("inherited_open_finding_ids") == decision.get("open_findings"), "open findings diverge")
    _require(ledger.get("deferred_qualification_ids") == [row["id"] for row in reconciliation.get("deferred_qualification", [])], "deferred qualifications diverge")
    _require([row.get("id") for row in ledger.get("activation_boundaries", [])] == BOUNDARY_IDS, "activation boundaries diverge")
    evidence = ledger.get("evidence_boundary", {})
    _require(evidence.get("lifecycle_contracts") == "planned-unimplemented" and evidence.get("runtime_behavior") == "unimplemented", "ledger overclaims lifecycle implementation")
    _require(evidence.get("acceptance_conditions") == "planned" and evidence.get("support") == "unsupported", "ledger overclaims acceptance or support")
    _require(evidence.get("next_phase") == "eligible-after-phase-1-not-authorized", "ledger authorizes Phase 2")


def validate_contract(contract: dict[str, Any]) -> None:
    _require(contract.get("status") == "authorized-planned-unimplemented", "contract overclaims implementation")
    _require([row.get("id") for row in contract.get("compatibility_identities", [])] == COMPATIBILITY_IDS, "compatibility identities diverge")
    _require(all(row.get("state") == "planned-unimplemented" for row in contract["compatibility_identities"]), "compatibility identity overclaims implementation")
    _require(contract.get("host_states") == HOST_STATES, "host lifecycle vocabulary diverges")
    _require(contract.get("root_states") == ROOT_STATES, "root lifecycle vocabulary diverges")
    _require(contract.get("failure_classes") == FAILURE_CLASSES, "failure vocabulary diverges")
    _require([row.get("id") for row in contract.get("repository_boundaries", [])] == BOUNDARY_IDS, "contract boundaries diverge")
    negotiation = contract.get("version_negotiation", {})
    _require(negotiation.get("state") == "planned-unimplemented" and negotiation.get("partial_activation") == "forbidden", "version negotiation overclaims behavior")
    evidence = contract.get("evidence_boundary", {})
    _require(all(evidence.get(key) == 0 for key in ("fixtures", "scenarios", "browser_results", "measurements", "acceptance_evidence")), "contract contains premature evidence")
    _require(evidence.get("implementation") == "unimplemented" and evidence.get("later_phases") == "not-authorized", "contract implements or authorizes later work")
    _require(evidence.get("public_api_state") == "experimental-not-stable" and evidence.get("support_state") == "unsupported", "contract promotes stability or support")
    serialized = json.dumps(contract).lower()
    for phrase in ("boot_fixture", "dispatch_fixture_message", "dispose_fixture"):
        _require(phrase not in serialized, f"disposable BH-01 fixture protocol leaked into BH-03 contract: {phrase}")


def _mix_dependencies(path: Path) -> list[str]:
    text = (path / "mix.exs").read_text(encoding="utf-8")
    return re.findall(r"\{:\s*([a-z0-9_]+)\s*,", text)


def validate_activation(activation: dict[str, Any], contract: dict[str, Any], repo_root: Path = REPO_ROOT, phase2_authorized: bool = False, phase3_authorized: bool = False, phase4_authorized: bool = False, phase5_authorized: bool = False, phase6_authorized: bool = False) -> None:
    phase7_authorized = PHASE7_AUTHORIZATION.is_file() and _load(PHASE7_AUTHORIZATION).get("status") == "approved-phase-7-only"
    boundaries = activation.get("boundaries", [])
    _require([row.get("id") for row in boundaries] == BOUNDARY_IDS and len({row.get("id") for row in boundaries}) == 5, "activation boundaries are incomplete or duplicated")
    contract_rows = {row["id"]: row for row in contract.get("repository_boundaries", [])}
    for row in boundaries:
        path = repo_root / row["path"]
        _require(path.is_dir(), f"activation path is missing: {path}")
        metadata_path = path / "blazex.project.json"
        if metadata_path.is_file():
            metadata = _load(metadata_path)
            for key in ("id", "path", "kind", "owner_role"):
                _require(metadata.get(key) == row.get(key), f"activation metadata differs: {row['id']} {key}")
            current_matches = metadata.get("current_phase") == row.get("current_phase") and metadata.get("status") == row.get("status")
            successor_matches = phase2_authorized and metadata.get("current_phase") == "BH-03 Phase 2" and metadata.get("status") == PHASE2_STATUSES.get(row["id"])
            phase3_matches = phase3_authorized and metadata.get("current_phase") == "BH-03 Phase 3" and metadata.get("status") == PHASE3_STATUSES.get(row["id"])
            phase4_matches = phase4_authorized and metadata.get("current_phase") == "BH-03 Phase 4" and metadata.get("status") == PHASE4_STATUSES.get(row["id"])
            phase5_matches = phase5_authorized and metadata.get("current_phase") == "BH-03 Phase 5" and metadata.get("status") == PHASE5_STATUSES.get(row["id"])
            phase6_matches = phase6_authorized and metadata.get("current_phase") == "BH-03 Phase 6" and metadata.get("status") == PHASE6_STATUSES.get(row["id"])
            phase7_matches = phase7_authorized and metadata.get("current_phase") == "BH-03 Phase 7" and metadata.get("status") == PHASE7_STATUSES.get(row["id"])
            _require(current_matches or successor_matches or phase3_matches or phase4_matches or phase5_matches or phase6_matches or phase7_matches, f"activation metadata differs: {row['id']} current phase or status")
            _require(metadata.get("activation_phase") == row.get("origin_activation"), f"origin activation was rewritten: {row['id']}")
            _require(metadata.get("public_api_state") == "experimental-not-stable", f"public API was promoted: {row['id']}")
        manifest = path / contract_rows[row["id"]]["manifest"]
        _require(manifest.is_file(), f"activation manifest is missing: {manifest}")
    _require(_mix_dependencies(repo_root / "packages/blazex_runtime_popcorn") == [], "runtime adapter acquired a dependency")
    _require(_mix_dependencies(repo_root / "packages/blazex_host_browser") == [], "browser host acquired a dependency")
    expected_profile = contract_rows["profiles/browser_phoenix"]["dependencies"]
    _require(_mix_dependencies(repo_root / "profiles/browser_phoenix") == expected_profile, "profile dependency inventory is stale")
    package = _load(repo_root / "js/blazex_runtime/package.json")
    _require(package.get("dependencies") == {}, "browser loader acquired a runtime dependency")
    _require(package.get("devDependencies") == {"esbuild": "0.28.2", "playwright-core": "1.62.1"}, "browser loader development pins changed")
    _require(activation.get("actual_dependency_edges") == ["profiles/browser_phoenix -> blazex_phoenix", "profiles/browser_phoenix -> blazex_renderer_dom_liveview"], "actual dependency edges are stale")
    _require(activation.get("lifecycle_behavior") == "unimplemented" and activation.get("next_authorized_work") is None, "activation overclaims behavior or later authority")
    _require(activation.get("api_state") == "experimental-not-stable" and activation.get("support_state") == "unsupported", "activation promotes stability or support")


def validate_phase2_authorization(auth: dict[str, Any], repo_root: Path = REPO_ROOT) -> None:
    _require(auth.get("authorization_id") == "BX-BH03-PHASE-02-AUTHORIZATION-0.1", "Phase 2 authorization ID is invalid")
    _require(auth.get("status") == "approved-phase-2-only", "BH-03 Phase 2 lacks explicit approval")
    approver = auth.get("approved_by", {})
    _require(approver.get("identity") and approver.get("role") == "repository-owner", "Phase 2 repository-owner approval is incomplete")
    activation = auth.get("activation", {})
    base = str(activation.get("base_revision", ""))
    _require(base == "0d4d70231ecc2b0f6ca839b72a5ba55bea36e590" and base == activation.get("base_remote_revision"), "Phase 2 synchronized base is invalid")
    _require(activation.get("main_synchronized_before_branch") is True, "Phase 2 main synchronization is not recorded")
    for binding in auth.get("approval_basis", []):
        path = repo_root / str(binding.get("path", ""))
        _require(path.is_file() and (_sha256(path) == binding.get("sha256") or planning_policy.source_amendment_is_bound(path, binding.get("sha256"))), f"Phase 2 authorization input is stale: {path}")
    result = subprocess.run(["git", "merge-base", "--is-ancestor", base, "HEAD"], cwd=repo_root, capture_output=True, text=True, check=False)
    _require(result.returncode == 0, "current work does not descend from the Phase 2 authorized base")


def validate_integration(index: dict[str, Any], repo_root: Path = REPO_ROOT, phase2_authorized: bool = False, phase3_authorized: bool = False, phase4_authorized: bool = False, phase5_authorized: bool = False, phase6_authorized: bool = False) -> None:
    phase1_state = index.get("status") == "activated-no-lifecycle-fixtures-or-results" and all(index.get(key) == [] for key in EMPTY_EVIDENCE_FIELDS)
    _require(phase1_state, "integration index is not the immutable empty Phase 1 activation")
    _require(index.get("next_authorized_work") is None, "integration index authorizes later work")
    _require(index.get("api_state") == "experimental-not-stable" and index.get("support_state") == "unsupported", "integration index promotes stability or support")
    successor_index = repo_root / "integration/bh-03/integration-index-v0.2.0.json"
    successor_state = phase2_authorized and successor_index.is_file()
    phase3_index = repo_root / "integration/bh-03/integration-index-v0.3.0.json"
    phase3_state = phase3_authorized and phase3_index.is_file()
    phase4_index = repo_root / "integration/bh-03/integration-index-v0.4.0.json"
    phase4_state = phase4_authorized and phase4_index.is_file()
    phase5_index = repo_root / "integration/bh-03/integration-index-v0.5.0.json"
    phase5_state = phase5_authorized and phase5_index.is_file()
    phase6_index = repo_root / "integration/bh-03/integration-index-v0.6.0.json"
    phase6_state = phase6_authorized and phase6_index.is_file()
    phase7_state = PHASE7_AUTHORIZATION.is_file() and _load(PHASE7_AUTHORIZATION).get("status") == "approved-phase-7-only" and (repo_root / "integration/bh-03/integration-index-v0.7.0.json").is_file()
    files = {path.name for path in (repo_root / "integration/bh-03").iterdir() if path.is_file()}
    expected_files = {"README.md", "integration-index-v0.1.0.json"}
    if successor_state:
        expected_files.add("integration-index-v0.2.0.json")
    if phase3_state:
        expected_files.add("integration-index-v0.3.0.json")
    if phase4_state:
        expected_files.add("integration-index-v0.4.0.json")
    if phase5_state:
        expected_files.add("integration-index-v0.5.0.json")
    if phase6_state:
        expected_files.add("integration-index-v0.6.0.json")
    if phase7_state:
        expected_files.add("integration-index-v0.7.0.json")
    _require(files == expected_files, "unowned BH-03 integration artifact exists")
    directories = {path.name for path in (repo_root / "integration/bh-03").iterdir() if path.is_dir()}
    expected_directories = set()
    if successor_state:
        expected_directories.add("phase-02")
    if phase3_state:
        expected_directories.add("phase-03")
    if phase4_state:
        expected_directories.add("phase-04")
    if phase5_state:
        expected_directories.add("phase-05")
    if phase6_state:
        expected_directories.add("phase-06")
    if phase7_state:
        expected_directories.add("phase-07")
    _require(directories == expected_directories, "unowned BH-03 integration directory exists")


def validate_completion(completion: dict[str, Any], repo_root: Path = REPO_ROOT) -> None:
    _require(completion.get("record_id") == "BX-BH03-DECISION-PHASE-01-GO", "completion decision ID is invalid")
    _require(completion.get("state") == "passed", "completion decision does not pass")
    _require(completion.get("authorization_ref") == "BX-BH03-PHASE-01-AUTHORIZATION-0.1", "completion authorization is missing")
    _require(completion.get("section_commits") == SECTION_COMMITS, "completion section commits diverge")
    bindings = completion.get("artifact_hashes", [])
    _require(len(bindings) == 7 and len({row.get("path") for row in bindings}) == 7, "completion artifact bindings diverge")
    for binding in bindings:
        path = repo_root / str(binding.get("path", ""))
        _require(path.is_file(), f"completion artifact is missing: {path}")
        _require(_sha256(path) == binding.get("sha256"), f"completion artifact is stale: {path}")
    outcome = completion.get("outcome", {})
    _require(outcome.get("activated_boundaries") == 5, "completion boundary count diverges")
    _require(outcome.get("required_outputs") == "nine-of-nine-planned-unimplemented", "completion overclaims outputs")
    _require(outcome.get("acceptance_conditions") == "ten-of-ten-planned-unexecuted", "completion overclaims acceptance")
    _require(outcome.get("lifecycle_behavior") == "unimplemented" and outcome.get("integration_evidence") == "empty", "completion overclaims lifecycle evidence")
    _require(outcome.get("public_api_state") == "experimental-not-stable" and outcome.get("support_state") == "unsupported", "completion promotes stability or support")
    _require(outcome.get("next_phase") == "BH-03 Phase 2 eligible but not authorized", "completion authorizes Phase 2")
    _require(completion.get("next_authorized_work") is None and completion.get("next_eligible_phase") == "BH-03 Phase 2", "completion next-work state diverges")


def validate(repo_root: Path = REPO_ROOT, research_root: Path = RESEARCH_ROOT) -> None:
    auth = _load(research_root / AUTHORIZATION.relative_to(RESEARCH_ROOT))
    ledger = _load(research_root / LEDGER.relative_to(RESEARCH_ROOT))
    contract = _load(research_root / CONTRACT.relative_to(RESEARCH_ROOT))
    activation = _load(research_root / ACTIVATION.relative_to(RESEARCH_ROOT))
    index = _load(repo_root / INTEGRATION_INDEX.relative_to(REPO_ROOT))
    completion = _load(research_root / COMPLETION.relative_to(RESEARCH_ROOT))
    phase2_authorization = _load(research_root / PHASE2_AUTHORIZATION.relative_to(RESEARCH_ROOT))
    phase3_authorization = _load(research_root / PHASE3_AUTHORIZATION.relative_to(RESEARCH_ROOT))
    phase4_authorization = _load(research_root / PHASE4_AUTHORIZATION.relative_to(RESEARCH_ROOT))
    phase5_authorization = _load(research_root / PHASE5_AUTHORIZATION.relative_to(RESEARCH_ROOT))
    phase6_authorization = _load(research_root / PHASE6_AUTHORIZATION.relative_to(RESEARCH_ROOT))
    registry = _load(research_root / REGISTRY.relative_to(RESEARCH_ROOT))
    decision = _load(research_root / BH02_DECISION.relative_to(RESEARCH_ROOT))
    reconciliation = _load(research_root / BH02_RECONCILIATION.relative_to(RESEARCH_ROOT))
    validate_authorization(auth, repo_root)
    validate_ledger(ledger, registry, decision, reconciliation)
    validate_contract(contract)
    validate_phase2_authorization(phase2_authorization, repo_root)
    _require(phase3_authorization.get("status") == "approved-phase-3-only", "BH-03 Phase 3 lacks explicit approval")
    _require(phase4_authorization.get("status") == "approved-phase-4-only", "BH-03 Phase 4 lacks explicit approval")
    _require(phase5_authorization.get("status") == "approved-phase-5-only", "BH-03 Phase 5 lacks explicit approval")
    _require(phase6_authorization.get("status") == "approved-phase-6-only", "Phase 6 authorization is invalid")
    validate_activation(activation, contract, repo_root, phase2_authorized=True, phase3_authorized=True, phase4_authorized=True, phase5_authorized=True, phase6_authorized=True)
    validate_integration(index, repo_root, phase2_authorized=True, phase3_authorized=True, phase4_authorized=True, phase5_authorized=True, phase6_authorized=True)
    validate_completion(completion, repo_root)


def main() -> int:
    try:
        validate()
    except ValidationError as exc:
        print(f"BH-03 activation validation failed: {exc}", file=sys.stderr)
        return 1
    print("BH-03 Phase 1 activation passed: authority, BH-02 handoff, 9 outputs, 10 acceptance conditions, lifecycle vocabulary, 5 boundaries, empty evidence, completion bindings, and unsupported experimental state verified.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
