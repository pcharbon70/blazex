#!/usr/bin/env python3
"""Validate the source-bound BlazeX BH-00 governance and release contract."""

from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator
from jsonschema.exceptions import SchemaError

import generate_bh00_release as release_generator


ROOT = Path(__file__).resolve().parent
REPO_ROOT = ROOT.parent.parent
ASSET_DIR = ROOT / "assets" / "bh-00-release"
SCHEMA_PATH = ASSET_DIR / "blazex-bh-00-governance.schema.json"
CONTRACT_PATH = ASSET_DIR / "blazex-bh-00-governance-v0.1.0.json"
QUALITY_PATH = ROOT / "assets" / "quality-acceptance" / "blazex-quality-contract-v0.1.0.json"
ACCEPTANCE_PATH = ROOT / "assets" / "quality-acceptance" / "blazex-acceptance-registry-v0.1.0.json"
CATALOG_PATH = ROOT / "assets" / "component-catalog" / "blazex-component-catalog-v0.1.0.json"
CLASSIFICATION_PATH = ROOT / "assets" / "component-catalog" / "blazex-component-classification-v0.1.0.json"
FINAL_ACCEPTANCE_PATH = ASSET_DIR / "blazex-bh-00-final-acceptance-v0-1-0.md"
PHASE_DIR = (
    ROOT
    / "60-planning"
    / "01-browser-host"
    / "bh-00-product-boundary-catalog-and-acceptance-contract"
)
PHASE_EVIDENCE_PATH = PHASE_DIR / "phase-06-implementation-evidence.md"

EXPECTED_AXES = {
    "runtime-substrate",
    "execution-host",
    "renderer-backend",
    "capability-provider",
    "server-adapter",
    "profile-composition",
}
EXPECTED_PACKAGES = {
    "blazex_build", "blazex_charts", "blazex_core", "blazex_data", "blazex_effects",
    "blazex_forms", "blazex_host_browser", "blazex_phoenix", "blazex_plug",
    "blazex_renderer", "blazex_renderer_dom", "blazex_renderer_dom_liveview",
    "blazex_renderer_headless", "blazex_runtime_popcorn", "blazex_surfaces",
    "blazex_test", "blazex_ui", "blazex_ui_tree",
}
EXPECTED_PROFILES = {"PROFILE-BROWSER-PHOENIX", "PROFILE-BROWSER-PLUG", "PROFILE-HEADLESS"}
EXPECTED_RECONCILIATION = {
    "BX-BH00-REC-ACCEPTANCE",
    "BX-BH00-REC-ADAPTER-ISOLATION",
    "BX-BH00-REC-ARCHITECTURE-AXES",
    "BX-BH00-REC-CAPABILITY-ISOLATION",
    "BX-BH00-REC-CATALOG-COVERAGE",
    "BX-BH00-REC-CLASSIFICATION-COVERAGE",
    "BX-BH00-REC-GENERATED-FRESHNESS",
    "BX-BH00-REC-HEADLESS-INDEPENDENCE",
    "BX-BH00-REC-NATIVE-CLAIMS",
    "BX-BH00-REC-NO-DOTNET-COMPATIBILITY",
    "BX-BH00-REC-PACKAGE-OWNERSHIP",
    "BX-BH00-REC-PLUG-INDEPENDENCE",
    "BX-BH00-REC-PROVENANCE",
    "BX-BH00-REC-QUALITY-BUDGETS",
    "BX-BH00-REC-RENDERER-NEUTRALITY",
    "BX-BH00-REC-SERVER-TRUST",
    "BX-BH00-REC-SUPPORT-TRUTH",
}
EXPECTED_ADR_BINDINGS = {f"BX-BH00-SOURCE-ADR-{number:04d}" for number in range(1, 9)}
EXPECTED_REVIEW_DISCIPLINES = {
    "product", "architecture", "implementation", "security", "accessibility",
    "performance-reliability", "packaging", "provenance",
}
EXPECTED_FINDINGS = {
    "BX-BH00-FIND-ACCESSIBILITY-MANUAL-EVIDENCE",
    "BX-BH00-FIND-ARCHITECTURE-NATIVE-PORTABILITY",
    "BX-BH00-FIND-IMPLEMENTATION-RUNTIME-FEASIBILITY",
    "BX-BH00-FIND-PACKAGING-REACHABILITY",
    "BX-BH00-FIND-PERFORMANCE-CALIBRATION",
    "BX-BH00-FIND-PRODUCT-SUPPORT-QUALIFICATION",
    "BX-BH00-FIND-PROVENANCE-RELEASE-MATERIAL",
    "BX-BH00-FIND-SECURITY-EXECUTABLE-CONTROLS",
}
EXPECTED_RISKS = {
    "BX-BH01-RISK-AUTHENTICATED-COMMAND",
    "BX-BH01-RISK-BROWSER-PREREQUISITES",
    "BX-BH01-RISK-DEPENDENCY-ACCESS",
    "BX-BH01-RISK-MOBILE-PERFORMANCE",
    "BX-BH01-RISK-PRIVATE-API-COUPLING",
    "BX-BH01-RISK-RUNTIME-SEMANTICS",
    "BX-BH01-RISK-TOOLCHAIN-REPRODUCIBILITY",
    "BX-BH01-RISK-WASM-ARTIFACT-ACCOUNTING",
}
EXPECTED_BH01_INPUTS = {
    "BX-BH01-INPUT-ARTIFACTS",
    "BX-BH01-INPUT-BEHAVIORS",
    "BX-BH01-INPUT-BROWSERS",
    "BX-BH01-INPUT-MEASUREMENTS",
    "BX-BH01-INPUT-PRIVATE-API",
    "BX-BH01-INPUT-PROFILE-SLICE",
    "BX-BH01-INPUT-STOP-CONDITIONS",
    "BX-BH01-INPUT-TOOLCHAIN",
}
EXPECTED_BH01_PROOFS = {
    "BX-BH01-PROOF-ARTIFACT-ACCOUNTING",
    "BX-BH01-PROOF-AUTHENTICATED-COMMAND",
    "BX-BH01-PROOF-BROWSER-FALLBACK",
    "BX-BH01-PROOF-BUILD-REPRODUCIBILITY",
    "BX-BH01-PROOF-DOM-UPDATE",
    "BX-BH01-PROOF-FORM-EVENT",
    "BX-BH01-PROOF-MOBILE-MEASUREMENT",
    "BX-BH01-PROOF-NESTED-STATE",
    "BX-BH01-PROOF-RUNTIME-BOOT",
    "BX-BH01-PROOF-TIMER-MESSAGE",
}
EXPECTED_COMPLETE_EVIDENCE = {
    "BX-BH00-EVIDENCE-FINAL-ACCEPTANCE-6-4",
    "BX-BH00-EVIDENCE-RECONCILIATION-6-1",
    "BX-BH00-EVIDENCE-REVIEW-ACCESSIBILITY",
    "BX-BH00-EVIDENCE-REVIEW-ARCHITECTURE",
    "BX-BH00-EVIDENCE-REVIEW-IMPLEMENTATION",
    "BX-BH00-EVIDENCE-REVIEW-PACKAGING",
    "BX-BH00-EVIDENCE-REVIEW-PERFORMANCE-RELIABILITY",
    "BX-BH00-EVIDENCE-REVIEW-PRODUCT",
    "BX-BH00-EVIDENCE-REVIEW-PROVENANCE",
    "BX-BH00-EVIDENCE-REVIEW-SECURITY",
    "BX-BH00-EVIDENCE-VERSIONED-RELEASE-6-3",
}


class GovernanceValidationError(ValueError):
    """Raised when the BH-00 governance contract is incoherent."""


def load_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise GovernanceValidationError(f"cannot read valid JSON from {path}: {error}") from error
    if not isinstance(value, dict):
        raise GovernanceValidationError(f"{path} must contain a JSON object")
    return value


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _ids(records: list[dict[str, Any]], label: str) -> set[str]:
    ids = [record.get("id") for record in records]
    if ids != sorted(ids):
        raise GovernanceValidationError(f"{label} IDs must be sorted")
    if len(ids) != len(set(ids)):
        raise GovernanceValidationError(f"{label} IDs must be unique")
    return set(ids)


def validate_schema(document: dict[str, Any], schema: dict[str, Any]) -> None:
    try:
        Draft202012Validator.check_schema(schema)
    except SchemaError as error:
        raise GovernanceValidationError(f"governance schema is invalid: {error.message}") from error
    if schema.get("$id") != "https://blazex.dev/schemas/bh-00-governance/1.0.0":
        raise GovernanceValidationError("governance schema ID must remain version 1.0.0")
    errors = sorted(
        Draft202012Validator(schema).iter_errors(document),
        key=lambda error: [str(part) for part in error.absolute_path],
    )
    if errors:
        error = errors[0]
        path = ".".join(str(part) for part in error.absolute_path) or "<root>"
        raise GovernanceValidationError(f"governance schema violation at {path}: {error.message}")


def validate_sources(document: dict[str, Any]) -> set[str]:
    source_ids = _ids(document["source_bindings"], "source binding")
    if not EXPECTED_ADR_BINDINGS <= source_ids:
        raise GovernanceValidationError("all eight accepted ADRs must be source-bound")
    required_roles = {"repository-boundary", "vocabulary", "architecture-decision", "support-envelope", "catalog", "classification", "quality", "acceptance", "roadmap"}
    if {record["role"] for record in document["source_bindings"]} != required_roles:
        raise GovernanceValidationError("governance source roles are incomplete")
    for record in document["source_bindings"]:
        path = (ROOT / record["path"]).resolve()
        if not path.is_file():
            raise GovernanceValidationError(f"source binding path is missing: {record['id']}")
        if sha256(path) != record["sha256"]:
            raise GovernanceValidationError(f"source binding is stale: {record['id']}")
    return source_ids


def validate_reconciliation(document: dict[str, Any], source_ids: set[str]) -> None:
    if _ids(document["architecture_axes"], "architecture axis") != EXPECTED_AXES:
        raise GovernanceValidationError("the six independent architecture axes must remain complete")
    package_ids = _ids(document["package_boundaries"], "package boundary")
    if package_ids != EXPECTED_PACKAGES:
        raise GovernanceValidationError("all eighteen package boundaries must remain complete")
    disk_packages = {path.name for path in (REPO_ROOT / "packages").iterdir() if path.is_dir()}
    if disk_packages != EXPECTED_PACKAGES:
        raise GovernanceValidationError("repository package directories differ from governance ownership")
    activated_packages = {
        package
        for package in disk_packages
        if any((REPO_ROOT / "packages" / package / name).exists() for name in ("mix.exs", "package.json", "Cargo.toml"))
    }
    if activated_packages:
        authorization_path = ROOT / "assets/bh-01-baseline/blazex-bh-01-authorization-v0.1.0.json"
        activation_path = ROOT / "assets/bh-01-baseline/blazex-bh-01-repository-activation-v0.1.0.json"
        if not authorization_path.is_file() or not activation_path.is_file():
            raise GovernanceValidationError("repository packages were activated without BH-01 authorization records")
        authorization = load_json(authorization_path)
        activation = load_json(activation_path)
        if authorization.get("status") != "approved-phase-1-only":
            raise GovernanceValidationError("repository packages were activated without approved BH-01 Phase 1 scope")
        authorized_packages = {
            Path(record["path"]).name
            for record in activation.get("boundaries", [])
            if record.get("kind") == "elixir-package"
        }
        if activated_packages != authorized_packages:
            raise GovernanceValidationError(
                f"repository package activation differs from approved BH-01 slice: {sorted(activated_packages ^ authorized_packages)}"
            )
        for package in activated_packages:
            package_dir = REPO_ROOT / "packages" / package
            if not (package_dir / "mix.exs").is_file() or not (package_dir / "blazex.project.json").is_file():
                raise GovernanceValidationError(f"authorized BH-01 package activation is incomplete: {package}")
            if any((package_dir / name).exists() for name in ("mix.lock", "deps", "package-lock.json", "node_modules", "Cargo.toml")):
                raise GovernanceValidationError(f"BH-01 Phase 1 package acquired or locked a dependency: {package}")
    profiles = document["profile_boundaries"]
    if _ids(profiles, "profile boundary") != EXPECTED_PROFILES:
        raise GovernanceValidationError("all three profile boundaries must remain complete")
    plug = next(record for record in profiles if record["id"] == "PROFILE-BROWSER-PLUG")
    required_exclusions = {"blazex_phoenix", "blazex_renderer_dom_liveview", "phoenix", "liveview", "local-live-view"}
    if not required_exclusions <= set(plug["forbidden_dependencies"]):
        raise GovernanceValidationError("Plug profile transitive exclusions are incomplete")
    reconciliation_ids = _ids(document["reconciliation_checks"], "reconciliation check")
    if reconciliation_ids != EXPECTED_RECONCILIATION:
        raise GovernanceValidationError("reconciliation check identities are incomplete")
    for record in document["reconciliation_checks"]:
        if not set(record["source_refs"]) <= source_ids:
            raise GovernanceValidationError(f"reconciliation check {record['id']} references an unknown source")
        if record["outcome"] != "passed" or record["conflicts"] or record["resolution"] != "no-authoritative-conflict-found":
            raise GovernanceValidationError(f"reconciliation check {record['id']} has an unresolved conflict")

    catalog = load_json(CATALOG_PATH)
    classification = load_json(CLASSIFICATION_PATH)
    quality = load_json(QUALITY_PATH)
    acceptance = load_json(ACCEPTANCE_PATH)
    if len(catalog["families"]) != 83 or len(catalog["exceptions"]) != 12:
        raise GovernanceValidationError("catalog reconciliation counts changed")
    if len(classification["families"]) != 83 or len(classification["exceptions"]) != 12:
        raise GovernanceValidationError("classification reconciliation counts changed")
    if len(quality["budgets"]) != 31 or len(quality["failure_scenarios"]) != 8 or len(quality["release_blockers"]) != 7:
        raise GovernanceValidationError("quality reconciliation counts changed")
    if sum(len(gate["requirements"]) for gate in quality["cross_cutting_gates"]) != 21:
        raise GovernanceValidationError("cross-cutting gate requirement count changed")
    if len(acceptance["requirements"]) != 290 or len(acceptance["acceptance_conditions"]) != 290:
        raise GovernanceValidationError("acceptance reconciliation counts changed")
    if acceptance["summary"]["executed_evidence"] != 0:
        raise GovernanceValidationError("BH-00 cannot claim executed product evidence")


def validate_stage(document: dict[str, Any]) -> None:
    stage = document["stage"]
    boundary = document["evidence_boundary"]
    if document["exceptions"]:
        raise GovernanceValidationError("BH-00 governance has no accepted exception")
    if any(boundary[key] != value for key, value in {
        "runtime_implementation": "not-executed",
        "browser_support": "unsupported-unproven",
        "component_implementation": "not-executed",
        "measurements": "not-executed",
        "release_support": "not-authorized",
    }.items()):
        raise GovernanceValidationError("governance evidence boundary overstates product delivery")
    if stage == "section-6.1":
        if document["status"] != "reconciled-pending-review" or boundary["contract_evidence"] != "reconciled":
            raise GovernanceValidationError("Section 6.1 stage/status evidence combination is invalid")
        if document["reviews"] or document["findings"] or document["risks"] or document["release"] is not None or document["bh01_entry"] is not None:
            raise GovernanceValidationError("Section 6.1 cannot pre-empt review, release, risk, or BH-01 decisions")
    elif stage in {"section-6.2", "section-6.3", "complete"}:
        validate_review(document)
        if stage == "section-6.2":
            if document["status"] != "reviewed-pending-release" or boundary["contract_evidence"] != "reviewed":
                raise GovernanceValidationError("Section 6.2 stage/status evidence combination is invalid")
            if document["release"] is not None or document["bh01_entry"] is not None:
                raise GovernanceValidationError("Section 6.2 cannot pre-empt release or BH-01 entry decisions")
        if stage in {"section-6.3", "complete"}:
            validate_release_and_entry(document)
            if document["status"] != "accepted-conditionally-ready" or boundary["contract_evidence"] != "accepted":
                raise GovernanceValidationError("release stage/status evidence combination is invalid")
            if stage == "complete":
                validate_completion(document)


def validate_completion(document: dict[str, Any]) -> None:
    """Validate the final BH-00 acceptance and planning closure records."""
    evidence_ids = set(document["evidence_boundary"]["evidence_ids"])
    if evidence_ids != EXPECTED_COMPLETE_EVIDENCE:
        raise GovernanceValidationError("complete BH-00 evidence identities are incomplete")
    for path in (FINAL_ACCEPTANCE_PATH, PHASE_EVIDENCE_PATH):
        if not path.is_file():
            raise GovernanceValidationError(f"final BH-00 evidence artifact is missing: {path.name}")
    phase_plans = [
        path for path in sorted(PHASE_DIR.glob("phase-0[1-6]-*.md"))
        if not path.name.endswith("-implementation-evidence.md")
    ]
    if len(phase_plans) != 6:
        raise GovernanceValidationError("BH-00 must retain all six phase plans")
    if any("- [ ]" in path.read_text(encoding="utf-8") for path in phase_plans):
        raise GovernanceValidationError("a BH-00 phase plan still contains unchecked work")
    phase_evidence = [PHASE_DIR / f"phase-{number:02d}-implementation-evidence.md" for number in range(1, 7)]
    if not all(path.is_file() for path in phase_evidence):
        raise GovernanceValidationError("BH-00 phase implementation evidence is incomplete")
    acceptance = FINAL_ACCEPTANCE_PATH.read_text(encoding="utf-8")
    required_truth = (
        "accepted-conditionally-ready",
        "unsupported-unproven",
        "not-executed",
        "not-authorized",
        "zero accepted exceptions",
    )
    if any(value not in acceptance for value in required_truth):
        raise GovernanceValidationError("final BH-00 acceptance omits a required evidence boundary")


def validate_review(document: dict[str, Any]) -> None:
    """Validate multidisciplinary reviews, findings, and BH-01 risk transfer."""
    reviews = document["reviews"]
    findings = document["findings"]
    risks = document["risks"]
    _ids(reviews, "review")
    finding_ids = _ids(findings, "finding")
    risk_ids = _ids(risks, "risk")
    if {review["discipline"] for review in reviews} != EXPECTED_REVIEW_DISCIPLINES or len(reviews) != 8:
        raise GovernanceValidationError("all eight independent discipline reviews are required")
    if finding_ids != EXPECTED_FINDINGS:
        raise GovernanceValidationError("multidisciplinary finding coverage is incomplete")
    if risk_ids != EXPECTED_RISKS:
        raise GovernanceValidationError("BH-01 feasibility risk register is incomplete")
    source_ids = {record["id"] for record in document["source_bindings"]}
    evidence_ids = set(document["evidence_boundary"]["evidence_ids"])
    referenced_findings: list[str] = []
    for review in reviews:
        if review["outcome"] == "blocking":
            raise GovernanceValidationError(f"review {review['id']} remains blocking")
        if review["evidence_id"] not in evidence_ids:
            raise GovernanceValidationError(f"review {review['id']} lacks governance evidence identity")
        if not set(review["finding_ids"]) <= finding_ids:
            raise GovernanceValidationError(f"review {review['id']} references an unknown finding")
        referenced_findings.extend(review["finding_ids"])
    if sorted(referenced_findings) != sorted(finding_ids):
        raise GovernanceValidationError("every finding must be owned by exactly one discipline review")
    for finding in findings:
        if finding["severity"] == "blocker" or finding["status"] == "blocking":
            raise GovernanceValidationError(f"BH-00 review finding remains blocking: {finding['id']}")
        if not set(finding["affected_source_refs"]) <= source_ids:
            raise GovernanceValidationError(f"finding {finding['id']} references an unknown source")
        if not set(finding["evidence_ids"]) <= evidence_ids:
            raise GovernanceValidationError(f"finding {finding['id']} lacks review evidence")
    if any(risk["first_milestone"] != "BH-01" or risk["status"] != "open-feasibility-risk" for risk in risks):
        raise GovernanceValidationError("all unresolved feasibility risks must transfer visibly to BH-01")


def validate_release_and_entry(document: dict[str, Any]) -> None:
    """Validate the versioned baseline and conditional BH-01 handoff."""
    release = document["release"]
    entry = document["bh01_entry"]
    if release is None or entry is None:
        raise GovernanceValidationError("release stage requires a release identity and BH-01 entry decision")
    manifest_hash = release_generator.source_manifest_sha256(document)
    if release["source_manifest_sha256"] != manifest_hash:
        raise GovernanceValidationError("BH-00 release source manifest hash is stale")
    if release["published_index"] != "assets/bh-00-release/blazex-bh-00-release-index-v0-1-0.md":
        raise GovernanceValidationError("BH-00 release index path is not canonical")
    review_evidence = {review["evidence_id"] for review in document["reviews"]}
    if set(release["review_evidence_ids"]) != review_evidence:
        raise GovernanceValidationError("release review approvals do not cover all disciplines")
    release_text, entry_text = release_generator.output_texts()
    if not release_generator.RELEASE_INDEX_PATH.exists() or release_generator.RELEASE_INDEX_PATH.read_text(encoding="utf-8") != release_text:
        raise GovernanceValidationError("BH-00 release index is stale")
    if not release_generator.BH01_MANIFEST_PATH.exists() or release_generator.BH01_MANIFEST_PATH.read_text(encoding="utf-8") != entry_text:
        raise GovernanceValidationError("BH-01 entry manifest is stale")

    if entry["decision"] != "conditionally-ready":
        raise GovernanceValidationError("BH-01 entry must remain conditional before its phase plan is approved")
    if not any(
        ("phase plan" in condition.lower() or "implementation plan" in condition.lower())
        and "approved" in condition.lower()
        for condition in entry["conditions"]
    ):
        raise GovernanceValidationError("BH-01 entry lacks the separate approved-plan condition")
    if _ids(entry["input_manifest"], "BH-01 input") != EXPECTED_BH01_INPUTS:
        raise GovernanceValidationError("BH-01 input manifest is incomplete")
    if _ids(entry["proof_obligations"], "BH-01 proof") != EXPECTED_BH01_PROOFS:
        raise GovernanceValidationError("BH-01 proof obligations are incomplete")
    source_ids = {record["id"] for record in document["source_bindings"]}
    for item in entry["input_manifest"]:
        if not set(item["source_refs"]) <= source_ids or item["state"] != "required-unproven":
            raise GovernanceValidationError(f"BH-01 input {item['id']} lacks governed unproven sources")

    quality = load_json(QUALITY_PATH)
    acceptance = load_json(ACCEPTANCE_PATH)
    known_budgets = {budget["id"] for budget in quality["budgets"]}
    known_acceptance = {condition["id"] for condition in acceptance["acceptance_conditions"]}
    support_claims = {
        requirement["source_id"] for requirement in acceptance["requirements"]
        if requirement["source_kind"] == "browser-envelope"
    }
    for proof in entry["proof_obligations"]:
        if proof["support_claim_ref"] not in support_claims:
            raise GovernanceValidationError(f"proof {proof['id']} has no support-envelope claim")
        if not set(proof["budget_refs"]) <= known_budgets:
            raise GovernanceValidationError(f"proof {proof['id']} references an unknown budget")
        if not set(proof["acceptance_refs"]) <= known_acceptance:
            raise GovernanceValidationError(f"proof {proof['id']} references an unknown acceptance condition")
        if proof["decision_ref"] not in {f"ADR-{number:04d}" for number in range(1, 9)}:
            raise GovernanceValidationError(f"proof {proof['id']} references an unknown architecture decision")
        if not proof["stop_on_failure"]:
            raise GovernanceValidationError(f"proof {proof['id']} cannot continue after failure")
    prohibited = " ".join(entry["prohibited_actions"]).lower()
    if "do not initialize" not in prohibited or "do not claim" not in prohibited:
        raise GovernanceValidationError("BH-01 prohibited action boundary is incomplete")


def validate_contract(document: dict[str, Any], schema: dict[str, Any]) -> dict[str, int]:
    validate_schema(document, schema)
    source_ids = validate_sources(document)
    validate_reconciliation(document, source_ids)
    validate_stage(document)
    return {
        "sources": len(source_ids),
        "axes": len(document["architecture_axes"]),
        "packages": len(document["package_boundaries"]),
        "profiles": len(document["profile_boundaries"]),
        "reconciliation_checks": len(document["reconciliation_checks"]),
        "reviews": len(document["reviews"]),
        "findings": len(document["findings"]),
        "risks": len(document["risks"]),
    }


def main() -> int:
    try:
        document = load_json(CONTRACT_PATH)
        counts = validate_contract(document, load_json(SCHEMA_PATH))
    except GovernanceValidationError as error:
        print(f"BH-00 governance validation failed: {error}", file=sys.stderr)
        return 1
    print(
        "BH-00 governance validation passed: "
        f"stage {document['stage']}; status {document['status']}; "
        + "; ".join(f"{value} {key.replace('_', ' ')}" for key, value in counts.items())
        + "; product evidence remains unexecuted."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
