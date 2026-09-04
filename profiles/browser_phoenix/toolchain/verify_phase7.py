#!/usr/bin/env python3
"""Validate retained BH-01 Phase 7 resilience/security/resource evidence."""

from __future__ import annotations

import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
PLAN_DIR = ROOT / "docs/research/60-planning/01-browser-host/bh-01-reproducible-browser-feasibility-baseline"
PLAN = PLAN_DIR / "phase-07-resilience-security-and-resource-lifecycle.md"
MILESTONE = PLAN_DIR / "README.md"
REPORT = PLAN_DIR / "phase-07-implementation-evidence.md"
ASSETS = ROOT / "docs/research/assets/bh-01-baseline"
AUTHORIZATION = ASSETS / "blazex-bh-01-phase-07-authorization-v0.1.0.json"
COMPLETION = ASSETS / "blazex-bh-01-phase-07-completion-v0.1.0.json"
SCHEMA = ASSETS / "blazex-bh-01-evidence-record.schema.json"
EVIDENCE = ROOT / "integration/fixtures/raw-evidence/bh01-phase7-resilience-security-resource.json"
SCENARIO = ROOT / "integration/fixtures/scenarios/bh01-phase7-resilience-security-resource.json"
FIXTURE_INDEX = ROOT / "integration/fixtures/fixture-index.json"
RESILIENCE = ROOT / "integration/fixtures/resilience"
POLICIES = {
    name: RESILIENCE / name
    for name in (
        "failure-taxonomy.json",
        "recovery-policy.json",
        "resource-policy.json",
        "adversarial-matrix.json",
        "diagnostic-contract.json",
    )
}
SHA256 = re.compile(r"^[0-9a-f]{64}$")
COMMIT = re.compile(r"^[0-9a-f]{40}$")
EXPECTED_TOOLCHAIN = {
    "node": "v26.8.1",
    "playwright_core": "1.62.1",
    "browser_product": "Chrome for Testing",
    "browser_version": "152.0.7977.75",
    "browser_archive_sha256": "a16d36890636bd72251133b27f05825f7f9269c2425b3408fa3a76e10dccd8f1",
}
ZERO_RUNTIME = {"mailbox_messages": 0, "pending_messages": 0, "processes": 0, "timers": 0}
ZERO_DOM = {"roots": 0, "listeners": 0, "nodes": 0}


def load(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def file_sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def historical_sha256(revision: str, path: str) -> str | None:
    result = subprocess.run(
        ["git", "show", f"{revision}:{path}"],
        cwd=ROOT,
        capture_output=True,
        check=False,
    )
    return hashlib.sha256(result.stdout).hexdigest() if result.returncode == 0 else None


def committed_sha256s(path: str) -> set[str]:
    history = subprocess.run(
        ["git", "log", "--format=%H", "--", path],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    values: set[str] = set()
    for revision in history.stdout.splitlines():
        value = historical_sha256(revision, path)
        if value:
            values.add(value)
    return values


def validate_browser(evidence: dict[str, Any], resource_policy: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    if evidence.get("status") != "observed-pass":
        errors.append("actual-browser Phase 7 evidence did not pass")
    if evidence.get("support_status") != "unsupported-provisional-feasibility":
        errors.append("Phase 7 evidence promotes browser support")
    if not COMMIT.fullmatch(evidence.get("implementation_parent_revision", "")):
        errors.append("Phase 7 evidence lacks an exact implementation parent")
    for key, value in EXPECTED_TOOLCHAIN.items():
        if evidence.get("toolchain", {}).get(key) != value:
            errors.append(f"browser toolchain drifted: {key}")

    stress = evidence.get("stress", {})
    results = stress.get("iteration_results", [])
    if stress.get("iterations") != 20 or len(results) != 20:
        errors.append("Phase 7 stress count is not exactly twenty")
    if stress.get("generations") != list(range(1, 21)):
        errors.append("Phase 7 runtime generations are incomplete or stale")
    if stress.get("recovered_disconnects") != 4 or sum(item.get("recovered") is True for item in results) != 4:
        errors.append("Phase 7 did not retain exactly four recoveries")
    if stress.get("interruption_points") != resource_policy.get("interruption_points"):
        errors.append("Phase 7 interruption coverage drifted from policy")
    for item in results:
        if item.get("resource_value") != 1 or item.get("audit_events") != 1:
            errors.append("a stress generation did not apply exactly one authorized effect")
            break
        if item.get("disposed_runtime") != ZERO_RUNTIME or item.get("disposed_dom") != ZERO_DOM:
            errors.append("a stress generation retained runtime or DOM resources")
            break

    recovery = evidence.get("recovery", {})
    attempts = recovery.get("attempts", {})
    if recovery.get("state") != "stable" or recovery.get("pending") != 0:
        errors.append("coordinated recovery did not converge")
    if set(attempts.values()) != {2} or len(attempts) != 4:
        errors.append("recovery attempt budget or correlation count drifted")
    trace = recovery.get("trace", [])
    if len(trace) != 16 or [item.get("kind") for item in trace] != ["attempt", "failed", "attempt", "stable"] * 4:
        errors.append("recovery trace does not prove four bounded two-attempt recoveries")

    adversarial = evidence.get("adversarial", {})
    if adversarial.get("artifact_tamper") != {
        "state": "failed", "code": "artifact-integrity-mismatch", "runtime_ready": False
    }:
        errors.append("artifact tamper did not fail before runtime readiness")
    if adversarial.get("forged_command") != {
        "http_status": 403, "code": "csrf-invalid", "effect_delta": 0
    }:
        errors.append("forged authority-bearing command did not fail closed")
    if adversarial.get("oversized_bridge") != "bridge-payload-string-exceeded":
        errors.append("oversized bridge input was not rejected")
    if adversarial.get("inert_html") is not True or adversarial.get("unauthorized_effects") != 0:
        errors.append("adversarial input injected content or applied an unauthorized effect")

    diagnostics = evidence.get("diagnostics", {})
    if diagnostics.get("count", 0) < 5 or diagnostics.get("correlated_transport_failure") is not True:
        errors.append("correlated failure diagnostics are incomplete")
    if diagnostics.get("redaction") != "passed":
        errors.append("diagnostic redaction did not pass")
    if diagnostics.get("console_only_failures") != 0 or diagnostics.get("uncaught_page_errors") != 0:
        errors.append("browser failures escaped structured diagnostics")

    resources = evidence.get("resources", {})
    disposed = resources.get("disposed", {}).get("resources", {})
    if resources.get("sample_count") != 40 or resources.get("converged") is not True or resources.get("leaks") != []:
        errors.append("resource report did not converge over forty samples")
    for name in resource_policy.get("zero_at_disposal", []):
        if disposed.get(name) != 0:
            errors.append(f"resource did not converge at disposal: {name}")
    if resources.get("unknown") != {
        "browser.workers": "The selected parent-frame browser API does not expose worker count"
    } or disposed.get("browser.workers", "missing") is not None:
        errors.append("unavailable browser worker observation is not an explicit unknown")
    if disposed.get("runtime.memory_pages") != 256 or disposed.get("server.processes") != 1:
        errors.append("explained runtime/server floors drifted")

    hash_input = {
        key: evidence.get(key)
        for key in ("stress", "recovery", "adversarial", "diagnostics", "resources")
    }
    actual_hash = hashlib.sha256(
        json.dumps(hash_input, ensure_ascii=False, separators=(",", ":")).encode()
    ).hexdigest()
    if evidence.get("evidence_sha256") != actual_hash:
        errors.append("raw Phase 7 evidence self-hash drifted")
    return errors


def validate(
    completion: dict[str, Any],
    authorization: dict[str, Any],
    evidence: dict[str, Any],
    scenario: dict[str, Any],
    fixture_index: dict[str, Any],
    policies: dict[str, dict[str, Any]],
    plan_text: str,
    milestone_text: str,
    report_text: str,
    repository_hashes: dict[str, set[str]],
) -> list[str]:
    errors = validate_browser(evidence, policies["resource-policy.json"])
    if authorization.get("status") != "approved-phase-7-only":
        errors.append("Phase 7 lacks explicit repository-owner authorization")
    if not any(item.startswith("Phase 8 browser compatibility") for item in authorization.get("not_authorized", [])):
        errors.append("Phase 7 authorization does not preserve the Phase 8 boundary")

    expected_policy_states = {
        "failure-taxonomy.json": "phase7-policy",
        "recovery-policy.json": "phase7-policy",
        "resource-policy.json": "proposed-feasibility-limits",
        "adversarial-matrix.json": "phase7-executed-contract-matrix",
        "diagnostic-contract.json": "phase7-fixture-contract",
    }
    for name, status in expected_policy_states.items():
        if policies.get(name, {}).get("status") != status:
            errors.append(f"Phase 7 policy status drifted: {name}")

    if completion.get("record_id") != "BX-BH01-DECISION-PHASE-07-GO":
        errors.append("Phase 7 completion record identity changed")
    if completion.get("record_type") != "decision" or completion.get("state") != "passed":
        errors.append("Phase 7 completion is not a passed decision")
    if not COMMIT.fullmatch(completion.get("source_revision", "")):
        errors.append("Phase 7 completion lacks an exact source revision")
    if completion.get("review", {}).get("disposition") != "accepted":
        errors.append("Phase 7 completion lacks accepted owner review")
    if "Phase 8 is eligible but not authorized" not in completion.get("outcome", {}).get("summary", ""):
        errors.append("Phase 7 completion over-authorizes downstream work")
    for record in completion.get("input_hashes", []) + completion.get("output_hashes", []):
        path = record.get("path", "")
        expected = record.get("sha256", "")
        if not SHA256.fullmatch(expected) or expected not in repository_hashes.get(path, set()):
            errors.append(f"Phase 7 evidence hash drifted: {path}")

    if scenario.get("scenario_id") != "BX-BH01-SCENARIO-PHASE7-RESILIENCE-SECURITY-RESOURCE" or scenario.get("status") != "passed":
        errors.append("Phase 7 governed scenario did not pass")
    indexed = [item for item in fixture_index.get("scenarios", []) if item.get("scenario_id") == scenario.get("scenario_id")]
    if len(indexed) != 1 or indexed[0].get("status") != "passed" or indexed[0].get("evidence") != "raw-evidence/bh01-phase7-resilience-security-resource.json":
        errors.append("Phase 7 scenario/evidence is not uniquely indexed as passed")

    if "- [ ]" in plan_text:
        errors.append("Phase 7 plan still contains open work")
    if "| complete — gate passed | Stress failures, retries, adversarial inputs" not in milestone_text:
        errors.append("BH-01 milestone does not record the passed Phase 7 gate")
    phase8_pending = re.search(r"Phase\s+8 is eligible but not authorized", milestone_text)
    phase8_blocked = "| complete — gate blocked | Run the complete scenario set" in milestone_text
    if not (phase8_pending or phase8_blocked):
        errors.append("BH-01 milestone does not preserve the Phase 8 authorization boundary")
    for revision in ("8f980b2", "875af9d", "afb75fc", "0c26d65"):
        if revision not in report_text:
            errors.append(f"Phase 7 report omits section revision {revision}")
    normalized_report = " ".join(report_text.split()).lower()
    for boundary in (
        "all browsers remain unsupported",
        "not a production soak",
        "phase 8 is eligible but is not authorized",
    ):
        if boundary not in normalized_report:
            errors.append(f"Phase 7 report omits claim boundary: {boundary}")
    return errors


def inputs() -> tuple[Any, ...]:
    completion = load(COMPLETION)
    records = completion.get("input_hashes", []) + completion.get("output_hashes", [])
    hashes: dict[str, set[str]] = {}
    for record in records:
        path = record["path"]
        values: set[str] = set()
        if (ROOT / path).is_file():
            values.add(file_sha256(ROOT / path))
        values.update(committed_sha256s(path))
        hashes[path] = values
    return (
        completion,
        load(AUTHORIZATION),
        load(EVIDENCE),
        load(SCENARIO),
        load(FIXTURE_INDEX),
        {name: load(path) for name, path in POLICIES.items()},
        PLAN.read_text(encoding="utf-8"),
        MILESTONE.read_text(encoding="utf-8"),
        REPORT.read_text(encoding="utf-8"),
        hashes,
    )


def main() -> int:
    errors: list[str] = []
    commands = [
        [sys.executable, str(HERE / "verify_phase6.py")],
        *[
            [sys.executable, str(RESILIENCE / name)]
            for name in (
                "verify_failure_model.py",
                "verify_resource_policy.py",
                "verify_adversarial_matrix.py",
                "verify_diagnostics.py",
            )
        ],
        [sys.executable, str(ROOT / "integration/fixtures/browser_host/verify_fixture.py"), "--generated", "integration/fixtures/browser_host/generated"],
        [sys.executable, str(ROOT / "profiles/browser_phoenix/assets/phase4/verify_profile.py"), "profiles/browser_phoenix/priv/static/bh01"],
    ]
    for command in commands:
        result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, check=False)
        if result.returncode != 0:
            errors.append(f"{Path(command[1]).name}: {result.stderr.strip() or result.stdout.strip()}")

    completion = load(COMPLETION)
    errors.extend(
        f"completion schema: {error.message}"
        for error in Draft202012Validator(load(SCHEMA), format_checker=FormatChecker()).iter_errors(completion)
    )
    errors.extend(validate(*inputs()))
    revision = completion.get("source_revision", "")
    if subprocess.run(["git", "merge-base", "--is-ancestor", revision, "HEAD"], cwd=ROOT, check=False).returncode:
        errors.append("Phase 7 source revision is not an ancestor of the delivery")
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print("BH-01 Phase 7 resilience, security, and resource lifecycle gate: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
