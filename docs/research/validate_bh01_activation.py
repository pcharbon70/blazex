#!/usr/bin/env python3
"""Validate BH-01 authorization, inherited truth, governance, and activation."""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker
from jsonschema.exceptions import SchemaError, ValidationError as JsonSchemaValidationError

import planning_policy


RESEARCH_ROOT = Path(__file__).resolve().parent
REPO_ROOT = RESEARCH_ROOT.parent.parent
BH00_GOVERNANCE = RESEARCH_ROOT / "assets/bh-00-release/blazex-bh-00-governance-v0.1.0.json"
QUALITY_CONTRACT = RESEARCH_ROOT / "assets/quality-acceptance/blazex-quality-contract-v0.1.0.json"
ACCEPTANCE_REGISTRY = RESEARCH_ROOT / "assets/quality-acceptance/blazex-acceptance-registry-v0.1.0.json"
AUTHORIZATION = RESEARCH_ROOT / "assets/bh-01-baseline/blazex-bh-01-authorization-v0.1.0.json"
LEDGER = RESEARCH_ROOT / "assets/bh-01-baseline/blazex-bh-01-milestone-ledger-v0.1.0.json"
EVIDENCE_SCHEMA = RESEARCH_ROOT / "assets/bh-01-baseline/blazex-bh-01-evidence-record.schema.json"
GOVERNANCE_SCHEMA = RESEARCH_ROOT / "assets/bh-01-baseline/blazex-bh-01-governance.schema.json"
EVIDENCE_GOVERNANCE = RESEARCH_ROOT / "assets/bh-01-baseline/blazex-bh-01-evidence-governance-v0.1.0.json"
ACTIVATION_SCHEMA = RESEARCH_ROOT / "assets/bh-01-baseline/blazex-bh-01-repository-activation.schema.json"
REPOSITORY_ACTIVATION = RESEARCH_ROOT / "assets/bh-01-baseline/blazex-bh-01-repository-activation-v0.1.0.json"
PHASE_1_COMPLETION = RESEARCH_ROOT / "assets/bh-01-baseline/blazex-bh-01-phase-01-completion-v0.1.0.json"
PHASE_1_PLAN = RESEARCH_ROOT / "60-planning/01-browser-host/bh-01-reproducible-browser-feasibility-baseline/phase-01-authorization-evidence-and-repository-activation.md"
DEVELOPMENT_POLICY = planning_policy.DEVELOPMENT_POLICY_PATH


class ValidationError(Exception):
    """Raised when BH-01 activation must fail closed."""


def _load_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ValidationError(f"cannot load {path.relative_to(REPO_ROOT)}: {exc}") from exc
    if not isinstance(value, dict):
        raise ValidationError(f"{path.relative_to(REPO_ROOT)} must contain a JSON object")
    return value


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _git(*args: str) -> str:
    result = subprocess.run(
        ["git", *args],
        cwd=REPO_ROOT,
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode:
        raise ValidationError(f"git {' '.join(args)} failed: {result.stderr.strip()}")
    return result.stdout.strip()


def _git_blob_sha256(revision: str, path: str) -> str:
    result = subprocess.run(
        ["git", "show", f"{revision}:{path}"],
        cwd=REPO_ROOT,
        check=False,
        capture_output=True,
    )
    if result.returncode:
        raise ValidationError(f"approved plan blob is unavailable at {revision}:{path}")
    return hashlib.sha256(result.stdout).hexdigest()


def _require(condition: bool, message: str) -> None:
    if not condition:
        raise ValidationError(message)


def _record_ids(records: list[dict[str, Any]]) -> set[str]:
    return {str(record.get("id")) for record in records}


def _validate_authorization(auth: dict[str, Any], governance: dict[str, Any]) -> None:
    _require(auth.get("authorization_id") == "BX-BH01-AUTHORIZATION-0.1", "authorization ID is missing or stale")
    _require(auth.get("status") == "approved-phase-1-only", "Phase 1 lacks explicit approval")
    approver = auth.get("approved_by", {})
    _require(approver.get("identity") and approver.get("role") == "repository-owner", "approval identity is incomplete")

    plan = auth.get("approved_plan", {})
    plan_repo_path = str(plan.get("path", ""))
    plan_path = REPO_ROOT / plan_repo_path
    _require(plan_path.is_file(), "approved plan is missing")
    _git("cat-file", "-e", f"{plan.get('revision')}^{{commit}}")
    _require(
        _git_blob_sha256(str(plan.get("revision", "")), plan_repo_path) == plan.get("sha256"),
        "approved plan revision/hash is stale",
    )

    activation = auth.get("activation", {})
    base = str(activation.get("base_revision", ""))
    remote_base = str(activation.get("base_remote_revision", ""))
    _require(len(base) == 40 and base == remote_base, "activation main/remote revision is missing or stale")
    _git("cat-file", "-e", f"{base}^{{commit}}")
    ancestry = subprocess.run(
        ["git", "merge-base", "--is-ancestor", base, "HEAD"],
        cwd=REPO_ROOT,
        check=False,
    )
    _require(ancestry.returncode == 0, "current work does not descend from the approved synchronized main revision")
    _require(activation.get("main_synchronized_before_branch") is True, "main synchronization was not recorded")
    _require(str(activation.get("working_branch", "")).startswith("codex/"), "dedicated codex branch is not recorded")

    inherited = auth.get("inherited_baseline", {})
    release = governance.get("release", {})
    entry = governance.get("bh01_entry", {})
    _require(inherited.get("release_id") == release.get("release_id") == "BX-BH00-BASELINE-0.1.0", "BH-00 baseline identity changed")
    _require(inherited.get("entry_decision_id") == entry.get("decision_id") == "BX-BH01-ENTRY-0.1", "BH-01 entry decision changed")
    _require(inherited.get("source_manifest_sha256") == release.get("source_manifest_sha256"), "BH-00 source manifest changed")
    _require(inherited.get("governance_status") == governance.get("status"), "BH-00 governance status changed")
    _require(inherited.get("accepted_exceptions") == len(governance.get("exceptions", [])) == 0, "accepted exception count is not zero")

    for path_key, hash_key in (
        ("governance_path", "governance_sha256"),
        ("release_index_path", "release_index_sha256"),
        ("entry_manifest_path", "entry_manifest_sha256"),
    ):
        bound_path = REPO_ROOT / str(inherited.get(path_key, ""))
        _require(bound_path.is_file(), f"bound inherited artifact is missing: {path_key}")
        _require(_sha256(bound_path) == inherited.get(hash_key), f"bound inherited artifact is stale: {path_key}")

    _require(len(auth.get("binding_conditions", [])) >= 5, "authorization conditions are incomplete")
    non_authorizations = " ".join(auth.get("not_authorized", [])).lower()
    for term in ("phase 2", "bh-02", "stable", "support"):
        _require(term in non_authorizations, f"authorization fails to exclude {term}")


def _validate_bound_sources(
    governance: dict[str, Any],
    development_policy_text: str | None = None,
) -> None:
    _require(governance.get("stage") == "complete", "BH-00 governance is incomplete")
    _require(governance.get("release", {}).get("status") == "accepted-product-contract", "BH-00 release is not accepted")
    _require(governance.get("bh01_entry", {}).get("decision") == "conditionally-ready", "BH-01 entry is not conditionally ready")
    policy_text = development_policy_text
    if policy_text is None:
        _require(DEVELOPMENT_POLICY.is_file(), "development-environment planning amendment is missing")
        policy_text = DEVELOPMENT_POLICY.read_text(encoding="utf-8")
    for binding in governance.get("source_bindings", []):
        path = RESEARCH_ROOT / str(binding.get("path", ""))
        _require(path.is_file(), f"bound BH-00 source is missing: {binding.get('id')}")
        actual_sha256 = _sha256(path)
        expected_sha256 = str(binding.get("sha256", ""))
        if actual_sha256 == expected_sha256:
            continue
        if binding.get("id") == "BX-BH00-SOURCE-ROADMAP":
            amendment_error = planning_policy.roadmap_amendment_error(
                expected_sha256,
                actual_sha256,
                policy_text,
            )
            _require(amendment_error is None, amendment_error or "roadmap amendment is invalid")
            continue
        raise ValidationError(f"bound BH-00 source is stale: {binding.get('id')}")


def _validate_ledger(
    ledger: dict[str, Any],
    governance: dict[str, Any],
    quality: dict[str, Any],
    acceptance: dict[str, Any],
) -> None:
    _require(ledger.get("authorization_ref") == "BX-BH01-AUTHORIZATION-0.1", "ledger authorization link is missing")
    _require(ledger.get("status") == "activated-phase-1-unproven", "ledger state overclaims Phase 1 evidence")
    entry = governance.get("bh01_entry", {})

    expected_inputs = _record_ids(entry.get("input_manifest", []))
    expected_proofs = _record_ids(entry.get("proof_obligations", []))
    expected_risks = _record_ids(governance.get("risks", []))
    _require(_record_ids(ledger.get("inputs", [])) == expected_inputs and len(expected_inputs) == 8, "ledger must import exactly eight BH-01 inputs")
    _require(_record_ids(ledger.get("proof_obligations", [])) == expected_proofs and len(expected_proofs) == 10, "ledger must import exactly ten proof obligations")
    _require(_record_ids(ledger.get("risks", [])) == expected_risks and len(expected_risks) == 8, "ledger must import exactly eight risks")
    _require(len(ledger.get("stop_conditions", [])) == len(entry.get("stop_conditions", [])) == 5, "ledger must import exactly five stop conditions")
    _require([item.get("statement") for item in ledger["stop_conditions"]] == entry["stop_conditions"], "ledger stop conditions diverge from BH-00")
    _require(ledger.get("prohibited_actions") == entry.get("prohibited_actions"), "ledger prohibited actions diverge from BH-00")

    input_source = {record["id"]: record for record in entry["input_manifest"]}
    for record in ledger["inputs"]:
        source = input_source[record["id"]]
        _require(record.get("owner") == source.get("owner") and record.get("state") == source.get("state"), f"input ownership/state changed: {record['id']}")

    proof_source = {record["id"]: record for record in entry["proof_obligations"]}
    budget_ids = _record_ids(quality.get("budgets", []))
    acceptance_ids = _record_ids(acceptance.get("acceptance_conditions", []))
    for record in ledger["proof_obligations"]:
        source = proof_source[record["id"]]
        _require(record.get("owner") == source.get("repository_owner"), f"proof owner changed: {record['id']}")
        _require(record.get("budget_refs") == source.get("budget_refs"), f"proof budget links changed: {record['id']}")
        _require(record.get("acceptance_refs") == source.get("acceptance_refs"), f"proof acceptance links changed: {record['id']}")
        _require(set(record["budget_refs"]) <= budget_ids, f"proof has unknown budget: {record['id']}")
        _require(set(record["acceptance_refs"]) <= acceptance_ids, f"proof has unknown acceptance condition: {record['id']}")
        _require(record.get("state") == "planned-unexecuted" and record.get("stop_on_failure") is True, f"proof overclaims evidence: {record['id']}")

    assignments = {record.get("role"): record for record in ledger.get("owner_assignments", [])}
    referenced_owners = {
        *(record["owner"] for record in ledger["inputs"]),
        *(record["owner"] for record in ledger["proof_obligations"]),
        *(record["owner"] for record in ledger["risks"]),
        *(record["owner"] for record in ledger["stop_conditions"]),
        *entry.get("owner_roles", []),
    }
    _require(referenced_owners <= set(assignments), f"unowned BH-01 records: {sorted(referenced_owners - set(assignments))}")
    _require(all(record.get("identity") for record in assignments.values()), "owner assignment identity is incomplete")

    boundary = ledger.get("evidence_boundary", {})
    _require(boundary.get("runtime_state") == "unexecuted", "runtime evidence was claimed during activation")
    _require(boundary.get("browser_state") == "untested", "browser evidence was claimed during activation")
    _require(boundary.get("support_state") == "unsupported", "support was claimed during activation")
    _require(boundary.get("budget_state") == "proposed-unmeasured", "a budget was claimed during activation")


def _validate_evidence_governance(
    governance: dict[str, Any],
    ledger: dict[str, Any],
    evidence_governance_document: dict[str, Any] | None = None,
) -> None:
    evidence_schema = _load_json(EVIDENCE_SCHEMA)
    governance_schema = _load_json(GOVERNANCE_SCHEMA)
    evidence_governance = evidence_governance_document or _load_json(EVIDENCE_GOVERNANCE)
    try:
        Draft202012Validator.check_schema(evidence_schema)
        Draft202012Validator.check_schema(governance_schema)
        Draft202012Validator(
            governance_schema,
            format_checker=FormatChecker(),
        ).validate(evidence_governance)
    except (SchemaError, JsonSchemaValidationError) as exc:
        raise ValidationError(f"BH-01 evidence governance schema failure: {exc.message}") from exc

    expected_types = {
        "environment-fingerprint",
        "command",
        "log",
        "artifact",
        "scenario",
        "trace",
        "measurement",
        "review",
        "finding",
        "risk",
        "exception",
        "decision",
    }
    expected_states = {
        "planned",
        "observed",
        "passed",
        "failed",
        "blocked",
        "conditional",
        "unsupported",
        "untested",
        "superseded",
        "invalidated",
    }
    configured_types = {record["type"] for record in evidence_governance["evidence_types"]}
    _require(configured_types == expected_types, "evidence governance must cover exactly twelve canonical record types")
    _require(set(evidence_governance["state_vocabulary"]) == expected_states, "evidence states are incomplete or collapsed")
    schema_types = set(evidence_schema["properties"]["record_type"]["enum"])
    schema_states = set(evidence_schema["properties"]["state"]["enum"])
    _require(schema_types == expected_types and schema_states == expected_states, "evidence schema and governance vocabulary diverge")

    prefix_by_type = {record["type"]: record["id_prefix"] for record in evidence_governance["evidence_types"]}
    sample_sha = "0" * 64
    sample_revision = "0" * 40
    validator = Draft202012Validator(evidence_schema, format_checker=FormatChecker())
    for record_type in sorted(expected_types):
        sample = {
            "schema_version": "1.0.0",
            "record_id": f"{prefix_by_type[record_type]}SCHEMA-PROBE",
            "record_type": record_type,
            "state": "planned",
            "title": f"Schema probe for {record_type}",
            "owner_role": "bh01-owner",
            "recorded_at": "2026-09-03T12:00:00Z",
            "observed_at": None,
            "source_revision": sample_revision,
            "environment_refs": [],
            "tool_identities": [{"name": "schema-validator", "version": "1.0.0", "source": "repository", "sha256": sample_sha}],
            "requirement_refs": ["BX-BH01-PHASE-1"],
            "reciprocal_links": ["phase-01-authorization-evidence-and-repository-activation.md"],
            "command_refs": [],
            "input_hashes": [],
            "output_hashes": [],
            "raw_evidence_refs": [],
            "normalization": [],
            "limitations": ["Schema-only probe; not product evidence."],
            "supersedes": [],
            "invalidates": [],
            "retention": {"class": "phase", "minimum_days": 30, "immutable_raw_evidence": True},
            "outcome": {"summary": "Schema-only probe", "expected": "Schema accepts planned record", "observed": None},
            "review": {"required": False, "reviewer_role": None, "reviewed_at": None, "disposition": "not-required"},
        }
        errors = sorted(validator.iter_errors(sample), key=lambda error: list(error.path))
        _require(not errors, f"evidence schema rejects {record_type}: {errors[0].message if errors else ''}")

    expected_domains = {
        "dependency-access",
        "reproducibility",
        "runtime-semantics",
        "artifacts",
        "private-apis",
        "browser-prerequisites",
        "authenticated-commands",
        "mobile-viability",
    }
    assignments = evidence_governance["authority_assignments"]
    _require({record["domain"] for record in assignments} == expected_domains, "finding/stop authority domains are incomplete")
    ledger_owners = {record["role"] for record in ledger["owner_assignments"]}
    for assignment in assignments:
        referenced = {assignment["owner"], *assignment["escalates_to"], *assignment["stop_authority"]}
        _require(referenced <= ledger_owners, f"governance references unassigned owner in {assignment['domain']}")

    severities = {record["severity"]: record for record in evidence_governance["finding_severities"]}
    _require(severities.get("critical", {}).get("phase_effect") == "stop", "critical findings must stop the phase")
    _require(severities.get("high", {}).get("phase_effect") == "conditional-stop", "high findings require conditional stop review")
    _require(len(evidence_governance["blocker_rules"]) >= 4, "blocker rules are incomplete")

    expected_changes = {
        "runtime substrate",
        "server stack",
        "activation boundary",
        "proof method",
        "browser matrix",
        "quality threshold",
        "stop condition",
    }
    triggers = evidence_governance["reapproval_triggers"]
    _require({record["change"] for record in triggers} == expected_changes, "explicit reapproval triggers are incomplete")
    _require(all(record["invalidation_required"] for record in triggers), "reapproval must invalidate dependent evidence")
    prohibited = " ".join(evidence_governance["prohibited_governance_actions"]).lower()
    for term in ("threshold", "scenario", "planned", "delete", "downstream"):
        _require(term in prohibited, f"governance prohibition is missing: {term}")


def _source_files(path: Path) -> list[Path]:
    result: list[Path] = []
    for root_name in ("lib", "src", "config"):
        root = path / root_name
        if root.is_dir():
            result.extend(file for file in root.rglob("*") if file.is_file())
    return result


def _validate_repository_activation(
    ledger: dict[str, Any],
    activation_document: dict[str, Any] | None = None,
) -> None:
    activation_schema = _load_json(ACTIVATION_SCHEMA)
    activation = activation_document or _load_json(REPOSITORY_ACTIVATION)
    try:
        Draft202012Validator.check_schema(activation_schema)
        Draft202012Validator(
            activation_schema,
            format_checker=FormatChecker(),
        ).validate(activation)
    except (SchemaError, JsonSchemaValidationError) as exc:
        raise ValidationError(f"BH-01 repository activation schema failure: {exc.message}") from exc

    expected_paths = {
        "packages/blazex_runtime_popcorn",
        "packages/blazex_host_browser",
        "packages/blazex_renderer_dom",
        "packages/blazex_renderer_dom_liveview",
        "packages/blazex_phoenix",
        "js/blazex_runtime",
        "profiles/browser_phoenix",
        "integration/fixtures",
        "integration/benchmarks",
    }
    boundaries = activation["boundaries"]
    by_path = {record["path"]: record for record in boundaries}
    _require(set(by_path) == expected_paths and len(boundaries) == 9, "repository activation must contain exactly the approved nine boundaries")

    owner_roles = {record["role"] for record in ledger["owner_assignments"]}
    active_ids = {record["id"] for record in boundaries}
    for record in boundaries:
        boundary = REPO_ROOT / record["path"]
        _require(boundary.is_dir(), f"activated boundary is missing: {record['path']}")
        _require(record["owner"] in owner_roles, f"activated boundary has unassigned owner: {record['path']}")
        manifest = boundary / record["manifest"]
        metadata_path = boundary / record["ownership_metadata"]
        _require(manifest.is_file(), f"activated manifest is missing: {manifest.relative_to(REPO_ROOT)}")
        _require(metadata_path.is_file(), f"ownership metadata is missing: {metadata_path.relative_to(REPO_ROOT)}")
        metadata = _load_json(metadata_path)
        _require(metadata.get("schema_version") == "1.0.0", f"ownership metadata schema is stale: {record['path']}")
        _require(metadata.get("id") == record["id"] and metadata.get("path") == record["path"], f"ownership identity mismatch: {record['path']}")
        _require(metadata.get("kind") == record["kind"] and metadata.get("owner_role") == record["owner"], f"ownership kind/owner mismatch: {record['path']}")
        _require(metadata.get("manifest") == record["manifest"], f"ownership manifest mismatch: {record['path']}")
        _require(metadata.get("dependencies") == [], f"Phase 1 acquired a dependency: {record['path']}")
        _require(metadata.get("planned_dependencies") == record["allowed_planned_dependencies"], f"planned dependency graph changed: {record['path']}")
        _require(metadata.get("public_api_state") == record["api_state"], f"API state changed: {record['path']}")
        _require(set(metadata.get("planned_dependencies", [])) <= active_ids, f"planned edge leaves activated slice: {record['path']}")
        for source_root in record["source_roots"]:
            _require((boundary / source_root).exists(), f"source/evidence root is missing: {record['path']}/{source_root}")
        for test_entrypoint in record["test_entrypoints"]:
            _require((boundary / test_entrypoint).exists(), f"test entrypoint is missing: {record['path']}/{test_entrypoint}")

        # Dependency-free activation is historical evidence bound by the Phase 1
        # completion record and its source revision. Later, separately authorized
        # phases may add locks, local dependency trees, and manifest entries. The
        # persistent activation check is ownership, boundary, graph, API, and
        # source/test isolation rather than an assertion that the repository is
        # forever frozen at its Phase 1 filesystem state.

    standalone = REPO_ROOT / "packages/blazex_renderer_dom"
    standalone_text = "\n".join(path.read_text(encoding="utf-8") for path in _source_files(standalone))
    for token in ("Phoenix", "Plug", "LiveView", "LocalLiveView"):
        _require(token not in standalone_text, f"standalone DOM source contains forbidden coupling: {token}")

    inactive_import_tokens = (
        "BlazeX.Core",
        "BlazeX.Effects",
        "BlazeX.UITree",
        "BlazeX.Renderer behaviour",
        "integration/fixtures",
    )
    production_boundaries = [record for record in boundaries if record["kind"] not in {"integration-fixtures", "integration-benchmarks"}]
    for record in production_boundaries:
        for source in _source_files(REPO_ROOT / record["path"]):
            text = source.read_text(encoding="utf-8")
            for token in inactive_import_tokens:
                _require(token not in text, f"forbidden inactive/fixture import {token!r} in {source.relative_to(REPO_ROOT)}")

    successor_authorization_path = RESEARCH_ROOT / "assets/bh-02-baseline/blazex-bh-02-authorization-v0.1.0.json"
    successor_activation_path = RESEARCH_ROOT / "assets/bh-02-baseline/blazex-bh-02-repository-activation-v0.1.0.json"
    successor_paths: set[str] = set()
    if successor_authorization_path.is_file() or successor_activation_path.is_file():
        _require(successor_authorization_path.is_file() and successor_activation_path.is_file(), "BH-02 successor activation records are incomplete")
        successor_authorization = _load_json(successor_authorization_path)
        successor_activation = _load_json(successor_activation_path)
        _require(successor_authorization.get("status") == "approved-phase-1-only", "BH-02 successor activation lacks approval")
        _require(successor_activation.get("authorization_ref") == successor_authorization.get("authorization_id"), "BH-02 successor activation authorization link is invalid")
        successor_paths = {str(record.get("path")) for record in successor_activation.get("boundaries", [])}

    for inactive in activation["inactive_boundaries"]:
        boundary = REPO_ROOT / inactive
        _require(boundary.is_dir(), f"declared inactive boundary is missing: {inactive}")
        if inactive in successor_paths:
            continue
        for forbidden in ("mix.exs", "package.json", "blazex.project.json", "lib", "src"):
            _require(not (boundary / forbidden).exists(), f"inactive boundary was activated: {inactive}/{forbidden}")

    fixture_index = _load_json(REPO_ROOT / "integration/fixtures/fixture-index.json")
    benchmark_index = _load_json(REPO_ROOT / "integration/benchmarks/benchmark-index.json")
    for schema_path in (
        REPO_ROOT / "integration/fixtures/scenario.schema.json",
        REPO_ROOT / "integration/benchmarks/environment-fingerprint.schema.json",
        REPO_ROOT / "integration/benchmarks/sample.schema.json",
    ):
        try:
            Draft202012Validator.check_schema(_load_json(schema_path))
        except SchemaError as exc:
            raise ValidationError(f"integration schema failure in {schema_path.relative_to(REPO_ROOT)}: {exc.message}") from exc
    _require(fixture_index.get("production_import_allowed") is False, "fixture index permits production import")
    for scenario in fixture_index.get("scenarios", []):
        scenario_path = REPO_ROOT / "integration/fixtures" / str(scenario.get("path", ""))
        evidence_path = REPO_ROOT / "integration/fixtures" / str(scenario.get("evidence", ""))
        _require(scenario_path.is_file(), f"fixture scenario is missing: {scenario.get('scenario_id')}")
        _require(evidence_path.is_file(), f"fixture scenario evidence is missing: {scenario.get('scenario_id')}")
        try:
            Draft202012Validator(_load_json(REPO_ROOT / "integration/fixtures/scenario.schema.json")).validate(_load_json(scenario_path))
        except JsonSchemaValidationError as exc:
            raise ValidationError(f"fixture scenario schema failure in {scenario_path.relative_to(REPO_ROOT)}: {exc.message}") from exc
    environment_schema = _load_json(REPO_ROOT / "integration/benchmarks/environment-fingerprint.schema.json")
    for environment in benchmark_index.get("environments", []):
        environment_path = REPO_ROOT / "integration/benchmarks" / str(environment.get("path", ""))
        raw_path = REPO_ROOT / "integration/benchmarks" / str(environment.get("raw_evidence", ""))
        _require(environment_path.is_file(), f"benchmark environment is missing: {environment.get('environment_id')}")
        _require(raw_path.is_file(), f"benchmark environment raw evidence is missing: {environment.get('environment_id')}")
        try:
            Draft202012Validator(environment_schema, format_checker=FormatChecker()).validate(_load_json(environment_path))
        except JsonSchemaValidationError as exc:
            raise ValidationError(f"benchmark environment schema failure in {environment_path.relative_to(REPO_ROOT)}: {exc.message}") from exc
    phase9_authorization_path = REPO_ROOT / "docs/research/assets/bh-01-baseline/blazex-bh-01-phase-09-authorization-v0.1.0.json"
    phase9_authorized = phase9_authorization_path.is_file() and _load_json(phase9_authorization_path).get("status") == "approved-phase-9-only"
    if phase9_authorized:
        _require(bool(benchmark_index.get("measurements")), "authorized Phase 9 benchmark index omits measurements")
        _require(bool(benchmark_index.get("samples")), "authorized Phase 9 benchmark index omits samples")
        _require(bool(benchmark_index.get("reports")), "authorized Phase 9 benchmark index omits reports")
        _require(
            benchmark_index.get("budget_state") == "phase9-active-development-evaluated-conditional-no-support-credit",
            "authorized Phase 9 benchmark index overclaims its conditional budget state",
        )
    else:
        _require(
            benchmark_index.get("measurements") == []
            and benchmark_index.get("samples") == []
            and benchmark_index.get("reports") == [],
            "benchmark index contains measurement evidence before its authorized phase",
        )
        _require(benchmark_index.get("budget_state") == "proposed-unmeasured", "benchmark index claims a passed budget")

    evidence_boundary = activation["evidence_boundary"]
    _require(evidence_boundary == {
        "dependencies": "none-acquired",
        "locks": "none-created",
        "runtime": "unexecuted",
        "browser": "untested",
        "measurements": "unexecuted",
        "support": "unsupported",
    }, "repository activation evidence boundary changed")


def _validate_phase_1_completion() -> None:
    completion = _load_json(PHASE_1_COMPLETION)
    evidence_schema = _load_json(EVIDENCE_SCHEMA)
    try:
        Draft202012Validator(
            evidence_schema,
            format_checker=FormatChecker(),
        ).validate(completion)
    except JsonSchemaValidationError as exc:
        raise ValidationError(f"Phase 1 completion evidence schema failure: {exc.message}") from exc

    _require(completion.get("record_id") == "BX-BH01-DECISION-PHASE-01-GO", "Phase 1 completion ID changed")
    _require(completion.get("record_type") == "decision" and completion.get("state") == "passed", "Phase 1 completion outcome is not a passed decision")
    source_revision = str(completion.get("source_revision", ""))
    _git("cat-file", "-e", f"{source_revision}^{{commit}}")
    ancestry = subprocess.run(
        ["git", "merge-base", "--is-ancestor", source_revision, "HEAD"],
        cwd=REPO_ROOT,
        check=False,
    )
    _require(ancestry.returncode == 0, "Phase 1 completion does not cover an ancestor of the current delivery")

    for hash_record in [*completion["input_hashes"], *completion["output_hashes"]]:
        path = REPO_ROOT / hash_record["path"]
        _require(path.is_file(), f"Phase 1 completion hash target is missing: {hash_record['path']}")
        _require(_sha256(path) == hash_record["sha256"], f"Phase 1 completion hash is stale: {hash_record['path']}")

    outcome_text = " ".join(str(value) for value in completion["outcome"].values()).lower()
    _require("phase 2" in outcome_text and "not authorized" in outcome_text, "Phase 1 completion must not authorize Phase 2")
    _require(len(completion.get("limitations", [])) >= 3, "Phase 1 completion limitations are incomplete")
    _require(completion.get("review", {}).get("disposition") == "accepted", "Phase 1 gate lacks accepted review")
    _require("- [ ]" not in PHASE_1_PLAN.read_text(encoding="utf-8"), "Phase 1 plan still contains open work")


def validate() -> None:
    auth = _load_json(AUTHORIZATION)
    ledger = _load_json(LEDGER)
    governance = _load_json(BH00_GOVERNANCE)
    quality = _load_json(QUALITY_CONTRACT)
    acceptance = _load_json(ACCEPTANCE_REGISTRY)
    _validate_authorization(auth, governance)
    _validate_bound_sources(governance)
    _validate_ledger(ledger, governance, quality, acceptance)
    _validate_evidence_governance(governance, ledger)
    _validate_repository_activation(ledger)
    _validate_phase_1_completion()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.parse_args()
    try:
        validate()
    except ValidationError as exc:
        print(f"BH-01 activation validation failed: {exc}", file=sys.stderr)
        return 1
    print("BH-01 authorization, inherited ledger, evidence governance, activation, and Phase 1 completion are valid.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
