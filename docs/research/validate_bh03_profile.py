#!/usr/bin/env python3
"""Validate BH-03 Phase 6 browser-profile and active-matrix conformance."""

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
AUTHORIZATION = BASELINE_ROOT / "blazex-bh-03-phase-06-authorization-v0.1.0.json"
CONTRACT = BASELINE_ROOT / "blazex-bh-03-phase-06-contract-v0.1.0.json"
COMPLETION = BASELINE_ROOT / "blazex-bh-03-phase-06-completion-v0.1.0.json"
FIXTURES = REPO_ROOT / "integration/bh-03/phase-06/browser-profile-fixtures-v0.1.0.json"
INTEGRATION_INDEX = REPO_ROOT / "integration/bh-03/integration-index-v0.6.0.json"
EVIDENCE = REPO_ROOT / "integration/fixtures/raw-evidence/bh03-phase6-browser-matrix.json"
PLAN = RESEARCH_ROOT / "60-planning/01-browser-host/bh-03-browser-execution-host-and-runtime-boot-lifecycle/phase-06-browser-profile-integration-and-active-matrix-conformance.md"
MILESTONE = PLAN.parent / "README.md"

BASE_REVISION = "8aee16c17a8e4c3130a638457ec43afe9f48fdee"
IMPLEMENTATION_REVISION = "fbb078e95b7f8eaaa014c9d01602b1a3102ca83c"
SCENARIOS = [
    "verified-profile-startup",
    "shared-runtime-two-root-lifecycle",
    "identity-mismatch-fallback",
    "unsupported-prerequisite-fallback",
    "registry-owned-shutdown",
]
READY_CHECKS = [
    "exact-manifest-and-prerequisites",
    "one-shared-runtime",
    "two-independent-root-registrations",
    "independent-mount",
    "update-and-move-isolation",
    "dispose-and-remount-isolation",
    "intentional-fallback-decisions",
    "elixir-runtime-root-acknowledgements",
]
BROWSERS = [
    ("chrome", "140.0.7339.80", "/usr/bin/google-chrome"),
    ("firefox", "153.0", "/home/ducky/.cache/ms-playwright/firefox-1538/firefox/firefox"),
]
DEFERRED = ["safari", "mobile", "physical-devices", "second-host", "manual-assistive-technology"]
SECTION_COMMITS = [
    {"section": "6.1", "commit": "a57a3b7"},
    {"section": "6.2", "commit": "fbb078e"},
    {"section": "6.3", "commit": "00c70d5"},
    {"section": "6.4", "commit": "resolve-from-this-records-git-commit"},
]


class ValidationError(Exception):
    """Raised when the Phase 6 gate must fail closed."""


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
    _require(auth.get("authorization_id") == "BX-BH03-PHASE-06-AUTHORIZATION-0.1", "authorization ID is invalid")
    _require(auth.get("status") == "approved-phase-6-only", "BH-03 Phase 6 lacks explicit approval")
    _require(auth.get("approved_by", {}).get("role") == "repository-owner", "repository-owner approval is incomplete")
    activation = auth.get("activation", {})
    _require(activation.get("base_revision") == BASE_REVISION == activation.get("base_remote_revision"), "synchronized base is invalid")
    _require(activation.get("main_synchronized_before_branch") is True, "main synchronization is not recorded")
    _require(activation.get("working_branch") == "codex/bh-03-phase-06-browser-profile", "working branch is invalid")
    rules = auth.get("delivery_rules", {})
    _require(rules.get("section_count") == 4, "Phase 6 must have four sections")
    for key in ("sections_in_order", "commit_per_section", "single_pull_request", "merge_pull_request", "return_to_synchronized_main_after_delivery", "delete_local_feature_branch_after_delivery", "delete_remote_feature_branch_after_delivery"):
        _require(rules.get(key) is True, f"delivery rule is missing: {key}")
    for binding in auth.get("approval_basis", []):
        path = repo_root / str(binding.get("path", ""))
        _require(path.is_file() and _sha256(path) == binding.get("sha256"), f"authorization input is stale: {path}")
    excluded = " ".join(auth.get("not_authorized", [])).lower()
    for phrase in ("phase 7", "measure", "acceptance", "dom interaction", "phoenix command", "safari", "support claims"):
        _require(phrase in excluded, f"authorization does not exclude {phrase}")
    ancestry = subprocess.run(["git", "merge-base", "--is-ancestor", BASE_REVISION, "HEAD"], cwd=repo_root, check=False)
    _require(ancestry.returncode == 0, "current work does not descend from the authorized base")


def validate_contract(contract: dict[str, Any]) -> None:
    _require(contract.get("contract_id") == "BX-BH03-PHASE-06-CONTRACT-0.1" and contract.get("status") == "authorized-experimental", "contract identity or status is invalid")
    profile = contract.get("profile", {})
    _require(profile.get("path") == "/bh03/" and profile.get("legacy_profile") == "/bh01/" and profile.get("legacy_profile_policy") == "immutable", "profile separation diverges")
    scenario = contract.get("scenario", {})
    _require(scenario.get("runtime_scopes") == 1 and scenario.get("compatible_open_calls") == 2 and scenario.get("expected_runtime_starts") == 1, "runtime sharing contract diverges")
    _require(scenario.get("roots") == ["primary-root", "secondary-root"], "root contract diverges")
    _require([row.get("browser") for row in contract.get("active_matrix", [])] == ["chrome", "firefox"], "active browser matrix diverges")
    _require(contract.get("active_row_rule") == "same-scenario-set-and-observed-pass-required", "active row rule diverges")
    _require(contract.get("deferred_matrix") == DEFERRED, "deferred matrix diverges")
    _require(contract.get("api_state") == "experimental-not-stable" and contract.get("support_state") == "unsupported", "contract promotes stability or support")


def validate_fixtures(fixtures: dict[str, Any]) -> None:
    _require(fixtures.get("fixture_id") == "BX-BH03-PHASE-06-BROWSER-PROFILE-FIXTURES-0.1", "fixture ID is invalid")
    _require(fixtures.get("profile_path") == "/bh03/" and fixtures.get("scenario_set") == SCENARIOS, "fixture scenario set diverges")
    _require(fixtures.get("ready_checks") == READY_CHECKS, "fixture ready checks diverge")
    expected = fixtures.get("expected", {})
    _require(expected.get("runtime_starts") == 1 and expected.get("compatible_open_calls") == 2, "fixture runtime sharing diverges")
    _require(expected.get("runtime_acknowledgements_before_shutdown") == 8 and expected.get("runtime_acknowledgements_after_shutdown") == 11, "fixture runtime acknowledgement counts diverge")
    _require(expected.get("support_state") == "unsupported", "fixture promotes browser support")


def validate_evidence(evidence: dict[str, Any]) -> None:
    _require(evidence.get("evidence_id") == "BX-BH03-PHASE-06-ACTIVE-BROWSER-MATRIX-0.1", "browser evidence ID is invalid")
    _require(evidence.get("implementation_revision") == IMPLEMENTATION_REVISION, "browser evidence implementation revision diverges")
    _require(evidence.get("scenario_set") == SCENARIOS, "browser evidence scenario set diverges")
    results = evidence.get("results", [])
    _require(len(results) == 2, "both active browser rows are required")
    for row, (browser, version, executable) in zip(results, BROWSERS, strict=True):
        _require(row.get("browser") == browser and row.get("browser_version") == version and row.get("executable") == executable, f"active browser identity diverges: {browser}")
        _require(row.get("result") == "passed" and row.get("scenario_set") == SCENARIOS and row.get("failures") == [], f"active browser row did not pass: {browser}")
        positive = row.get("observations", {}).get("positive", {})
        _require(positive.get("runtime_starts") == 1 and positive.get("shared_opens") == 2, f"runtime sharing failed: {browser}")
        _require(positive.get("roots") == {"primary-root": "ready", "secondary-root": "ready"}, f"root isolation failed: {browser}")
        _require(positive.get("runtime_acknowledgements_before_shutdown") == 8 and positive.get("runtime_acknowledgements_after_shutdown") == 11, f"Elixir acknowledgements diverge: {browser}")
        shutdown = positive.get("shutdown", {})
        _require(shutdown.get("acknowledged") is True and shutdown.get("released") is True and shutdown.get("root_failures") == 0, f"shutdown failed: {browser}")
        _require(row["observations"]["identity_mismatch"].get("action") == "deployment-action", f"mismatch fallback diverges: {browser}")
        _require(row["observations"]["unsupported_prerequisite"].get("action") == "static-content", f"prerequisite fallback diverges: {browser}")
    deferred = evidence.get("deferred", [])
    _require([row.get("environment") for row in deferred] == DEFERRED and all(row.get("state") == "deferred-unavailable" for row in deferred), "deferred rows became false passes")
    _require(evidence.get("support_state") == "unsupported", "browser evidence promotes support")


def validate_index(index: dict[str, Any], repo_root: Path = REPO_ROOT) -> None:
    _require(index.get("index_id") == "BX-BH03-INTEGRATION-INDEX-0.6" and index.get("status") == "phase-6-active-browser-conformance", "integration index phase is invalid")
    fixture_sets = index.get("fixture_sets", [])
    _require(len(fixture_sets) == 5 and fixture_sets[-1].get("state") == "implemented-active-browser-conformance", "integration fixture states diverge")
    for row in fixture_sets:
        _require((repo_root / str(row.get("path", ""))).is_file(), f"integration fixture is missing: {row.get('path')}")
    _require(index.get("scenarios", [])[-5:] == SCENARIOS, "integration scenario set diverges")
    _require([(row.get("browser"), row.get("version"), row.get("result")) for row in index.get("browser_results", [])] == [("chrome", "140.0.7339.80", "passed"), ("firefox", "153.0", "passed")], "active browser results diverge")
    _require(index.get("measurements") == [] and index.get("acceptance_evidence") == [], "integration index overclaims later evidence")
    _require(index.get("next_authorized_work") is None and index.get("support_state") == "unsupported", "integration index authorizes or supports later work")


def validate_implementation(repo_root: Path = REPO_ROOT) -> None:
    host = (repo_root / "profiles/browser_phoenix/assets/phase6/host.js").read_text(encoding="utf-8")
    builder = (repo_root / "profiles/browser_phoenix/assets/phase6/build_profile.py").read_text(encoding="utf-8")
    verifier = (repo_root / "profiles/browser_phoenix/assets/phase6/verify_profile.py").read_text(encoding="utf-8")
    plug = (repo_root / "profiles/browser_phoenix/lib/blazex_browser_phoenix/asset_plug.ex").read_text(encoding="utf-8")
    protocol = (repo_root / "integration/fixtures/browser_host/lib/blazex/bh01/browser_host/protocol.ex").read_text(encoding="utf-8")
    runner = (repo_root / "js/blazex_runtime/test/browser/bh03-phase6.integration.mjs").read_text(encoding="utf-8")
    for marker in ("BrowserRuntimeStartup", "SharedRuntimeRegistry", "inspectHostManifest", "page-runtime", "primary-root", "secondary-root", "blazexBh03Stop"):
        _require(marker in host, f"profile composition is incomplete: {marker}")
    for forbidden in ("FixtureDOMRenderer", "/commands/", "LiveView"):
        _require(forbidden not in host, f"later interaction or server behavior leaked into BH-03: {forbidden}")
    _require("priv/static/bh03" not in builder and "js/blazex_runtime/src" in builder, "profile builder boundary diverges")
    _require("support_state" in verifier and "unsupported" in verifier, "profile verifier lacks support guard")
    _require('["bh01", "bh03"]' in plug and 'static_root("bh03")' in plug, "Phoenix profile route is missing")
    for operation in ("root.register", "root.mount", "root.update", "root.move", "root.dispose", "runtime.shutdown"):
        _require(operation in protocol, f"AVM fixture operation is missing: {operation}")
    _require("chromium, firefox" in runner and "scenarioSet" in runner, "active matrix runner diverges")
    for path in ("js/blazex_runtime", "profiles/browser_phoenix"):
        metadata = _load(repo_root / path / "blazex.project.json")
        _require(metadata.get("current_phase") == "BH-03 Phase 6" and metadata.get("status") == "experimental-bh03-phase6-browser-profile", f"Phase 6 metadata diverges: {path}")
        _require(metadata.get("public_api_state") == "experimental-not-stable", f"public API was promoted: {path}")


def validate_completion(completion: dict[str, Any], repo_root: Path = REPO_ROOT) -> None:
    _require(completion.get("record_id") == "BX-BH03-DECISION-PHASE-06-GO" and completion.get("state") == "passed", "completion decision does not pass")
    _require(completion.get("authorization_ref") == "BX-BH03-PHASE-06-AUTHORIZATION-0.1" and completion.get("contract_ref") == "BX-BH03-PHASE-06-CONTRACT-0.1", "completion authority or contract is missing")
    _require(completion.get("section_commits") == SECTION_COMMITS, "completion section commits diverge")
    bindings = completion.get("artifact_hashes", [])
    _require(len(bindings) == 16 and len({row.get("path") for row in bindings}) == 16, "completion artifact bindings diverge")
    for binding in bindings:
        path = repo_root / str(binding.get("path", ""))
        _require(path.is_file() and _sha256(path) == binding.get("sha256"), f"completion artifact is stale: {path}")
    outcome = completion.get("outcome", {})
    _require(outcome.get("active_browser_rows") == 2 and outcome.get("scenarios_per_browser") == 5 and outcome.get("profile_governed_files") == 29, "completion browser counts diverge")
    _require(outcome.get("runtime_starts_per_browser") == 1 and outcome.get("roots_per_browser") == 2, "completion runtime/root counts diverge")
    _require(outcome.get("measurements") == 0 and outcome.get("acceptance_evidence") == 0, "completion overclaims later evidence")
    _require(outcome.get("next_phase") == "BH-03 Phase 7 eligible but not authorized", "completion authorizes Phase 7")
    _require(completion.get("next_authorized_work") is None and completion.get("next_eligible_phase") == "BH-03 Phase 7", "completion next-work state diverges")
    _require(outcome.get("public_api_state") == "experimental-not-stable" and outcome.get("support_state") == "unsupported", "completion promotes stability or support")


def validate_plan() -> None:
    text = PLAN.read_text(encoding="utf-8")
    _require("- [ ]" not in text, "Phase 6 plan still contains open work")
    _require("complete — gate passed" in MILESTONE.read_text(encoding="utf-8"), "milestone does not record the passed Phase 6 gate")


def validate(repo_root: Path = REPO_ROOT, research_root: Path = RESEARCH_ROOT) -> None:
    validate_authorization(_load(research_root / AUTHORIZATION.relative_to(RESEARCH_ROOT)), repo_root)
    validate_contract(_load(research_root / CONTRACT.relative_to(RESEARCH_ROOT)))
    validate_fixtures(_load(repo_root / FIXTURES.relative_to(REPO_ROOT)))
    validate_evidence(_load(repo_root / EVIDENCE.relative_to(REPO_ROOT)))
    validate_index(_load(repo_root / INTEGRATION_INDEX.relative_to(REPO_ROOT)), repo_root)
    validate_implementation(repo_root)
    validate_completion(_load(research_root / COMPLETION.relative_to(RESEARCH_ROOT)), repo_root)
    validate_plan()


def main() -> int:
    try:
        validate()
    except ValidationError as exc:
        print(f"BH-03 Phase 6 browser-profile validation failed: {exc}", file=sys.stderr)
        return 1
    print("BH-03 Phase 6 browser-profile validation passed: separate Phoenix profile, actual AtomVM/Elixir acknowledgements, identical active Chrome/Firefox scenarios, closed fallback, registry-owned shutdown, deferred qualification, and unsupported experimental state verified.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
