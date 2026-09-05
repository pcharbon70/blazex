#!/usr/bin/env python3
"""Validate BH-02 Phase 4 portable presentation-intent contracts."""

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
AUTHORIZATION = BASELINE_ROOT / "blazex-bh-02-phase-04-authorization-v0.1.0.json"
CONTRACT = BASELINE_ROOT / "blazex-bh-02-phase-04-contract-v0.1.0.json"
LEDGER = BASELINE_ROOT / "blazex-bh-02-phase-04-output-ledger-v0.4.0.json"
PHASE_3_LEDGER = BASELINE_ROOT / "blazex-bh-02-phase-03-output-ledger-v0.3.0.json"
COMPLETION = BASELINE_ROOT / "blazex-bh-02-phase-04-completion-v0.1.0.json"
CONFORMANCE_INDEX = REPO_ROOT / "integration/conformance/conformance-index-v0.4.0.json"
FIXTURES = REPO_ROOT / "integration/conformance/presentation-intent-fixtures-v0.1.0.json"

TOKEN_CATEGORIES = ["space", "size", "color", "typography", "radius", "motion"]
METRIC_FORMS = ["auto", "content", "fill", "units", "token"]
LAYOUT_FIELDS = [
    "version", "owner", "mode", "direction", "align", "gap", "padding", "width",
    "height", "min_width", "min_height", "max_width", "max_height", "grow",
    "overflow", "virtualization",
]
ACCESSIBILITY_ROLES = [
    "generic", "text", "group", "button", "text_field", "checkbox", "list",
    "list_item", "dialog", "status",
]
ACCESSIBILITY_STATES = [
    "disabled", "expanded", "selected", "checked", "invalid", "required", "readonly", "busy",
]
RELATIONSHIPS = ["labelled_by", "described_by", "controls", "owns", "error_message"]
SCENARIOS = [
    "portable-token-reference",
    "logical-stack-layout",
    "logical-grid-layout",
    "virtualization-hint",
    "invalid-layout-range",
    "accessibility-relationship",
    "missing-accessibility-target",
    "focus-order",
    "focus-scope-restoration",
    "duplicate-focus-order",
    "controlled-collection-selection",
    "controlled-text-selection",
    "stale-annotation-owner",
    "atomic-intent-output",
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
    "docs/research/assets/bh-02-baseline/blazex-bh-02-phase-03-completion-v0.1.0.json",
    "docs/research/20-notes/architecture-decisions/adr-0001-host-neutral-semantic-component-kernel.md",
    "docs/research/20-notes/architecture-decisions/adr-0002-versioned-semantic-ui-tree.md",
    "docs/research/20-notes/architecture-decisions/adr-0007-native-control-portability-gate.md",
]
COMPLETION_PATHS = [
    "docs/research/assets/bh-02-baseline/blazex-bh-02-phase-04-authorization-v0.1.0.json",
    "docs/research/assets/bh-02-baseline/blazex-bh-02-phase-04-contract-v0.1.0.json",
    "docs/research/assets/bh-02-baseline/blazex-bh-02-phase-04-output-ledger-v0.4.0.json",
    "integration/conformance/presentation-intent-fixtures-v0.1.0.json",
    "integration/conformance/conformance-index-v0.4.0.json",
]
CONCRETE_LEAKAGE = re.compile(
    r"\b(?:phoenix|plug|liveview|localliveview|local_live_view|popcorn|atomvm|dom|css|javascript|html|aria|taffy|yoga|accesskit|uiautomation|nsaccessibility|at-spi|win32|appkit|gtk|qt|wxwidgets)\b",
    re.IGNORECASE,
)


class ValidationError(Exception):
    """Raised when Phase 4 evidence must fail closed."""


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
    _require(auth.get("authorization_id") == "BX-BH02-PHASE-04-AUTHORIZATION-0.1", "Phase 4 authorization ID is invalid")
    _require(auth.get("status") == "approved-phase-4-only", "BH-02 Phase 4 lacks explicit approval")
    approver = auth.get("approved_by", {})
    _require(approver.get("identity") and approver.get("role") == "repository-owner", "repository-owner approval is incomplete")
    activation = auth.get("activation", {})
    base = str(activation.get("base_revision", ""))
    _require(base == activation.get("base_remote_revision") and len(base) == 40, "synchronized base is invalid")
    _require(activation.get("main_synchronized_before_branch") is True, "main synchronization is not recorded")
    _require(activation.get("working_branch") == "codex/bh-02-phase-04-semantic-intent", "Phase 4 branch is invalid")
    _require(activation.get("phase") == "BH-02 Phase 4", "authorization names the wrong phase")
    rules = auth.get("delivery_rules", {})
    for rule in (
        "sections_in_order", "commit_per_section", "single_pull_request",
        "return_to_synchronized_main_after_delivery", "delete_local_feature_branch_after_delivery",
        "delete_remote_feature_branch_after_delivery",
    ):
        _require(rules.get(rule) is True, f"delivery rule is missing: {rule}")
    _require(rules.get("section_count") == 4, "Phase 4 must contain exactly four sections")
    exclusions = " ".join(auth.get("not_authorized", [])).lower()
    for phrase in ("phases 5 through 8", "stable", "product component", "geometry calculation", "concrete layout engines", "support claims"):
        _require(phrase in exclusions, f"authorization does not exclude {phrase}")
    bindings = auth.get("approval_basis", [])
    _require([item.get("path") for item in bindings] == APPROVAL_PATHS, "authorization basis differs")
    for binding in bindings:
        path = repo_root / str(binding.get("path", ""))
        _require(path.is_file() and _sha256(path) == binding.get("sha256"), f"authorization input is stale: {path}")
    result = subprocess.run(["git", "merge-base", "--is-ancestor", base, "HEAD"], cwd=repo_root, check=False)
    _require(result.returncode == 0, "current work does not descend from the authorized base")


def validate_contract(contract: dict[str, Any], auth: dict[str, Any]) -> None:
    _require(contract.get("contract_id") == "BX-BH02-PHASE-04-CONTRACT-0.1", "contract ID is invalid")
    _require(contract.get("status") == "authorized-experimental", "contract status is not experimental")
    _require(contract.get("authorization_ref") == auth.get("authorization_id"), "contract authorization link is invalid")
    token = contract.get("token_reference", {})
    _require(token.get("fields") == ["version", "category", "name"], "token fields differ")
    _require(token.get("categories") == TOKEN_CATEGORIES, "token vocabulary expanded or reordered")
    metric = contract.get("metric", {})
    _require(metric.get("forms") == METRIC_FORMS, "metric vocabulary expanded or reordered")
    _require(metric.get("token_categories") == ["space", "size"], "metric token categories differ")
    layout = contract.get("layout", {})
    _require(layout.get("fields") == LAYOUT_FIELDS, "layout fields differ")
    _require(layout.get("modes") == ["none", "stack", "grid", "overlay"], "layout modes expanded or reordered")
    _require(layout.get("directions") == ["row", "column"], "layout directions differ")
    _require(layout.get("alignments") == ["start", "center", "end", "stretch"], "layout alignments differ")
    _require(layout.get("overflow") == ["visible", "clip", "scroll"], "layout overflow differs")
    _require(layout.get("geometry_output") == "forbidden", "geometry output is permitted")
    accessibility = contract.get("accessibility", {})
    _require(accessibility.get("roles") == ACCESSIBILITY_ROLES, "accessibility roles expanded or reordered")
    _require(accessibility.get("state_keys") == ACCESSIBILITY_STATES, "accessibility states differ")
    _require(accessibility.get("relationship_keys") == RELATIONSHIPS, "accessibility relationships differ")
    _require(accessibility.get("live") == ["off", "polite", "assertive"], "live intent differs")
    _require(accessibility.get("platform_mapping") == "deferred", "platform accessibility is overclaimed")
    focus = contract.get("focus", {})
    _require(focus.get("behaviors") == ["none", "target", "scope"], "focus behaviors differ")
    _require(focus.get("restore") == ["none", "previous"], "focus restoration differs")
    _require(focus.get("execution") == "deferred", "host focus execution is overclaimed")
    selection = contract.get("selection", {})
    _require(selection.get("kinds") == ["none", "single", "multiple", "text_range"], "selection kinds differ")
    _require(selection.get("text_directions") == ["forward", "backward"], "selection directions differ")
    intent = contract.get("intent_set", {})
    _require(intent.get("fields") == ["version", "document", "layouts", "accessibility", "focus", "selections"], "intent-set fields differ")
    _require(intent.get("owner_rule") == "every-annotation-owner-is-an-exact-document-node", "annotation ownership differs")
    _require(intent.get("relationship_rule") == "every-target-is-an-exact-document-node", "relationship ownership differs")
    _require(intent.get("partial_acceptance") == "forbidden", "partial intent acceptance is allowed")
    _require(contract.get("api_state") == "experimental", "stable API is overclaimed")
    _require(contract.get("support_state") == "unsupported", "support is overclaimed")


def validate_ledger(ledger: dict[str, Any], phase_3_ledger: Path = PHASE_3_LEDGER) -> None:
    _require(ledger.get("ledger_id") == "BX-BH02-OUTPUT-LEDGER-0.4", "Phase 4 ledger ID is invalid")
    _require(ledger.get("status") == "phase-4-presentation-intent-contracts-implemented-experimental", "Phase 4 ledger state differs")
    predecessor = ledger.get("supersedes", {})
    _require(predecessor.get("preserved_unchanged") is True, "Phase 3 ledger preservation is not recorded")
    _require(_sha256(phase_3_ledger) == predecessor.get("sha256"), "Phase 3 ledger hash is stale")
    outputs = ledger.get("required_outputs", [])
    _require([item.get("id") for item in outputs] == OUTPUT_IDS, "required outputs differ")
    expected_states = [
        "implemented-experimental-phase-2",
        "implemented-experimental-phase-3",
        "implemented-experimental-phase-3",
        "implemented-experimental-phase-4",
    ]
    _require([item.get("state") for item in outputs[:4]] == expected_states, "implemented output history differs")
    _require(all(item.get("state") == "planned-unimplemented" for item in outputs[4:-1]), "later output is overclaimed")
    _require(outputs[-1].get("state") == "implemented-phase-1-extended-phase-4", "leakage state differs")
    evidence = ledger.get("evidence_boundary", {})
    _require(evidence.get("presentation_intent") == "experimental-version-1-local-beam", "Phase 4 evidence state differs")
    for field in ("geometry", "concrete_accessibility_mapping", "host_focus_selection_execution", "headless_renderer", "dom_conformance", "native_controls"):
        _require(evidence.get(field) in {"unimplemented", "unexecuted"}, f"later evidence is overclaimed: {field}")
    _require(evidence.get("support") == "unsupported", "ledger support is overclaimed")


def validate_no_concrete_leakage(repo_root: Path = REPO_ROOT) -> None:
    for relative in ("packages/blazex_core/lib", "packages/blazex_ui_tree/lib", "packages/blazex_effects/lib"):
        source_root = repo_root / relative
        _require(source_root.is_dir(), f"contract source root is missing: {source_root}")
        for source in sorted(source_root.rglob("*.ex")):
            match = CONCRETE_LEAKAGE.search(source.read_text(encoding="utf-8"))
            _require(match is None, f"concrete layout/accessibility/platform leakage in {source}: {match.group(0) if match else ''}")


def validate_sources(repo_root: Path = REPO_ROOT) -> None:
    validate_no_concrete_leakage(repo_root)
    files = {
        "token": repo_root / "packages/blazex_ui_tree/lib/blazex/ui_tree/token_ref.ex",
        "metric": repo_root / "packages/blazex_ui_tree/lib/blazex/ui_tree/metric.ex",
        "layout": repo_root / "packages/blazex_ui_tree/lib/blazex/ui_tree/layout.ex",
        "accessibility": repo_root / "packages/blazex_ui_tree/lib/blazex/ui_tree/accessibility.ex",
        "focus": repo_root / "packages/blazex_ui_tree/lib/blazex/ui_tree/focus.ex",
        "selection": repo_root / "packages/blazex_ui_tree/lib/blazex/ui_tree/selection.ex",
        "intent": repo_root / "packages/blazex_ui_tree/lib/blazex/ui_tree/intent_set.ex",
    }
    for name, path in files.items():
        _require(path.is_file(), f"implemented {name} source is missing: {path}")
    source = "\n".join(path.read_text(encoding="utf-8") for path in files.values())
    for marker in ("def validate", "duplicate_focus_order", "annotation_owner_missing", "selection_kind_incompatible"):
        _require(marker in source, f"intent validation marker is missing: {marker}")
    for project in (repo_root / "packages/blazex_core", repo_root / "packages/blazex_ui_tree", repo_root / "packages/blazex_effects"):
        manifest = (project / "mix.exs").read_text(encoding="utf-8")
        _require(not re.search(r"\b(?:git|github|hex):", manifest), f"external dependency source found in {manifest}")
        _require(not (project / "mix.lock").exists(), f"unexpected lockfile: {project / 'mix.lock'}")


def validate_fixtures(index: dict[str, Any], fixtures: dict[str, Any], repo_root: Path = REPO_ROOT) -> None:
    _require(index.get("status") == "phase-4-presentation-intent-passed-local", "conformance index state differs")
    _require(index.get("activation_phase") == "BH-02 Phase 4", "conformance index names the wrong phase")
    _require(index.get("api_state") == "experimental", "conformance index claims stable API")
    _require(index.get("support_state") == "unsupported", "conformance index claims support")
    for field in ("geometry_results", "accessibility_mapping_results", "provider_results", "backend_results"):
        _require(index.get(field) == [], f"premature concrete result exists: {field}")
    bindings = index.get("fixture_sets", [])
    _require(len(bindings) == 3, "Phase 4 must preserve two prior fixture sets and bind one Phase 4 set")
    binding = bindings[2]
    _require(binding.get("scenario_count") == len(SCENARIOS), "fixture scenario count differs")
    fixture_path = repo_root / str(binding.get("path", ""))
    _require(fixture_path.is_file() and _sha256(fixture_path) == binding.get("sha256"), "fixture binding is stale")
    for bound in (index.get("authorization", {}), index.get("phase_contract", {})):
        path = repo_root / str(bound.get("path", ""))
        _require(path.is_file() and _sha256(path) == bound.get("sha256"), f"conformance binding is stale: {path}")
    _require(fixtures.get("contract_ref") == "BX-BH02-PHASE-04-CONTRACT-0.1", "fixture contract link is invalid")
    _require(fixtures.get("status") == "passed-local-presentation-intent-evaluation", "fixture result state differs")
    scenarios = fixtures.get("scenarios", [])
    _require([item.get("id") for item in scenarios] == SCENARIOS, "fixture coverage differs")
    _require(all(item.get("expected") for item in scenarios), "fixture expected outcomes are incomplete")
    for field in ("geometry_results", "accessibility_mapping_results", "renderer_results"):
        _require(fixtures.get(field) == [], f"fixture contains premature concrete result: {field}")
    _require(fixtures.get("api_state") == "experimental", "fixtures claim stable API")
    _require(fixtures.get("support_state") == "unsupported", "fixtures claim support")


def validate_completion(completion: dict[str, Any], repo_root: Path = REPO_ROOT) -> None:
    _require(completion.get("record_id") == "BX-BH02-DECISION-PHASE-04-GO", "completion ID is invalid")
    _require(completion.get("state") == "passed", "Phase 4 completion did not pass")
    _require(completion.get("authorization_ref") == "BX-BH02-PHASE-04-AUTHORIZATION-0.1", "completion authorization link is invalid")
    _require(completion.get("contract_ref") == "BX-BH02-PHASE-04-CONTRACT-0.1", "completion contract link is invalid")
    commits = completion.get("section_commits", [])
    _require([(item.get("section"), item.get("commit")) for item in commits] == [
        ("4.1", "beeac9e"), ("4.2", "9f61ea0"), ("4.3", "b300845"),
        ("4.4", "resolve-from-this-records-git-commit"),
    ], "section commit record differs")
    bindings = completion.get("artifact_hashes", [])
    _require([item.get("path") for item in bindings] == COMPLETION_PATHS, "completion artifact inventory differs")
    for binding in bindings:
        path = repo_root / str(binding.get("path", ""))
        _require(path.is_file() and _sha256(path) == binding.get("sha256"), f"completion binding is stale: {path}")
    outcome = completion.get("outcome", {})
    _require(outcome.get("api_state") == "experimental", "completion claims stable API")
    _require(outcome.get("support_state") == "unsupported", "completion claims support")
    _require(outcome.get("geometry_state") == "unimplemented", "completion claims geometry")
    _require(outcome.get("platform_accessibility_state") == "unimplemented", "completion claims platform accessibility")
    _require(outcome.get("renderer_state") == "unimplemented", "completion claims renderer behavior")
    _require("eligible but not authorized" in outcome.get("next_phase", ""), "Phase 5 authorization boundary is missing")


def validate(repo_root: Path = REPO_ROOT, research_root: Path = RESEARCH_ROOT) -> None:
    auth = _load_json(research_root / AUTHORIZATION.relative_to(RESEARCH_ROOT))
    contract = _load_json(research_root / CONTRACT.relative_to(RESEARCH_ROOT))
    ledger = _load_json(research_root / LEDGER.relative_to(RESEARCH_ROOT))
    completion = _load_json(research_root / COMPLETION.relative_to(RESEARCH_ROOT))
    index = _load_json(repo_root / CONFORMANCE_INDEX.relative_to(REPO_ROOT))
    fixtures = _load_json(repo_root / FIXTURES.relative_to(REPO_ROOT))
    validate_authorization(auth, repo_root)
    validate_contract(contract, auth)
    validate_ledger(ledger, research_root / PHASE_3_LEDGER.relative_to(RESEARCH_ROOT))
    validate_sources(repo_root)
    validate_fixtures(index, fixtures, repo_root)
    validate_completion(completion, repo_root)


def main() -> int:
    try:
        validate()
    except ValidationError as exc:
        print(f"BH-02 Phase 4 intent validation failed: {exc}", file=sys.stderr)
        return 1
    print("BH-02 Phase 4 intent validation passed: authorization, tokens, layout, accessibility, focus, selection, ownership, fixtures, leakage, and support limits checked.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
