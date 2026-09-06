#!/usr/bin/env python3
"""Validate BH-03 Phase 4 shared-runtime and independent-root behavior."""

from __future__ import annotations

import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any


RESEARCH_ROOT = Path(__file__).resolve().parent
REPO_ROOT = RESEARCH_ROOT.parent.parent
BASELINE_ROOT = RESEARCH_ROOT / "assets/bh-03-baseline"
AUTHORIZATION = BASELINE_ROOT / "blazex-bh-03-phase-04-authorization-v0.1.0.json"
CONTRACT = BASELINE_ROOT / "blazex-bh-03-phase-04-contract-v0.1.0.json"
FIXTURES = REPO_ROOT / "integration/bh-03/phase-04/shared-runtime-root-fixtures-v0.1.0.json"
INTEGRATION_INDEX = REPO_ROOT / "integration/bh-03/integration-index-v0.4.0.json"
COMPLETION = BASELINE_ROOT / "blazex-bh-03-phase-04-completion-v0.1.0.json"
PHASE5_AUTHORIZATION = BASELINE_ROOT / "blazex-bh-03-phase-05-authorization-v0.1.0.json"
PHASE5_BASE = "a4b3f1d78f98434ae2d0a20b87be5421b9f53ada"

SCOPE_STATES = ["starting", "ready", "failed"]
ROOT_STATES = ["unregistered", "registered", "mounting", "ready", "moving", "disposing", "disposed", "failed"]
OPERATIONS = ["root.register", "root.mount", "root.update", "root.move", "root.dispose"]
CASES = [
    "concurrent-startup-coalescing",
    "ready-runtime-reuse",
    "incompatible-scope-reuse",
    "sticky-startup-failure",
    "unique-root-registration",
    "reserved-or-existing-root",
    "independent-root-queues",
    "mount-update-move-dispose-remount",
    "wrong-root-generation",
    "foreign-root-acknowledgement",
    "failed-root-isolation",
    "bounded-root-registry",
]
SECTION_COMMITS = [
    {"section": "4.1", "commit": "109a0e7"},
    {"section": "4.2", "commit": "666ed96"},
    {"section": "4.3", "commit": "7cf1776"},
    {"section": "4.4", "commit": "resolve-from-this-records-git-commit"},
]
EMPTY_LATER_RESULTS = ["browser_results", "shutdown_results", "runtime_loss_results", "recovery_results", "fallback_results", "measurements", "acceptance_evidence"]


class ValidationError(Exception):
    """Raised when the Phase 4 gate must fail closed."""


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


def _sha256_at_revision(repo_root: Path, revision: str, path: str) -> str | None:
    result = subprocess.run(["git", "show", f"{revision}:{path}"], cwd=repo_root, capture_output=True, check=False)
    return hashlib.sha256(result.stdout).hexdigest() if result.returncode == 0 else None


def _require(condition: bool, message: str) -> None:
    if not condition:
        raise ValidationError(message)


def validate_authorization(auth: dict[str, Any], repo_root: Path = REPO_ROOT) -> None:
    _require(auth.get("authorization_id") == "BX-BH03-PHASE-04-AUTHORIZATION-0.1", "authorization ID is invalid")
    _require(auth.get("status") == "approved-phase-4-only", "BH-03 Phase 4 lacks explicit approval")
    approver = auth.get("approved_by", {})
    _require(approver.get("identity") and approver.get("role") == "repository-owner", "repository-owner approval is incomplete")
    activation = auth.get("activation", {})
    base = str(activation.get("base_revision", ""))
    _require(base == "0fec9157c14ab400fdd1615e873f0b5d2ecea9b5" and base == activation.get("base_remote_revision"), "synchronized base is invalid")
    _require(activation.get("main_synchronized_before_branch") is True, "main synchronization is not recorded")
    _require(activation.get("working_branch") == "codex/bh-03-phase-04-shared-runtime-roots", "working branch is invalid")
    rules = auth.get("delivery_rules", {})
    _require(rules.get("section_count") == 4, "Phase 4 must have four sections")
    for key in ("sections_in_order", "commit_per_section", "single_pull_request", "merge_pull_request", "return_to_synchronized_main_after_delivery", "delete_local_feature_branch_after_delivery", "delete_remote_feature_branch_after_delivery"):
        _require(rules.get(key) is True, f"delivery rule is missing: {key}")
    for binding in auth.get("approval_basis", []):
        path = repo_root / str(binding.get("path", ""))
        _require(path.is_file() and _sha256(path) == binding.get("sha256"), f"authorization input is stale: {path}")
    excluded = " ".join(auth.get("not_authorized", [])).lower()
    for phrase in ("phase 5", "runtime shutdown", "runtime-loss", "recovery", "fallback", "browser-profile composition", "measurements", "support claims"):
        _require(phrase in excluded, f"authorization does not exclude {phrase}")
    result = subprocess.run(["git", "merge-base", "--is-ancestor", base, "HEAD"], cwd=repo_root, capture_output=True, text=True, check=False)
    _require(result.returncode == 0, "current work does not descend from the authorized base")


def validate_contract(contract: dict[str, Any]) -> None:
    _require(contract.get("contract_id") == "BX-BH03-PHASE-04-CONTRACT-0.1" and contract.get("status") == "authorized-experimental", "contract identity or status is invalid")
    _require(contract.get("authorization_ref") == "BX-BH03-PHASE-04-AUTHORIZATION-0.1", "contract authorization is missing")
    registry = contract.get("runtime_registry", {})
    _require(registry.get("protocol") == "blazex.runtime-registry/1" and registry.get("max_scopes") == 16, "runtime registry identity or scope limit diverges")
    _require(registry.get("states") == SCOPE_STATES, "runtime registry states diverge")
    _require(registry.get("compatibility") == "complete-exact-opaque-identity-table", "runtime registry compatibility is not exact")
    _require(registry.get("startup") == "one-coalesced-attempt-per-scope" and registry.get("ready_reuse") == "same-scope-and-compatibility-returns-same-runtime-scope", "runtime sharing is not coalesced and exact")
    _require(registry.get("failure") == "sticky-tombstone-no-retry-or-fallback" and registry.get("runtime_release_owner") == "registry-not-root", "runtime failure or ownership policy diverges")
    roots = contract.get("root_lifecycle", {})
    _require(roots.get("protocol") == "blazex.root-lifecycle/1" and roots.get("max_roots_per_scope") == 64, "root lifecycle identity or limit diverges")
    _require(roots.get("states") == ROOT_STATES and roots.get("operations") == OPERATIONS, "root lifecycle vocabulary diverges")
    _require(roots.get("serialization") == "one-fifo-queue-per-root" and roots.get("cross_root_progress") == "independent", "root queue independence diverges")
    _require(roots.get("acknowledgement") == ["root-id", "root-generation"] and roots.get("generation") == "positive-safe-integer-incremented-per-dispatched-operation", "root acknowledgement contract diverges")
    _require(roots.get("remount") == "disposed-to-mounting-to-ready-on-same-registration" and roots.get("dispose") == "idempotent-after-disposed", "root disposal or remount contract diverges")
    failures = contract.get("failure_classes", {})
    _require(failures.get("duplicate-root") == ["existing-or-reserved-root-id"], "duplicate-root failure diverges")
    _require(failures.get("stale-generation") == ["wrong-root-generation"], "stale-generation failure diverges")
    _require(failures.get("ownership-violation") == ["foreign-root-acknowledgement"], "ownership failure diverges")
    deferred = set(contract.get("explicitly_deferred", []))
    for value in ("runtime-shutdown", "runtime-loss", "retry-restart-and-recovery", "fallback-execution", "browser-profile-composition", "browser-results", "resource-and-reliability-measurements", "acceptance-evidence"):
        _require(value in deferred, f"later behavior is not deferred: {value}")
    _require(contract.get("api_state") == "experimental-not-stable" and contract.get("support_state") == "unsupported", "contract promotes stability or support")


def validate_fixtures(fixtures: dict[str, Any]) -> None:
    _require(fixtures.get("fixture_set_id") == "BX-BH03-PHASE-04-SHARED-RUNTIME-ROOT-FIXTURES-0.1", "fixture set ID is invalid")
    registry = fixtures.get("runtime_registry", {})
    roots = fixtures.get("root_lifecycle", {})
    _require(registry.get("protocol") == "blazex.runtime-registry/1" and registry.get("max_scopes") == 16 and registry.get("states") == SCOPE_STATES, "fixture runtime registry diverges")
    _require(roots.get("protocol") == "blazex.root-lifecycle/1" and roots.get("max_roots_per_scope") == 64 and roots.get("states") == ROOT_STATES and roots.get("operations") == OPERATIONS, "fixture root lifecycle diverges")
    _require([row.get("id") for row in fixtures.get("cases", [])] == CASES, "fixture cases diverge")
    boundary = fixtures.get("evidence_boundary", {})
    _require(boundary.get("transport") == "injected-unit-conformance" and boundary.get("compatible_runtime_instances") == 1 and boundary.get("root_operation_conformance") is True, "fixture execution boundary diverges")
    _require(all(boundary.get(key) == 0 for key in ("runtime_shutdown_results", "runtime_loss_results", "recovery_or_fallback_results", "browser_results", "measurements", "acceptance_evidence")), "fixture overclaims later evidence")
    _require(boundary.get("api_state") == "experimental-not-stable" and boundary.get("support_state") == "unsupported", "fixture promotes stability or support")


def validate_index(index: dict[str, Any], repo_root: Path = REPO_ROOT) -> None:
    _require(index.get("index_id") == "BX-BH03-INTEGRATION-INDEX-0.4" and index.get("status") == "phase-4-shared-runtime-root-unit-conformance" and index.get("current_phase") == "BH-03 Phase 4", "integration index phase is invalid")
    fixture_sets = index.get("fixture_sets", [])
    _require([row.get("id") for row in fixture_sets] == ["BX-BH03-PHASE-02-PRE-ACQUISITION-FIXTURES-0.1", "BX-BH03-PHASE-03-STARTUP-FIXTURES-0.1", "BX-BH03-PHASE-04-SHARED-RUNTIME-ROOT-FIXTURES-0.1"], "integration fixture bindings diverge")
    _require([row.get("state") for row in fixture_sets] == ["immutable-predecessor", "immutable-predecessor", "implemented-unit-conformance"], "integration fixture states diverge")
    for row in fixture_sets:
        _require((repo_root / str(row.get("path", ""))).is_file(), f"integration fixture is missing: {row.get('path')}")
    _require(index.get("scenarios", [])[-8:] == ["concurrent-startup-coalescing", "ready-runtime-reuse", "incompatible-scope-reuse", "sticky-startup-failure", "unique-root-registration", "independent-root-queues", "mount-update-move-dispose-remount", "root-acknowledgement-validation"], "Phase 4 integration scenarios diverge")
    _require(all(index.get(field) == [] for field in EMPTY_LATER_RESULTS), "integration index contains later execution results")
    _require(index.get("next_authorized_work") is None, "integration index authorizes later work")
    _require(index.get("api_state") == "experimental-not-stable" and index.get("support_state") == "unsupported", "integration index promotes stability or support")


def _mix_dependencies(path: Path) -> list[str]:
    return re.findall(r"\{:\s*([a-z0-9_]+)\s*,", (path / "mix.exs").read_text(encoding="utf-8"))


def validate_implementation(repo_root: Path = REPO_ROOT) -> None:
    registry = (repo_root / "js/blazex_runtime/src/runtime-registry.js").read_text(encoding="utf-8")
    roots = (repo_root / "js/blazex_runtime/src/root-lifecycle.js").read_text(encoding="utf-8")
    bridge = (repo_root / "js/blazex_runtime/src/bridge-protocol.js").read_text(encoding="utf-8")
    host = (repo_root / "packages/blazex_host_browser/lib/blazex/host/browser/lifecycle.ex").read_text(encoding="utf-8")
    for marker in ("blazex.runtime-registry/1", "scope-shared", "sticky-failure", "max_scopes"):
        _require(marker in registry, f"runtime registry implementation is incomplete: {marker}")
    for marker in ("blazex.root-lifecycle/1", "#tail", "duplicate-root", "stale-generation", "ownership-violation", "owns_runtime_release: false"):
        _require(marker in roots, f"root lifecycle implementation is incomplete: {marker}")
    for operation in OPERATIONS:
        _require(f'"{operation}"' in roots and f'"{operation}"' in bridge and f'"{operation}"' in host, f"root operation is missing: {operation}")
    phase5_authorized = PHASE5_AUTHORIZATION.is_file() and _load(PHASE5_AUTHORIZATION).get("status") == "approved-phase-5-only"
    _require(".release(" not in roots, "a root acquired runtime release ownership")
    _require((phase5_authorized and "runtime.shutdown" in registry) or (not phase5_authorized and "runtime.shutdown" not in roots + registry), "registry shutdown differs without an authorized Phase 5 successor")
    metadata_expectations = {
        "packages/blazex_runtime_popcorn": ("BH-03 Phase 3", "experimental-bh03-phase3-startup-descriptor"),
        "packages/blazex_host_browser": ("BH-03 Phase 4", "experimental-bh03-phase4-shared-runtime-roots"),
        "js/blazex_runtime": ("BH-03 Phase 4", "experimental-bh03-phase4-shared-runtime-roots"),
        "profiles/browser_phoenix": ("BH-03 Phase 2", "experimental-bh03-phase2-profile-manifest"),
    }
    for path, (phase, status) in metadata_expectations.items():
        metadata = _load(repo_root / path / "blazex.project.json")
        current = metadata.get("current_phase") == phase and metadata.get("status") == status
        phase5_successor = phase5_authorized and path in {"packages/blazex_host_browser", "js/blazex_runtime"} and metadata.get("current_phase") == "BH-03 Phase 5" and metadata.get("status") == "experimental-bh03-phase5-recovery-fallback"
        _require(current or phase5_successor, f"Phase 4 metadata diverges: {path}")
        _require(metadata.get("public_api_state") == "experimental-not-stable", f"public API was promoted: {path}")
    _require(_mix_dependencies(repo_root / "packages/blazex_runtime_popcorn") == [], "runtime adapter acquired a dependency")
    _require(_mix_dependencies(repo_root / "packages/blazex_host_browser") == [], "browser host acquired a dependency")
    package = _load(repo_root / "js/blazex_runtime/package.json")
    _require(package.get("dependencies") == {}, "browser loader acquired a runtime dependency")


def validate_completion(completion: dict[str, Any], repo_root: Path = REPO_ROOT) -> None:
    _require(completion.get("record_id") == "BX-BH03-DECISION-PHASE-04-GO" and completion.get("state") == "passed", "completion decision does not pass")
    _require(completion.get("authorization_ref") == "BX-BH03-PHASE-04-AUTHORIZATION-0.1" and completion.get("contract_ref") == "BX-BH03-PHASE-04-CONTRACT-0.1", "completion authority or contract is missing")
    _require(completion.get("section_commits") == SECTION_COMMITS, "completion section commits diverge")
    bindings = completion.get("artifact_hashes", [])
    _require(len(bindings) == 13 and len({row.get("path") for row in bindings}) == 13, "completion artifact bindings diverge")
    phase5_mutable = {
        "js/blazex_runtime/src/runtime-registry.js",
        "js/blazex_runtime/test/runtime-registry.test.js",
        "js/blazex_runtime/src/root-lifecycle.js",
        "packages/blazex_host_browser/lib/blazex/host/browser/lifecycle.ex",
    }
    for binding in bindings:
        relative = str(binding.get("path", ""))
        path = repo_root / relative
        current = path.is_file() and _sha256(path) == binding.get("sha256")
        authorized_successor = relative in phase5_mutable and _sha256_at_revision(repo_root, PHASE5_BASE, relative) == binding.get("sha256")
        _require(current or authorized_successor, f"completion artifact is stale: {path}")
    outcome = completion.get("outcome", {})
    _require(outcome.get("max_scopes") == 16 and outcome.get("max_roots_per_scope") == 64 and outcome.get("conformance_cases") == 12, "completion contract counts diverge")
    _require(outcome.get("runtime_root_evidence") == "injected-transport-unit-conformance", "completion overclaims runtime/root evidence")
    _require(all(outcome.get(key) == 0 for key in ("browser_results", "shutdown_results", "runtime_loss_results", "recovery_results", "fallback_results", "measurements", "acceptance_evidence")), "completion overclaims later evidence")
    _require(outcome.get("public_api_state") == "experimental-not-stable" and outcome.get("support_state") == "unsupported", "completion promotes stability or support")
    _require(outcome.get("next_phase") == "BH-03 Phase 5 eligible but not authorized", "completion authorizes Phase 5")
    _require(completion.get("next_authorized_work") is None and completion.get("next_eligible_phase") == "BH-03 Phase 5", "completion next-work state diverges")


def validate(repo_root: Path = REPO_ROOT, research_root: Path = RESEARCH_ROOT) -> None:
    authorization = _load(research_root / AUTHORIZATION.relative_to(RESEARCH_ROOT))
    contract = _load(research_root / CONTRACT.relative_to(RESEARCH_ROOT))
    fixtures = _load(repo_root / FIXTURES.relative_to(REPO_ROOT))
    index = _load(repo_root / INTEGRATION_INDEX.relative_to(REPO_ROOT))
    completion = _load(research_root / COMPLETION.relative_to(RESEARCH_ROOT))
    validate_authorization(authorization, repo_root)
    validate_contract(contract)
    validate_fixtures(fixtures)
    validate_index(index, repo_root)
    validate_implementation(repo_root)
    validate_completion(completion, repo_root)


def main() -> int:
    try:
        validate()
    except ValidationError as exc:
        print(f"BH-03 Phase 4 shared-runtime/root validation failed: {exc}", file=sys.stderr)
        return 1
    print("BH-03 Phase 4 shared-runtime/root validation passed: exact compatible reuse, one coalesced startup per scope, 12 registry/root cases, independent FIFO roots, generation/ownership failures, completion bindings, empty later evidence, and unsupported experimental state verified.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
