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


RESEARCH_ROOT = Path(__file__).resolve().parent
REPO_ROOT = RESEARCH_ROOT.parent.parent
BH00_GOVERNANCE = RESEARCH_ROOT / "assets/bh-00-release/blazex-bh-00-governance-v0.1.0.json"
QUALITY_CONTRACT = RESEARCH_ROOT / "assets/quality-acceptance/blazex-quality-contract-v0.1.0.json"
ACCEPTANCE_REGISTRY = RESEARCH_ROOT / "assets/quality-acceptance/blazex-acceptance-registry-v0.1.0.json"
AUTHORIZATION = RESEARCH_ROOT / "assets/bh-01-baseline/blazex-bh-01-authorization-v0.1.0.json"
LEDGER = RESEARCH_ROOT / "assets/bh-01-baseline/blazex-bh-01-milestone-ledger-v0.1.0.json"


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
    plan_path = REPO_ROOT / str(plan.get("path", ""))
    _require(plan_path.is_file(), "approved plan is missing")
    _require(_sha256(plan_path) == plan.get("sha256"), "approved plan content is stale")
    _git("cat-file", "-e", f"{plan.get('revision')}^{{commit}}")

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


def _validate_bound_sources(governance: dict[str, Any]) -> None:
    _require(governance.get("stage") == "complete", "BH-00 governance is incomplete")
    _require(governance.get("release", {}).get("status") == "accepted-product-contract", "BH-00 release is not accepted")
    _require(governance.get("bh01_entry", {}).get("decision") == "conditionally-ready", "BH-01 entry is not conditionally ready")
    for binding in governance.get("source_bindings", []):
        path = RESEARCH_ROOT / str(binding.get("path", ""))
        _require(path.is_file(), f"bound BH-00 source is missing: {binding.get('id')}")
        _require(_sha256(path) == binding.get("sha256"), f"bound BH-00 source is stale: {binding.get('id')}")


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


def validate() -> None:
    auth = _load_json(AUTHORIZATION)
    ledger = _load_json(LEDGER)
    governance = _load_json(BH00_GOVERNANCE)
    quality = _load_json(QUALITY_CONTRACT)
    acceptance = _load_json(ACCEPTANCE_REGISTRY)
    _validate_authorization(auth, governance)
    _validate_bound_sources(governance)
    _validate_ledger(ledger, governance, quality, acceptance)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.parse_args()
    try:
        validate()
    except ValidationError as exc:
        print(f"BH-01 activation validation failed: {exc}", file=sys.stderr)
        return 1
    print("BH-01 activation authorization and inherited ledger are valid.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
