#!/usr/bin/env python3
"""Validate BH-02 Phase 5 renderer lifecycle and headless-oracle evidence."""

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
BASELINE_ROOT = RESEARCH_ROOT / "assets/bh-02-baseline"
AUTHORIZATION = BASELINE_ROOT / "blazex-bh-02-phase-05-authorization-v0.1.0.json"
CONTRACT = BASELINE_ROOT / "blazex-bh-02-phase-05-contract-v0.1.0.json"
LEDGER = BASELINE_ROOT / "blazex-bh-02-phase-05-output-ledger-v0.5.0.json"
PHASE_4_LEDGER = BASELINE_ROOT / "blazex-bh-02-phase-04-output-ledger-v0.4.0.json"
COMPLETION = BASELINE_ROOT / "blazex-bh-02-phase-05-completion-v0.1.0.json"
INDEX = REPO_ROOT / "integration/conformance/conformance-index-v0.5.0.json"
FIXTURES = REPO_ROOT / "integration/conformance/renderer-headless-fixtures-v0.1.0.json"

NODE_KINDS = ["text", "group", "action", "field", "selection", "collection", "surface"]
LAYOUT_MODES = ["none", "stack", "grid", "overlay"]
ACCESSIBILITY_ROLES = [
    "generic", "text", "group", "button", "text_field", "checkbox", "list",
    "list_item", "dialog", "status",
]
FEATURES = ["event_bindings", "logical_layout", "accessibility", "focus", "selection"]
CAPABILITY_FIELDS = [
    "version", "tree_versions", "node_kinds", "layout_modes", "accessibility_roles", "features",
]
REQUIREMENT_FIELDS = [
    "tree_version", "node_kinds", "layout_modes", "accessibility_roles", "features",
]
CONTEXT_FIELDS = ["version", "owner", "generation", "revision", "transition"]
CALLBACKS = ["capabilities", "mount", "update", "replace", "dispose"]
SESSION_FIELDS = [
    "backend", "capabilities", "requirements", "owner", "generation", "revision",
    "status", "backend_state", "artifact",
]
SNAPSHOT_FIELDS = [
    "version", "owner", "generation", "revision", "tree", "bindings", "layouts",
    "accessibility", "focus", "selections", "digest",
]
TRACE_FIELDS = ["sequence", "transition", "owner", "generation", "revision", "digest"]
TRANSITIONS = ["mount", "update", "replace", "dispose"]
SCENARIOS = [
    "renderer-capability-negotiation", "missing-renderer-capability", "headless-mount-snapshot",
    "headless-repeatability", "headless-update-revision", "headless-generation-replacement",
    "headless-disposal", "headless-idempotent-disposal", "unordered-declaration-normalization",
    "meaningful-child-order", "event-render-update", "effect-resource-render-disposal",
    "focus-intent-snapshot", "selection-intent-snapshot", "invalid-semantic-rejection",
    "callback-failure-atomicity",
]
OUTPUT_IDS = [
    "semantic-ui-node-identity", "event-action-contract", "effect-capability-resource-contract",
    "layout-token-accessibility-focus-selection-file-intent",
    "renderer-lifecycle-capability-negotiation", "deterministic-headless-renderer-traces",
    "minimal-dom-lowering", "limited-direct-native-control-spike",
    "forbidden-dependency-leakage-checks",
]
COMPLETION_PATHS = [
    "docs/research/assets/bh-02-baseline/blazex-bh-02-phase-05-authorization-v0.1.0.json",
    "docs/research/assets/bh-02-baseline/blazex-bh-02-phase-05-contract-v0.1.0.json",
    "docs/research/assets/bh-02-baseline/blazex-bh-02-phase-05-output-ledger-v0.5.0.json",
    "integration/conformance/renderer-headless-fixtures-v0.1.0.json",
    "integration/conformance/conformance-index-v0.5.0.json",
]
CONCRETE_LEAKAGE = re.compile(
    r"\b(?:phoenix|plug|liveview|localliveview|local_live_view|popcorn|atomvm|dom|css|javascript|html|aria|uiautomation|nsaccessibility|at-spi|win32|appkit|gtk|qt|wxwidgets)\b",
    re.IGNORECASE,
)


class ValidationError(Exception):
    """Raised when Phase 5 evidence must fail closed."""


def _load_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ValidationError(f"cannot load {path}: {exc}") from exc
    if not isinstance(value, dict):
        raise ValidationError(f"{path} must contain a JSON object")
    return value


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _require(condition: bool, message: str) -> None:
    if not condition:
        raise ValidationError(message)


def validate_authorization(auth: dict[str, Any], repo_root: Path = REPO_ROOT) -> None:
    _require(auth.get("authorization_id") == "BX-BH02-PHASE-05-AUTHORIZATION-0.1", "authorization ID is invalid")
    _require(auth.get("status") == "approved-phase-5-only", "Phase 5 lacks explicit approval")
    _require(auth.get("approved_by", {}).get("role") == "repository-owner", "owner approval is incomplete")
    activation = auth.get("activation", {})
    base = str(activation.get("base_revision", ""))
    _require(base == activation.get("base_remote_revision") and len(base) == 40, "synchronized base is invalid")
    _require(activation.get("working_branch") == "codex/bh-02-phase-05-headless-renderer", "working branch differs")
    rules = auth.get("delivery_rules", {})
    for rule in (
        "sections_in_order", "commit_per_section", "single_pull_request",
        "return_to_synchronized_main_after_delivery", "delete_local_feature_branch_after_delivery",
        "delete_remote_feature_branch_after_delivery",
    ):
        _require(rules.get(rule) is True, f"delivery rule is missing: {rule}")
    _require(rules.get("section_count") == 4, "Phase 5 must contain four sections")
    exclusions = " ".join(auth.get("not_authorized", [])).lower()
    for phrase in ("phases 6 through 8", "stable", "geometry", "visual output", "dom lowering", "native-control", "support claims"):
        _require(phrase in exclusions, f"authorization does not exclude {phrase}")
    for binding in auth.get("approval_basis", []):
        path = repo_root / str(binding.get("path", ""))
        _require(path.is_file() and _sha256(path) == binding.get("sha256"), f"authorization input is stale: {path}")
    result = subprocess.run(["git", "merge-base", "--is-ancestor", base, "HEAD"], cwd=repo_root, check=False)
    _require(result.returncode == 0, "work does not descend from the authorized base")


def validate_contract(contract: dict[str, Any], auth: dict[str, Any]) -> None:
    _require(contract.get("contract_id") == "BX-BH02-PHASE-05-CONTRACT-0.1", "contract ID is invalid")
    _require(contract.get("authorization_ref") == auth.get("authorization_id"), "contract authorization differs")
    capabilities = contract.get("renderer_capabilities", {})
    _require(capabilities.get("fields") == CAPABILITY_FIELDS, "capability fields differ")
    _require(capabilities.get("tree_versions") == [1], "tree versions differ")
    _require(capabilities.get("node_kinds") == NODE_KINDS, "node kinds expanded or reordered")
    _require(capabilities.get("layout_modes") == LAYOUT_MODES, "layout modes expanded or reordered")
    _require(capabilities.get("accessibility_roles") == ACCESSIBILITY_ROLES, "roles expanded or reordered")
    _require(capabilities.get("features") == FEATURES, "features expanded or reordered")
    _require(capabilities.get("default") == "unsupported", "capabilities are not deny-by-default")
    _require(contract.get("renderer_requirements", {}).get("fields") == REQUIREMENT_FIELDS, "requirement fields differ")
    _require(contract.get("renderer_context", {}).get("fields") == CONTEXT_FIELDS, "context fields differ")
    _require(contract.get("renderer_context", {}).get("transitions") == TRANSITIONS, "context transitions differ")
    _require(contract.get("backend_behavior", {}).get("callbacks") == CALLBACKS, "backend callbacks differ")
    _require(contract.get("session", {}).get("fields") == SESSION_FIELDS, "session fields differ")
    _require(contract.get("session", {}).get("dispose") == "idempotent", "disposal is not idempotent")
    snapshot = contract.get("headless_snapshot", {})
    _require(snapshot.get("fields") == SNAPSHOT_FIELDS, "snapshot fields differ")
    _require(snapshot.get("canonical_encoding") == "erlang-deterministic-term", "encoding differs")
    _require(snapshot.get("digest") == "sha256-lower-hex", "digest differs")
    trace = contract.get("headless_trace", {})
    _require(trace.get("entry_fields") == TRACE_FIELDS, "trace fields differ")
    _require(trace.get("transitions") == TRANSITIONS, "trace transitions differ")
    _require(contract.get("api_state") == "experimental", "contract claims stable API")
    _require(contract.get("support_state") == "unsupported", "contract claims support")


def validate_source_text(text: str) -> None:
    match = CONCRETE_LEAKAGE.search(text)
    _require(match is None, f"concrete backend leakage found: {match.group(0) if match else ''}")


def validate_sources(repo_root: Path = REPO_ROOT) -> None:
    roots = [
        repo_root / "packages/blazex_renderer/lib",
        repo_root / "packages/blazex_renderer_headless/lib",
        repo_root / "packages/blazex_test/lib",
    ]
    for root in roots:
        _require(root.is_dir(), f"source root is missing: {root}")
        for source in sorted(root.rglob("*.ex")):
            validate_source_text(source.read_text(encoding="utf-8"))
    required = {
        "capabilities": repo_root / "packages/blazex_renderer/lib/blazex/renderer/capabilities.ex",
        "session": repo_root / "packages/blazex_renderer/lib/blazex/renderer/session.ex",
        "headless": repo_root / "packages/blazex_renderer_headless/lib/blazex/renderer/headless.ex",
        "snapshot": repo_root / "packages/blazex_renderer_headless/lib/blazex/renderer/headless/snapshot.ex",
        "trace": repo_root / "packages/blazex_renderer_headless/lib/blazex/renderer/headless/trace.ex",
        "script": repo_root / "packages/blazex_test/lib/blazex/test/render_script.ex",
    }
    for name, path in required.items():
        _require(path.is_file(), f"implemented {name} source is missing")
    combined = "\n".join(path.read_text(encoding="utf-8") for path in required.values())
    for marker in ("def capabilities", "def mount", "def update", "def replace", "def dispose", ":deterministic", ":sha256", "assert_artifact_equal!"):
        _require(marker in combined, f"implementation marker is missing: {marker}")
    for project in ("blazex_renderer", "blazex_renderer_headless", "blazex_test"):
        root = repo_root / "packages" / project
        manifest = (root / "mix.exs").read_text(encoding="utf-8")
        _require(not re.search(r"\b(?:git|github|hex):", manifest), f"external dependency source found: {project}")
        _require(not (root / "mix.lock").exists(), f"unexpected lockfile: {project}")


def validate_fixtures(index: dict[str, Any], fixtures: dict[str, Any], repo_root: Path = REPO_ROOT) -> None:
    _require(index.get("status") == "phase-5-renderer-headless-passed-local", "index status differs")
    _require(index.get("activation_phase") == "BH-02 Phase 5", "index phase differs")
    _require(index.get("next_authorized_work") is None, "later work is prematurely authorized")
    _require(index.get("api_state") == "experimental", "index claims stable API")
    _require(index.get("support_state") == "unsupported", "index claims support")
    for field in ("geometry_results", "visual_results", "accessibility_mapping_results", "dom_results", "browser_results", "native_results", "provider_results"):
        _require(index.get(field) == [], f"premature concrete result exists: {field}")
    bindings = index.get("fixture_sets", [])
    _require(len(bindings) == 4, "Phase 5 must preserve three fixture sets and add one")
    for binding in bindings:
        path = repo_root / str(binding.get("path", ""))
        _require(path.is_file() and _sha256(path) == binding.get("sha256"), f"fixture binding is stale: {path}")
    _require(bindings[-1].get("scenario_count") == len(SCENARIOS), "Phase 5 scenario count differs")
    for bound in (index.get("authorization", {}), index.get("phase_contract", {})):
        path = repo_root / str(bound.get("path", ""))
        _require(path.is_file() and _sha256(path) == bound.get("sha256"), f"index binding is stale: {path}")
    _require(fixtures.get("fixture_set_id") == "BX-BH02-RENDERER-HEADLESS-FIXTURES-0.1", "fixture ID differs")
    _require([item.get("id") for item in fixtures.get("scenarios", [])] == SCENARIOS, "fixture coverage differs")
    _require(all(item.get("expected") for item in fixtures.get("scenarios", [])), "fixture outcomes are incomplete")
    trace = fixtures.get("canonical_trace", [])
    _require([item.get("transition") for item in trace] == TRANSITIONS, "canonical trace coverage differs")
    _require([item.get("sequence") for item in trace] == [1, 2, 3, 4], "trace sequence differs")
    for field in ("visual_results", "geometry_results", "dom_results", "browser_results", "native_results", "platform_accessibility_results"):
        _require(fixtures.get(field) == [], f"fixture overclaims {field}")
    _require(fixtures.get("api_state") == "experimental", "fixtures claim stable API")
    _require(fixtures.get("support_state") == "unsupported", "fixtures claim support")


def validate_ledger(ledger: dict[str, Any], predecessor: Path = PHASE_4_LEDGER) -> None:
    _require(ledger.get("ledger_id") == "BX-BH02-OUTPUT-LEDGER-0.5", "ledger ID differs")
    _require(_sha256(predecessor) == ledger.get("supersedes", {}).get("sha256"), "Phase 4 ledger hash is stale")
    outputs = ledger.get("required_outputs", [])
    _require([item.get("id") for item in outputs] == OUTPUT_IDS, "output ledger differs")
    _require([item.get("state") for item in outputs[4:6]] == ["implemented-experimental-phase-5"] * 2, "Phase 5 outputs are not implemented")
    _require([item.get("state") for item in outputs[6:8]] == ["planned-unimplemented"] * 2, "later output is overclaimed")
    evidence = ledger.get("evidence_boundary", {})
    _require(evidence.get("headless_renderer") == "experimental-deterministic-nonvisual-local-beam", "headless evidence differs")
    for field in ("geometry", "visual_output", "concrete_accessibility_mapping", "host_focus_selection_execution"):
        _require(evidence.get(field) == "unimplemented", f"ledger overclaims {field}")
    _require(evidence.get("support") == "unsupported", "ledger claims support")


def validate_completion(completion: dict[str, Any], repo_root: Path = REPO_ROOT) -> None:
    _require(completion.get("record_id") == "BX-BH02-DECISION-PHASE-05-GO", "completion ID differs")
    _require(completion.get("state") == "passed", "Phase 5 completion did not pass")
    commits = completion.get("section_commits", [])
    _require([(item.get("section"), item.get("commit")) for item in commits] == [
        ("5.1", "337484f"), ("5.2", "ab1c3b3"), ("5.3", "4d92ac3"),
        ("5.4", "resolve-from-this-records-git-commit"),
    ], "section commit record differs")
    bindings = completion.get("artifact_hashes", [])
    _require([item.get("path") for item in bindings] == COMPLETION_PATHS, "completion inventory differs")
    for binding in bindings:
        path = repo_root / str(binding.get("path", ""))
        _require(path.is_file() and _sha256(path) == binding.get("sha256"), f"completion binding is stale: {path}")
    outcome = completion.get("outcome", {})
    _require(outcome.get("api_state") == "experimental", "completion claims stable API")
    _require(outcome.get("support_state") == "unsupported", "completion claims support")
    _require(outcome.get("next_phase") == "BH-02 Phase 6 is eligible but not authorized", "Phase 6 authority differs")


def validate(repo_root: Path = REPO_ROOT, research_root: Path = RESEARCH_ROOT) -> None:
    auth = _load_json(research_root / AUTHORIZATION.relative_to(RESEARCH_ROOT))
    contract = _load_json(research_root / CONTRACT.relative_to(RESEARCH_ROOT))
    ledger = _load_json(research_root / LEDGER.relative_to(RESEARCH_ROOT))
    completion = _load_json(research_root / COMPLETION.relative_to(RESEARCH_ROOT))
    index = _load_json(repo_root / INDEX.relative_to(REPO_ROOT))
    fixtures = _load_json(repo_root / FIXTURES.relative_to(REPO_ROOT))
    validate_authorization(auth, repo_root)
    validate_contract(contract, auth)
    validate_sources(repo_root)
    validate_fixtures(index, fixtures, repo_root)
    validate_ledger(ledger, research_root / PHASE_4_LEDGER.relative_to(RESEARCH_ROOT))
    validate_completion(completion, repo_root)


def main() -> int:
    try:
        validate()
    except ValidationError as exc:
        print(f"BH-02 Phase 5 renderer validation failed: {exc}", file=sys.stderr)
        return 1
    print("BH-02 Phase 5 renderer validation passed: authorization, vocabularies, lifecycle, deterministic oracle, fixtures, leakage, and evidence limits checked.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
