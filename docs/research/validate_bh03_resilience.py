#!/usr/bin/env python3
"""Validate BH-03 Phase 5 shutdown, recovery, and fallback behavior."""

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
AUTHORIZATION = BASELINE_ROOT / "blazex-bh-03-phase-05-authorization-v0.1.0.json"
CONTRACT = BASELINE_ROOT / "blazex-bh-03-phase-05-contract-v0.1.0.json"
FIXTURES = REPO_ROOT / "integration/bh-03/phase-05/resilience-fixtures-v0.1.0.json"
INTEGRATION_INDEX = REPO_ROOT / "integration/bh-03/integration-index-v0.5.0.json"
COMPLETION = BASELINE_ROOT / "blazex-bh-03-phase-05-completion-v0.1.0.json"
PHASE6_AUTHORIZATION = BASELINE_ROOT / "blazex-bh-03-phase-06-authorization-v0.1.0.json"
PHASE7_AUTHORIZATION = BASELINE_ROOT / "blazex-bh-03-phase-07-authorization-v0.1.0.json"
PHASE6_BASE = "8aee16c17a8e4c3130a638457ec43afe9f48fdee"

RUNTIME_STATES = ["starting", "ready", "stopping", "stopped", "recovering", "failed", "fallback"]
FALLBACK_CLASSES = {
    "identity-mismatch": "deployment-action",
    "unsupported-prerequisite": "static-content",
    "runtime-startup": "user-action",
    "runtime-loss": "user-action",
    "recovery-exhausted": "user-action",
}
CASES = [
    "ordered-root-drain",
    "coalesced-concurrent-close",
    "idempotent-late-close",
    "shutdown-timeout",
    "foreign-shutdown-ack",
    "stale-shutdown-ack",
    "stale-loss-report",
    "active-loss-replacement",
    "registered-root-replay",
    "ready-root-replay",
    "disposed-root-replay",
    "root-replay-failure",
    "replacement-limit",
    "non-retryable-loss",
    "closed-fallback-classes",
    "fallback-diagnostic",
]
SECTION_COMMITS = [
    {"section": "5.1", "commit": "6909002"},
    {"section": "5.2", "commit": "b3f2462"},
    {"section": "5.3", "commit": "2ae84d2"},
    {"section": "5.4", "commit": "resolve-from-this-records-git-commit"},
]


class ValidationError(Exception):
    """Raised when the Phase 5 gate must fail closed."""


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
    result = subprocess.run(
        ["git", "show", f"{revision}:{path}"],
        cwd=repo_root,
        capture_output=True,
        check=False,
    )
    return hashlib.sha256(result.stdout).hexdigest() if result.returncode == 0 else None


def _require(condition: bool, message: str) -> None:
    if not condition:
        raise ValidationError(message)


def validate_authorization(auth: dict[str, Any], repo_root: Path = REPO_ROOT) -> None:
    _require(auth.get("authorization_id") == "BX-BH03-PHASE-05-AUTHORIZATION-0.1", "authorization ID is invalid")
    _require(auth.get("status") == "approved-phase-5-only", "BH-03 Phase 5 lacks explicit approval")
    approver = auth.get("approved_by", {})
    _require(approver.get("identity") and approver.get("role") == "repository-owner", "repository-owner approval is incomplete")
    activation = auth.get("activation", {})
    base = str(activation.get("base_revision", ""))
    _require(base == "a4b3f1d78f98434ae2d0a20b87be5421b9f53ada" and base == activation.get("base_remote_revision"), "synchronized base is invalid")
    _require(activation.get("main_synchronized_before_branch") is True, "main synchronization is not recorded")
    _require(activation.get("working_branch") == "codex/bh-03-phase-05-shutdown-recovery", "working branch is invalid")
    rules = auth.get("delivery_rules", {})
    _require(rules.get("section_count") == 4, "Phase 5 must have four sections")
    for key in ("sections_in_order", "commit_per_section", "single_pull_request", "merge_pull_request", "return_to_synchronized_main_after_delivery", "delete_local_feature_branch_after_delivery", "delete_remote_feature_branch_after_delivery"):
        _require(rules.get(key) is True, f"delivery rule is missing: {key}")
    for binding in auth.get("approval_basis", []):
        path = repo_root / str(binding.get("path", ""))
        _require(path.is_file() and _sha256(path) == binding.get("sha256"), f"authorization input is stale: {path}")
    excluded = " ".join(auth.get("not_authorized", [])).lower()
    for phrase in ("phase 6", "more than one runtime replacement", "dom", "active browser composition", "measurements", "acceptance", "public api stability", "support claims"):
        _require(phrase in excluded, f"authorization does not exclude {phrase}")
    result = subprocess.run(["git", "merge-base", "--is-ancestor", base, "HEAD"], cwd=repo_root, capture_output=True, text=True, check=False)
    _require(result.returncode == 0, "current work does not descend from the authorized base")


def validate_contract(contract: dict[str, Any]) -> None:
    _require(contract.get("contract_id") == "BX-BH03-PHASE-05-CONTRACT-0.1" and contract.get("status") == "authorized-experimental", "contract identity or status is invalid")
    lifecycle = contract.get("runtime_lifecycle", {})
    _require(lifecycle.get("protocol") == "blazex.runtime-registry/1" and lifecycle.get("states") == RUNTIME_STATES, "runtime lifecycle diverges")
    _require(lifecycle.get("runtime_release_owner") == "runtime-registry-not-root", "runtime release ownership diverges")
    shutdown = contract.get("shutdown", {})
    _require(shutdown.get("protocol") == "blazex.runtime-shutdown/1" and shutdown.get("operation") == "runtime.shutdown", "shutdown protocol diverges")
    _require(shutdown.get("default_timeout_ms") == 5000 and shutdown.get("max_timeout_ms") == 10000, "shutdown bounds diverge")
    _require(shutdown.get("acknowledgement") == ["scope-id", "runtime-generation"], "shutdown acknowledgement diverges")
    recovery = contract.get("runtime_loss", {})
    _require(recovery.get("protocol") == "blazex.runtime-loss/1" and recovery.get("max_replacements") == 1 and recovery.get("replacement_delay_ms") == 100, "runtime-loss bounds diverge")
    _require(recovery.get("root_replay") == "same-handles-all-or-nothing-register-and-restore", "root replay contract diverges")
    fallback = contract.get("fallback", {})
    _require(fallback.get("protocol") == "blazex.runtime-fallback/1" and fallback.get("classes") == FALLBACK_CLASSES, "fallback classes diverge")
    _require(fallback.get("presentation") == "bounded-non-dom-decision-only" and fallback.get("partial_activation") == "forbidden", "fallback presentation or activation diverges")
    deferred = set(contract.get("explicitly_deferred", []))
    for value in ("browser-profile-composition", "dom-or-html-fallback-presentation", "active-browser-results", "resource-and-reliability-measurements", "bh-03-acceptance-evidence", "public-api-stability-and-support"):
        _require(value in deferred, f"later behavior is not deferred: {value}")


def validate_fixtures(fixtures: dict[str, Any]) -> None:
    _require(fixtures.get("fixture_set_id") == "BX-BH03-PHASE-05-RESILIENCE-FIXTURES-0.1", "fixture set ID is invalid")
    _require([row.get("id") for row in fixtures.get("cases", [])] == CASES, "fixture cases diverge")
    _require(fixtures.get("shutdown", {}).get("release") == "registry-owned-exactly-once", "fixture shutdown ownership diverges")
    loss = fixtures.get("runtime_loss", {})
    _require(loss.get("max_replacements") == 1 and loss.get("replacement_delay_ms") == 100 and loss.get("root_replay") == "same-handles-all-or-nothing", "fixture recovery bounds diverge")
    fallback = fixtures.get("fallback", {})
    _require(fallback.get("presentation") == "bounded-non-dom-decision-only" and fallback.get("partial_activation") is False, "fixture fallback overclaims presentation")
    boundary = fixtures.get("evidence_boundary", {})
    _require(boundary.get("transport") == "injected-unit-conformance", "fixture transport evidence is invalid")
    _require(boundary.get("browser_profile_composition") is False and boundary.get("dom_fallback_presentation") is False, "fixture leaks Phase 6 composition")
    _require(all(boundary.get(key) == 0 for key in ("browser_results", "measurements", "acceptance_evidence")), "fixture overclaims later evidence")


def validate_index(index: dict[str, Any], repo_root: Path = REPO_ROOT) -> None:
    _require(index.get("index_id") == "BX-BH03-INTEGRATION-INDEX-0.5" and index.get("status") == "phase-5-resilience-unit-conformance" and index.get("current_phase") == "BH-03 Phase 5", "integration index phase is invalid")
    fixture_sets = index.get("fixture_sets", [])
    _require([row.get("state") for row in fixture_sets] == ["immutable-predecessor", "immutable-predecessor", "immutable-predecessor", "implemented-unit-conformance"], "integration fixture states diverge")
    for row in fixture_sets:
        _require((repo_root / str(row.get("path", ""))).is_file(), f"integration fixture is missing: {row.get('path')}")
    expected_results = {"shutdown_results": 6, "runtime_loss_results": 2, "recovery_results": 5, "fallback_results": 3}
    for field, count in expected_results.items():
        rows = index.get(field, [])
        _require(len(rows) == 1 and rows[0].get("result") == "passed" and rows[0].get("cases") == count, f"integration result diverges: {field}")
    _require(all(index.get(field) == [] for field in ("browser_results", "measurements", "acceptance_evidence")), "integration index overclaims later evidence")
    _require(index.get("next_authorized_work") is None and index.get("support_state") == "unsupported", "integration index authorizes or supports later work")


def _mix_dependencies(path: Path) -> list[str]:
    return re.findall(r"\{:\s*([a-z0-9_]+)\s*,", (path / "mix.exs").read_text(encoding="utf-8"))


def validate_implementation(repo_root: Path = REPO_ROOT) -> None:
    registry = (repo_root / "js/blazex_runtime/src/runtime-registry.js").read_text(encoding="utf-8")
    roots = (repo_root / "js/blazex_runtime/src/root-lifecycle.js").read_text(encoding="utf-8")
    host = (repo_root / "packages/blazex_host_browser/lib/blazex/host/browser/lifecycle.ex").read_text(encoding="utf-8")
    for marker in ("runtime.shutdown", "shutdown-timeout", "reportRuntimeLoss", "replacement_delay_ms", "max_replacements", "recovery-exhausted", "non-dom-decision-only", "RUNTIME_SCOPE_OWNERS"):
        _require(marker in registry, f"runtime resilience implementation is incomplete: {marker}")
    for marker in ("runtimeLost", "recover", "forceStop", "#desired", "root.mount"):
        _require(marker in roots, f"root replay implementation is incomplete: {marker}")
    for marker in ("blazex.runtime-shutdown/1", "blazex.runtime-loss/1", "blazex.runtime-fallback/1"):
        _require(marker in registry and marker in host, f"host/runtime protocol agreement is missing: {marker}")
    for forbidden in ("document.", "innerHTML", "HTMLElement", "createElement("):
        _require(forbidden not in registry + roots, f"DOM fallback leaked into reusable lifecycle: {forbidden}")
    phase6_authorized = PHASE6_AUTHORIZATION.is_file() and _load(PHASE6_AUTHORIZATION).get("status") == "approved-phase-6-only"
    phase7_authorized = PHASE7_AUTHORIZATION.is_file() and _load(PHASE7_AUTHORIZATION).get("status") == "approved-phase-7-only"
    for path in ("packages/blazex_host_browser", "js/blazex_runtime"):
        metadata = _load(repo_root / path / "blazex.project.json")
        current = metadata.get("current_phase") == "BH-03 Phase 5" and metadata.get("status") == "experimental-bh03-phase5-recovery-fallback"
        successor = phase6_authorized and path == "js/blazex_runtime" and metadata.get("current_phase") == "BH-03 Phase 6" and metadata.get("status") == "experimental-bh03-phase6-browser-profile"
        phase7_successor = phase7_authorized and path == "js/blazex_runtime" and metadata.get("current_phase") == "BH-03 Phase 7" and metadata.get("status") == "experimental-bh03-phase7-measurements"
        _require(current or successor or phase7_successor, f"Phase 5 metadata diverges: {path}")
        _require(metadata.get("public_api_state") == "experimental-not-stable", f"public API was promoted: {path}")
    _require(_mix_dependencies(repo_root / "packages/blazex_host_browser") == [], "browser host acquired a dependency")
    _require(_load(repo_root / "js/blazex_runtime/package.json").get("dependencies") == {}, "browser runtime acquired a dependency")


def validate_completion(completion: dict[str, Any], repo_root: Path = REPO_ROOT) -> None:
    _require(completion.get("record_id") == "BX-BH03-DECISION-PHASE-05-GO" and completion.get("state") == "passed", "completion decision does not pass")
    _require(completion.get("authorization_ref") == "BX-BH03-PHASE-05-AUTHORIZATION-0.1" and completion.get("contract_ref") == "BX-BH03-PHASE-05-CONTRACT-0.1", "completion authority or contract is missing")
    _require(completion.get("section_commits") == SECTION_COMMITS, "completion section commits diverge")
    bindings = completion.get("artifact_hashes", [])
    _require(len(bindings) == 14 and len({row.get("path") for row in bindings}) == 14, "completion artifact bindings diverge")
    phase6_mutable = {"docs/research/validate_bh03_resilience.py"}
    for binding in bindings:
        relative = str(binding.get("path", ""))
        path = repo_root / relative
        current = path.is_file() and _sha256(path) == binding.get("sha256")
        authorized_successor = relative in phase6_mutable and _sha256_at_revision(repo_root, PHASE6_BASE, relative) == binding.get("sha256")
        _require(current or authorized_successor, f"completion artifact is stale: {path}")
    outcome = completion.get("outcome", {})
    _require(outcome.get("conformance_cases") == 16 and outcome.get("shutdown_test_cases") == 4 and outcome.get("recovery_fallback_test_cases") == 9, "completion case counts diverge")
    _require(outcome.get("evidence") == "injected-transport-unit-conformance", "completion overclaims evidence")
    _require(all(outcome.get(key) == 0 for key in ("browser_results", "measurements", "acceptance_evidence")), "completion overclaims later evidence")
    _require(outcome.get("next_phase") == "BH-03 Phase 6 eligible but not authorized", "completion authorizes Phase 6")
    _require(completion.get("next_authorized_work") is None and completion.get("next_eligible_phase") == "BH-03 Phase 6", "completion next-work state diverges")


def validate(repo_root: Path = REPO_ROOT, research_root: Path = RESEARCH_ROOT) -> None:
    validate_authorization(_load(research_root / AUTHORIZATION.relative_to(RESEARCH_ROOT)), repo_root)
    validate_contract(_load(research_root / CONTRACT.relative_to(RESEARCH_ROOT)))
    validate_fixtures(_load(repo_root / FIXTURES.relative_to(REPO_ROOT)))
    validate_index(_load(repo_root / INTEGRATION_INDEX.relative_to(REPO_ROOT)), repo_root)
    validate_implementation(repo_root)
    validate_completion(_load(research_root / COMPLETION.relative_to(RESEARCH_ROOT)), repo_root)


def main() -> int:
    try:
        validate()
    except ValidationError as exc:
        print(f"BH-03 Phase 5 resilience validation failed: {exc}", file=sys.stderr)
        return 1
    print("BH-03 Phase 5 resilience validation passed: bounded registry shutdown, exact-generation loss handling, one replacement, same-handle atomic replay, closed non-DOM fallback, completion bindings, empty browser/measurement/acceptance evidence, and unsupported experimental state verified.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
