#!/usr/bin/env python3
"""Validate BH-02 Phase 2 semantic nodes, identity, and component evaluation."""

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
AUTHORIZATION = BASELINE_ROOT / "blazex-bh-02-phase-02-authorization-v0.1.0.json"
CONTRACT = BASELINE_ROOT / "blazex-bh-02-phase-02-contract-v0.1.0.json"
LEDGER = BASELINE_ROOT / "blazex-bh-02-phase-02-output-ledger-v0.2.0.json"
PHASE_1_LEDGER = BASELINE_ROOT / "blazex-bh-02-entry-ledger-v0.1.0.json"
CONFORMANCE_INDEX = REPO_ROOT / "integration/conformance/conformance-index-v0.2.0.json"
FIXTURES = REPO_ROOT / "integration/conformance/semantic-kernel-fixtures-v0.1.0.json"
COMPLETION = BASELINE_ROOT / "blazex-bh-02-phase-02-completion-v0.1.0.json"

EXPECTED_KINDS = ["text", "group", "action", "field", "selection", "collection", "surface"]
EXPECTED_FIELDS = ["version", "kind", "identity", "key", "content", "children"]
EXPECTED_SCENARIOS = [
    "semantic-text-tree",
    "pure-mount-update",
    "stateful-mount-update",
    "keyed-reorder",
    "replacement-generation",
    "duplicate-sibling-rejection",
    "opaque-term-rejection",
    "invalid-output-rejection",
]
EXPECTED_OUTPUT_IDS = [
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
DEFERRED_FIELDS = [
    "events",
    "effects",
    "capabilities",
    "resources",
    "layout",
    "tokens",
    "accessibility",
    "focus",
    "selection",
    "renderer-lifecycle",
    "renderer-output",
    "disposal",
]
EXPECTED_APPROVAL_PATHS = [
    "docs/research/assets/bh-02-baseline/blazex-bh-02-phase-01-completion-v0.1.0.json",
    "docs/research/20-notes/architecture-decisions/adr-0001-host-neutral-semantic-component-kernel.md",
    "docs/research/20-notes/architecture-decisions/adr-0002-versioned-semantic-ui-tree.md",
    "docs/research/20-notes/host-neutral-blazex-architecture-and-native-control-backends.md",
]
EXPECTED_COMPLETION_PATHS = [
    "docs/research/assets/bh-02-baseline/blazex-bh-02-phase-02-authorization-v0.1.0.json",
    "docs/research/assets/bh-02-baseline/blazex-bh-02-phase-02-contract-v0.1.0.json",
    "docs/research/assets/bh-02-baseline/blazex-bh-02-phase-02-output-ledger-v0.2.0.json",
    "integration/conformance/semantic-kernel-fixtures-v0.1.0.json",
    "integration/conformance/conformance-index-v0.2.0.json",
]
CONCRETE_LEAKAGE = re.compile(
    r"\b(?:phoenix|plug|liveview|localliveview|local_live_view|popcorn|atomvm|dom|javascript|htmlelement|win32|appkit|gtk|hwnd|nsview|qt|wxwidgets)\b",
    re.IGNORECASE,
)


class ValidationError(Exception):
    """Raised when Phase 2 semantics must fail closed."""


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
    _require(
        auth.get("authorization_id") == "BX-BH02-PHASE-02-AUTHORIZATION-0.1",
        "Phase 2 authorization ID is invalid",
    )
    _require(auth.get("status") == "approved-phase-2-only", "BH-02 Phase 2 lacks explicit approval")
    approver = auth.get("approved_by", {})
    _require(
        approver.get("identity") and approver.get("role") == "repository-owner",
        "repository-owner approval is incomplete",
    )
    activation = auth.get("activation", {})
    base = str(activation.get("base_revision", ""))
    _require(base == activation.get("base_remote_revision") and len(base) == 40, "synchronized base is invalid")
    _require(activation.get("main_synchronized_before_branch") is True, "main synchronization is not recorded")
    _require(activation.get("working_branch") == "codex/bh-02-phase-02-semantic-kernel", "Phase 2 branch is invalid")
    _require(activation.get("phase") == "BH-02 Phase 2", "authorization names the wrong phase")
    rules = auth.get("delivery_rules", {})
    for rule in (
        "sections_in_order",
        "commit_per_section",
        "single_pull_request",
        "return_to_synchronized_main_after_delivery",
        "delete_local_feature_branch_after_delivery",
        "delete_remote_feature_branch_after_delivery",
    ):
        _require(rules.get(rule) is True, f"delivery rule is missing: {rule}")
    _require(rules.get("section_count") == 4, "Phase 2 must contain exactly four sections")
    exclusions = " ".join(auth.get("not_authorized", [])).lower()
    for phrase in ("phases 3 through 8", "stable", "product component", "renderer behavior", "external dependency", "support claims"):
        _require(phrase in exclusions, f"authorization does not exclude {phrase}")
    approval_basis = auth.get("approval_basis", [])
    _require([binding.get("path") for binding in approval_basis] == EXPECTED_APPROVAL_PATHS, "authorization basis differs")
    for binding in approval_basis:
        path = repo_root / str(binding.get("path", ""))
        _require(path.is_file(), f"authorization input is missing: {path}")
        _require(_sha256(path) == binding.get("sha256"), f"authorization input is stale: {path}")
    result = subprocess.run(
        ["git", "merge-base", "--is-ancestor", base, "HEAD"],
        cwd=repo_root,
        check=False,
        capture_output=True,
        text=True,
    )
    _require(result.returncode == 0, "current work does not descend from the authorized base")


def validate_contract(contract: dict[str, Any], auth: dict[str, Any]) -> None:
    _require(contract.get("contract_id") == "BX-BH02-PHASE-02-CONTRACT-0.1", "contract ID is invalid")
    _require(contract.get("status") == "authorized-experimental", "contract status is not experimental")
    _require(contract.get("authorization_ref") == auth.get("authorization_id"), "contract authorization link is invalid")
    tree = contract.get("semantic_tree", {})
    _require(tree.get("version") == 1, "semantic-tree version differs")
    _require(tree.get("node_kinds") == EXPECTED_KINDS, "semantic node vocabulary expanded or reordered")
    _require(tree.get("fields") == EXPECTED_FIELDS, "semantic node fields expanded or reordered")
    _require(tree.get("duplicate_sibling_identity") == "reject", "duplicate identities are not rejected")
    _require(tree.get("duplicate_sibling_key") == "reject", "duplicate keys are not rejected")
    identity = contract.get("identity", {})
    _require(identity.get("fields") == ["root", "path", "generation"], "identity fields differ")
    _require(identity.get("replacement") == "increment-generation", "replacement generation rule differs")
    _require("pid" in identity.get("forbidden_key_terms", []), "opaque identity terms are not excluded")
    evaluation = contract.get("component_evaluation", {})
    _require(evaluation.get("modes") == ["pure", "stateful"], "component modes differ")
    _require(evaluation.get("transitions") == ["mount", "update", "replace"], "evaluation transitions differ")
    _require(evaluation.get("partial_acceptance") == "forbidden", "partial evaluation acceptance is allowed")
    _require(contract.get("explicitly_deferred") == DEFERRED_FIELDS, "later-phase fields changed")
    _require(contract.get("api_state") == "experimental", "stable API is overclaimed")
    _require(contract.get("support_state") == "unsupported", "support is overclaimed")


def validate_ledger(ledger: dict[str, Any], phase_1_ledger: Path = PHASE_1_LEDGER) -> None:
    _require(ledger.get("ledger_id") == "BX-BH02-OUTPUT-LEDGER-0.2", "Phase 2 ledger ID is invalid")
    _require(ledger.get("status") == "phase-2-semantic-contracts-implemented-experimental", "Phase 2 ledger state differs")
    _require(ledger.get("authorization_ref") == "BX-BH02-PHASE-02-AUTHORIZATION-0.1", "Phase 2 ledger authorization link is invalid")
    predecessor = ledger.get("supersedes", {})
    _require(predecessor.get("preserved_unchanged") is True, "Phase 1 ledger preservation is not recorded")
    _require(_sha256(phase_1_ledger) == predecessor.get("sha256"), "Phase 1 ledger hash is stale")
    outputs = ledger.get("required_outputs", [])
    _require([record.get("id") for record in outputs] == EXPECTED_OUTPUT_IDS, "required outputs differ")
    _require(outputs[0].get("state") == "implemented-experimental-phase-2", "semantic output is not recorded")
    _require(all(record.get("state") == "planned-unimplemented" for record in outputs[1:-1]), "later output is overclaimed")
    _require(outputs[-1].get("state") == "implemented-phase-1-extended-phase-2", "leakage validation state differs")
    evidence = ledger.get("evidence_boundary", {})
    _require(evidence.get("semantic_contracts") == "experimental-version-1", "semantic evidence state differs")
    _require(evidence.get("component_behavior") == "experimental-pure-stateful-evaluation", "component evidence state differs")
    for field in ("headless_renderer", "dom_conformance", "native_controls"):
        _require(evidence.get(field) in {"unimplemented", "unexecuted"}, f"later evidence is overclaimed: {field}")
    _require(evidence.get("support") == "unsupported", "ledger support is overclaimed")


def validate_sources(repo_root: Path = REPO_ROOT) -> None:
    source_roots = [
        repo_root / "packages/blazex_core/lib",
        repo_root / "packages/blazex_ui_tree/lib",
    ]
    for source_root in source_roots:
        _require(source_root.is_dir(), f"semantic source root is missing: {source_root}")
        for source in sorted(source_root.rglob("*.ex")):
            match = CONCRETE_LEAKAGE.search(source.read_text(encoding="utf-8"))
            _require(match is None, f"concrete adapter/platform leakage in {source}: {match.group(0) if match else ''}")

    node_source = (repo_root / "packages/blazex_ui_tree/lib/blazex/ui_tree/node.ex").read_text(encoding="utf-8")
    _require(
        "@kinds [:text, :group, :action, :field, :selection, :collection, :surface]" in node_source,
        "implemented node vocabulary differs from the contract",
    )
    match = re.search(r"defstruct\s+\[([^\]]+)\]", node_source)
    _require(match is not None, "semantic node struct is missing")
    fields = [field.strip().removeprefix(":") for field in match.group(1).split(",")]
    _require(fields == EXPECTED_FIELDS, "implemented semantic node fields differ")
    for forbidden in DEFERRED_FIELDS:
        _require(forbidden not in fields, f"later-phase node field implemented prematurely: {forbidden}")

    identity_source = (repo_root / "packages/blazex_core/lib/blazex/core/identity.ex").read_text(encoding="utf-8")
    for forbidden_guard in ("is_pid", "is_reference", "is_function", "is_port", "is_map", "is_float"):
        _require(forbidden_guard not in identity_source, f"identity admits an opaque key class: {forbidden_guard}")
    evaluator_source = (repo_root / "packages/blazex_core/lib/blazex/core/evaluator.ex").read_text(encoding="utf-8")
    for transition in (":mount", ":update", ":replace"):
        _require(transition in evaluator_source, f"evaluation transition is missing: {transition}")

    for project in (repo_root / "packages/blazex_core", repo_root / "packages/blazex_ui_tree"):
        manifest = (project / "mix.exs").read_text(encoding="utf-8")
        _require(not re.search(r"\b(?:git|github|hex):", manifest), f"external dependency source found in {manifest}")
        _require(not (project / "mix.lock").exists(), f"unexpected lockfile: {project / 'mix.lock'}")


def validate_fixtures(index: dict[str, Any], fixtures: dict[str, Any], repo_root: Path = REPO_ROOT) -> None:
    _require(index.get("status") == "phase-2-semantic-kernel-passed-local", "conformance index state differs")
    _require(index.get("activation_phase") == "BH-02 Phase 2", "conformance index names the wrong phase")
    _require(index.get("api_state") == "experimental", "conformance index claims stable API")
    _require(index.get("support_state") == "unsupported", "conformance index claims support")
    _require(index.get("backend_results") == [], "renderer results exist before renderer phases")
    fixture_sets = index.get("fixture_sets", [])
    _require(len(fixture_sets) == 1, "Phase 2 must bind exactly one fixture set")
    fixture_binding = fixture_sets[0]
    _require(fixture_binding.get("scenario_count") == len(EXPECTED_SCENARIOS), "fixture scenario count differs")
    fixture_path = repo_root / str(fixture_binding.get("path", ""))
    _require(fixture_path.is_file() and _sha256(fixture_path) == fixture_binding.get("sha256"), "fixture binding is stale")
    auth_binding = index.get("authorization", {})
    contract_binding = index.get("semantic_contract", {})
    for binding in (auth_binding, contract_binding):
        path = repo_root / str(binding.get("path", ""))
        _require(path.is_file() and _sha256(path) == binding.get("sha256"), f"conformance binding is stale: {path}")
    scenarios = fixtures.get("scenarios", [])
    _require(fixtures.get("contract_ref") == "BX-BH02-PHASE-02-CONTRACT-0.1", "fixture contract link is invalid")
    _require(fixtures.get("status") == "passed-local-semantic-evaluation", "fixture result state differs")
    _require([scenario.get("id") for scenario in scenarios] == EXPECTED_SCENARIOS, "fixture coverage differs")
    _require(all(scenario.get("expected") for scenario in scenarios), "fixture expected outcomes are incomplete")
    _require(fixtures.get("renderer_results") == [], "fixtures contain premature renderer results")
    _require(fixtures.get("support_state") == "unsupported", "fixtures claim support")


def validate_completion(completion: dict[str, Any], repo_root: Path = REPO_ROOT) -> None:
    _require(completion.get("record_id") == "BX-BH02-DECISION-PHASE-02-GO", "completion ID is invalid")
    _require(completion.get("state") == "passed", "Phase 2 completion did not pass")
    _require(
        completion.get("authorization_ref") == "BX-BH02-PHASE-02-AUTHORIZATION-0.1",
        "completion authorization link is invalid",
    )
    _require(completion.get("contract_ref") == "BX-BH02-PHASE-02-CONTRACT-0.1", "completion contract link is invalid")
    commits = completion.get("section_commits", [])
    _require(
        [(record.get("section"), record.get("commit")) for record in commits]
        == [
            ("2.1", "e22fbd4"),
            ("2.2", "9b8ac52"),
            ("2.3", "42d66ec"),
            ("2.4", "resolve-from-this-records-git-commit"),
        ],
        "section commit record differs",
    )
    artifact_hashes = completion.get("artifact_hashes", [])
    _require([binding.get("path") for binding in artifact_hashes] == EXPECTED_COMPLETION_PATHS, "completion artifact inventory differs")
    for binding in artifact_hashes:
        path = repo_root / str(binding.get("path", ""))
        _require(path.is_file() and _sha256(path) == binding.get("sha256"), f"completion binding is stale: {path}")
    outcome = completion.get("outcome", {})
    _require(outcome.get("api_state") == "experimental", "completion claims stable API")
    _require(outcome.get("support_state") == "unsupported", "completion claims support")
    _require("eligible but not authorized" in outcome.get("next_phase", ""), "Phase 3 authorization boundary is missing")


def validate(repo_root: Path = REPO_ROOT, research_root: Path = RESEARCH_ROOT) -> None:
    auth = _load_json(research_root / AUTHORIZATION.relative_to(RESEARCH_ROOT))
    contract = _load_json(research_root / CONTRACT.relative_to(RESEARCH_ROOT))
    ledger = _load_json(research_root / LEDGER.relative_to(RESEARCH_ROOT))
    index = _load_json(repo_root / CONFORMANCE_INDEX.relative_to(REPO_ROOT))
    fixtures = _load_json(repo_root / FIXTURES.relative_to(REPO_ROOT))
    completion = _load_json(research_root / COMPLETION.relative_to(RESEARCH_ROOT))
    validate_authorization(auth, repo_root)
    validate_contract(contract, auth)
    validate_ledger(ledger, research_root / PHASE_1_LEDGER.relative_to(RESEARCH_ROOT))
    validate_sources(repo_root)
    validate_fixtures(index, fixtures, repo_root)
    validate_completion(completion, repo_root)


def main() -> int:
    try:
        validate()
    except ValidationError as exc:
        print(f"BH-02 Phase 2 semantic validation failed: {exc}", file=sys.stderr)
        return 1
    print("BH-02 Phase 2 semantic validation passed: authorization, contract, identity, node surface, evaluation boundary, fixtures, and support limits checked.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
