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


ROOT = Path(__file__).resolve().parent
REPO_ROOT = ROOT.parent.parent
ASSET_DIR = ROOT / "assets" / "bh-00-release"
SCHEMA_PATH = ASSET_DIR / "blazex-bh-00-governance.schema.json"
CONTRACT_PATH = ASSET_DIR / "blazex-bh-00-governance-v0.1.0.json"
QUALITY_PATH = ROOT / "assets" / "quality-acceptance" / "blazex-quality-contract-v0.1.0.json"
ACCEPTANCE_PATH = ROOT / "assets" / "quality-acceptance" / "blazex-acceptance-registry-v0.1.0.json"
CATALOG_PATH = ROOT / "assets" / "component-catalog" / "blazex-component-catalog-v0.1.0.json"
CLASSIFICATION_PATH = ROOT / "assets" / "component-catalog" / "blazex-component-classification-v0.1.0.json"

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
    for package in disk_packages:
        package_dir = REPO_ROOT / "packages" / package
        for activation_file in ("mix.exs", "package.json", "Cargo.toml"):
            if (package_dir / activation_file).exists():
                raise GovernanceValidationError(f"BH-00 cannot activate package {package}: found {activation_file}")
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
    """Validate Section 6.3+ records; populated in the release section."""
    if document["release"] is None or document["bh01_entry"] is None:
        raise GovernanceValidationError("release stage requires a release identity and BH-01 entry decision")


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
