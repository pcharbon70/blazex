#!/usr/bin/env python3
"""Validate BH-03 Phase 2 compatibility and pre-acquisition behavior."""

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
AUTHORIZATION = BASELINE_ROOT / "blazex-bh-03-phase-02-authorization-v0.1.0.json"
CONTRACT = BASELINE_ROOT / "blazex-bh-03-phase-02-contract-v0.1.0.json"
FIXTURES = REPO_ROOT / "integration/bh-03/phase-02/pre-acquisition-fixtures-v0.1.0.json"
INTEGRATION_INDEX = REPO_ROOT / "integration/bh-03/integration-index-v0.2.0.json"
PROFILE_MANIFEST = REPO_ROOT / "profiles/browser_phoenix/priv/static/bh01/bh03-runtime-manifest.json"
COMPLETION = BASELINE_ROOT / "blazex-bh-03-phase-02-completion-v0.1.0.json"
PHASE3_AUTHORIZATION = BASELINE_ROOT / "blazex-bh-03-phase-03-authorization-v0.1.0.json"
PHASE4_AUTHORIZATION = BASELINE_ROOT / "blazex-bh-03-phase-04-authorization-v0.1.0.json"
PHASE5_AUTHORIZATION = BASELINE_ROOT / "blazex-bh-03-phase-05-authorization-v0.1.0.json"
PHASE6_AUTHORIZATION = BASELINE_ROOT / "blazex-bh-03-phase-06-authorization-v0.1.0.json"

REQUIRED_COMPATIBILITY = {
    "browser_host": "blazex.browser-host/1",
    "runtime_adapter": "blazex.popcorn-runtime-adapter/1",
    "runtime_loader": "blazex.browser-runtime-loader/1",
    "profile_manifest": "blazex.browser-profile-manifest/1",
    "root_lifecycle": "blazex.browser-root-lifecycle/1",
    "semantic_tree": "blazex.ui-tree/1",
    "renderer": "blazex.renderer/1",
    "dom_projection": "blazex.dom-projection/1",
}
BROWSER_REQUIRED = ["webassembly", "workers", "module-scripts", "fetch", "abort-controller", "subtle-crypto"]
DEPLOYMENT_REQUIRED = ["secure-context", "cross-origin-isolation", "same-origin-artifacts"]
OPTIONAL = ["wasm-streaming"]
ARTIFACT_ROLES = ["runtime-module", "runtime-wasm", "application-bundle"]
SCENARIOS = ["compatibility-exact-match", "manifest-discovery", "prerequisite-evaluation", "strict-manifest-validation"]
RESULT_FIELDS = ["browser_results", "runtime_results", "root_results", "failure_results", "measurements", "acceptance_evidence"]
SECTION_COMMITS = [
    {"section": "2.1", "commit": "b4344e4"},
    {"section": "2.2", "commit": "492c7ca"},
    {"section": "2.3", "commit": "85dce00"},
    {"section": "2.4", "commit": "resolve-from-this-records-git-commit"},
]


class ValidationError(Exception):
    """Raised when Phase 2 must fail closed."""


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
    _require(auth.get("authorization_id") == "BX-BH03-PHASE-02-AUTHORIZATION-0.1", "authorization ID is invalid")
    _require(auth.get("status") == "approved-phase-2-only", "BH-03 Phase 2 lacks explicit approval")
    approver = auth.get("approved_by", {})
    _require(approver.get("identity") and approver.get("role") == "repository-owner", "repository-owner approval is incomplete")
    activation = auth.get("activation", {})
    base = str(activation.get("base_revision", ""))
    _require(base == "0d4d70231ecc2b0f6ca839b72a5ba55bea36e590" and base == activation.get("base_remote_revision"), "synchronized base is invalid")
    _require(activation.get("main_synchronized_before_branch") is True, "main synchronization is not recorded")
    _require(activation.get("working_branch") == "codex/bh-03-phase-02-compatibility-manifest", "working branch is invalid")
    rules = auth.get("delivery_rules", {})
    _require(rules.get("section_count") == 4, "Phase 2 must have four sections")
    for key in ("sections_in_order", "commit_per_section", "single_pull_request", "merge_pull_request", "return_to_synchronized_main_after_delivery", "delete_local_feature_branch_after_delivery", "delete_remote_feature_branch_after_delivery"):
        _require(rules.get(key) is True, f"delivery rule is missing: {key}")
    for binding in auth.get("approval_basis", []):
        path = repo_root / str(binding.get("path", ""))
        _require(path.is_file() and _sha256(path) == binding.get("sha256"), f"authorization input is stale: {path}")
    excluded = " ".join(auth.get("not_authorized", [])).lower()
    for phrase in ("phase 3", "artifact acquisition", "runtime startup", "shared runtime registry", "public api stability", "support claims"):
        _require(phrase in excluded, f"authorization does not exclude {phrase}")
    result = subprocess.run(["git", "merge-base", "--is-ancestor", base, "HEAD"], cwd=repo_root, capture_output=True, text=True, check=False)
    _require(result.returncode == 0, "current work does not descend from the authorized base")


def validate_contract(contract: dict[str, Any]) -> None:
    _require(contract.get("contract_id") == "BX-BH03-PHASE-02-CONTRACT-0.1", "contract ID is invalid")
    _require(contract.get("status") == "authorized-experimental", "contract status is invalid")
    compatibility = contract.get("compatibility", {})
    _require(compatibility.get("required") == REQUIRED_COMPATIBILITY, "compatibility identity table diverges")
    _require(compatibility.get("matching") == "exact-opaque-identity" and compatibility.get("partial_match") == "forbidden", "compatibility matching is not fail closed")
    discovery = contract.get("discovery", {})
    _require(discovery.get("sources") == ["explicit-option", "link-rel-blazex-runtime-manifest", "meta-name-blazex-runtime-manifest"], "discovery sources diverge")
    prerequisites = contract.get("prerequisites", {})
    _require(prerequisites.get("browser_required") == BROWSER_REQUIRED, "browser prerequisites diverge")
    _require(prerequisites.get("deployment_required") == DEPLOYMENT_REQUIRED, "deployment prerequisites diverge")
    _require(prerequisites.get("optional") == OPTIONAL, "optional prerequisites diverge")
    _require(prerequisites.get("decisions") == ["compatible", "alternate-loading", "unsupported-prerequisite"], "prerequisite decisions diverge")
    manifest = contract.get("manifest", {})
    _require(manifest.get("schema_version") == "1.0.0" and manifest.get("contract_identity") == "blazex.browser-profile-manifest/1", "manifest identity diverges")
    _require(manifest.get("artifact_roles") == ARTIFACT_ROLES and manifest.get("strict_unknown_fields") is True, "manifest envelope diverges")
    _require(contract.get("failure_classes") == ["identity-mismatch", "unsupported-prerequisite", "manifest-invalid"], "failure classes diverge")
    deferred = set(contract.get("explicitly_deferred", []))
    for value in ("artifact-acquisition", "runtime-startup", "shared-runtime-registry", "root-lifecycle", "browser-results", "acceptance-evidence"):
        _require(value in deferred, f"Phase 3 behavior is not deferred: {value}")
    _require(contract.get("api_state") == "experimental-not-stable" and contract.get("support_state") == "unsupported", "contract promotes stability or support")


def validate_fixtures(fixtures: dict[str, Any], contract: dict[str, Any]) -> None:
    _require(fixtures.get("fixture_set_id") == "BX-BH03-PHASE-02-PRE-ACQUISITION-FIXTURES-0.1", "fixture set ID is invalid")
    manifest = fixtures.get("valid_manifest", {})
    _require(manifest.get("compatibility") == REQUIRED_COMPATIBILITY, "fixture compatibility table diverges")
    _require(manifest.get("prerequisites") == {"browser_required": BROWSER_REQUIRED, "deployment_required": DEPLOYMENT_REQUIRED, "optional": OPTIONAL}, "fixture prerequisites diverge")
    _require([row.get("role") for row in manifest.get("artifacts", [])] == ARTIFACT_ROLES, "fixture artifact roles diverge")
    _require([row.get("id") for row in fixtures.get("identity_cases", [])] == ["exact-match", "missing-identity", "unknown-identity", "duplicate-identity", "malformed-identity", "version-mismatch"], "identity cases diverge")
    _require(len(fixtures.get("discovery_cases", [])) == 7 and len(fixtures.get("prerequisite_cases", [])) == 4, "discovery or prerequisite cases diverge")
    _require(len(fixtures.get("invalid_manifests", [])) == 10, "invalid manifest cases diverge")
    boundary = fixtures.get("evidence_boundary", {})
    _require(all(boundary.get(key) == 0 for key in ("artifact_bytes", "artifacts_acquired", "runtime_starts", "root_operations", "browser_results", "measurements", "acceptance_evidence")), "fixture overclaims execution evidence")
    _require(boundary.get("support_state") == "unsupported", "fixture promotes support")
    _require(contract.get("compatibility", {}).get("required") == manifest.get("compatibility"), "fixture and contract identities disagree")


def validate_index(index: dict[str, Any], repo_root: Path = REPO_ROOT) -> None:
    _require(index.get("status") == "phase-2-pre-acquisition-contract-fixtures" and index.get("current_phase") == "BH-03 Phase 2", "integration index phase is invalid")
    fixture_sets = index.get("fixture_sets", [])
    _require(len(fixture_sets) == 1 and fixture_sets[0].get("id") == "BX-BH03-PHASE-02-PRE-ACQUISITION-FIXTURES-0.1", "integration fixture binding diverges")
    path = repo_root / str(fixture_sets[0].get("path", ""))
    _require(path == FIXTURES and path.is_file(), "integration fixture path is invalid")
    _require(index.get("scenarios") == SCENARIOS, "integration scenarios diverge")
    _require(all(index.get(key) == [] for key in RESULT_FIELDS), "integration index contains later-phase results")
    _require(index.get("next_authorized_work") is None, "integration index authorizes later work")
    _require(index.get("api_state") == "experimental-not-stable" and index.get("support_state") == "unsupported", "integration index promotes stability or support")


def validate_artifact_declarations(manifest: dict[str, Any], static_root: Path) -> None:
    for artifact in manifest.get("artifacts", []):
        path = (static_root / artifact["path"]).resolve()
        _require(path.is_file(), f"declared profile artifact is missing: {path}")
        _require(path.stat().st_size == artifact.get("bytes"), f"declared profile artifact size is stale: {artifact['id']}")
        _require(_sha256(path) == artifact.get("sha256"), f"declared profile artifact digest is stale: {artifact['id']}")


def validate_profile_manifest(profile: dict[str, Any], fixtures: dict[str, Any], repo_root: Path = REPO_ROOT) -> None:
    _require(profile == fixtures.get("valid_manifest"), "profile manifest and canonical fixture diverge")
    validate_artifact_declarations(profile, repo_root / "profiles/browser_phoenix/priv/static/bh01")


def _mix_dependencies(path: Path) -> list[str]:
    return re.findall(r"\{:\s*([a-z0-9_]+)\s*,", (path / "mix.exs").read_text(encoding="utf-8"))


def validate_implementation(contract: dict[str, Any], repo_root: Path = REPO_ROOT) -> None:
    host_source = (repo_root / "packages/blazex_host_browser/lib/blazex/host/browser/compatibility.ex").read_text(encoding="utf-8")
    runtime_source = (repo_root / "packages/blazex_runtime_popcorn/lib/blazex/runtime/popcorn/identity.ex").read_text(encoding="utf-8")
    javascript_source = (repo_root / "js/blazex_runtime/src/compatibility.js").read_text(encoding="utf-8")
    for key, identity in REQUIRED_COMPATIBILITY.items():
        _require(f'"{key}" => "{identity}"' in host_source, f"Elixir host identity diverges: {key}")
        _require(f'{key}: "{identity}"' in javascript_source, f"JavaScript host identity diverges: {key}")
    _require('"identity" => "blazex.popcorn-runtime-adapter/1"' in runtime_source, "runtime adapter identity diverges")
    _require(_mix_dependencies(repo_root / "packages/blazex_host_browser") == [], "browser host acquired a dependency")
    _require(_mix_dependencies(repo_root / "packages/blazex_runtime_popcorn") == [], "runtime adapter acquired a dependency")
    package = _load(repo_root / "js/blazex_runtime/package.json")
    _require(package.get("dependencies") == {}, "browser loader acquired a runtime dependency")
    phase2_sources = "\n".join((repo_root / path).read_text(encoding="utf-8") for path in [
        "js/blazex_runtime/src/compatibility.js",
        "js/blazex_runtime/src/discovery.js",
        "js/blazex_runtime/src/host-manifest.js",
    ])
    for forbidden in ("fetchDeclaredArtifact(", "acquireDeclaredArtifacts(", "new BrowserRuntimeLoader", "registerRoot(", "startRuntime("):
        _require(forbidden not in phase2_sources, f"Phase 3 behavior leaked into Phase 2: {forbidden}")
    _require("artifacts_acquired: 0" in phase2_sources, "pre-acquisition boundary is not explicit")
    metadata_expectations = {
        "packages/blazex_runtime_popcorn": ("BH-03 Phase 2", "experimental-bh03-phase2-compatibility-identity", "BH-03 Phase 3", "experimental-bh03-phase3-startup-descriptor"),
        "packages/blazex_host_browser": ("BH-03 Phase 2", "experimental-bh03-phase2-identity-negotiation", "BH-03 Phase 3", "experimental-bh03-phase3-isolated-startup-boundary"),
        "js/blazex_runtime": ("BH-03 Phase 2", "experimental-bh03-phase2-identity-negotiation", "BH-03 Phase 3", "experimental-bh03-phase3-acquisition-startup-readiness"),
        "profiles/browser_phoenix": ("BH-03 Phase 2", "experimental-bh03-phase2-profile-manifest", None, None),
    }
    phase3_authorized = PHASE3_AUTHORIZATION.is_file() and _load(PHASE3_AUTHORIZATION).get("status") == "approved-phase-3-only"
    phase4_authorized = PHASE4_AUTHORIZATION.is_file() and _load(PHASE4_AUTHORIZATION).get("status") == "approved-phase-4-only"
    phase5_authorized = PHASE5_AUTHORIZATION.is_file() and _load(PHASE5_AUTHORIZATION).get("status") == "approved-phase-5-only"
    phase6_authorized = PHASE6_AUTHORIZATION.is_file() and _load(PHASE6_AUTHORIZATION).get("status") == "approved-phase-6-only"
    for path, (phase, status, successor_phase, successor_status) in metadata_expectations.items():
        metadata = _load(repo_root / path / "blazex.project.json")
        current = metadata.get("current_phase") == phase and metadata.get("status") == status
        successor = phase3_authorized and successor_phase is not None and metadata.get("current_phase") == successor_phase and metadata.get("status") == successor_status
        phase4_successor = phase4_authorized and path in {"packages/blazex_host_browser", "js/blazex_runtime"} and metadata.get("current_phase") == "BH-03 Phase 4" and metadata.get("status") == "experimental-bh03-phase4-shared-runtime-roots"
        phase5_successor = phase5_authorized and path in {"packages/blazex_host_browser", "js/blazex_runtime"} and metadata.get("current_phase") == "BH-03 Phase 5" and metadata.get("status") == "experimental-bh03-phase5-recovery-fallback"
        phase6_successor = phase6_authorized and path in {"js/blazex_runtime", "profiles/browser_phoenix"} and metadata.get("current_phase") == "BH-03 Phase 6" and metadata.get("status") == "experimental-bh03-phase6-browser-profile"
        _require(current or successor or phase4_successor or phase5_successor or phase6_successor, f"Phase 2 metadata diverges without an authorized successor: {path}")
        _require(metadata.get("public_api_state") == "experimental-not-stable", f"public API was promoted: {path}")
    _require(contract.get("owners", {}).get("browser_discovery_prerequisites_and_manifest_validation") == "js/blazex_runtime", "implementation owner diverges")


def validate_completion(completion: dict[str, Any], repo_root: Path = REPO_ROOT) -> None:
    _require(completion.get("record_id") == "BX-BH03-DECISION-PHASE-02-GO", "completion decision ID is invalid")
    _require(completion.get("state") == "passed", "completion decision does not pass")
    _require(completion.get("authorization_ref") == "BX-BH03-PHASE-02-AUTHORIZATION-0.1", "completion authorization is missing")
    _require(completion.get("section_commits") == SECTION_COMMITS, "completion section commits diverge")
    bindings = completion.get("artifact_hashes", [])
    _require(len(bindings) == 10 and len({row.get("path") for row in bindings}) == 10, "completion artifact bindings diverge")
    for binding in bindings:
        path = repo_root / str(binding.get("path", ""))
        _require(path.is_file() and _sha256(path) == binding.get("sha256"), f"completion artifact is stale: {path}")
    outcome = completion.get("outcome", {})
    _require(outcome.get("compatibility_identities") == 8 and outcome.get("contract_cases") == 27, "completion contract counts diverge")
    _require(outcome.get("artifacts_acquired") == 0 and outcome.get("runtime_starts") == 0 and outcome.get("later_phase_results") == "empty", "completion overclaims later-phase evidence")
    _require(outcome.get("public_api_state") == "experimental-not-stable" and outcome.get("support_state") == "unsupported", "completion promotes stability or support")
    _require(outcome.get("next_phase") == "BH-03 Phase 3 eligible but not authorized", "completion authorizes Phase 3")
    _require(completion.get("next_authorized_work") is None and completion.get("next_eligible_phase") == "BH-03 Phase 3", "completion next-work state diverges")


def validate(repo_root: Path = REPO_ROOT, research_root: Path = RESEARCH_ROOT) -> None:
    authorization = _load(research_root / AUTHORIZATION.relative_to(RESEARCH_ROOT))
    contract = _load(research_root / CONTRACT.relative_to(RESEARCH_ROOT))
    fixtures = _load(repo_root / FIXTURES.relative_to(REPO_ROOT))
    index = _load(repo_root / INTEGRATION_INDEX.relative_to(REPO_ROOT))
    profile = _load(repo_root / PROFILE_MANIFEST.relative_to(REPO_ROOT))
    completion = _load(research_root / COMPLETION.relative_to(RESEARCH_ROOT))
    validate_authorization(authorization, repo_root)
    validate_contract(contract)
    validate_fixtures(fixtures, contract)
    validate_index(index, repo_root)
    validate_profile_manifest(profile, fixtures, repo_root)
    validate_implementation(contract, repo_root)
    validate_completion(completion, repo_root)


def main() -> int:
    try:
        validate()
    except ValidationError as exc:
        print(f"BH-03 Phase 2 compatibility validation failed: {exc}", file=sys.stderr)
        return 1
    print("BH-03 Phase 2 compatibility validation passed: 8 exact identities, 3 discovery sources, 10 prerequisites, 3 artifact declarations, 27 conformance cases, completion bindings, empty later-phase results, and unsupported experimental state verified.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
