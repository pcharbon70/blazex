#!/usr/bin/env python3
"""Validate the retained BH-01 Phase 6 trust-boundary evidence and gate."""

from __future__ import annotations

import copy
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
PLAN = PLAN_DIR / "phase-06-phoenix-trust-boundary-and-liveview-isolation.md"
MILESTONE = PLAN_DIR / "README.md"
REPORT = PLAN_DIR / "phase-06-implementation-evidence.md"
ASSETS = ROOT / "docs/research/assets/bh-01-baseline"
AUTHORIZATION = ASSETS / "blazex-bh-01-phase-06-authorization-v0.1.0.json"
COMPLETION = ASSETS / "blazex-bh-01-phase-06-completion-v0.1.0.json"
SCHEMA = ASSETS / "blazex-bh-01-evidence-record.schema.json"
EVIDENCE = ROOT / "integration/fixtures/raw-evidence/bh01-phase6-trust-and-isolation.json"
SCENARIO = ROOT / "integration/fixtures/scenarios/bh01-phase6-trust-boundary.json"
FIXTURE_INDEX = ROOT / "integration/fixtures/fixture-index.json"
PRIVATE_APIS = HERE / "private-api-inventory.json"
STANDALONE = ROOT / "integration/fixtures/browser_host/standalone-boundary.json"
SHA256 = re.compile(r"^[0-9a-f]{64}$")
COMMIT = re.compile(r"^[0-9a-f]{40}$")

EXPECTED_TOOLCHAIN = {
    "node": "v26.8.1",
    "playwright_core": "1.62.1",
    "browser_product": "Chrome for Testing",
    "browser_version": "152.0.7977.75",
    "browser_archive_sha256": "a16d36890636bd72251133b27f05825f7f9269c2425b3408fa3a76e10dccd8f1",
}
EXPECTED_FAILURES = {
    "unauthorized": "authorization-denied",
    "expired": "session-invalid",
    "stale": "state-stale",
    "rate_limited": "rate-limited",
    "transaction": "transaction-failed",
    "server_error": "server-unavailable",
    "disconnect": "transport-unavailable",
    "retry_after_disconnect": "ok",
    "timeout": "transport-timeout",
    "disposal_delivery": False,
    "unauthorized_effects": 0,
}
FORBIDDEN_SECRET_KEYS = {
    "authorization_rules",
    "cookie",
    "credential",
    "csrf_token",
    "role_rules",
    "session_id",
    "set_cookie",
    "stacktrace",
}


def load(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def file_sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def object_keys(value: Any) -> set[str]:
    keys: set[str] = set()
    if isinstance(value, dict):
        for key, child in value.items():
            keys.add(str(key).lower())
            keys.update(object_keys(child))
    elif isinstance(value, list):
        for child in value:
            keys.update(object_keys(child))
    return keys


def validate_browser(evidence: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    if evidence.get("status") != "observed-pass":
        errors.append("actual-browser trust-boundary evidence did not pass")
    if evidence.get("support_status") != "unsupported-provisional-feasibility":
        errors.append("Phase 6 evidence promotes browser support")
    if not COMMIT.fullmatch(evidence.get("implementation_parent_revision", "")):
        errors.append("Phase 6 evidence lacks an exact implementation parent")
    for key, value in EXPECTED_TOOLCHAIN.items():
        if evidence.get("toolchain", {}).get(key) != value:
            errors.append(f"browser toolchain drifted: {key}")

    adapter = evidence.get("adapter_capability", {})
    if adapter.get("status") != "eligible" or adapter.get("fallback") != "standalone-dom":
        errors.append("optional LiveView adapter eligibility/fallback drifted")
    if adapter.get("versions") != {
        "local_live_view": "0.1.0",
        "phoenix_live_view": "1.2.11",
    }:
        errors.append("optional LiveView adapter pins drifted")

    command = evidence.get("command_path", {})
    projection = command.get("runtime_projection", {})
    accepted = command.get("accepted", {}).get("result", {})
    replayed = command.get("replayed", {}).get("result", {})
    if command.get("normalized_dom_action") is not True:
        errors.append("normalized DOM action did not cross the command path")
    if (projection.get("value"), projection.get("version"), projection.get("status")) != (1, 1, "accepted"):
        errors.append("runtime projection does not retain the rendered accepted result")
    if (accepted.get("value"), accepted.get("version"), accepted.get("replayed")) != (2, 2, False):
        errors.append("explicit accepted command result drifted")
    if (replayed.get("value"), replayed.get("version"), replayed.get("replayed")) != (2, 2, True):
        errors.append("idempotent replay applied or returned a different result")
    if command.get("authoritative_resource") != {"id": "counter", "value": 2, "version": 2}:
        errors.append("authoritative resource did not converge to exactly two effects")
    audit = command.get("correlated_audit", [])
    if [item.get("outcome") for item in audit] != [
        "accepted", "accepted", "replayed", "state-stale", "rate-limited"
    ]:
        errors.append("correlated server audit outcome order drifted")
    if sum(item.get("effect_applied") is True for item in audit) != 2:
        errors.append("correlated audit does not prove exactly two authorized effects")
    if any(not item.get("correlation_id") or not item.get("idempotency_digest") for item in audit):
        errors.append("correlated audit lacks bounded correlation or idempotency identity")

    if evidence.get("failure_matrix") != EXPECTED_FAILURES:
        errors.append("trust-boundary failure matrix drifted")

    cleanup = evidence.get("cleanup", {})
    bridge = cleanup.get("bridge", {})
    lifecycle = cleanup.get("lifecycle", {})
    if bridge.get("pending") != 0 or bridge.get("stopped") is not True or bridge.get("timers") != 0:
        errors.append("browser bridge retained pending work after disposal")
    if lifecycle.get("state") != "stopped" or lifecycle.get("resources") != {}:
        errors.append("runtime lifecycle retained owned resources after disposal")
    if cleanup.get("server") != {"pending": 0, "session_configured": False}:
        errors.append("browser server transport retained pending/session state")
    if cleanup.get("dom") != {"roots": 0, "listeners": 0, "nodes": 0}:
        errors.append("standalone DOM retained owned resources")

    leaked = object_keys(evidence) & FORBIDDEN_SECRET_KEYS
    if leaked or evidence.get("audit") != []:
        errors.append(f"retained evidence contains secret-bearing fields: {sorted(leaked)}")

    expected_hash = evidence.get("evidence_sha256", "")
    hash_input = {
        "command_path": evidence.get("command_path"),
        "failure_matrix": evidence.get("failure_matrix"),
        "cleanup": evidence.get("cleanup"),
    }
    actual_hash = hashlib.sha256(
        json.dumps(hash_input, ensure_ascii=False, separators=(",", ":")).encode()
    ).hexdigest()
    if expected_hash != actual_hash:
        errors.append("raw Phase 6 evidence self-hash drifted")
    return errors


def validate(
    completion: dict[str, Any],
    authorization: dict[str, Any],
    evidence: dict[str, Any],
    scenario: dict[str, Any],
    fixture_index: dict[str, Any],
    private_apis: dict[str, Any],
    standalone: dict[str, Any],
    plan_text: str,
    milestone_text: str,
    report_text: str,
    repository_hashes: dict[str, str],
) -> list[str]:
    errors = validate_browser(evidence)
    if authorization.get("status") != "approved-phase-6-only":
        errors.append("Phase 6 lacks explicit repository-owner authorization")
    if not any(item.startswith("Phase 7 resilience") for item in authorization.get("not_authorized", [])):
        errors.append("Phase 6 authorization does not preserve the Phase 7 boundary")
    if completion.get("record_id") != "BX-BH01-DECISION-PHASE-06-GO":
        errors.append("Phase 6 completion record identity changed")
    if completion.get("record_type") != "decision" or completion.get("state") != "passed":
        errors.append("Phase 6 completion is not a passed decision")
    if not COMMIT.fullmatch(completion.get("source_revision", "")):
        errors.append("Phase 6 completion lacks an exact source revision")
    if completion.get("review", {}).get("disposition") != "accepted":
        errors.append("Phase 6 completion lacks accepted owner review")
    if "Phase 7 is eligible but not authorized" not in completion.get("outcome", {}).get("summary", ""):
        errors.append("Phase 6 completion over-authorizes downstream work")
    for record in completion.get("input_hashes", []) + completion.get("output_hashes", []):
        path = record.get("path", "")
        expected = record.get("sha256", "")
        if not SHA256.fullmatch(expected) or repository_hashes.get(path) != expected:
            errors.append(f"Phase 6 evidence hash drifted: {path}")

    if scenario.get("scenario_id") != "BX-BH01-SCENARIO-PHASE6-TRUST-BOUNDARY" or scenario.get("status") != "passed":
        errors.append("Phase 6 governed scenario did not pass")
    indexed = [item for item in fixture_index.get("scenarios", []) if item.get("scenario_id") == scenario.get("scenario_id")]
    if len(indexed) != 1 or indexed[0].get("evidence") != "raw-evidence/bh01-phase6-trust-and-isolation.json":
        errors.append("Phase 6 scenario/evidence is not uniquely indexed")

    entries = private_apis.get("entries", [])
    if len(entries) != 8 or any(not item.get("source_revision") or not item.get("source_lines") for item in entries):
        errors.append("private LiveView API inventory is incomplete")
    defaults = private_apis.get("entry_defaults", {})
    if defaults.get("owner") != "packages/blazex_renderer_dom_liveview" or "Disable" not in defaults.get("fallback", ""):
        errors.append("private LiveView API ownership/fallback drifted")
    if standalone.get("status") != "phase6-verified" or "executable Plug profile" not in standalone.get("claims_not_made", []):
        errors.append("standalone/Plug/headless claim boundary drifted")
    if set(standalone.get("forbidden_atomvm_runtime_apis", [])) != {"Regex", "~r/"}:
        errors.append("AtomVM runtime API regression guard drifted")

    if "- [ ]" in plan_text:
        errors.append("Phase 6 plan still contains open work")
    if "| complete — gate passed | Prove one authenticated command" not in milestone_text:
        errors.append("BH-01 milestone does not record the passed Phase 6 gate")
    if not (
        re.search(r"Phase 7 is eligible but (?:is )?not authorized", milestone_text)
        or "Phase 7 and later\nwork remain outside the current authorization" in milestone_text
    ):
        errors.append("BH-01 milestone does not preserve the Phase 7 authorization boundary")
    for revision in ("b39bdeb", "8cc8851", "b3281b4", "1dbcbfd"):
        if revision not in report_text:
            errors.append(f"Phase 6 report omits section revision {revision}")
    normalized_report = " ".join(report_text.split()).lower()
    for boundary in (
        "all browsers remain unsupported",
        "plug and headless remain dependency contracts",
        "phase 7 is eligible but is not authorized",
    ):
        if boundary not in normalized_report:
            errors.append(f"Phase 6 report omits claim boundary: {boundary}")
    return errors


def inputs() -> tuple[Any, ...]:
    completion = load(COMPLETION)
    records = completion.get("input_hashes", []) + completion.get("output_hashes", [])
    hashes = {
        record["path"]: file_sha256(ROOT / record["path"])
        for record in records
        if (ROOT / record["path"]).is_file()
    }
    return (
        completion,
        load(AUTHORIZATION),
        load(EVIDENCE),
        load(SCENARIO),
        load(FIXTURE_INDEX),
        load(PRIVATE_APIS),
        load(STANDALONE),
        PLAN.read_text(encoding="utf-8"),
        MILESTONE.read_text(encoding="utf-8"),
        REPORT.read_text(encoding="utf-8"),
        hashes,
    )


def main() -> int:
    errors: list[str] = []
    for command in (
        [sys.executable, str(HERE / "verify_phase5.py")],
        [sys.executable, str(HERE / "verify_server.py")],
        [sys.executable, str(HERE / "verify_phase6_boundaries.py")],
        [sys.executable, str(ROOT / "integration/fixtures/browser_host/verify_fixture.py"), "--generated", "integration/fixtures/browser_host/generated"],
    ):
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
    if subprocess.run(
        ["git", "merge-base", "--is-ancestor", revision, "HEAD"], cwd=ROOT, check=False
    ).returncode:
        errors.append("Phase 6 source revision is not an ancestor of the delivery")
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print("BH-01 Phase 6 Phoenix trust boundary and adapter isolation gate: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
