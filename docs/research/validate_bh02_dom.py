#!/usr/bin/env python3
"""Validate BH-02 Phase 6 standalone DOM and browser evidence."""

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
AUTHORIZATION = BASELINE_ROOT / "blazex-bh-02-phase-06-authorization-v0.1.0.json"
CONTRACT = BASELINE_ROOT / "blazex-bh-02-phase-06-contract-v0.1.0.json"
LEDGER = BASELINE_ROOT / "blazex-bh-02-phase-06-output-ledger-v0.6.0.json"
PHASE_5_LEDGER = BASELINE_ROOT / "blazex-bh-02-phase-05-output-ledger-v0.5.0.json"
COMPLETION = BASELINE_ROOT / "blazex-bh-02-phase-06-completion-v0.1.0.json"
INDEX = REPO_ROOT / "integration/conformance/conformance-index-v0.6.0.json"
FIXTURES = REPO_ROOT / "integration/conformance/dom-renderer-fixtures-v0.1.0.json"
BROWSER_MATRIX = REPO_ROOT / "integration/conformance/dom-browser-matrix-v0.1.0.json"

DEPENDENCIES = ["blazex_core", "blazex_effects", "blazex_ui_tree", "blazex_renderer"]
NODE_KINDS = ["text", "group", "action", "field", "selection", "collection", "surface"]
LAYOUT_MODES = ["none", "stack", "grid", "overlay"]
ROLES = ["generic", "text", "group", "button", "text_field", "checkbox", "list", "list_item", "dialog", "status"]
FEATURES = ["event_bindings", "logical_layout", "accessibility", "focus", "selection"]
BATCH_FIELDS = ["version", "owner", "generation", "revision", "transition", "root", "digest"]
NODE_FIELDS = ["version", "id", "tag", "text", "attributes", "listeners", "focus", "selection", "children"]
LISTENER_FIELDS = ["semantic", "native", "owner", "source"]
TAGS = ["span", "div", "button", "input", "ul", "li", "section"]
EVENTS = ["activate", "change", "submit", "select", "expand", "dismiss", "move", "reorder", "increment", "decrement", "request_open", "request_close", "request_page"]
NATIVE_MAPPING = {
    "activate": "click", "change": "input", "submit": "submit", "select": "change",
    "expand": "click", "dismiss": "click", "move": "pointermove", "reorder": "drop",
    "increment": "click", "decrement": "click", "request_open": "click",
    "request_close": "click", "request_page": "click",
}
SCENARIOS = [
    "dom-complete-capabilities", "dom-all-semantic-node-kinds", "dom-deterministic-identity",
    "dom-deterministic-projection", "dom-atomic-mount", "dom-update-revision",
    "dom-generation-replacement", "dom-idempotent-disposal", "dom-stale-revision-rejection",
    "dom-accessibility-lowering", "dom-layout-token-lowering", "dom-autofocus",
    "dom-update-focus-restoration", "dom-controlled-selection", "dom-semantic-event-mapping",
    "dom-bounded-event-payload", "headless-dom-semantic-parity", "dom-framework-isolation",
    "linux-chrome-page-conformance", "linux-firefox-page-conformance",
]
BROWSER_CHECKS = ["mount", "semantic-accessibility", "autofocus-selection", "event-normalization", "focus-restoration", "atomic-stale-rejection", "dispose"]
OUTPUT_IDS = [
    "semantic-ui-node-identity", "event-action-contract", "effect-capability-resource-contract",
    "layout-token-accessibility-focus-selection-file-intent",
    "renderer-lifecycle-capability-negotiation", "deterministic-headless-renderer-traces",
    "minimal-dom-lowering", "limited-direct-native-control-spike",
    "forbidden-dependency-leakage-checks",
]
COMPLETION_PATHS = [
    "docs/research/assets/bh-02-baseline/blazex-bh-02-phase-06-authorization-v0.1.0.json",
    "docs/research/assets/bh-02-baseline/blazex-bh-02-phase-06-contract-v0.1.0.json",
    "docs/research/assets/bh-02-baseline/blazex-bh-02-phase-06-output-ledger-v0.6.0.json",
    "integration/conformance/dom-renderer-fixtures-v0.1.0.json",
    "integration/conformance/dom-browser-matrix-v0.1.0.json",
    "integration/conformance/conformance-index-v0.6.0.json",
]
SERVER_LEAKAGE = re.compile(r"\b(?:phoenix|plug|liveview|localliveview|local_live_view)\b", re.IGNORECASE)


class ValidationError(Exception):
    """Raised when Phase 6 evidence must fail closed."""


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
    _require(auth.get("authorization_id") == "BX-BH02-PHASE-06-AUTHORIZATION-0.1", "authorization ID is invalid")
    _require(auth.get("status") == "approved-phase-6-only", "Phase 6 lacks explicit approval")
    _require(auth.get("approved_by", {}).get("role") == "repository-owner", "owner approval is incomplete")
    activation = auth.get("activation", {})
    base = str(activation.get("base_revision", ""))
    _require(base == activation.get("base_remote_revision") and len(base) == 40, "synchronized base is invalid")
    _require(activation.get("working_branch") == "codex/bh-02-phase-06-dom-lowering", "working branch differs")
    rules = auth.get("delivery_rules", {})
    for rule in ("sections_in_order", "commit_per_section", "single_pull_request", "return_to_synchronized_main_after_delivery", "delete_local_feature_branch_after_delivery", "delete_remote_feature_branch_after_delivery"):
        _require(rules.get(rule) is True, f"delivery rule is missing: {rule}")
    _require(rules.get("section_count") == 4, "Phase 6 must contain four sections")
    exclusions = " ".join(auth.get("not_authorized", [])).lower()
    for phrase in ("phases 7 through 8", "stable", "incremental dom", "visual or pixel", "native-control", "external dependencies", "support claims"):
        _require(phrase in exclusions, f"authorization does not exclude {phrase}")
    for binding in auth.get("approval_basis", []):
        path = repo_root / str(binding.get("path", ""))
        _require(path.is_file() and _sha256(path) == binding.get("sha256"), f"authorization input is stale: {path}")
    result = subprocess.run(["git", "merge-base", "--is-ancestor", base, "HEAD"], cwd=repo_root, check=False)
    _require(result.returncode == 0, "work does not descend from the authorized base")


def validate_contract(contract: dict[str, Any], auth: dict[str, Any]) -> None:
    _require(contract.get("contract_id") == "BX-BH02-PHASE-06-CONTRACT-0.1", "contract ID is invalid")
    _require(contract.get("authorization_ref") == auth.get("authorization_id"), "contract authorization differs")
    package = contract.get("package_boundary", {})
    _require(package.get("dependencies") == DEPENDENCIES, "DOM dependencies differ")
    _require(package.get("external_dependencies") == "none", "external dependency is authorized")
    caps = contract.get("dom_capabilities", {})
    _require(caps.get("tree_versions") == [1], "tree versions differ")
    _require(caps.get("node_kinds") == NODE_KINDS, "node kinds differ")
    _require(caps.get("layout_modes") == LAYOUT_MODES, "layout modes differ")
    _require(caps.get("accessibility_roles") == ROLES, "roles differ")
    _require(caps.get("features") == FEATURES, "features differ")
    batch = contract.get("dom_batch", {})
    _require(batch.get("version") == 1 and batch.get("fields") == BATCH_FIELDS, "DOM batch surface differs")
    _require(batch.get("projection_transitions") == ["mount", "update", "replace"], "projection transitions differ")
    _require(batch.get("application") == "atomic-full-root-replacement", "application is not atomic full-root replacement")
    node = contract.get("dom_node", {})
    _require(node.get("version") == 1 and node.get("fields") == NODE_FIELDS, "DOM node surface differs")
    _require(node.get("tags") == TAGS and node.get("unknown_tag_or_field") == "reject", "DOM tags are not closed")
    listener = contract.get("dom_listener", {})
    _require(listener.get("fields") == LISTENER_FIELDS, "listener fields differ")
    _require(listener.get("semantic_events") == EVENTS, "semantic events differ")
    _require(listener.get("native_mapping") == NATIVE_MAPPING, "native event mapping differs")
    _require(listener.get("retains_browser_event") is False, "browser events may be retained")
    driver = contract.get("browser_driver", {})
    _require(driver.get("methods") == ["apply", "snapshot", "dispose"], "browser driver surface differs")
    _require(driver.get("stale_generation_or_revision") == "reject-before-mutation", "stale work is not rejected atomically")
    _require(driver.get("dispose") == "idempotent-remove-root-and-listeners", "driver disposal differs")
    _require(driver.get("global_or_network_access") == "forbidden", "global or network access is allowed")
    _require(contract.get("active_browser_matrix") == ["linux-google-chrome", "linux-firefox"], "active browser matrix differs")
    _require(contract.get("api_state") == "experimental", "contract claims stable API")
    _require(contract.get("support_state") == "unsupported", "contract claims support")


def validate_source_text(text: str) -> None:
    match = SERVER_LEAKAGE.search(text)
    _require(match is None, f"server-framework leakage found: {match.group(0) if match else ''}")


def validate_sources(repo_root: Path = REPO_ROOT) -> None:
    package_root = repo_root / "packages/blazex_renderer_dom"
    metadata = _load_json(package_root / "blazex.project.json")
    _require(metadata.get("activation_phase") == "BH-02 Phase 6", "DOM activation phase differs")
    _require(metadata.get("dependencies") == DEPENDENCIES and metadata.get("planned_dependencies") == [], "DOM metadata dependencies differ")
    _require(metadata.get("public_api_state") == "experimental-not-stable", "DOM metadata claims stable API")
    for source in sorted((package_root / "lib").rglob("*.ex")):
        validate_source_text(source.read_text(encoding="utf-8"))
    manifest = (package_root / "mix.exs").read_text(encoding="utf-8")
    for dependency in DEPENDENCIES:
        _require(f"{{:{dependency}, path:" in manifest, f"local dependency missing: {dependency}")
    _require(not re.search(r"\b(?:git|github|hex):", manifest), "external dependency source found")
    _require(not (package_root / "mix.lock").exists(), "unexpected DOM lockfile")
    required = [
        package_root / "lib/blazex/renderer/dom.ex",
        package_root / "lib/blazex/renderer/dom/batch.ex",
        package_root / "lib/blazex/renderer/dom/lowerer.ex",
        package_root / "js/dom-protocol.js",
        package_root / "js/dom-driver.js",
        package_root / "js/run-browser-conformance.py",
        repo_root / "integration/conformance/test/cross_renderer_conformance_test.exs",
    ]
    for path in required:
        _require(path.is_file(), f"implemented source is missing: {path}")
    combined = "\n".join(path.read_text(encoding="utf-8") for path in required)
    for marker in ("def capabilities", "def mount", "def update", "def replace", "def dispose", "validateBatch", "#preflightTransition", "normalizeEvent", "replaceChildren", "sha256"):
        _require(marker in combined.lower() if marker == "sha256" else marker in combined, f"implementation marker is missing: {marker}")
    js_text = "\n".join((package_root / "js" / name).read_text(encoding="utf-8") for name in ("dom-protocol.js", "dom-driver.js"))
    for forbidden in ("innerHTML", "eval(", "fetch(", "XMLHttpRequest", "WebSocket", "localStorage", "sessionStorage", "document.cookie"):
        _require(forbidden not in js_text, f"forbidden browser-driver capability found: {forbidden}")


def validate_browser_matrix(matrix: dict[str, Any]) -> None:
    _require(matrix.get("record_id") == "BX-BH02-PHASE-06-DOM-BROWSER-MATRIX-0.1", "browser matrix ID differs")
    _require(matrix.get("environment") == "local-linux-x86_64", "browser environment differs")
    _require(matrix.get("command") == "python3 js/run-browser-conformance.py", "browser command differs")
    rows = matrix.get("results", [])
    _require([row.get("browser") for row in rows] == ["chrome", "firefox"], "Chrome and Firefox rows are required")
    _require(all(row.get("result") == "passed" and row.get("checks") == BROWSER_CHECKS for row in rows), "browser checks did not all pass")
    _require(all(str(row.get("version", "")) and str(row.get("executable", "")).startswith("/") for row in rows), "browser version or executable is missing")
    _require(matrix.get("support_state") == "unsupported", "browser evidence claims support")
    limits = " ".join(matrix.get("limitations", [])).lower()
    for phrase in ("no browser support claim", "no pixel", "incremental reconciliation"):
        _require(phrase in limits, f"browser evidence limitation is missing: {phrase}")


def validate_fixtures(index: dict[str, Any], fixtures: dict[str, Any], matrix: dict[str, Any], repo_root: Path = REPO_ROOT) -> None:
    _require(fixtures.get("fixture_set_id") == "BX-BH02-DOM-RENDERER-FIXTURES-0.1", "fixture ID differs")
    _require([item.get("id") for item in fixtures.get("scenarios", [])] == SCENARIOS, "DOM fixture coverage differs")
    _require(all(item.get("expected") for item in fixtures.get("scenarios", [])), "fixture outcomes are incomplete")
    for field in ("visual_results", "pixel_results", "manual_accessibility_results", "native_results", "performance_results"):
        _require(fixtures.get(field) == [], f"fixture overclaims {field}")
    _require(fixtures.get("api_state") == "experimental", "fixtures claim stable API")
    _require(fixtures.get("support_state") == "unsupported", "fixtures claim support")
    _require(index.get("status") == "phase-6-standalone-dom-passed-local", "index status differs")
    _require(index.get("activation_phase") == "BH-02 Phase 6", "index phase differs")
    _require(index.get("next_authorized_work") is None, "Phase 7 is prematurely authorized")
    _require(index.get("api_state") == "experimental", "index claims stable API")
    _require(index.get("support_state") == "unsupported", "index claims support")
    for field in ("geometry_results", "visual_results", "pixel_results", "manual_accessibility_results", "native_results", "provider_results"):
        _require(index.get(field) == [], f"index overclaims {field}")
    bindings = index.get("fixture_sets", [])
    _require(len(bindings) == 5 and bindings[-1].get("scenario_count") == len(SCENARIOS), "Phase 6 fixture inventory differs")
    for binding in bindings:
        path = repo_root / str(binding.get("path", ""))
        _require(path.is_file() and _sha256(path) == binding.get("sha256"), f"fixture binding is stale: {path}")
    for binding in (index.get("authorization", {}), index.get("phase_contract", {}), index.get("browser_matrix", {})):
        path = repo_root / str(binding.get("path", ""))
        _require(path.is_file() and _sha256(path) == binding.get("sha256"), f"index binding is stale: {path}")
    expected_rows = [("linux-google-chrome", "passed-local-development-conformance"), ("linux-firefox", "passed-local-development-conformance")]
    _require([(row.get("browser"), row.get("result")) for row in index.get("browser_results", [])] == expected_rows, "browser result index differs")
    validate_browser_matrix(matrix)


def validate_ledger(ledger: dict[str, Any], predecessor: Path = PHASE_5_LEDGER) -> None:
    _require(ledger.get("ledger_id") == "BX-BH02-OUTPUT-LEDGER-0.6", "ledger ID differs")
    _require(_sha256(predecessor) == ledger.get("supersedes", {}).get("sha256"), "Phase 5 ledger hash is stale")
    outputs = ledger.get("required_outputs", [])
    _require([item.get("id") for item in outputs] == OUTPUT_IDS, "output ledger differs")
    _require(outputs[6].get("state") == "implemented-experimental-phase-6", "DOM output is not implemented")
    _require(outputs[7].get("state") == "planned-unimplemented", "native spike is overclaimed")
    evidence = ledger.get("evidence_boundary", {})
    _require(evidence.get("standalone_dom") == "experimental-full-projection-local-beam-node-chrome-firefox", "DOM evidence differs")
    for field, expected in (("incremental_reconciliation", "unimplemented"), ("hydration", "unimplemented"), ("server_transport", "unimplemented"), ("visual_equivalence", "unexecuted"), ("pixel_results", "unexecuted"), ("manual_accessibility", "unexecuted"), ("native_controls", "unexecuted")):
        _require(evidence.get(field) == expected, f"ledger overclaims {field}")
    _require(evidence.get("support") == "unsupported", "ledger claims support")


def validate_completion(completion: dict[str, Any], repo_root: Path = REPO_ROOT) -> None:
    _require(completion.get("record_id") == "BX-BH02-DECISION-PHASE-06-GO", "completion ID differs")
    _require(completion.get("state") == "passed", "Phase 6 completion did not pass")
    _require([(item.get("section"), item.get("commit")) for item in completion.get("section_commits", [])] == [("6.1", "9161542"), ("6.2", "a265ad1"), ("6.3", "7150b1d"), ("6.4", "resolve-from-this-records-git-commit")], "section commit record differs")
    bindings = completion.get("artifact_hashes", [])
    _require([item.get("path") for item in bindings] == COMPLETION_PATHS, "completion inventory differs")
    for binding in bindings:
        path = repo_root / str(binding.get("path", ""))
        _require(path.is_file() and _sha256(path) == binding.get("sha256"), f"completion binding is stale: {path}")
    outcome = completion.get("outcome", {})
    _require(outcome.get("api_state") == "experimental", "completion claims stable API")
    _require(outcome.get("support_state") == "unsupported", "completion claims support")
    _require(outcome.get("next_phase") == "BH-02 Phase 7 is eligible but not authorized", "Phase 7 authority differs")


def validate(repo_root: Path = REPO_ROOT, research_root: Path = RESEARCH_ROOT) -> None:
    auth = _load_json(research_root / AUTHORIZATION.relative_to(RESEARCH_ROOT))
    contract = _load_json(research_root / CONTRACT.relative_to(RESEARCH_ROOT))
    ledger = _load_json(research_root / LEDGER.relative_to(RESEARCH_ROOT))
    completion = _load_json(research_root / COMPLETION.relative_to(RESEARCH_ROOT))
    index = _load_json(repo_root / INDEX.relative_to(REPO_ROOT))
    fixtures = _load_json(repo_root / FIXTURES.relative_to(REPO_ROOT))
    matrix = _load_json(repo_root / BROWSER_MATRIX.relative_to(REPO_ROOT))
    validate_authorization(auth, repo_root)
    validate_contract(contract, auth)
    validate_sources(repo_root)
    validate_fixtures(index, fixtures, matrix, repo_root)
    validate_ledger(ledger, research_root / PHASE_5_LEDGER.relative_to(RESEARCH_ROOT))
    validate_completion(completion, repo_root)


def main() -> int:
    try:
        validate()
    except ValidationError as exc:
        print(f"BH-02 Phase 6 DOM validation failed: {exc}", file=sys.stderr)
        return 1
    print("BH-02 Phase 6 DOM validation passed: authorization, lowering, driver, browsers, fixtures, leakage, and evidence limits checked.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
