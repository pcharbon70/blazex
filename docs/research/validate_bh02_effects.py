#!/usr/bin/env python3
"""Validate BH-02 Phase 3 semantic-event, effect, and resource contracts."""

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
AUTHORIZATION = BASELINE_ROOT / "blazex-bh-02-phase-03-authorization-v0.1.0.json"
CONTRACT = BASELINE_ROOT / "blazex-bh-02-phase-03-contract-v0.1.0.json"
LEDGER = BASELINE_ROOT / "blazex-bh-02-phase-03-output-ledger-v0.3.0.json"
PHASE_2_LEDGER = BASELINE_ROOT / "blazex-bh-02-phase-02-output-ledger-v0.2.0.json"
COMPLETION = BASELINE_ROOT / "blazex-bh-02-phase-03-completion-v0.1.0.json"
CONFORMANCE_INDEX = REPO_ROOT / "integration/conformance/conformance-index-v0.3.0.json"
FIXTURES = REPO_ROOT / "integration/conformance/event-effect-resource-fixtures-v0.1.0.json"

EVENT_NAMES = [
    "activate", "change", "submit", "select", "expand", "dismiss", "move",
    "reorder", "increment", "decrement", "request_open", "request_close", "request_page",
]
CAPABILITY_NAMES = ["time", "ui.clipboard", "ui.files.choose", "ui.storage"]
CAPABILITY_OPERATIONS = {
    "time": ["schedule"],
    "ui.clipboard": ["read", "write"],
    "ui.files.choose": ["choose"],
    "ui.storage": ["get", "put", "delete"],
}
SCENARIO_IDS = [
    "semantic-event-dispatch",
    "unbound-event-rejection",
    "stale-event-rejection",
    "capability-grant",
    "required-capability-denial",
    "component-fallback",
    "effect-completion",
    "effect-cancellation",
    "effect-timeout",
    "resource-transfer",
    "stale-resource-rejection",
    "owner-generation-cleanup",
]
OUTPUT_IDS = [
    "semantic-ui-node-identity",
    "event-action-contract",
    "effect-capability-resource-contract",
    "layout-token-accessibility-focus-selection-file-intent",
    "renderer-lifecycle-capability-negotiation",
    "deterministic-headless-renderer-traces",
    "minimal-dom-lowering",
    "limited-direct-native-control-spike",
    "forbidden-dependency-leakage-checks",
]
APPROVAL_PATHS = [
    "docs/research/assets/bh-02-baseline/blazex-bh-02-phase-02-completion-v0.1.0.json",
    "docs/research/20-notes/architecture-decisions/adr-0001-host-neutral-semantic-component-kernel.md",
    "docs/research/20-notes/architecture-decisions/adr-0003-host-neutral-effects-capabilities-and-resources.md",
    "docs/research/20-notes/host-neutral-blazex-architecture-and-native-control-backends.md",
]
COMPLETION_PATHS = [
    "docs/research/assets/bh-02-baseline/blazex-bh-02-phase-03-authorization-v0.1.0.json",
    "docs/research/assets/bh-02-baseline/blazex-bh-02-phase-03-contract-v0.1.0.json",
    "docs/research/assets/bh-02-baseline/blazex-bh-02-phase-03-output-ledger-v0.3.0.json",
    "integration/conformance/event-effect-resource-fixtures-v0.1.0.json",
    "integration/conformance/conformance-index-v0.3.0.json",
]
CONCRETE_LEAKAGE = re.compile(
    r"\b(?:phoenix|plug|liveview|localliveview|local_live_view|popcorn|atomvm|dom|javascript|htmlelement|win32|appkit|gtk|hwnd|nsview|qt|wxwidgets)\b",
    re.IGNORECASE,
)


class ValidationError(Exception):
    """Raised when Phase 3 evidence must fail closed."""


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
    _require(auth.get("authorization_id") == "BX-BH02-PHASE-03-AUTHORIZATION-0.1", "Phase 3 authorization ID is invalid")
    _require(auth.get("status") == "approved-phase-3-only", "BH-02 Phase 3 lacks explicit approval")
    approver = auth.get("approved_by", {})
    _require(approver.get("identity") and approver.get("role") == "repository-owner", "repository-owner approval is incomplete")
    activation = auth.get("activation", {})
    base = str(activation.get("base_revision", ""))
    _require(base == activation.get("base_remote_revision") and len(base) == 40, "synchronized base is invalid")
    _require(activation.get("main_synchronized_before_branch") is True, "main synchronization is not recorded")
    _require(activation.get("working_branch") == "codex/bh-02-phase-03-events-effects", "Phase 3 branch is invalid")
    _require(activation.get("phase") == "BH-02 Phase 3", "authorization names the wrong phase")
    rules = auth.get("delivery_rules", {})
    for rule in (
        "sections_in_order", "commit_per_section", "single_pull_request",
        "return_to_synchronized_main_after_delivery", "delete_local_feature_branch_after_delivery",
        "delete_remote_feature_branch_after_delivery",
    ):
        _require(rules.get(rule) is True, f"delivery rule is missing: {rule}")
    _require(rules.get("section_count") == 4, "Phase 3 must contain exactly four sections")
    exclusions = " ".join(auth.get("not_authorized", [])).lower()
    for phrase in ("phases 4 through 8", "stable", "product component", "concrete capability providers", "support claims"):
        _require(phrase in exclusions, f"authorization does not exclude {phrase}")
    bindings = auth.get("approval_basis", [])
    _require([item.get("path") for item in bindings] == APPROVAL_PATHS, "authorization basis differs")
    for binding in bindings:
        path = repo_root / str(binding.get("path", ""))
        _require(path.is_file() and _sha256(path) == binding.get("sha256"), f"authorization input is stale: {path}")
    result = subprocess.run(["git", "merge-base", "--is-ancestor", base, "HEAD"], cwd=repo_root, check=False)
    _require(result.returncode == 0, "current work does not descend from the authorized base")


def validate_contract(contract: dict[str, Any], auth: dict[str, Any]) -> None:
    _require(contract.get("contract_id") == "BX-BH02-PHASE-03-CONTRACT-0.1", "contract ID is invalid")
    _require(contract.get("status") == "authorized-experimental", "contract status is not experimental")
    _require(contract.get("authorization_ref") == auth.get("authorization_id"), "contract authorization link is invalid")
    event = contract.get("semantic_event", {})
    _require(event.get("version") == 1, "semantic-event version differs")
    _require(event.get("names") == EVENT_NAMES, "semantic-event vocabulary expanded or reordered")
    _require(event.get("fields") == ["version", "name", "owner", "source", "payload", "sequence"], "semantic-event fields differ")
    _require(event.get("owner_source_rule") == "same-root-generation-source-descends-from-owner", "event ownership rule differs")
    _require(event.get("stale_generation") == "reject", "stale event generation is allowed")
    dispatch = contract.get("component_dispatch", {})
    _require(dispatch.get("mode") == "stateful-only" and dispatch.get("transition") == "event", "component event boundary differs")
    _require(dispatch.get("partial_acceptance") == "forbidden", "partial event acceptance is allowed")
    capabilities = contract.get("capabilities", {})
    _require(capabilities.get("names") == CAPABILITY_NAMES, "capability vocabulary expanded or reordered")
    _require(capabilities.get("operations") == CAPABILITY_OPERATIONS, "capability operations differ")
    _require(capabilities.get("default") == "denied", "capability default is not denied")
    _require(capabilities.get("requirement") == ["required", "optional"], "capability requirement modes differ")
    _require(capabilities.get("fallback") == ["fail", "omit", "component"], "capability fallback modes differ")
    effect = contract.get("effect", {})
    _require(effect.get("fields") == ["version", "id", "owner", "capability", "operation", "payload", "timeout_ms", "fallback"], "effect fields differ")
    _require(effect.get("result_statuses") == ["ok", "denied", "cancelled", "timeout", "unsupported", "failed"], "effect statuses differ")
    resource = contract.get("resource", {})
    _require(resource.get("identifier_fields") == ["owner", "capability", "id", "generation"], "resource identity fields differ")
    _require(resource.get("transfer") == "explicit-owner-to-owner-same-generation", "resource transfer ownership differs")
    _require(resource.get("owner_cleanup") == "cancel-pending-and-dispose-active-for-exact-generation", "owner cleanup rule differs")
    _require(contract.get("api_state") == "experimental", "stable API is overclaimed")
    _require(contract.get("support_state") == "unsupported", "support is overclaimed")


def validate_ledger(ledger: dict[str, Any], phase_2_ledger: Path = PHASE_2_LEDGER) -> None:
    _require(ledger.get("ledger_id") == "BX-BH02-OUTPUT-LEDGER-0.3", "Phase 3 ledger ID is invalid")
    _require(ledger.get("status") == "phase-3-event-effect-resource-contracts-implemented-experimental", "Phase 3 ledger state differs")
    predecessor = ledger.get("supersedes", {})
    _require(predecessor.get("preserved_unchanged") is True, "Phase 2 ledger preservation is not recorded")
    _require(_sha256(phase_2_ledger) == predecessor.get("sha256"), "Phase 2 ledger hash is stale")
    outputs = ledger.get("required_outputs", [])
    _require([item.get("id") for item in outputs] == OUTPUT_IDS, "required outputs differ")
    _require(outputs[0].get("state") == "implemented-experimental-phase-2", "Phase 2 semantic output changed")
    _require(all(outputs[index].get("state") == "implemented-experimental-phase-3" for index in (1, 2)), "Phase 3 outputs are not recorded")
    _require(all(item.get("state") == "planned-unimplemented" for item in outputs[3:-1]), "later output is overclaimed")
    _require(outputs[-1].get("state") == "implemented-phase-1-extended-phase-3", "leakage state differs")
    evidence = ledger.get("evidence_boundary", {})
    _require(evidence.get("event_effect_resources") == "experimental-version-1-local-beam", "Phase 3 evidence state differs")
    for field in ("concrete_providers", "headless_renderer", "dom_conformance", "native_controls"):
        _require(evidence.get(field) in {"unimplemented", "unexecuted"}, f"later evidence is overclaimed: {field}")
    _require(evidence.get("support") == "unsupported", "ledger support is overclaimed")


def validate_no_concrete_leakage(repo_root: Path = REPO_ROOT) -> None:
    for relative in ("packages/blazex_core/lib", "packages/blazex_ui_tree/lib", "packages/blazex_effects/lib"):
        source_root = repo_root / relative
        _require(source_root.is_dir(), f"contract source root is missing: {source_root}")
        for source in sorted(source_root.rglob("*.ex")):
            match = CONCRETE_LEAKAGE.search(source.read_text(encoding="utf-8"))
            _require(match is None, f"concrete provider/platform leakage in {source}: {match.group(0) if match else ''}")


def validate_sources(repo_root: Path = REPO_ROOT) -> None:
    validate_no_concrete_leakage(repo_root)
    event_source = (repo_root / "packages/blazex_core/lib/blazex/core/event.ex").read_text(encoding="utf-8")
    capability_source = (repo_root / "packages/blazex_effects/lib/blazex/effects/capability.ex").read_text(encoding="utf-8")
    tracker_source = (repo_root / "packages/blazex_effects/lib/blazex/effects/tracker.ex").read_text(encoding="utf-8")
    for name in EVENT_NAMES:
        _require(f":{name}" in event_source, f"implemented event is missing: {name}")
    for name in CAPABILITY_NAMES:
        rendered = f':"{name}"' if "." in name else f":{name}"
        _require(rendered in capability_source, f"implemented capability is missing: {name}")
    for marker in ("def submit", "def complete", "def cancel", "def timeout", "def transfer", "def dispose", "def dispose_owner"):
        _require(marker in tracker_source, f"resource/effect lifecycle operation is missing: {marker}")
    for project in (repo_root / "packages/blazex_core", repo_root / "packages/blazex_ui_tree", repo_root / "packages/blazex_effects"):
        manifest = (project / "mix.exs").read_text(encoding="utf-8")
        _require(not re.search(r"\b(?:git|github|hex):", manifest), f"external dependency source found in {manifest}")
        _require(not (project / "mix.lock").exists(), f"unexpected lockfile: {project / 'mix.lock'}")


def validate_fixtures(index: dict[str, Any], fixtures: dict[str, Any], repo_root: Path = REPO_ROOT) -> None:
    _require(index.get("status") == "phase-3-event-effect-resource-passed-local", "conformance index state differs")
    _require(index.get("activation_phase") == "BH-02 Phase 3", "conformance index names the wrong phase")
    _require(index.get("api_state") == "experimental", "conformance index claims stable API")
    _require(index.get("support_state") == "unsupported", "conformance index claims support")
    _require(index.get("provider_results") == [] and index.get("backend_results") == [], "provider or renderer results exist prematurely")
    bindings = index.get("fixture_sets", [])
    _require(len(bindings) == 2, "Phase 3 must preserve Phase 2 and bind one Phase 3 fixture set")
    phase_3_binding = bindings[1]
    _require(phase_3_binding.get("scenario_count") == len(SCENARIO_IDS), "fixture scenario count differs")
    fixture_path = repo_root / str(phase_3_binding.get("path", ""))
    _require(fixture_path.is_file() and _sha256(fixture_path) == phase_3_binding.get("sha256"), "fixture binding is stale")
    for binding in (index.get("authorization", {}), index.get("phase_contract", {})):
        path = repo_root / str(binding.get("path", ""))
        _require(path.is_file() and _sha256(path) == binding.get("sha256"), f"conformance binding is stale: {path}")
    _require(fixtures.get("contract_ref") == "BX-BH02-PHASE-03-CONTRACT-0.1", "fixture contract link is invalid")
    _require(fixtures.get("status") == "passed-local-event-effect-resource-evaluation", "fixture result state differs")
    scenarios = fixtures.get("scenarios", [])
    _require([item.get("id") for item in scenarios] == SCENARIO_IDS, "fixture coverage differs")
    _require(all(item.get("expected") for item in scenarios), "fixture expected outcomes are incomplete")
    _require(fixtures.get("provider_results") == [] and fixtures.get("renderer_results") == [], "fixtures contain premature provider or renderer results")
    _require(fixtures.get("api_state") == "experimental", "fixtures claim stable API")
    _require(fixtures.get("support_state") == "unsupported", "fixtures claim support")


def validate_completion(completion: dict[str, Any], repo_root: Path = REPO_ROOT) -> None:
    _require(completion.get("record_id") == "BX-BH02-DECISION-PHASE-03-GO", "completion ID is invalid")
    _require(completion.get("state") == "passed", "Phase 3 completion did not pass")
    _require(completion.get("authorization_ref") == "BX-BH02-PHASE-03-AUTHORIZATION-0.1", "completion authorization link is invalid")
    _require(completion.get("contract_ref") == "BX-BH02-PHASE-03-CONTRACT-0.1", "completion contract link is invalid")
    commits = completion.get("section_commits", [])
    _require([(item.get("section"), item.get("commit")) for item in commits] == [
        ("3.1", "1072aeb"), ("3.2", "218cba9"), ("3.3", "0c315ee"),
        ("3.4", "resolve-from-this-records-git-commit"),
    ], "section commit record differs")
    bindings = completion.get("artifact_hashes", [])
    _require([item.get("path") for item in bindings] == COMPLETION_PATHS, "completion artifact inventory differs")
    for binding in bindings:
        path = repo_root / str(binding.get("path", ""))
        _require(path.is_file() and _sha256(path) == binding.get("sha256"), f"completion binding is stale: {path}")
    outcome = completion.get("outcome", {})
    _require(outcome.get("api_state") == "experimental", "completion claims stable API")
    _require(outcome.get("support_state") == "unsupported", "completion claims support")
    _require(outcome.get("concrete_provider_state") == "unimplemented", "completion claims a concrete provider")
    _require("eligible but not authorized" in outcome.get("next_phase", ""), "Phase 4 authorization boundary is missing")


def validate(repo_root: Path = REPO_ROOT, research_root: Path = RESEARCH_ROOT) -> None:
    auth = _load_json(research_root / AUTHORIZATION.relative_to(RESEARCH_ROOT))
    contract = _load_json(research_root / CONTRACT.relative_to(RESEARCH_ROOT))
    ledger = _load_json(research_root / LEDGER.relative_to(RESEARCH_ROOT))
    completion = _load_json(research_root / COMPLETION.relative_to(RESEARCH_ROOT))
    index = _load_json(repo_root / CONFORMANCE_INDEX.relative_to(REPO_ROOT))
    fixtures = _load_json(repo_root / FIXTURES.relative_to(REPO_ROOT))
    validate_authorization(auth, repo_root)
    validate_contract(contract, auth)
    validate_ledger(ledger, research_root / PHASE_2_LEDGER.relative_to(RESEARCH_ROOT))
    validate_sources(repo_root)
    validate_fixtures(index, fixtures, repo_root)
    validate_completion(completion, repo_root)


def main() -> int:
    try:
        validate()
    except ValidationError as exc:
        print(f"BH-02 Phase 3 effect validation failed: {exc}", file=sys.stderr)
        return 1
    print("BH-02 Phase 3 effect validation passed: authorization, event vocabulary, capabilities, effects, resources, fixtures, leakage, and support limits checked.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
