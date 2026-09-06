#!/usr/bin/env python3
"""Validate BH-03 Phase 3 artifact acquisition and isolated startup behavior."""

from __future__ import annotations

import base64
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
AUTHORIZATION = BASELINE_ROOT / "blazex-bh-03-phase-03-authorization-v0.1.0.json"
CONTRACT = BASELINE_ROOT / "blazex-bh-03-phase-03-contract-v0.1.0.json"
FIXTURES = REPO_ROOT / "integration/bh-03/phase-03/startup-fixtures-v0.1.0.json"
INTEGRATION_INDEX = REPO_ROOT / "integration/bh-03/integration-index-v0.3.0.json"
PROFILE_MANIFEST = REPO_ROOT / "profiles/browser_phoenix/priv/static/bh01/bh03-runtime-manifest.json"
COMPLETION = BASELINE_ROOT / "blazex-bh-03-phase-03-completion-v0.1.0.json"
PHASE4_AUTHORIZATION = BASELINE_ROOT / "blazex-bh-03-phase-04-authorization-v0.1.0.json"
PHASE5_AUTHORIZATION = BASELINE_ROOT / "blazex-bh-03-phase-05-authorization-v0.1.0.json"

ROLES = ["runtime-module", "runtime-wasm", "application-bundle"]
LIMITS = {"runtime-module": 2_097_152, "runtime-wasm": 16_777_216, "application-bundle": 33_554_432}
STARTUP = {
    "protocol": "blazex.runtime-startup/1",
    "adapter_identity": "blazex.popcorn-runtime-adapter/1",
    "engine": "fissionvm-popcorn",
    "transport_protocol": "blazex.runtime.frame/1",
    "memory_pages": 256,
    "bundle_virtual_path": "/bundle.avm",
    "entrypoint": "Elixir.BlazeX.BH01.BrowserHost.Boot",
    "readiness_event": "popcorn_app_ready",
    "required_features": ["shared-memory", "threads"],
}
CASES = [
    "verified-acquisition",
    "artifact-integrity-rejection",
    "artifact-unavailable-rejection",
    "correlated-readiness",
    "stale-readiness-rejection",
    "duplicate-readiness-rejection",
    "transport-startup-rejection",
    "bundle-load-rejection",
    "readiness-timeout",
    "startup-cancellation",
]
RESULT_FIELDS = ["browser_results", "runtime_results", "root_results", "failure_results", "measurements", "acceptance_evidence"]
SECTION_COMMITS = [
    {"section": "3.1", "commit": "54360f3"},
    {"section": "3.2", "commit": "866890e"},
    {"section": "3.3", "commit": "dd3d11e"},
    {"section": "3.4", "commit": "resolve-from-this-records-git-commit"},
]


class ValidationError(Exception):
    """Raised when the Phase 3 gate must fail closed."""


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
    _require(auth.get("authorization_id") == "BX-BH03-PHASE-03-AUTHORIZATION-0.1", "authorization ID is invalid")
    _require(auth.get("status") == "approved-phase-3-only", "BH-03 Phase 3 lacks explicit approval")
    approver = auth.get("approved_by", {})
    _require(approver.get("identity") and approver.get("role") == "repository-owner", "repository-owner approval is incomplete")
    activation = auth.get("activation", {})
    base = str(activation.get("base_revision", ""))
    _require(base == "63bc9799d45853d8f01d32e9c70cdb1113e2bdd8" and base == activation.get("base_remote_revision"), "synchronized base is invalid")
    _require(activation.get("main_synchronized_before_branch") is True, "main synchronization is not recorded")
    _require(activation.get("working_branch") == "codex/bh-03-phase-03-startup-readiness", "working branch is invalid")
    rules = auth.get("delivery_rules", {})
    _require(rules.get("section_count") == 4, "Phase 3 must have four sections")
    for key in ("sections_in_order", "commit_per_section", "single_pull_request", "merge_pull_request", "return_to_synchronized_main_after_delivery", "delete_local_feature_branch_after_delivery", "delete_remote_feature_branch_after_delivery"):
        _require(rules.get(key) is True, f"delivery rule is missing: {key}")
    for binding in auth.get("approval_basis", []):
        path = repo_root / str(binding.get("path", ""))
        _require(path.is_file() and _sha256(path) == binding.get("sha256"), f"authorization input is stale: {path}")
    excluded = " ".join(auth.get("not_authorized", [])).lower()
    for phrase in ("phase 4", "shared runtime registry", "root registration", "browser-profile composition", "measurements", "support claims"):
        _require(phrase in excluded, f"authorization does not exclude {phrase}")
    result = subprocess.run(["git", "merge-base", "--is-ancestor", base, "HEAD"], cwd=repo_root, capture_output=True, text=True, check=False)
    _require(result.returncode == 0, "current work does not descend from the authorized base")


def validate_contract(contract: dict[str, Any]) -> None:
    _require(contract.get("contract_id") == "BX-BH03-PHASE-03-CONTRACT-0.1" and contract.get("status") == "authorized-experimental", "contract identity or status is invalid")
    gate = contract.get("input_gate", {})
    _require(gate.get("protocol") == "blazex.pre-acquisition-gate/1" and gate.get("required_decision") == "eligible-for-artifact-acquisition", "input gate diverges")
    acquisition = contract.get("acquisition", {})
    _require(acquisition.get("protocol") == "blazex.artifact-acquisition/1" and acquisition.get("roles_in_order") == ROLES, "acquisition identity or order diverges")
    _require(acquisition.get("per_role_max_bytes") == LIMITS and acquisition.get("aggregate_max_bytes") == 52_428_800, "artifact byte limits diverge")
    _require(acquisition.get("publication") == "all-or-nothing-after-all-artifacts-pass", "artifact publication is not atomic")
    startup = contract.get("startup", {})
    for key, value in STARTUP.items():
        _require(startup.get(key) == value, f"startup descriptor diverges: {key}")
    _require(startup.get("attempt_timeout_default_ms") == 15_000 and startup.get("attempt_timeout_max_ms") == 60_000, "startup timeout bounds diverge")
    _require(startup.get("ready_handle_scope") == "single-attempt-not-shared", "startup handle overclaims sharing")
    failure_classes = contract.get("failure_classes", {})
    _require(list(failure_classes) == ["artifact-integrity", "artifact-unavailable", "runtime-startup", "bundle-load", "readiness-timeout"], "failure classes diverge")
    deferred = set(contract.get("explicitly_deferred", []))
    for value in ("shared-runtime-registry", "runtime-reuse", "root-registration-and-lifecycle", "browser-profile-composition", "browser-results", "measurements", "acceptance-evidence"):
        _require(value in deferred, f"later behavior is not deferred: {value}")
    _require(contract.get("api_state") == "experimental-not-stable" and contract.get("support_state") == "unsupported", "contract promotes stability or support")


def validate_fixtures(fixtures: dict[str, Any]) -> None:
    _require(fixtures.get("fixture_set_id") == "BX-BH03-PHASE-03-STARTUP-FIXTURES-0.1", "fixture set ID is invalid")
    payloads = fixtures.get("artifact_payloads", [])
    _require([row.get("role") for row in payloads] == ROLES, "fixture payload roles diverge")
    for payload in payloads:
        try:
            decoded = base64.b64decode(payload.get("base64", ""), validate=True)
        except (ValueError, TypeError) as exc:
            raise ValidationError(f"fixture payload is not valid base64: {payload.get('role')}") from exc
        _require(len(decoded) == payload.get("bytes"), f"fixture payload size diverges: {payload.get('role')}")
        _require(hashlib.sha256(decoded).hexdigest() == payload.get("sha256"), f"fixture payload digest diverges: {payload.get('role')}")
    _require(fixtures.get("startup_descriptor") == STARTUP, "fixture startup descriptor diverges")
    _require([row.get("id") for row in fixtures.get("cases", [])] == CASES, "fixture cases diverge")
    boundary = fixtures.get("evidence_boundary", {})
    _require(boundary.get("transport") == "injected-unit-conformance", "fixture transport evidence is invalid")
    _require(all(boundary.get(key) == 0 for key in ("shared_runtime_instances", "root_operations", "browser_results", "measurements", "acceptance_evidence")), "fixture overclaims later evidence")
    _require(boundary.get("api_state") == "experimental-not-stable" and boundary.get("support_state") == "unsupported", "fixture promotes stability or support")


def validate_index(index: dict[str, Any], repo_root: Path = REPO_ROOT) -> None:
    _require(index.get("index_id") == "BX-BH03-INTEGRATION-INDEX-0.3" and index.get("current_phase") == "BH-03 Phase 3", "integration index phase is invalid")
    fixtures = index.get("fixture_sets", [])
    _require([row.get("id") for row in fixtures] == ["BX-BH03-PHASE-02-PRE-ACQUISITION-FIXTURES-0.1", "BX-BH03-PHASE-03-STARTUP-FIXTURES-0.1"], "integration fixture bindings diverge")
    for row in fixtures:
        _require((repo_root / row["path"]).is_file(), f"integration fixture is missing: {row['path']}")
    _require(index.get("scenarios", [])[-4:] == ["verified-artifact-acquisition", "isolated-runtime-startup", "application-bundle-load", "bounded-correlated-readiness"], "Phase 3 integration scenarios diverge")
    _require(all(index.get(field) == [] for field in RESULT_FIELDS), "integration index contains later execution results")
    _require(index.get("next_authorized_work") is None, "integration index authorizes later work")
    _require(index.get("api_state") == "experimental-not-stable" and index.get("support_state") == "unsupported", "integration index promotes stability or support")


def _mix_dependencies(path: Path) -> list[str]:
    return re.findall(r"\{:\s*([a-z0-9_]+)\s*,", (path / "mix.exs").read_text(encoding="utf-8"))


def validate_implementation(contract: dict[str, Any], repo_root: Path = REPO_ROOT) -> None:
    acquisition = (repo_root / "js/blazex_runtime/src/artifact-acquisition.js").read_text(encoding="utf-8")
    startup = (repo_root / "js/blazex_runtime/src/runtime-startup.js").read_text(encoding="utf-8")
    adapter = (repo_root / "packages/blazex_runtime_popcorn/lib/blazex/runtime/popcorn/startup.ex").read_text(encoding="utf-8")
    for marker in ("blazex.artifact-acquisition/1", "artifact-integrity", "artifact-unavailable", "all"):
        _require(marker in acquisition, f"artifact acquisition implementation is incomplete: {marker}")
    for key, value in STARTUP.items():
        if isinstance(value, list):
            _require(all(item in startup and item in adapter for item in value), f"startup implementation diverges: {key}")
        else:
            _require(str(value) in startup and str(value) in adapter, f"startup implementation diverges: {key}")
    for forbidden in ("registerRoot(", "register_root", "sharedRuntime", "runtimeRegistry"):
        _require(forbidden not in acquisition + startup + adapter, f"Phase 4 behavior leaked into Phase 3: {forbidden}")
    expected_metadata = {
        "packages/blazex_runtime_popcorn": "experimental-bh03-phase3-startup-descriptor",
        "packages/blazex_host_browser": "experimental-bh03-phase3-isolated-startup-boundary",
        "js/blazex_runtime": "experimental-bh03-phase3-acquisition-startup-readiness",
    }
    phase4_authorized = PHASE4_AUTHORIZATION.is_file() and _load(PHASE4_AUTHORIZATION).get("status") == "approved-phase-4-only"
    phase5_authorized = PHASE5_AUTHORIZATION.is_file() and _load(PHASE5_AUTHORIZATION).get("status") == "approved-phase-5-only"
    for path, status in expected_metadata.items():
        metadata = _load(repo_root / path / "blazex.project.json")
        current = metadata.get("current_phase") == "BH-03 Phase 3" and metadata.get("status") == status
        phase4_successor = phase4_authorized and path in {"packages/blazex_host_browser", "js/blazex_runtime"} and metadata.get("current_phase") == "BH-03 Phase 4" and metadata.get("status") == "experimental-bh03-phase4-shared-runtime-roots"
        phase5_successor = phase5_authorized and path in {"packages/blazex_host_browser", "js/blazex_runtime"} and metadata.get("current_phase") == "BH-03 Phase 5" and metadata.get("status") == "experimental-bh03-phase5-recovery-fallback"
        _require(current or phase4_successor or phase5_successor, f"Phase 3 metadata diverges: {path}")
        _require(metadata.get("public_api_state") == "experimental-not-stable", f"public API was promoted: {path}")
    profile = _load(repo_root / "profiles/browser_phoenix/blazex.project.json")
    _require(profile.get("current_phase") == "BH-03 Phase 2" and profile.get("status") == "experimental-bh03-phase2-profile-manifest", "Phase 6 profile integration leaked into Phase 3")
    _require(_mix_dependencies(repo_root / "packages/blazex_runtime_popcorn") == [], "runtime adapter acquired a dependency")
    _require(_mix_dependencies(repo_root / "packages/blazex_host_browser") == [], "browser host acquired a dependency")
    package = _load(repo_root / "js/blazex_runtime/package.json")
    _require(package.get("dependencies") == {}, "browser loader acquired a runtime dependency")
    _require(contract.get("ownership", {}).get("runtime_descriptor") == "packages/blazex_runtime_popcorn", "runtime descriptor owner diverges")


def validate_profile_artifacts(manifest: dict[str, Any], repo_root: Path = REPO_ROOT) -> None:
    static_root = repo_root / "profiles/browser_phoenix/priv/static/bh01"
    _require([row.get("role") for row in manifest.get("artifacts", [])] == ROLES, "profile artifact roles diverge")
    for artifact in manifest["artifacts"]:
        path = (static_root / artifact["path"]).resolve()
        _require(path.is_file() and path.stat().st_size == artifact.get("bytes"), f"profile artifact size is stale: {artifact['id']}")
        _require(_sha256(path) == artifact.get("sha256"), f"profile artifact digest is stale: {artifact['id']}")
        _require(artifact["bytes"] <= LIMITS[artifact["role"]], f"profile artifact exceeds Phase 3 limit: {artifact['id']}")


def validate_completion(completion: dict[str, Any], repo_root: Path = REPO_ROOT) -> None:
    _require(completion.get("record_id") == "BX-BH03-DECISION-PHASE-03-GO" and completion.get("state") == "passed", "completion decision does not pass")
    _require(completion.get("authorization_ref") == "BX-BH03-PHASE-03-AUTHORIZATION-0.1", "completion authorization is missing")
    _require(completion.get("section_commits") == SECTION_COMMITS, "completion section commits diverge")
    bindings = completion.get("artifact_hashes", [])
    _require(len(bindings) == 13 and len({row.get("path") for row in bindings}) == 13, "completion artifact bindings diverge")
    for binding in bindings:
        path = repo_root / str(binding.get("path", ""))
        _require(path.is_file() and _sha256(path) == binding.get("sha256"), f"completion artifact is stale: {path}")
    outcome = completion.get("outcome", {})
    _require(outcome.get("artifact_roles") == 3 and outcome.get("conformance_cases") == 10, "completion contract counts diverge")
    _require(outcome.get("startup_evidence") == "injected-transport-unit-conformance", "completion overclaims startup evidence")
    _require(outcome.get("browser_results") == 0 and outcome.get("root_operations") == 0 and outcome.get("measurements") == 0 and outcome.get("acceptance_evidence") == 0, "completion overclaims later evidence")
    _require(outcome.get("public_api_state") == "experimental-not-stable" and outcome.get("support_state") == "unsupported", "completion promotes stability or support")
    _require(outcome.get("next_phase") == "BH-03 Phase 4 eligible but not authorized", "completion authorizes Phase 4")
    _require(completion.get("next_authorized_work") is None and completion.get("next_eligible_phase") == "BH-03 Phase 4", "completion next-work state diverges")


def validate(repo_root: Path = REPO_ROOT, research_root: Path = RESEARCH_ROOT) -> None:
    authorization = _load(research_root / AUTHORIZATION.relative_to(RESEARCH_ROOT))
    contract = _load(research_root / CONTRACT.relative_to(RESEARCH_ROOT))
    fixtures = _load(repo_root / FIXTURES.relative_to(REPO_ROOT))
    index = _load(repo_root / INTEGRATION_INDEX.relative_to(REPO_ROOT))
    profile = _load(repo_root / PROFILE_MANIFEST.relative_to(REPO_ROOT))
    completion = _load(research_root / COMPLETION.relative_to(RESEARCH_ROOT))
    validate_authorization(authorization, repo_root)
    validate_contract(contract)
    validate_fixtures(fixtures)
    validate_index(index, repo_root)
    validate_implementation(contract, repo_root)
    validate_profile_artifacts(profile, repo_root)
    validate_completion(completion, repo_root)


def main() -> int:
    try:
        validate()
    except ValidationError as exc:
        print(f"BH-03 Phase 3 startup validation failed: {exc}", file=sys.stderr)
        return 1
    print("BH-03 Phase 3 startup validation passed: 3 bounded artifact roles, 10 acquisition/startup cases, immutable adapter agreement, pinned profile artifact declarations, completion bindings, empty later-phase results, and unsupported experimental state verified.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
