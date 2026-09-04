#!/usr/bin/env python3
"""Validate the retained BH-01 Phase 5 local browser behavior evidence."""

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
PLAN = PLAN_DIR / "phase-05-local-browser-behavior-and-dom-vertical-slice.md"
MILESTONE = PLAN_DIR / "README.md"
REPORT = PLAN_DIR / "phase-05-implementation-evidence.md"
ASSETS = ROOT / "docs/research/assets/bh-01-baseline"
COMPLETION = ASSETS / "blazex-bh-01-phase-05-completion-v0.1.0.json"
SCHEMA = ASSETS / "blazex-bh-01-evidence-record.schema.json"
EVIDENCE = ROOT / "integration/fixtures/raw-evidence/bh01-phase5-local-browser.json"
SHA256 = re.compile(r"^[0-9a-f]{64}$")
COMMIT = re.compile(r"^[0-9a-f]{40}$")

EXPECTED_FAILURES = {
    "duplicate_child": "fixture-child-duplicate",
    "missing_child": "fixture-child-missing",
    "disabled_input": "fixture-field-disabled",
    "read_only_input": "fixture-field-read-only",
    "malformed_event": "fixture-field-event-invalid",
    "oversized_value": "bridge-payload-string-exceeded",
    "post_disposal": "bridge-stopped",
}
EXPECTED_ADAPTER_FAILURES = {
    "duplicate_listener": "fixture-listener-duplicate",
    "missing_target": "fixture-target-missing",
    "oversized_value": "fixture-value-exceeded",
    "partial_batch": "fixture-target-missing",
    "post_disposal": "fixture-renderer-disposed",
    "stale_generation": "fixture-generation-stale",
}
EXPECTED_PROOFS = {
    "BX-BH01-PROOF-NESTED-STATE",
    "BX-BH01-PROOF-FORM-EVENT",
    "BX-BH01-PROOF-TIMER-MESSAGE",
    "BX-BH01-PROOF-DOM-UPDATE",
}


def load(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as stream:
        return json.load(stream)


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


def validate_stop(stop: dict[str, Any], label: str) -> list[str]:
    errors: list[str] = []
    resources = stop.get("final_resources") or {}
    runtime = stop.get("disposal_runtime") or {}
    if stop.get("state") != "stopped":
        errors.append(f"{label} did not reach stopped")
    if resources.get("dom") != {"roots": 0, "listeners": 0, "nodes": 0}:
        errors.append(f"{label} retained DOM ownership")
    bridge = resources.get("bridge") or {}
    if bridge.get("pending") != 0 or bridge.get("stopped") is not True:
        errors.append(f"{label} retained bridge work")
    lifecycle = resources.get("lifecycle") or {}
    if lifecycle.get("state") != "stopped" or lifecycle.get("resources") != {}:
        errors.append(f"{label} retained lifecycle ownership")
    runtime_resources = runtime.get("resources") or {}
    for name in ("processes", "timers", "pending_messages"):
        if runtime_resources.get(name) != 0:
            errors.append(f"{label} retained runtime resource: {name}")
    return errors


def validate_browser(evidence: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    if evidence.get("status") != "observed-pass":
        errors.append("actual-browser behavior evidence did not pass")
    if evidence.get("support_status") != "unsupported-provisional-feasibility":
        errors.append("Phase 5 evidence promotes browser support")
    if not COMMIT.fullmatch(evidence.get("implementation_parent_revision", "")):
        errors.append("Phase 5 evidence lacks an exact implementation parent")

    toolchain = evidence.get("toolchain", {})
    expected_toolchain = {
        "node": "v26.8.1",
        "playwright_core": "1.62.1",
        "browser_product": "Chrome for Testing",
        "browser_version": "152.0.7977.75",
        "browser_archive_sha256": "a16d36890636bd72251133b27f05825f7f9269c2425b3408fa3a76e10dccd8f1",
    }
    for key, value in expected_toolchain.items():
        if toolchain.get(key) != value:
            errors.append(f"browser toolchain drifted: {key}")

    deployment = evidence.get("deployment", {})
    artifacts = deployment.get("artifacts", [])
    if deployment.get("manifest_id") != "BX-BH01-PHASE-05-PROFILE-ASSETS-0.1":
        errors.append("Phase 5 deployment manifest identity drifted")
    if deployment.get("governed_files") != 20 or len(artifacts) != 20:
        errors.append("deployment does not account for 20 governed files")
    if deployment.get("source_maps") != []:
        errors.append("undeclared browser source maps observed")
    for artifact in artifacts:
        if not SHA256.fullmatch(artifact.get("sha256", "")) or artifact.get("bytes", 0) <= 0:
            errors.append(f"invalid governed artifact observation: {artifact.get('path')}")

    repeatability = evidence.get("repeatability", {})
    trace = evidence.get("canonical_trace", [])
    trace_hash = hashlib.sha256(
        json.dumps(trace, ensure_ascii=False, separators=(",", ":")).encode()
    ).hexdigest()
    if repeatability.get("equivalent") is not True:
        errors.append("two-run semantic trace equivalence failed")
    if repeatability.get("checkpoint_count") != 29 or len(trace) != 29:
        errors.append("canonical Phase 5 trace does not contain 29 checkpoints")
    if repeatability.get("trace_sha256") != trace_hash:
        errors.append("canonical Phase 5 trace hash drifted")

    declared_paths = {"/bh01/", "blob:<runtime-worker-module>"} | {
        f"/bh01/{artifact['path']}" for artifact in artifacts
    }
    runs = evidence.get("runs", [])
    if [run.get("run_id") for run in runs] != ["repeat-1", "repeat-2"]:
        errors.append("Phase 5 evidence does not contain the two required independent runs")
    for run in runs:
        run_id = run.get("run_id", "unknown-run")
        if run.get("status") != "passed" or run.get("trace_sha256") != trace_hash:
            errors.append(f"{run_id} did not reproduce the canonical semantic trace")
        if run.get("behavior_network_requests") != [] or run.get("page_errors") != []:
            errors.append(f"{run_id} observed behavior-time network traffic or page errors")
        undeclared = set(run.get("network_paths", [])) - declared_paths
        if undeclared:
            errors.append(f"{run_id} observed undeclared network paths: {sorted(undeclared)}")
        if run.get("replacement_generation") != 2:
            errors.append(f"{run_id} did not prove generation-2 replacement")
        if run.get("failures") != EXPECTED_FAILURES:
            errors.append(f"{run_id} negative behavior outcomes drifted")
        errors.extend(validate_stop(run.get("first_stop") or {}, f"{run_id} first stop"))
        errors.extend(validate_stop(run.get("replacement_stop") or {}, f"{run_id} replacement stop"))

        accessibility = run.get("accessibility") or {}
        if accessibility.get("textbox_name") != "Name" or accessibility.get("alert_role_count") != 1:
            errors.append(f"{run_id} accessible role/name observations drifted")
        if accessibility.get("relationships") != {
            "described_by": "bx-field-help bx-field-error",
            "error_message": "bx-field-error",
        }:
            errors.append(f"{run_id} accessible field relationships drifted")
        tab_order = accessibility.get("tab_order", [])
        if "bx-field" not in tab_order or "bx-field-reset" not in tab_order:
            errors.append(f"{run_id} keyboard order omits the field or reset action")

    adapter = evidence.get("adapter_negative_scenarios", {})
    if adapter.get("codes") != EXPECTED_ADAPTER_FAILURES:
        errors.append("DOM adapter negative outcomes drifted")
    if adapter.get("partial_text_after_failure") != "before":
        errors.append("failed DOM batch committed a partial mutation")

    proofs = evidence.get("proofs", {})
    if set(proofs) != EXPECTED_PROOFS:
        errors.append("Phase 5 proof inventory drifted")
    for proof_id in EXPECTED_PROOFS:
        if (proofs.get(proof_id) or {}).get("status") != "provisional-pass":
            errors.append(f"Phase 5 proof did not receive a provisional pass: {proof_id}")
    return errors


def validate(
    completion: dict[str, Any],
    evidence: dict[str, Any],
    plan_text: str,
    milestone_text: str,
    report_text: str,
    repository_hashes: dict[str, set[str]],
) -> list[str]:
    errors = validate_browser(evidence)
    if completion.get("record_id") != "BX-BH01-DECISION-PHASE-05-GO":
        errors.append("Phase 5 completion record identity changed")
    if completion.get("record_type") != "decision" or completion.get("state") != "passed":
        errors.append("Phase 5 completion is not a passed decision")
    if not COMMIT.fullmatch(completion.get("source_revision", "")):
        errors.append("Phase 5 completion lacks an exact source revision")
    if completion.get("review", {}).get("disposition") != "accepted":
        errors.append("Phase 5 completion lacks accepted owner review")
    if "Phase 6 is eligible but not authorized" not in completion.get("outcome", {}).get("summary", ""):
        errors.append("Phase 5 completion over-authorizes downstream work")
    for record in completion.get("input_hashes", []) + completion.get("output_hashes", []):
        path = record.get("path", "")
        expected = record.get("sha256", "")
        if not SHA256.fullmatch(expected) or expected not in repository_hashes.get(path, set()):
            errors.append(f"Phase 5 evidence hash drifted: {path}")
    if "- [ ]" in plan_text:
        errors.append("Phase 5 plan still contains open work")
    if "| complete — gate passed | Exercise disposable state" not in milestone_text:
        errors.append("BH-01 milestone does not record the passed Phase 5 gate")
    if not (
        re.search(r"Phase 6 is eligible but\s+not\s+authorized", milestone_text)
        or "| complete — gate passed | Prove one authenticated command" in milestone_text
    ):
        errors.append("BH-01 milestone does not preserve or record the Phase 6 boundary")
    for revision in ("cd550a9", "7fc7782", "e78113a", "f5f0ee1", "7332b2e"):
        if revision not in report_text:
            errors.append(f"Phase 5 report omits section revision {revision}")
    for boundary in (
        "all browsers remain unsupported",
        "not public BlazeX contracts",
        "No authenticated command",
        "Phase 6 is eligible but not authorized",
    ):
        if boundary not in report_text and boundary not in milestone_text:
            errors.append(f"Phase 5 report omits claim boundary: {boundary}")
    return errors


def inputs() -> tuple[Any, ...]:
    completion = load(COMPLETION)
    revision = completion.get("source_revision", "")
    records = completion.get("input_hashes", []) + completion.get("output_hashes", [])
    hashes: dict[str, set[str]] = {}
    for record in records:
        path = record["path"]
        values: set[str] = set()
        if (ROOT / path).is_file():
            values.add(file_sha256(ROOT / path))
        historical = historical_sha256(revision, path)
        if historical:
            values.add(historical)
        hashes[path] = values
    return (
        completion,
        load(EVIDENCE),
        PLAN.read_text(encoding="utf-8"),
        MILESTONE.read_text(encoding="utf-8"),
        REPORT.read_text(encoding="utf-8"),
        hashes,
    )


def main() -> int:
    errors: list[str] = []
    for command in (
        [sys.executable, str(HERE / "verify_phase4.py")],
        [sys.executable, str(ROOT / "docs/research/validate_bh01_activation.py")],
        [sys.executable, str(ROOT / "integration/fixtures/local_browser/verify_contracts.py")],
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
        errors.append("Phase 5 source revision is not an ancestor of the delivery")
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print("BH-01 Phase 5 local browser behavior and DOM gate: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
