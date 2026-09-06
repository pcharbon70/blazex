#!/usr/bin/env python3
"""Fail-closed validation for the BH-02 Phase 8 acceptance candidate."""

from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any


RESEARCH_ROOT = Path(__file__).resolve().parent
REPO_ROOT = RESEARCH_ROOT.parent.parent
BASELINE_ROOT = RESEARCH_ROOT / "assets/bh-02-baseline"
PHASE_CONTRACT = BASELINE_ROOT / "blazex-bh-02-phase-08-contract-v0.1.0.json"
RECONCILIATION = BASELINE_ROOT / "blazex-bh-02-reconciliation-v0.1.0.json"
CONTRACT_BASELINE = BASELINE_ROOT / "blazex-bh-02-contract-baseline-v0.1.0.json"
REVIEW = BASELINE_ROOT / "blazex-bh-02-review-v0.1.0.json"
OVERLAY = BASELINE_ROOT / "blazex-bh-02-acceptance-overlay-v0.1.0.json"
CANDIDATE_DECISION = BASELINE_ROOT / "blazex-bh-02-candidate-decision-v0.1.0.json"
FINAL_OVERLAY = BASELINE_ROOT / "blazex-bh-02-acceptance-overlay-v0.2.0.json"
FINAL_LEDGER = BASELINE_ROOT / "blazex-bh-02-phase-08-output-ledger-v0.8.0.json"
FINAL_CONFORMANCE = REPO_ROOT / "integration/conformance/conformance-index-v0.8.0.json"
FINAL_DECISION = BASELINE_ROOT / "blazex-bh-02-acceptance-decision-v0.1.0.json"
COMPLETION = BASELINE_ROOT / "blazex-bh-02-phase-08-completion-v0.1.0.json"
ENTRY = RESEARCH_ROOT / "assets/bh-01-release/blazex-bh-02-entry-manifest-v0.1.0.json"
REGISTRY = RESEARCH_ROOT / "assets/quality-acceptance/blazex-acceptance-registry-v0.1.0.json"
CONFORMANCE = REPO_ROOT / "integration/conformance/conformance-index-v0.7.0.json"

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
SLICE_IDS = ["layout", "action", "field", "selection", "keyed-list", "surface", "focus", "file-choice", "disposal"]
LENSES = ["architecture", "implementation", "conformance", "accessibility", "security", "packaging", "provenance"]
A11Y_IDS = [
    "BX-ACC-GATE-BX-GREQ-A11Y-ANNOUNCEMENT",
    "BX-ACC-GATE-BX-GREQ-A11Y-FALLBACK",
    "BX-ACC-GATE-BX-GREQ-A11Y-INPUT-MODES",
    "BX-ACC-GATE-BX-GREQ-A11Y-KEYBOARD-FOCUS",
    "BX-ACC-GATE-BX-GREQ-A11Y-SEMANTICS",
    "BX-ACC-GATE-BX-GREQ-A11Y-VISUAL-ADAPTATION",
]
OVERLAY_IDS = ["BX-ACC-ROADMAP-BH-02", "BX-ACC-PACKAGE-BLAZEX-UI-TREE", *A11Y_IDS]
SURFACE_IDS = [
    "semantic-component-and-evaluation-v1",
    "event-effect-capability-resource-v1",
    "semantic-ui-and-presentation-intent-v1",
    "renderer-lifecycle-and-negotiation-v1",
    "headless-snapshot-and-trace-v1",
    "dom-full-projection-batch-v1",
    "native-full-projection-batch-v1",
    "cross-renderer-conformance-v1",
]
PACKAGE_METADATA = [
    "packages/blazex_core/blazex.project.json",
    "packages/blazex_effects/blazex.project.json",
    "packages/blazex_ui_tree/blazex.project.json",
    "packages/blazex_renderer/blazex.project.json",
    "packages/blazex_renderer_headless/blazex.project.json",
    "packages/blazex_test/blazex.project.json",
    "profiles/headless/blazex.project.json",
]


class ValidationError(Exception):
    """Raised when the BH-02 candidate must fail closed."""


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


def _resolve(path: str, repo_root: Path = REPO_ROOT) -> Path:
    candidate = repo_root / path
    _require(candidate.exists(), f"evidence path is missing: {path}")
    return candidate


def _validate_bindings(bindings: list[dict[str, Any]], repo_root: Path = REPO_ROOT) -> None:
    for binding in bindings:
        path = _resolve(str(binding.get("path", "")), repo_root)
        _require(path.is_file(), f"bound evidence is not a file: {path}")
        _require(_sha256(path) == binding.get("sha256"), f"stale evidence binding: {path}")


def validate_reconciliation(
    phase_contract: dict[str, Any],
    reconciliation: dict[str, Any],
    entry: dict[str, Any],
    conformance: dict[str, Any],
    repo_root: Path = REPO_ROOT,
) -> None:
    phase_decisions = reconciliation.get("phase_decisions", [])
    _require(len(phase_decisions) == 7 and [row.get("phase") for row in phase_decisions] == list(range(1, 8)), "phase decisions are incomplete")
    _validate_bindings(phase_decisions, repo_root)
    _require(
        [(row["phase"], row["path"], row["sha256"]) for row in phase_decisions]
        == [(row["phase"], row["path"], row["sha256"]) for row in phase_contract.get("candidate_phase_decisions", [])],
        "phase decision bindings diverge from the authorized contract",
    )

    outputs = reconciliation.get("required_outputs", [])
    _require([row.get("id") for row in outputs] == OUTPUT_IDS, "required outputs are incomplete or reordered")
    fixture_ids = {row.get("id") for row in conformance.get("fixture_sets", [])}
    for row in outputs:
        _require(str(row.get("state", "")).startswith("implemented"), f"output is not implemented: {row.get('id')}")
        for path in row.get("implementation", []):
            _resolve(path, repo_root)
        if str(row.get("conformance", "")).startswith("BX-BH02-"):
            _require(row["conformance"] in fixture_ids, f"conformance fixture is missing: {row['id']}")

    slices = reconciliation.get("representative_slice", [])
    _require([row.get("id") for row in slices] == SLICE_IDS, "representative slice is incomplete or reordered")
    for row in slices:
        _require(all(row.get(backend) for backend in ("headless", "dom", "native")), f"backend reconciliation is missing: {row.get('id')}")

    conditions = reconciliation.get("inherited_conditions", [])
    _require([row.get("id") for row in conditions] == [row["id"] for row in entry["conditions"]], "inherited conditions diverge")
    _require([row.get("owner") for row in conditions] == [row["owner"] for row in entry["conditions"]], "condition owners diverge")
    _require([row.get("id") for row in reconciliation.get("repeat_obligations", [])] == entry["repeat_obligations"], "repeat obligations diverge")
    _require([row.get("id") for row in reconciliation.get("deferred_qualification", [])] == [row["id"] for row in entry["deferred_qualification"]], "deferred qualifications diverge")
    _require(all(row.get("status") == "deferred-unchanged" for row in reconciliation["deferred_qualification"]), "deferred qualification was falsely promoted")
    _require(reconciliation.get("repository_boundaries") == entry["repository_boundaries"], "repository boundaries diverge")
    _require(reconciliation.get("forbidden_leakage") == entry["forbidden_leakage"], "forbidden leakage diverges")

    findings = reconciliation.get("findings", [])
    finding_ids = [row.get("id") for row in findings]
    _require(len(findings) == 6 and len(set(finding_ids)) == 6, "findings are missing or duplicated")
    for row in findings:
        _require(all(row.get(key) for key in ("severity", "owner", "disposition", "due", "stop_boundary")), f"finding disposition is incomplete: {row.get('id')}")
    _require(reconciliation.get("active_blockers") == [], "candidate has an active blocker")
    _require(reconciliation.get("api_state") == "experimental-not-stable", "reconciliation promotes public API stability")
    _require(reconciliation.get("support_state") == "unsupported", "reconciliation promotes support")


def validate_contract_baseline(baseline: dict[str, Any], repo_root: Path = REPO_ROOT) -> None:
    surfaces = baseline.get("surfaces", [])
    _require([row.get("id") for row in surfaces] == SURFACE_IDS, "contract surfaces are incomplete or reordered")
    for row in surfaces:
        owner = _resolve(row["owner"], repo_root)
        if "modules" in row:
            module_names: set[str] = set()
            for path in owner.rglob("*.ex"):
                module_names.update(re.findall(r"^defmodule\s+([A-Za-z0-9_.]+)", path.read_text(encoding="utf-8"), re.MULTILINE))
            _require(set(row["modules"]).issubset(module_names), f"contract module inventory is stale: {row['id']}")
        for fixture in row.get("fixtures", []):
            _resolve(f"integration/conformance/{fixture}", repo_root)
    stability = baseline.get("stability", {})
    _require(stability.get("public_api") == "experimental-not-stable" and stability.get("support") == "unsupported", "contract baseline promotes stability or support")
    _require(stability.get("semver_promise") == "none" and stability.get("package_publication") == "not-authorized", "contract baseline promotes publication")
    native = baseline.get("native_experiment_boundary", {})
    _require(native.get("outward_dependency_only") is True and native.get("production_profiles_may_depend_on_experiment") is False, "native experiment isolation is missing")
    _require(native.get("excluded_systems") == ["qt", "wxwidgets"], "excluded native systems diverge")
    _require(baseline.get("material_change_control", {}).get("silent_breaking_change") == "forbidden", "material change control is incomplete")


def validate_review(review: dict[str, Any], reconciliation: dict[str, Any], repo_root: Path = REPO_ROOT) -> None:
    _validate_bindings(review.get("input_bindings", []), repo_root)
    lenses = review.get("lenses", [])
    _require([row.get("lens") for row in lenses] == LENSES, "review lenses are incomplete or reordered")
    candidate_findings = {row["id"] for row in reconciliation["findings"]}
    reviewed_findings: set[str] = set()
    for row in lenses:
        _require(all(row.get(key) for key in ("id", "reviewer_role", "scope", "evidence", "disposition", "unresolved_risks", "decision")), f"review lens is incomplete: {row.get('lens')}")
        for path in row["evidence"]:
            _resolve(path, repo_root)
        reviewed_findings.update(row.get("finding_ids", []))
    dispositions = review.get("finding_dispositions", [])
    _require({row.get("id") for row in dispositions} == candidate_findings == reviewed_findings, "review hides or invents findings")
    _require(all(row.get("blocks_candidate") is False for row in dispositions), "review contains a candidate blocker")
    _require(review.get("unresolved_candidate_blockers") == [], "review has unresolved candidate blockers")
    _require(review.get("decision") == "accept-candidate-with-bounded-conditions", "review decision is not accepted")
    _require(review.get("api_state") == "experimental-not-stable" and review.get("support_state") == "unsupported", "review promotes stability or support")


def validate_overlay(overlay: dict[str, Any], registry: dict[str, Any], repo_root: Path = REPO_ROOT) -> None:
    canonical = overlay.get("canonical_registry", {})
    registry_path = _resolve(canonical.get("path", ""), repo_root)
    _require(_sha256(registry_path) == canonical.get("sha256"), "canonical acceptance registry hash is stale")
    _require(canonical.get("mutation") == "none", "canonical registry mutation is claimed")
    canonical_rows = {row["id"]: row for row in registry.get("acceptance_conditions", [])}
    updates = overlay.get("condition_updates", [])
    _require([row.get("id") for row in updates] == OVERLAY_IDS, "acceptance overlay conditions are incomplete or reordered")
    _require(all(row["id"] in canonical_rows for row in updates), "overlay references an unknown acceptance condition")
    roadmap = updates[0]
    _require((roadmap.get("status"), roadmap.get("implementation_state"), roadmap.get("verification_state")) == ("passed", "implemented", "passed"), "BH-02 roadmap condition is not a valid pass")
    _require(len(roadmap.get("evidence_ids", [])) == 3, "BH-02 roadmap pass lacks evidence")
    package = updates[1]
    _require((package.get("status"), package.get("implementation_state"), package.get("verification_state"), package.get("evidence_ids")) == ("implemented", "implemented", "not-executed", []), "UI-tree package condition is falsely passed")
    for row in updates[2:]:
        _require((row.get("status"), row.get("implementation_state"), row.get("verification_state"), row.get("evidence_ids")) == ("planned", "not-started", "not-executed", []), f"accessibility condition is falsely qualified: {row.get('id')}")
    _require(overlay.get("waivers") == [] and overlay.get("supersessions") == [], "overlay contains a waiver or supersession")
    _require(overlay.get("bh03_state") == "not-authorized", "BH-03 was prematurely authorized")
    _require(overlay.get("api_state") == "experimental-not-stable" and overlay.get("support_state") == "unsupported", "overlay promotes stability or support")


def validate_candidate_decision(decision: dict[str, Any], phase_contract: dict[str, Any], repo_root: Path = REPO_ROOT) -> None:
    _validate_bindings(decision.get("bindings", []), repo_root)
    checks = decision.get("checks", [])
    expected = phase_contract.get("acceptance_checks", [])
    _require([row.get("id") for row in checks] == expected, "candidate decision checks are incomplete or reordered")
    _require([row.get("result") for row in checks].count("pending-section-8.4") == 1, "candidate gate must leave only the full reproducible gate pending")
    _require(checks[8].get("result") == "pending-section-8.4", "wrong candidate check remains pending")
    _require(decision.get("candidate_outcome") == "accepted-with-bounded-conditions", "candidate outcome is not accepted")
    _require(decision.get("final_decision") == "pending-section-8.4-complete-reproducible-gate", "candidate falsely claims final acceptance")
    _require(decision.get("active_blockers") == [], "candidate decision has active blockers")
    _require(decision.get("bounded_conditions") and decision.get("bh03_state") == "not-authorized", "candidate loses conditions or prematurely authorizes BH-03")
    _require(decision.get("api_state") == "experimental-not-stable" and decision.get("support_state") == "unsupported", "candidate decision promotes stability or support")


def validate_package_metadata(repo_root: Path = REPO_ROOT) -> None:
    for relative in PACKAGE_METADATA:
        metadata = _load(repo_root / relative)
        _require(metadata.get("status") == "implemented-experimental-bh02-candidate", f"package candidate status is stale: {relative}")
        _require(metadata.get("public_api_state") == "experimental-not-stable", f"package API state is stale: {relative}")
    for path in repo_root.rglob("blazex.project.json"):
        metadata = _load(path)
        if metadata.get("id") == "experiments/native_renderer_spike":
            continue
        _require("experiments/native_renderer_spike" not in metadata.get("dependencies", []), f"production boundary depends on native experiment: {path}")


def validate_final_closure(
    phase_contract: dict[str, Any],
    reconciliation: dict[str, Any],
    registry: dict[str, Any],
    overlay: dict[str, Any],
    ledger: dict[str, Any],
    conformance: dict[str, Any],
    decision: dict[str, Any],
    completion: dict[str, Any],
    repo_root: Path = REPO_ROOT,
) -> None:
    canonical_rows = {row["id"] for row in registry.get("acceptance_conditions", [])}
    updates = overlay.get("condition_updates", [])
    _require([row.get("id") for row in updates] == OVERLAY_IDS and all(row["id"] in canonical_rows for row in updates), "final acceptance overlay conditions diverge")
    _require(overlay.get("canonical_registry", {}).get("mutation") == "none", "final overlay mutates the canonical registry")
    canonical_path = _resolve(overlay["canonical_registry"]["path"], repo_root)
    _require(_sha256(canonical_path) == overlay["canonical_registry"]["sha256"], "final overlay has a stale canonical registry")
    _require((updates[0].get("status"), updates[0].get("implementation_state"), updates[0].get("verification_state")) == ("passed", "implemented", "passed"), "final BH-02 roadmap condition is not passed")
    _require(len(updates[0].get("evidence_ids", [])) == 4, "final BH-02 roadmap pass lacks final evidence")
    _require((updates[1].get("status"), updates[1].get("verification_state"), updates[1].get("evidence_ids")) == ("implemented", "not-executed", []), "final UI-tree package state is overclaimed")
    for row in updates[2:]:
        _require((row.get("status"), row.get("implementation_state"), row.get("verification_state"), row.get("evidence_ids")) == ("planned", "not-started", "not-executed", []), f"final accessibility state is overclaimed: {row.get('id')}")
    _require(overlay.get("waivers") == [] and overlay.get("bh03_state") == "eligible-not-authorized", "final overlay contains a waiver or authorizes BH-03")
    _require(overlay.get("api_state") == "experimental-not-stable" and overlay.get("support_state") == "unsupported", "final overlay promotes stability or support")

    outputs = ledger.get("required_outputs", [])
    _require([row.get("id") for row in outputs] == OUTPUT_IDS, "final output ledger is incomplete")
    _require(all(str(row.get("state", "")).startswith("accepted") for row in outputs), "final output ledger contains an unaccepted output")
    _require(ledger.get("next_milestone", {}).get("state") == "eligible-not-authorized", "final ledger authorizes BH-03")
    _validate_bindings(conformance.get("acceptance_inputs", []), repo_root)
    _require(conformance.get("representative_slice") == SLICE_IDS, "final conformance slice diverges")
    _require([row.get("result") for row in conformance.get("backend_results", [])] and len(conformance["backend_results"]) == 3, "final backend results are incomplete")
    _require(conformance.get("final_reproduction", {}).get("result") == "passed", "final reproduction did not pass")
    _require(conformance.get("api_state") == "experimental-not-stable" and conformance.get("support_state") == "unsupported", "final conformance promotes stability or support")

    _validate_bindings(decision.get("bindings", []), repo_root)
    checks = decision.get("checks", [])
    _require([row.get("id") for row in checks] == phase_contract.get("acceptance_checks", []), "final checks are incomplete")
    _require(all(str(row.get("result", "")).startswith("passed") for row in checks), "final acceptance check did not pass")
    _require(decision.get("state") == "accepted-with-bounded-conditions", "final decision is not accepted")
    _require(set(decision.get("open_findings", [])) == {row["id"] for row in reconciliation["findings"]}, "final decision hides a finding")
    _require(decision.get("active_blockers") == [] and decision.get("waivers") == [], "final decision has a blocker or waiver")
    downstream = decision.get("downstream", {})
    _require(downstream.get("bh03_eligible") is True and downstream.get("bh03_authorized") is False, "final decision prematurely authorizes BH-03")

    _validate_bindings(completion.get("artifact_hashes", []), repo_root)
    _require(completion.get("state") == "passed", "Phase 8 completion did not pass")
    _require(completion.get("outcome", {}).get("active_blockers") == 0, "Phase 8 completion has blockers")
    _require(completion.get("next_authorized_work") is None and completion.get("next_eligible_milestone") == "BH-03", "Phase 8 completion over-authorizes downstream work")


def validate(repo_root: Path = REPO_ROOT, research_root: Path = RESEARCH_ROOT) -> None:
    phase_contract = _load(research_root / PHASE_CONTRACT.relative_to(RESEARCH_ROOT))
    reconciliation = _load(research_root / RECONCILIATION.relative_to(RESEARCH_ROOT))
    baseline = _load(research_root / CONTRACT_BASELINE.relative_to(RESEARCH_ROOT))
    review = _load(research_root / REVIEW.relative_to(RESEARCH_ROOT))
    overlay = _load(research_root / OVERLAY.relative_to(RESEARCH_ROOT))
    decision = _load(research_root / CANDIDATE_DECISION.relative_to(RESEARCH_ROOT))
    final_overlay = _load(research_root / FINAL_OVERLAY.relative_to(RESEARCH_ROOT))
    final_ledger = _load(research_root / FINAL_LEDGER.relative_to(RESEARCH_ROOT))
    final_conformance = _load(repo_root / FINAL_CONFORMANCE.relative_to(REPO_ROOT))
    final_decision = _load(research_root / FINAL_DECISION.relative_to(RESEARCH_ROOT))
    completion = _load(research_root / COMPLETION.relative_to(RESEARCH_ROOT))
    entry = _load(research_root / ENTRY.relative_to(RESEARCH_ROOT))
    registry = _load(research_root / REGISTRY.relative_to(RESEARCH_ROOT))
    conformance = _load(repo_root / CONFORMANCE.relative_to(REPO_ROOT))
    _require(phase_contract.get("status") == "authorized-acceptance-gate", "Phase 8 acceptance gate is not authorized")
    validate_reconciliation(phase_contract, reconciliation, entry, conformance, repo_root)
    validate_contract_baseline(baseline, repo_root)
    validate_review(review, reconciliation, repo_root)
    validate_overlay(overlay, registry, repo_root)
    validate_candidate_decision(decision, phase_contract, repo_root)
    validate_package_metadata(repo_root)
    validate_final_closure(phase_contract, reconciliation, registry, final_overlay, final_ledger, final_conformance, final_decision, completion, repo_root)


def main() -> int:
    try:
        validate()
    except ValidationError as exc:
        print(f"BH-02 acceptance validation failed: {exc}", file=sys.stderr)
        return 1
    print("BH-02 final acceptance passed: 7 phases, 9 outputs, 9 interactions, 7 review lenses, complete reproduction, exact deferrals, immutable registry overlays, and BH-03 eligibility without authorization verified.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
