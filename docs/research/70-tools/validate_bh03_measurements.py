#!/usr/bin/env python3
"""Validate BH-03 Phase 7 resource, reliability, and startup measurements."""

from __future__ import annotations

from bh03_history import phase9_historical_binding
from tooling_migration import relocated_evidence_path

import hashlib
import json
import statistics
import subprocess
import sys
from pathlib import Path
from typing import Any


from research_paths import RESEARCH_ROOT
REPO_ROOT = RESEARCH_ROOT.parent.parent
BASELINE_ROOT = RESEARCH_ROOT / "assets/bh-03-baseline"
AUTHORIZATION = BASELINE_ROOT / "blazex-bh-03-phase-07-authorization-v0.1.0.json"
CONTRACT = BASELINE_ROOT / "blazex-bh-03-phase-07-contract-v0.1.0.json"
COMPLETION = BASELINE_ROOT / "blazex-bh-03-phase-07-completion-v0.1.0.json"
FIXTURES = REPO_ROOT / "integration/bh-03/phase-07/measurement-fixtures-v0.1.0.json"
INDEX = REPO_ROOT / "integration/bh-03/integration-index-v0.7.0.json"
EVIDENCE = REPO_ROOT / "integration/fixtures/raw-evidence/bh03-phase7-measurements.json"
PLAN = RESEARCH_ROOT / "60-planning/01-browser-host/bh-03-browser-execution-host-and-runtime-boot-lifecycle/phase-07-resource-reliability-and-startup-measurements.md"
MILESTONE = PLAN.parent / "README.md"

BASE_REVISION = "eb4e1e8db89756f54b7f73803905ccdc6a5b5859"
IMPLEMENTATION_REVISION = "2a04d3a779aefd5243848826ecdc41e55699f7ca"
SCENARIOS = ["repeated-startup-readiness", "measurement-root-fanout", "resource-cleanup", "declared-failure-convergence", "capability-aware-memory-observation"]
DEFERRED = ["safari", "mobile", "physical-devices", "second-host", "manual-assistive-technology"]
BROWSERS = [
    ("chrome", "140.0.7339.80", "/usr/bin/google-chrome", "observed"),
    ("firefox", "153.0", "/home/ducky/.cache/ms-playwright/firefox-1538/firefox/firefox", "unavailable"),
]
FAILURES = [
    ("identity-mismatch", "identity-mismatch", "deployment-action"),
    ("unsupported-prerequisite", "unsupported-prerequisite", "static-content"),
    ("artifact-unavailable", "runtime-startup", "user-action"),
]
SAMPLE_FIELDS = ["iteration", "startup_to_ready_ms", "measurement_root_cycle_ms", "shutdown_ms", "runtime_memory_pages", "root_count_before_shutdown", "disposed_root_count_after_shutdown", "runtime_iframes_after_shutdown", "runtime_acknowledgements", "memory"]
SECTION_COMMITS = [
    {"section": "7.1", "commit": "a7f315f"},
    {"section": "7.2", "commit": "2a04d3a"},
    {"section": "7.3", "commit": "407bbcd"},
    {"section": "7.4", "commit": "resolve-from-this-records-git-commit"},
]


class ValidationError(Exception):
    """Raised when the Phase 7 gate must fail closed."""


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


def _sha256_at_revision(repo_root: Path, revision: str, relative: str) -> str | None:
    result = subprocess.run(["git", "show", f"{revision}:{relative}"], cwd=repo_root, capture_output=True, check=False)
    return hashlib.sha256(result.stdout).hexdigest() if result.returncode == 0 else None


def _require(condition: bool, message: str) -> None:
    if not condition:
        raise ValidationError(message)


def validate_authorization(auth: dict[str, Any], repo_root: Path = REPO_ROOT) -> None:
    _require(auth.get("authorization_id") == "BX-BH03-PHASE-07-AUTHORIZATION-0.1", "authorization ID is invalid")
    _require(auth.get("status") == "approved-phase-7-only", "BH-03 Phase 7 lacks explicit approval")
    _require(auth.get("approved_by", {}).get("role") == "repository-owner", "repository-owner approval is incomplete")
    activation = auth.get("activation", {})
    _require(activation.get("base_revision") == BASE_REVISION == activation.get("base_remote_revision"), "synchronized base is invalid")
    _require(activation.get("main_synchronized_before_branch") is True, "main synchronization is not recorded")
    _require(activation.get("working_branch") == "codex/bh-03-phase-07-resource-reliability-measurements", "working branch is invalid")
    rules = auth.get("delivery_rules", {})
    _require(rules.get("section_count") == 4, "Phase 7 must have four sections")
    for key in ("sections_in_order", "commit_per_section", "single_pull_request", "merge_pull_request", "return_to_synchronized_main_after_delivery", "delete_local_feature_branch_after_delivery", "delete_remote_feature_branch_after_delivery"):
        _require(rules.get(key) is True, f"delivery rule is missing: {key}")
    for binding in auth.get("approval_basis", []):
        path = repo_root / str(binding.get("path", ""))
        _require(path.is_file() and _sha256(path) == binding.get("sha256"), f"authorization input is stale: {path}")
    excluded = " ".join(auth.get("not_authorized", [])).lower()
    for phrase in ("phase 8", "acceptance", "release budgets", "dom interaction", "safari", "support claims"):
        _require(phrase in excluded, f"authorization does not exclude {phrase}")
    ancestry = subprocess.run(["git", "merge-base", "--is-ancestor", BASE_REVISION, "HEAD"], cwd=repo_root, check=False)
    _require(ancestry.returncode == 0, "current work does not descend from the authorized base")


def validate_contract(contract: dict[str, Any]) -> None:
    _require(contract.get("contract_id") == "BX-BH03-PHASE-07-CONTRACT-0.1" and contract.get("status") == "authorized-experimental-observation", "contract identity or status is invalid")
    sampling = contract.get("sampling", {})
    _require(sampling.get("warmup_repetitions_per_browser") == 1 and sampling.get("retained_repetitions_per_browser") == 5, "repetition contract diverges")
    _require(sampling.get("profile_roots") == 2 and sampling.get("additional_measurement_roots") == 8, "root-count contract diverges")
    _require(sampling.get("declared_failure_scenarios") == [row[0] for row in FAILURES], "declared failure contract diverges")
    _require([row.get("browser") for row in sampling.get("active_matrix", [])] == ["chrome", "firefox"], "active matrix diverges")
    evidence = contract.get("evidence_rules", {})
    _require(evidence.get("release_budgets") == "forbidden" and evidence.get("acceptance_evidence") == "empty", "contract promotes a budget or acceptance")
    _require(evidence.get("unavailable_memory_signal") == "recorded-not-failed-and-not-passed", "memory capability policy diverges")
    _require(contract.get("deferred_matrix") == DEFERRED, "deferred matrix diverges")
    _require(contract.get("api_state") == "experimental-not-stable" and contract.get("support_state") == "unsupported", "contract promotes stability or support")


def validate_fixtures(fixtures: dict[str, Any]) -> None:
    _require(fixtures.get("fixture_id") == "BX-BH03-PHASE-07-MEASUREMENT-FIXTURES-0.1" and fixtures.get("protocol") == "blazex.bh03.measurement/1", "fixture identity is invalid")
    sampling = fixtures.get("sampling", {})
    _require(sampling.get("warmup_repetitions_per_browser") == 1 and sampling.get("retained_repetitions_per_browser") == 5, "fixture repetitions diverge")
    _require(sampling.get("expected_acknowledgements_before_shutdown") == 40 and sampling.get("expected_acknowledgements_after_shutdown") == 43, "fixture acknowledgements diverge")
    _require(fixtures.get("sample_fields") == SAMPLE_FIELDS, "fixture sample fields diverge")
    _require([(row.get("id"), row.get("failure_class"), row.get("action")) for row in fixtures.get("declared_failure_scenarios", [])] == FAILURES, "fixture failure scenarios diverge")
    boundary = fixtures.get("evidence_boundary", {})
    _require(boundary.get("browser_results") == 0 and boundary.get("measurements") == 0 and boundary.get("acceptance_evidence") == 0, "fixture contains execution or acceptance evidence")
    _require(boundary.get("release_budget") is None and boundary.get("support_state") == "unsupported", "fixture promotes a budget or support")


def _describe(values: list[float]) -> dict[str, float | int]:
    return {
        "count": len(values),
        "minimum": round(min(values), 3),
        "median": round(statistics.median(values), 3),
        "maximum": round(max(values), 3),
        "mean": round(sum(values) / len(values), 3),
    }


def _validate_sample(sample: dict[str, Any], iteration: int, browser: str) -> None:
    _require(sorted(sample) == sorted(SAMPLE_FIELDS), f"sample fields diverge: {browser}")
    _require(sample.get("iteration") == iteration, f"sample iteration diverges: {browser}")
    for field in ("startup_to_ready_ms", "measurement_root_cycle_ms", "shutdown_ms"):
        value = sample.get(field)
        _require(isinstance(value, (int, float)) and not isinstance(value, bool) and 0 <= value <= 60_000, f"timing is invalid: {browser} {field}")
    _require(sample.get("runtime_memory_pages") == 256, f"runtime memory pages diverge: {browser}")
    _require(sample.get("root_count_before_shutdown") == 10 and sample.get("disposed_root_count_after_shutdown") == 10, f"root cleanup diverges: {browser}")
    _require(sample.get("runtime_iframes_after_shutdown") == 0 and sample.get("runtime_acknowledgements") == 43, f"resource cleanup diverges: {browser}")
    memory = sample.get("memory", {})
    if browser == "chrome":
        _require(sorted(memory) == sorted(["available", "api", "ready_bytes", "after_root_cycle_bytes", "after_shutdown_bytes"]), "Chrome memory fields diverge")
        _require(memory.get("available") is True and memory.get("api") == "performance.memory.usedJSHeapSize", "Chrome memory capability diverges")
        _require(all(isinstance(memory.get(key), int) and memory[key] >= 0 for key in ("ready_bytes", "after_root_cycle_bytes", "after_shutdown_bytes")), "Chrome memory bytes are invalid")
    else:
        _require(memory == {"available": False, "reason": "browser-memory-api-unavailable"}, "Firefox memory unavailability diverges")


def validate_evidence(evidence: dict[str, Any], expected_revision: str = IMPLEMENTATION_REVISION) -> None:
    _require(evidence.get("evidence_id") == "BX-BH03-PHASE-07-ACTIVE-MEASUREMENTS-0.1", "evidence ID is invalid")
    _require(evidence.get("implementation_revision") == expected_revision, "implementation revision diverges")
    _require(evidence.get("scenario_set") == SCENARIOS, "scenario set diverges")
    _require(evidence.get("sampling") == {"warmup_repetitions_per_browser": 1, "retained_repetitions_per_browser": 5, "profile_roots": 2, "additional_measurement_roots": 8}, "sampling evidence diverges")
    results = evidence.get("results", [])
    _require(len(results) == 2, "both active browser rows are required")
    for row, (browser, version, executable, memory_state) in zip(results, BROWSERS, strict=True):
        _require((row.get("browser"), row.get("browser_version"), row.get("executable")) == (browser, version, executable), f"browser identity diverges: {browser}")
        _require(row.get("result") == "passed" and row.get("scenario_set") == SCENARIOS and row.get("failures") == [], f"browser row failed: {browser}")
        _require(row.get("warmup") == {"result": "passed-discarded", "root_count_before_shutdown": 10, "disposed_root_count_after_shutdown": 10, "runtime_iframes_after_shutdown": 0}, f"warmup diverges: {browser}")
        samples = row.get("samples", [])
        _require(len(samples) == 5, f"retained sample count diverges: {browser}")
        for iteration, sample in enumerate(samples, 1):
            _validate_sample(sample, iteration, browser)
        summary = row.get("summary", {})
        _require(summary.get("sample_count") == 5 and summary.get("release_budget") is None and summary.get("support_state") == "unsupported", f"summary boundary diverges: {browser}")
        for source, target in (("startup_to_ready_ms", "startup_to_ready"), ("measurement_root_cycle_ms", "measurement_root_cycle"), ("shutdown_ms", "shutdown")):
            _require(summary.get("timing_ms", {}).get(target) == _describe([sample[source] for sample in samples]), f"timing summary diverges: {browser} {target}")
        _require(summary.get("lifecycle") == {"roots_per_sample": 10, "disposed_roots_per_sample": 10, "runtime_iframes_after_shutdown": 0, "runtime_memory_pages": 256, "runtime_acknowledgements_after_shutdown": 43}, f"lifecycle summary diverges: {browser}")
        _require(row.get("memory_growth", {}).get("state") == memory_state, f"memory growth state diverges: {browser}")
        if browser == "chrome":
            growth = [max(sample["memory"][key] for key in ("ready_bytes", "after_root_cycle_bytes", "after_shutdown_bytes")) - sample["memory"]["ready_bytes"] for sample in samples]
            _require(row["memory_growth"].get("observed_peak_growth_bytes") == _describe(growth), "Chrome memory growth summary diverges")
            _require(row["memory_growth"].get("release_budget") is None, "Chrome memory observation became a budget")
        else:
            _require(row["memory_growth"] == {"state": "unavailable", "api": None, "reason": "browser-memory-api-unavailable"}, "Firefox memory result is fabricated")
        actual_failures = [(item.get("id"), item.get("failure_class"), item.get("action")) for item in row.get("failure_scenarios", [])]
        _require(actual_failures == FAILURES and all(item.get("result") == "passed" and item.get("partial_activation") is False for item in row["failure_scenarios"]), f"declared failure convergence diverges: {browser}")
    _require([row.get("environment") for row in evidence.get("deferred", [])] == DEFERRED and all(row.get("state") == "deferred-unavailable" for row in evidence["deferred"]), "deferred rows became false passes")
    _require(evidence.get("release_budgets") == [] and evidence.get("acceptance_evidence") == [], "evidence promotes a budget or acceptance")
    _require(evidence.get("api_state") == "experimental-not-stable" and evidence.get("support_state") == "unsupported", "evidence promotes stability or support")


def validate_index(index: dict[str, Any], repo_root: Path = REPO_ROOT) -> None:
    _require(index.get("index_id") == "BX-BH03-INTEGRATION-INDEX-0.7" and index.get("status") == "phase-7-active-measurement-observations", "integration index phase is invalid")
    fixtures = index.get("fixture_sets", [])
    _require(len(fixtures) == 6 and fixtures[-1].get("state") == "implemented-active-browser-measurement", "fixture index diverges")
    _require(all((repo_root / str(row.get("path", ""))).is_file() for row in fixtures), "fixture index contains a missing path")
    _require(index.get("scenarios", [])[-5:] == SCENARIOS, "measurement scenarios diverge")
    _require([(row.get("browser"), row.get("result"), row.get("retained_samples")) for row in index.get("browser_results", [])] == [("chrome", "passed", 5), ("firefox", "passed", 5)], "browser result index diverges")
    _require([(row.get("browser"), row.get("memory_state"), row.get("cleanup_passes")) for row in index.get("measurements", [])] == [("chrome", "observed", 5), ("firefox", "unavailable", 5)], "measurement index diverges")
    _require(index.get("release_budgets") == [] and index.get("acceptance_evidence") == [], "index promotes a budget or acceptance")
    _require(index.get("next_authorized_work") is None and index.get("support_state") == "unsupported", "index authorizes or supports later work")


def validate_implementation(repo_root: Path = REPO_ROOT) -> None:
    host = (repo_root / "profiles/browser_phoenix/assets/phase6/host.js").read_text(encoding="utf-8")
    frame = (repo_root / "profiles/browser_phoenix/assets/phase6/runtime-frame.js").read_text(encoding="utf-8")
    startup = (repo_root / "js/blazex_runtime/src/runtime-startup.js").read_text(encoding="utf-8")
    support = (repo_root / "js/blazex_runtime/test/support/bh03-measurement.mjs").read_text(encoding="utf-8")
    runner = (repo_root / "js/blazex_runtime/test/browser/bh03-phase7-measurement.integration.mjs").read_text(encoding="utf-8")
    for marker in ("blazexBh03MeasureRoots", "runtime_memory_pages", "measurement_root_cycle", "runtime_iframes_after_shutdown"):
        _require(marker in host + runner, f"measurement implementation is incomplete: {marker}")
    _require('"runtime-memory"' in frame and "memory_pages" in frame and "#runtimeMemoryPages" in startup, "runtime memory-page observation is incomplete")
    for marker in ("describeSamples", "describeByteSamples", "normalizeMemoryObservation", "summarizeLifecycleSamples", "release_budget: null"):
        _require(marker in support, f"measurement normalization is incomplete: {marker}")
    _require(_sha256(repo_root / "profiles/browser_phoenix/assets/phase4/runtime-frame.js") == _sha256_at_revision(repo_root, BASE_REVISION, "profiles/browser_phoenix/assets/phase4/runtime-frame.js"), "immutable Phase 4 /bh01/ frame source changed")
    for path in ("js/blazex_runtime", "profiles/browser_phoenix"):
        metadata = _load(repo_root / path / "blazex.project.json")
        _require(metadata.get("current_phase") == "BH-03 Phase 7" and metadata.get("status") == "experimental-bh03-phase7-measurements", f"Phase 7 metadata diverges: {path}")
        _require(metadata.get("public_api_state") == "experimental-not-stable", f"public API was promoted: {path}")


def validate_completion(completion: dict[str, Any], repo_root: Path = REPO_ROOT) -> None:
    _require(completion.get("record_id") == "BX-BH03-DECISION-PHASE-07-GO" and completion.get("state") == "passed", "completion decision does not pass")
    _require(completion.get("authorization_ref") == "BX-BH03-PHASE-07-AUTHORIZATION-0.1" and completion.get("contract_ref") == "BX-BH03-PHASE-07-CONTRACT-0.1", "completion authority or contract is missing")
    _require(completion.get("section_commits") == SECTION_COMMITS, "completion section commits diverge")
    bindings = completion.get("artifact_hashes", [])
    _require(len(bindings) == 20 and len({row.get("path") for row in bindings}) == 20, "completion artifact bindings diverge")
    for binding in bindings:
        path = relocated_evidence_path(repo_root, str(binding.get("path", "")))
        _require(path.is_file() and (_sha256(path) == binding.get("sha256") or phase9_historical_binding(repo_root, binding["path"], binding.get("sha256"))), f"completion artifact is stale: {path}")
    outcome = completion.get("outcome", {})
    _require(outcome.get("active_browser_rows") == 2 and outcome.get("warmups_per_browser") == 1 and outcome.get("retained_samples_per_browser") == 5, "completion repetition counts diverge")
    _require(outcome.get("roots_per_sample") == 10 and outcome.get("cleanup_passes") == 10 and outcome.get("declared_failure_passes") == 6, "completion reliability counts diverge")
    _require(outcome.get("release_budgets") == 0 and outcome.get("acceptance_evidence") == 0, "completion promotes a budget or acceptance")
    _require(outcome.get("next_phase") == "BH-03 Phase 8 eligible but not authorized", "completion authorizes Phase 8")
    _require(completion.get("next_authorized_work") is None and completion.get("next_eligible_phase") == "BH-03 Phase 8", "completion next-work state diverges")
    _require(outcome.get("public_api_state") == "experimental-not-stable" and outcome.get("support_state") == "unsupported", "completion promotes stability or support")


def validate_plan() -> None:
    _require("- [ ]" not in PLAN.read_text(encoding="utf-8"), "Phase 7 plan still contains open work")
    milestone = " ".join(MILESTONE.read_text(encoding="utf-8").split())
    _require("Phase 7 completed" in milestone and "Phase 8 is eligible" in milestone and "complete — gate passed" in milestone, "milestone does not record the Phase 7 decision")


def validate(repo_root: Path = REPO_ROOT, research_root: Path = RESEARCH_ROOT) -> None:
    validate_authorization(_load(research_root / AUTHORIZATION.relative_to(RESEARCH_ROOT)), repo_root)
    validate_contract(_load(research_root / CONTRACT.relative_to(RESEARCH_ROOT)))
    validate_fixtures(_load(repo_root / FIXTURES.relative_to(REPO_ROOT)))
    validate_evidence(_load(repo_root / EVIDENCE.relative_to(REPO_ROOT)))
    validate_index(_load(repo_root / INDEX.relative_to(REPO_ROOT)), repo_root)
    validate_implementation(repo_root)
    validate_completion(_load(research_root / COMPLETION.relative_to(RESEARCH_ROOT)), repo_root)
    validate_plan()


def main() -> int:
    try:
        validate()
    except ValidationError as exc:
        print(f"BH-03 Phase 7 measurement validation failed: {exc}", file=sys.stderr)
        return 1
    print("BH-03 Phase 7 measurement validation passed: repeated active Chrome/Firefox startup, ten-root lifecycle, cleanup, failure convergence, capability-aware memory evidence, empty release budgets, deferred qualification, and unsupported experimental state verified.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
