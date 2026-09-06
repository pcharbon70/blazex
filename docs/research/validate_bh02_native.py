#!/usr/bin/env python3
"""Fail-closed validation for the BH-02 Phase 7 direct native-control spike."""

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
AUTHORIZATION = BASELINE_ROOT / "blazex-bh-02-phase-07-authorization-v0.1.0.json"
CONTRACT = BASELINE_ROOT / "blazex-bh-02-phase-07-contract-v0.1.0.json"
LEDGER = BASELINE_ROOT / "blazex-bh-02-phase-07-output-ledger-v0.7.0.json"
PREDECESSOR = BASELINE_ROOT / "blazex-bh-02-phase-06-output-ledger-v0.6.0.json"
COMPLETION = BASELINE_ROOT / "blazex-bh-02-phase-07-completion-v0.1.0.json"
INDEX = REPO_ROOT / "integration/conformance/conformance-index-v0.7.0.json"
FIXTURES = REPO_ROOT / "integration/conformance/native-control-fixtures-v0.1.0.json"
EXPERIMENT = REPO_ROOT / "experiments/native_renderer_spike"
EXPERIMENT_INDEX = EXPERIMENT / "experiment-index-v0.2.0.json"
GTK_EVIDENCE = EXPERIMENT / "gtk4-result-v0.1.0.json"

DEPENDENCIES = ["blazex_core", "blazex_effects", "blazex_ui_tree", "blazex_renderer"]
NODE_KINDS = ["text", "group", "action", "field", "selection", "collection", "surface"]
LAYOUT_MODES = ["none", "stack"]
ROLES = ["generic", "text", "group", "button", "text_field", "checkbox", "list", "list_item", "dialog", "status"]
FEATURES = ["event_bindings", "logical_layout", "accessibility", "focus", "selection"]
BATCH_FIELDS = ["version", "owner", "generation", "revision", "transition", "root", "digest"]
NODE_FIELDS = ["version", "id", "kind", "text", "attributes", "listeners", "focus", "selection", "children"]
PLATFORM_APIS = ["direct-win32", "direct-appkit", "direct-gtk4"]
MAPPINGS = {
    "windows": ["HWND", "STATIC", "BUTTON", "EDIT", "LISTBOX", "GetOpenFileNameW"],
    "macos": ["NSWindow", "NSStackView", "NSTextField", "NSButton", "NSTableView", "NSOpenPanel"],
    "linux": ["GtkWindow", "GtkBox", "GtkLabel", "GtkButton", "GtkEntry", "GtkCheckButton", "GtkListBox", "GtkFileDialog"],
}
OBSERVATIONS = [
    "actual-control-types", "semantic-events", "focus", "controlled-entry",
    "checkbox-selection", "keyed-list-selection", "accessible-roles",
    "stale-rejection-before-mutation", "idempotent-disposal",
]
SCENARIOS = [
    "native-complete-capabilities", "native-all-semantic-node-kinds",
    "native-deterministic-identity", "native-deterministic-batch",
    "native-bxn1-wire-roundtrip", "native-atomic-mount", "native-update-revision",
    "native-generation-replacement", "native-idempotent-disposal",
    "native-stale-revision-rejection", "native-accessibility-projection",
    "native-layout-projection", "native-focus", "native-controlled-text-selection",
    "native-checkbox-selection", "native-keyed-list-selection",
    "native-semantic-event-mapping", "native-validation-relationship",
    "native-file-choice-intent", "headless-dom-native-semantic-parity",
    "linux-gtk-direct-control-materialization", "windows-appkit-governed-deferral",
]
OUTPUT_IDS = [
    "semantic-ui-node-identity", "event-action-contract", "effect-capability-resource-contract",
    "layout-token-accessibility-focus-selection-file-intent",
    "renderer-lifecycle-capability-negotiation", "deterministic-headless-renderer-traces",
    "minimal-dom-lowering", "limited-direct-native-control-spike",
    "forbidden-dependency-leakage-checks",
]
COMPLETION_PATHS = [
    "docs/research/assets/bh-02-baseline/blazex-bh-02-phase-07-authorization-v0.1.0.json",
    "docs/research/assets/bh-02-baseline/blazex-bh-02-phase-07-contract-v0.1.0.json",
    "docs/research/assets/bh-02-baseline/blazex-bh-02-phase-07-output-ledger-v0.7.0.json",
    "integration/conformance/native-control-fixtures-v0.1.0.json",
    "experiments/native_renderer_spike/experiment-index-v0.2.0.json",
    "experiments/native_renderer_spike/gtk4-result-v0.1.0.json",
    "integration/conformance/conformance-index-v0.7.0.json",
]
FORBIDDEN_TOOLKITS = re.compile(r"\b(?:qt|wxwidgets)\b", re.IGNORECASE)
PORTABLE_LEAKAGE = re.compile(
    r"\b(?:phoenix|plug|liveview|localliveview|local_live_view|htmlelement|javascript|hwnd|nswindow|gtkwidget)\b",
    re.IGNORECASE,
)


class ValidationError(Exception):
    """Raised whenever Phase 7 evidence must fail closed."""


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


def _validate_binding(binding: dict[str, Any], repo_root: Path = REPO_ROOT) -> None:
    path = repo_root / str(binding.get("path", ""))
    _require(path.is_file() and _sha256(path) == binding.get("sha256"), f"stale evidence binding: {path}")


def validate_authorization(auth: dict[str, Any], repo_root: Path = REPO_ROOT) -> None:
    _require(auth.get("authorization_id") == "BX-BH02-PHASE-07-AUTHORIZATION-0.1", "authorization ID differs")
    _require(auth.get("status") == "approved-phase-7-only", "Phase 7 lacks explicit approval")
    _require(auth.get("approved_by", {}).get("role") == "repository-owner", "repository-owner approval is absent")
    activation = auth.get("activation", {})
    base = str(activation.get("base_revision", ""))
    _require(len(base) == 40 and base == activation.get("base_remote_revision"), "synchronized base differs")
    _require(activation.get("working_branch") == "codex/bh-02-phase-07-native-control-spike", "working branch differs")
    rules = auth.get("delivery_rules", {})
    for rule in (
        "sections_in_order", "commit_per_section", "single_pull_request", "merge_pull_request",
        "return_to_synchronized_main_after_delivery", "delete_local_feature_branch_after_delivery",
        "delete_remote_feature_branch_after_delivery",
    ):
        _require(rules.get(rule) is True, f"delivery rule is missing: {rule}")
    _require(rules.get("section_count") == 4, "Phase 7 must contain four sections")
    exclusions = " ".join(auth.get("not_authorized", [])).lower()
    for phrase in ("phase 8", "production package", "stable", "qt", "wxwidgets", "support claims"):
        _require(phrase in exclusions, f"authorization exclusion is missing: {phrase}")
    for binding in auth.get("approval_basis", []):
        _validate_binding(binding, repo_root)
    result = subprocess.run(["git", "merge-base", "--is-ancestor", base, "HEAD"], cwd=repo_root, check=False)
    _require(result.returncode == 0, "work does not descend from the authorized base")


def validate_contract(contract: dict[str, Any], auth: dict[str, Any]) -> None:
    _require(contract.get("contract_id") == "BX-BH02-PHASE-07-CONTRACT-0.1", "contract ID differs")
    _require(contract.get("authorization_ref") == auth.get("authorization_id"), "contract authorization differs")
    boundary = contract.get("experiment_boundary", {})
    _require(boundary.get("path") == "experiments/native_renderer_spike", "experiment boundary differs")
    _require(boundary.get("dependencies") == DEPENDENCIES, "experiment dependencies differ")
    _require(boundary.get("system_apis") == PLATFORM_APIS, "direct system APIs differ")
    _require(boundary.get("external_package_dependencies") == "none", "external package dependency is present")
    forbidden = boundary.get("forbidden_direct_or_transitive", [])
    for value in ("qt", "wxwidgets", "phoenix", "dom", "javascript"):
        _require(value in forbidden, f"forbidden boundary is missing: {value}")
    capabilities = contract.get("native_capabilities", {})
    _require(capabilities.get("node_kinds") == NODE_KINDS, "native node capabilities differ")
    _require(capabilities.get("layout_modes") == LAYOUT_MODES, "native layout capabilities differ")
    _require(capabilities.get("accessibility_roles") == ROLES, "native roles differ")
    _require(capabilities.get("features") == FEATURES, "native features differ")
    batch = contract.get("native_batch", {})
    _require(batch.get("version") == 1 and batch.get("fields") == BATCH_FIELDS, "native batch surface differs")
    _require(batch.get("application") == "validate-complete-batch-before-platform-mutation", "native application is not fail-closed")
    node = contract.get("native_node", {})
    _require(node.get("version") == 1 and node.get("fields") == NODE_FIELDS, "native node surface differs")
    _require(node.get("kinds") == NODE_KINDS and node.get("unknown_kind_or_field") == "reject", "native node vocabulary is open")
    _require(contract.get("platform_mappings") == MAPPINGS, "direct platform mappings differ")
    _require(contract.get("linux_automated_observations") == OBSERVATIONS, "Linux observation contract differs")
    rows = contract.get("platform_evidence", [])
    _require([(row.get("target"), row.get("state")) for row in rows] == [
        ("linux-x86_64", "active"), ("windows", "deferred"), ("macos", "deferred")
    ], "platform evidence states differ")
    _require(contract.get("api_state") == "experimental", "contract claims stable API")
    _require(contract.get("support_state") == "unsupported", "contract claims support")


def validate_source_text(text: str) -> None:
    match = PORTABLE_LEAKAGE.search(text)
    _require(match is None, f"portable implementation leakage found: {match.group(0) if match else ''}")


def validate_sources(repo_root: Path = REPO_ROOT) -> None:
    experiment = repo_root / "experiments/native_renderer_spike"
    metadata = _load_json(experiment / "blazex.project.json")
    _require(metadata.get("activation_phase") == "BH-02 Phase 7", "experiment activation phase differs")
    _require(metadata.get("dependencies") == DEPENDENCIES and metadata.get("planned_dependencies") == [], "experiment metadata dependencies differ")
    _require(metadata.get("public_api_state") == "experimental-not-stable", "experiment metadata claims stable API")
    manifest = (experiment / "mix.exs").read_text(encoding="utf-8")
    for dependency in DEPENDENCIES:
        _require(f"{{:{dependency}, path:" in manifest, f"local dependency missing: {dependency}")
    _require(not re.search(r"\b(?:git|github|hex):", manifest), "external dependency source found")
    _require(not (experiment / "mix.lock").exists(), "unexpected experiment lockfile")
    portable_text = "\n".join(path.read_text(encoding="utf-8") for path in sorted((experiment / "lib").rglob("*.ex")))
    validate_source_text(portable_text)
    required = [
        "platform/native_protocol.c", "platform/native_protocol.h", "platform/gtk4_adapter.c",
        "platform/win32_adapter.c", "platform/appkit_adapter.m", "scripts/build_gtk4.sh",
        "scripts/run_gtk4.py", "fixtures/representative-v0.1.0.bxn1",
        "fixtures/stale-update-v0.1.0.bxn1", "test/gtk4_platform_test.exs",
    ]
    for relative in required:
        _require((experiment / relative).is_file(), f"native source or evidence is missing: {relative}")
    platform_text = "\n".join(path.read_text(encoding="utf-8") for path in sorted((experiment / "platform").iterdir()) if path.is_file())
    match = FORBIDDEN_TOOLKITS.search(platform_text)
    _require(match is None, f"forbidden cross-platform toolkit found: {match.group(0) if match else ''}")
    for marker in ("CreateWindowW", "NSWindow", "gtk_window_new", "bx_read_batch", "xvfb-run"):
        combined = platform_text + (experiment / "scripts/run_gtk4.py").read_text(encoding="utf-8")
        _require(marker in combined, f"direct adapter marker is missing: {marker}")


def validate_gtk_evidence(evidence: dict[str, Any]) -> None:
    _require(evidence.get("result") == "passed", "GTK execution did not pass")
    _require(evidence.get("support_state") == "experimental-unsupported", "GTK evidence claims support")
    environment = evidence.get("environment", {})
    _require(str(environment.get("gtk_runtime_package", "")).startswith("4.14.5"), "GTK runtime version differs")
    for key in ("kernel", "architecture", "compiler", "glib_runtime_package", "display"):
        _require(bool(environment.get(key)), f"GTK environment field is missing: {key}")
    types = [item.get("native_type") for item in evidence.get("controls", [])]
    expected = ["GtkWindow", "GtkBox", "GtkLabel", "GtkButton", "GtkEntry", "GtkCheckButton", "GtkListBox", "GtkLabel", "GtkLabel", "GtkLabel"]
    _require(types == expected, "actual GTK control inventory differs")
    _require(evidence.get("services") == [{"intent": "file-choice", "native_type": "GtkFileDialog"}], "GTK service mapping differs")
    observation = evidence.get("observation", "")
    for token in ("RESULT\tpassed", "action=1", "change=1", "text_selection=1:0:3", "check=1", "list=1", "focus=1", "stale_rejected=1", "disposals=1"):
        _require(token in observation, f"GTK observation is missing: {token}")
    deferred = " ".join(evidence.get("deferred", [])).lower()
    for phrase in ("windows", "macos", "accessibility-tree", "screen-reader", "file-dialog interaction", "geometry"):
        _require(phrase in deferred, f"GTK deferral is missing: {phrase}")


def validate_experiment_index(index: dict[str, Any], evidence: dict[str, Any], repo_root: Path = REPO_ROOT) -> None:
    _require(index.get("status") == "phase-7-linux-gtk-passed-local-two-platforms-deferred", "experiment status differs")
    _require(index.get("experiment_dependencies") == DEPENDENCIES, "indexed experiment dependencies differ")
    rows = index.get("adapters", [])
    _require([row.get("target") for row in rows] == ["windows", "macos", "linux-x86_64"], "adapter inventory differs")
    _require("deferred-uncompiled" in rows[0].get("state", "") and "deferred-uncompiled" in rows[1].get("state", ""), "unavailable adapters are not deferred")
    _require(rows[2].get("state") == "passed-local-gtk-4.14.5-under-xvfb", "Linux adapter did not pass")
    _require(index.get("excluded_direct_or_transitive") == ["qt", "wxwidgets"], "excluded toolkits differ")
    _require(index.get("support_state") == "experimental-unsupported", "experiment index claims support")
    evidence_path = repo_root / "experiments/native_renderer_spike" / rows[2]["evidence"]
    _require(evidence_path.is_file() and _sha256(evidence_path) == _sha256(repo_root / GTK_EVIDENCE.relative_to(REPO_ROOT)), "experiment GTK evidence binding differs")
    validate_gtk_evidence(evidence)


def validate_fixtures(fixtures: dict[str, Any]) -> None:
    _require(fixtures.get("fixture_set_id") == "BX-BH02-NATIVE-CONTROL-FIXTURES-0.1", "native fixture ID differs")
    _require([item.get("id") for item in fixtures.get("scenarios", [])] == SCENARIOS, "native scenarios differ")
    _require(all(item.get("expected") for item in fixtures.get("scenarios", [])), "native expectations are incomplete")
    active = fixtures.get("active_platform_results", [])
    _require(len(active) == 1 and active[0].get("target") == "linux-x86_64" and active[0].get("result") == "passed-local-development-conformance", "active platform result differs")
    deferred = fixtures.get("deferred_platform_results", [])
    _require([(row.get("target"), row.get("result")) for row in deferred] == [
        ("windows", "deferred-environment-unavailable"), ("macos", "deferred-environment-unavailable")
    ], "platform deferrals differ")
    for field in ("geometry_results", "visual_results", "pixel_results", "manual_accessibility_results", "performance_results"):
        _require(fixtures.get(field) == [], f"fixtures overclaim {field}")
    _require(fixtures.get("api_state") == "experimental" and fixtures.get("support_state") == "unsupported", "fixtures overclaim maturity")


def validate_conformance_index(index: dict[str, Any], repo_root: Path = REPO_ROOT) -> None:
    _require(index.get("status") == "phase-7-direct-native-spike-passed-local-gtk", "conformance index status differs")
    _require(index.get("activation_phase") == "BH-02 Phase 7", "conformance index phase differs")
    _require(index.get("next_authorized_work") is None, "Phase 8 is prematurely authorized")
    _require(index.get("api_state") == "experimental" and index.get("support_state") == "unsupported", "conformance index claims maturity")
    bindings = index.get("fixture_sets", [])
    _require(len(bindings) == 6 and bindings[-1].get("scenario_count") == len(SCENARIOS), "fixture inventory differs")
    for binding in bindings:
        _validate_binding(binding, repo_root)
    for binding in (index.get("authorization", {}), index.get("phase_contract", {}), index.get("browser_matrix", {}), index.get("native_experiment", {})):
        _validate_binding(binding, repo_root)
    native = index.get("native_results", [])
    _require([(row.get("target"), row.get("result")) for row in native] == [
        ("linux-x86_64", "passed-local-development-conformance"),
        ("windows", "deferred-environment-unavailable"),
        ("macos", "deferred-environment-unavailable"),
    ], "native result rows differ")
    _validate_binding({"path": native[0].get("evidence"), "sha256": native[0].get("sha256")}, repo_root)
    for field in ("geometry_results", "visual_results", "pixel_results", "manual_accessibility_results", "provider_results"):
        _require(index.get(field) == [], f"conformance index overclaims {field}")


def validate_ledger(ledger: dict[str, Any], predecessor: Path = PREDECESSOR) -> None:
    _require(ledger.get("ledger_id") == "BX-BH02-OUTPUT-LEDGER-0.7", "ledger ID differs")
    _require(ledger.get("supersedes", {}).get("sha256") == _sha256(predecessor), "predecessor ledger binding is stale")
    outputs = ledger.get("required_outputs", [])
    _require([item.get("id") for item in outputs] == OUTPUT_IDS, "output ledger inventory differs")
    _require(outputs[7].get("state") == "implemented-experimental-phase-7-one-target-two-deferred", "native output state differs")
    evidence = ledger.get("evidence_boundary", {})
    _require(evidence.get("native_controls") == "experimental-direct-gtk4-local-xvfb-windows-macos-deferred", "native evidence boundary differs")
    _require(evidence.get("native_accessibility_roles") == "observed-defaults-not-qualified", "accessibility evidence is overclaimed")
    for field, expected in (("visual_equivalence", "unexecuted"), ("pixel_results", "unexecuted"), ("manual_accessibility", "unexecuted"), ("support", "unsupported")):
        _require(evidence.get(field) == expected, f"ledger overclaims {field}")


def validate_completion(completion: dict[str, Any], repo_root: Path = REPO_ROOT) -> None:
    _require(completion.get("record_id") == "BX-BH02-DECISION-PHASE-07-GO", "completion ID differs")
    _require(completion.get("state") == "passed", "Phase 7 completion did not pass")
    _require([(item.get("section"), item.get("commit")) for item in completion.get("section_commits", [])] == [
        ("7.1", "8dee03f"), ("7.2", "bcac88b"), ("7.3", "c3f41b9"),
        ("7.4", "resolve-from-this-records-git-commit"),
    ], "section commit record differs")
    bindings = completion.get("artifact_hashes", [])
    _require([item.get("path") for item in bindings] == COMPLETION_PATHS, "completion inventory differs")
    for binding in bindings:
        _validate_binding(binding, repo_root)
    outcome = completion.get("outcome", {})
    _require(outcome.get("windows") == "deferred-environment-unavailable" and outcome.get("macos") == "deferred-environment-unavailable", "unavailable platforms are overclaimed")
    _require(outcome.get("api_state") == "experimental" and outcome.get("support_state") == "unsupported", "completion claims maturity")
    _require(outcome.get("next_phase") == "BH-02 Phase 8 remains planned and unauthorized", "Phase 8 authority differs")


def validate(repo_root: Path = REPO_ROOT, research_root: Path = RESEARCH_ROOT) -> None:
    auth = _load_json(research_root / AUTHORIZATION.relative_to(RESEARCH_ROOT))
    contract = _load_json(research_root / CONTRACT.relative_to(RESEARCH_ROOT))
    ledger = _load_json(research_root / LEDGER.relative_to(RESEARCH_ROOT))
    completion = _load_json(research_root / COMPLETION.relative_to(RESEARCH_ROOT))
    evidence = _load_json(repo_root / GTK_EVIDENCE.relative_to(REPO_ROOT))
    experiment_index = _load_json(repo_root / EXPERIMENT_INDEX.relative_to(REPO_ROOT))
    fixtures = _load_json(repo_root / FIXTURES.relative_to(REPO_ROOT))
    index = _load_json(repo_root / INDEX.relative_to(REPO_ROOT))
    validate_authorization(auth, repo_root)
    validate_contract(contract, auth)
    validate_sources(repo_root)
    validate_experiment_index(experiment_index, evidence, repo_root)
    validate_fixtures(fixtures)
    validate_conformance_index(index, repo_root)
    validate_ledger(ledger, research_root / PREDECESSOR.relative_to(RESEARCH_ROOT))
    validate_completion(completion, repo_root)


def main() -> int:
    try:
        validate()
    except ValidationError as exc:
        print(f"BH-02 Phase 7 native validation failed: {exc}", file=sys.stderr)
        return 1
    print("BH-02 Phase 7 native validation passed: authority, direct adapters, GTK execution, parity, deferrals, leakage, and evidence limits checked.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
