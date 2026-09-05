#!/usr/bin/env python3
"""Validate the complete BH-01 Phase 9 measurement and conditional decision."""

from __future__ import annotations

import hashlib
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
BENCH = ROOT / "integration/benchmarks"
REPORTS = BENCH / "reports"
RAW = BENCH / "raw-evidence"
ASSETS = ROOT / "docs/research/assets/bh-01-baseline"
PLAN_DIR = ROOT / "docs/research/60-planning/01-browser-host/bh-01-reproducible-browser-feasibility-baseline"
PLAN = PLAN_DIR / "phase-09-measurement-mobile-viability-and-artifact-economics.md"
MILESTONE = PLAN_DIR / "README.md"
BROWSER_PLAN = PLAN_DIR.parent / "README.md"
REPORT_TEXT = PLAN_DIR / "phase-09-implementation-evidence.md"
AUTHORIZATION = ASSETS / "blazex-bh-01-phase-09-authorization-v0.1.0.json"
COMPLETION = ASSETS / "blazex-bh-01-phase-09-completion-v0.1.0.json"
COMPLETION_SCHEMA = ASSETS / "blazex-bh-01-evidence-record.schema.json"


def load(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def historical_hashes(path: str) -> set[str]:
    values: set[str] = set()
    current = ROOT / path
    if current.is_file():
        values.add(sha256(current))
    history = subprocess.run(["git", "log", "--format=%H", "--", path], cwd=ROOT, capture_output=True, text=True, check=False)
    for revision in history.stdout.splitlines():
        result = subprocess.run(["git", "show", f"{revision}:{path}"], cwd=ROOT, capture_output=True, check=False)
        if result.returncode == 0:
            values.add(hashlib.sha256(result.stdout).hexdigest())
    return values


def browser_samples(record: dict[str, Any]) -> int:
    return sum(len(item["samples"]) for item in record["measurements"])


def inputs() -> dict[str, Any]:
    completion = load(COMPLETION)
    referenced = completion.get("input_hashes", []) + completion.get("output_hashes", [])
    return {
        "authorization": load(AUTHORIZATION),
        "index": load(BENCH / "benchmark-index.json"),
        "definitions": load(BENCH / "phase9-metric-definitions.json"),
        "chrome": load(RAW / "bh01-phase9-chromium-linux.json"),
        "firefox": load(RAW / "bh01-phase9-firefox-linux.json"),
        "chrome_rerun1": load(RAW / "bh01-phase9-rerun-chromium-linux.json"),
        "chrome_rerun2": load(RAW / "bh01-phase9-rerun2-chromium-linux.json"),
        "firefox_rerun": load(RAW / "bh01-phase9-rerun-firefox-linux.json"),
        "summary": load(BENCH / "samples/bh01-phase9-linux-desktop-summary.json"),
        "artifacts": load(RAW / "bh01-phase9-artifacts-linux.json"),
        "economics": load(REPORTS / "bh01-phase9-artifact-economics.json"),
        "mitigations": load(REPORTS / "bh01-phase9-mitigation-assessment.json"),
        "deferrals": load(REPORTS / "bh01-phase9-deferred-qualification.json"),
        "budgets": load(REPORTS / "bh01-phase9-budget-evaluation.json"),
        "decision": load(REPORTS / "bh01-phase9-stop-decision.json"),
        "rerun_attempt": load(REPORTS / "bh01-phase9-rerun-comparison-attempt-1.json"),
        "rerun_final": load(REPORTS / "bh01-phase9-rerun-comparison.json"),
        "completion": completion,
        "plan": PLAN.read_text(encoding="utf-8"),
        "milestone": MILESTONE.read_text(encoding="utf-8"),
        "browser_plan": BROWSER_PLAN.read_text(encoding="utf-8"),
        "report": REPORT_TEXT.read_text(encoding="utf-8"),
        "repository_hashes": {record["path"]: historical_hashes(record["path"]) for record in referenced},
    }


def validate(value: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    authorization = value["authorization"]
    if authorization.get("status") != "approved-phase-9-only" or authorization.get("owner") != "repository-owner":
        errors.append("Phase 9 lacks exact repository-owner authorization")
    if not any("Phase 10" in item for item in authorization.get("not_authorized", [])):
        errors.append("Phase 9 authorization does not preserve the Phase 10 boundary")

    index = value["index"]
    if index.get("status") != "phase9-complete-conditional-proceed":
        errors.append("benchmark index does not record completed conditional Phase 9")
    if index.get("budget_state") != "phase9-active-development-evaluated-conditional-no-support-credit":
        errors.append("benchmark index overclaims budget or support state")
    if len(index.get("measurements", [])) != 7 or len(index.get("reports", [])) != 7:
        errors.append("benchmark index omits primary, rerun, or report records")

    primary_expected = {"chrome": (1303, "chromium"), "firefox": (1301, "firefox")}
    for name, (count, browser_type) in primary_expected.items():
        record = value[name]
        config = record.get("configuration", {})
        if record.get("status") != "observed" or record.get("failures") != [] or record.get("browser", {}).get("type") != browser_type:
            errors.append(f"{name} primary evidence is not a clean observed run")
        if browser_samples(record) != count or config.get("cold_start_samples") != 50 or config.get("warm_start_samples") != 50 or config.get("fallback_samples") != 30 or config.get("interaction_samples") != 100 or config.get("server_samples") != 50 or config.get("cleanup_samples") != 20:
            errors.append(f"{name} primary sample policy drifted")
        if record.get("browser", {}).get("support_status") != "unsupported":
            errors.append(f"{name} evidence claims support")
    for name, count in (("chrome_rerun1", 273), ("chrome_rerun2", 273), ("firefox_rerun", 271)):
        record = value[name]
        config = record.get("configuration", {})
        if record.get("status") != "observed" or record.get("failures") != [] or browser_samples(record) != count:
            errors.append(f"{name} representative rerun is incomplete")
        if (config.get("cold_start_samples"), config.get("warm_start_samples"), config.get("fallback_samples"), config.get("interaction_samples"), config.get("server_samples"), config.get("cleanup_samples")) != (10, 10, 10, 20, 10, 10):
            errors.append(f"{name} representative rerun policy drifted")

    manifests = {value[name].get("artifact_manifest", {}).get("sha256") for name in ("chrome", "firefox", "chrome_rerun1", "chrome_rerun2", "firefox_rerun")}
    manifests.add(value["artifacts"].get("profile_manifest", {}).get("sha256"))
    if manifests != {"818ac7b967db6519c766f9d1fff80455cc92d205e3f188252e6da27258ee4aad"}:
        errors.append("Phase 9 browser/artifact profile identity drifted")

    definitions = {item.get("id"): item for item in value["definitions"].get("metrics", [])}
    quality_budget_ids = {item["budget_id"] for item in value["budgets"].get("evaluations", [])}
    for definition in definitions.values():
        budget_ref = definition.get("budget_ref", "")
        for token in re.findall(r"BX-BUD-[A-Z0-9-]+", budget_ref):
            if token not in quality_budget_ids:
                errors.append(f"metric lacks reciprocal evaluated budget: {token}")

    summary = value["summary"]
    if summary.get("status") != "observed" or len(summary.get("measurements", [])) != 41:
        errors.append("desktop summary does not retain 41 observed distributions")
    if any(item.get("adequacy", {}).get("status") != "adequate" for item in summary.get("measurements", [])):
        errors.append("an active browser distribution is sample-inadequate")
    if any(item.get("outlier_review", {}).get("samples_excluded") != 0 for item in summary.get("measurements", [])):
        errors.append("desktop summary excludes raw samples")
    if summary.get("environment_drift", {}).get("drift_detected") is not False:
        errors.append("primary evidence identity drift is hidden")

    artifacts = value["artifacts"]
    if artifacts.get("totals", {}).get("total") != {"decoded_bytes": 7827221, "brotli_bytes": 2513184, "request_count": 23}:
        errors.append("artifact totals drifted")
    economics = value["economics"]
    if economics.get("dominant_cost", {}).get("owner_class") != "application-bundle-unpruned":
        errors.append("artifact economics hides the dominant unpruned AVM")
    if value["mitigations"].get("threshold_changes") != [] or len(value["mitigations"].get("rejected_approaches", [])) < 4:
        errors.append("mitigation review changed thresholds or omitted prohibited shortcuts")

    deferrals = value["deferrals"]
    if deferrals.get("status") != "deferred" or deferrals.get("policy", {}).get("reactivation_milestone") != "BH-22" or deferrals.get("policy", {}).get("excluded_from_active_pass_rates") is not True or len(deferrals.get("obligations", [])) != 6:
        errors.append("external qualification is not explicitly deferred to BH-22")
    if deferrals.get("phase_effect", {}).get("mobile_viability") != "undecided-deferred":
        errors.append("deferral ledger overclaims mobile viability")

    budgets = value["budgets"]
    failed = [item for item in budgets.get("evaluations", []) if item.get("status") == "fail-active-development"]
    if budgets.get("status") != "conditional-active-development" or len(budgets.get("evaluations", [])) != 52 or len(failed) != 4 or budgets.get("threshold_changes") != []:
        errors.append("budget evaluation no longer retains the conditional 52-result outcome")
    if budgets.get("quality_contract", {}).get("changed") is not False:
        errors.append("Phase 9 changed the quality contract")

    decision = value["decision"]
    if decision.get("status") != "conditional-proceed" or decision.get("decision", {}).get("support") != "unsupported":
        errors.append("Phase 9 stop decision is not conditional and unsupported")
    if decision.get("phase_10", {}).get("authorized") is not False or decision.get("phase_10", {}).get("eligibility_after_phase_9_completion") is not True:
        errors.append("Phase 9 stop decision over-authorizes or blocks Phase 10")
    if len(decision.get("active_failures", [])) != 3 or len(decision.get("required_mitigations", [])) != 3:
        errors.append("Phase 9 stop decision omits active failures or owners")

    for name in ("rerun_attempt", "rerun_final"):
        comparison = value[name]
        if comparison.get("status") != "observed-drift" or comparison.get("drift_count") != 2:
            errors.append(f"{name} does not retain observed reproducibility drift")
    attempt_metrics = {item["metric_id"] for item in value["rerun_attempt"]["comparisons"] if item["status"] == "drift"}
    final_scenarios = {item["scenario"] for item in value["rerun_final"]["comparisons"] if item["status"] == "drift"}
    if attempt_metrics != {"BX-BH01-METRIC-STARTUP-FALLBACK-READY-MS", "BX-BH01-METRIC-STARTUP-INSTANTIATE-READY-MS"}:
        errors.append("first rerun no longer retains startup drift")
    if final_scenarios != {"authorization-denial", "disconnect-retry"}:
        errors.append("second rerun no longer retains server timing drift")

    completion = value["completion"]
    if completion.get("record_id") != "BX-BH01-DECISION-PHASE-09-CONDITIONAL" or completion.get("state") != "conditional" or completion.get("review", {}).get("disposition") != "accepted":
        errors.append("Phase 9 completion is not an accepted conditional decision")
    if "Phase 10 is eligible but not authorized" not in completion.get("outcome", {}).get("summary", ""):
        errors.append("Phase 9 completion does not preserve Phase 10 authorization")
    for record in completion.get("input_hashes", []) + completion.get("output_hashes", []):
        if record.get("sha256") not in value["repository_hashes"].get(record.get("path", ""), set()):
            errors.append(f"completion evidence hash drifted: {record.get('path')}")

    if "- [ ]" in value["plan"]:
        errors.append("Phase 9 plan contains open active work")
    if "**[DEFERRED] 9.3 Section" not in value["plan"] or "BH-22" not in value["plan"]:
        errors.append("Phase 9 plan hides deferred mobile work")
    if "| complete — conditional active-Linux proceed; external qualification deferred | Measure payload" not in value["milestone"]:
        errors.append("BH-01 milestone does not record completed conditional Phase 9")
    if not any(
        text in value["milestone"]
        for text in (
            "| eligible — not authorized | Reproduce the complete baseline",
            "| complete — proceed with bounded conditions; BH-02 eligible but not authorized | Reproduce the complete baseline",
        )
    ):
        errors.append("BH-01 milestone over-authorizes or blocks Phase 10")
    if "Phase 9 is complete" not in value["browser_plan"] or not any(
        text in value["browser_plan"]
        for text in (
            "Phase 10 is eligible but not authorized",
            "BH-01 is complete with a proceed-with-bounded-conditions decision",
        )
    ):
        errors.append("browser planning index does not expose the Phase 9/10 boundary")
    normalized = " ".join(value["report"].split()).lower()
    for phrase in ("conditional proceed", "all browsers remain unsupported", "mobile viability remains undecided", "phase 10 is eligible but not authorized", "unpruned application avm", "representative rerun drift"):
        if phrase not in normalized:
            errors.append(f"Phase 9 report omits required finding: {phrase}")
    for revision in ("22dc980", "d834594", "edf2b09", "2ce8759", "04f9eb1"):
        if revision not in value["report"]:
            errors.append(f"Phase 9 report omits section revision {revision}")
    return errors


def validate_schemas() -> list[str]:
    pairs = [
        (BENCH / "measurement-run.schema.json", RAW / name)
        for name in ("bh01-phase9-chromium-linux.json", "bh01-phase9-firefox-linux.json", "bh01-phase9-rerun-chromium-linux.json", "bh01-phase9-rerun2-chromium-linux.json", "bh01-phase9-rerun-firefox-linux.json")
    ] + [
        (BENCH / "artifact-run.schema.json", RAW / "bh01-phase9-artifacts-linux.json"),
        (BENCH / "build-run.schema.json", RAW / "bh01-phase9-build-linux.json"),
        (BENCH / "desktop-summary.schema.json", BENCH / "samples/bh01-phase9-linux-desktop-summary.json"),
        (BENCH / "qualification-deferral.schema.json", REPORTS / "bh01-phase9-deferred-qualification.json"),
        (BENCH / "artifact-economics.schema.json", REPORTS / "bh01-phase9-artifact-economics.json"),
        (BENCH / "mitigation-assessment.schema.json", REPORTS / "bh01-phase9-mitigation-assessment.json"),
        (BENCH / "budget-evaluation.schema.json", REPORTS / "bh01-phase9-budget-evaluation.json"),
        (BENCH / "stop-decision.schema.json", REPORTS / "bh01-phase9-stop-decision.json"),
        (BENCH / "rerun-comparison.schema.json", REPORTS / "bh01-phase9-rerun-comparison-attempt-1.json"),
        (BENCH / "rerun-comparison.schema.json", REPORTS / "bh01-phase9-rerun-comparison.json"),
        (COMPLETION_SCHEMA, COMPLETION),
    ]
    errors = []
    for schema_path, data_path in pairs:
        for error in Draft202012Validator(load(schema_path), format_checker=FormatChecker()).iter_errors(load(data_path)):
            errors.append(f"{data_path.relative_to(ROOT)}: {error.message}")
    return errors


def regenerate() -> list[str]:
    errors: list[str] = []
    committed = {
        "summary": BENCH / "samples/bh01-phase9-linux-desktop-summary.json",
        "economics": REPORTS / "bh01-phase9-artifact-economics.json",
        "mitigations": REPORTS / "bh01-phase9-mitigation-assessment.json",
        "budgets": REPORTS / "bh01-phase9-budget-evaluation.json",
        "decision": REPORTS / "bh01-phase9-stop-decision.json",
        "rerun_attempt": REPORTS / "bh01-phase9-rerun-comparison-attempt-1.json",
        "rerun_final": REPORTS / "bh01-phase9-rerun-comparison.json",
    }
    generated_runs: list[dict[str, Path]] = []
    for repeat in (1, 2):
        directory = tempfile.TemporaryDirectory(prefix=f"blazex-phase9-verify-{repeat}-")
        temp = Path(directory.name)
        outputs = {name: temp / f"{name}.json" for name in committed}
        commands = [
            ([sys.executable, str(BENCH / "summarize_phase9.py"), "--browser", str(RAW / "bh01-phase9-chromium-linux.json"), "--browser", str(RAW / "bh01-phase9-firefox-linux.json"), "--build", str(RAW / "bh01-phase9-build-linux.json"), "--artifacts", str(RAW / "bh01-phase9-artifacts-linux.json"), "--output", str(outputs["summary"])], 0),
            ([sys.executable, str(BENCH / "analyze_phase9.py"), "--summary", str(committed["summary"]), "--artifacts", str(RAW / "bh01-phase9-artifacts-linux.json"), "--revision", load(committed["economics"])["source_revision"], "--economics-output", str(outputs["economics"]), "--mitigations-output", str(outputs["mitigations"]), "--economics-reference-path", str(committed["economics"])], 0),
            ([sys.executable, str(BENCH / "evaluate_phase9.py"), "--summary", str(committed["summary"]), "--economics", str(committed["economics"]), "--mitigations", str(committed["mitigations"]), "--deferrals", str(REPORTS / "bh01-phase9-deferred-qualification.json"), "--quality-contract", str(ROOT / "docs/research/assets/quality-acceptance/blazex-quality-contract-v0.1.0.json"), "--revision", load(committed["budgets"])["source_revision"], "--budget-output", str(outputs["budgets"]), "--decision-output", str(outputs["decision"]), "--budget-reference-path", str(committed["budgets"])], 0),
            ([sys.executable, str(BENCH / "compare_phase9_reruns.py"), "--primary", str(RAW / "bh01-phase9-chromium-linux.json"), "--rerun", str(RAW / "bh01-phase9-rerun-chromium-linux.json"), "--primary", str(RAW / "bh01-phase9-firefox-linux.json"), "--rerun", str(RAW / "bh01-phase9-rerun-firefox-linux.json"), "--revision", load(committed["rerun_attempt"])["source_revision"], "--attempt-label", "ATTEMPT-1", "--output", str(outputs["rerun_attempt"])], 1),
            ([sys.executable, str(BENCH / "compare_phase9_reruns.py"), "--primary", str(RAW / "bh01-phase9-chromium-linux.json"), "--rerun", str(RAW / "bh01-phase9-rerun2-chromium-linux.json"), "--primary", str(RAW / "bh01-phase9-firefox-linux.json"), "--rerun", str(RAW / "bh01-phase9-rerun-firefox-linux.json"), "--revision", load(committed["rerun_final"])["source_revision"], "--output", str(outputs["rerun_final"])], 1),
        ]
        for command, expected in commands:
            result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, check=False)
            if result.returncode != expected:
                errors.append(f"report regeneration failed: {Path(command[1]).name}: {result.stderr.strip() or result.stdout.strip()}")
        generated_runs.append(outputs)
        for name, path in outputs.items():
            if not path.is_file() or path.read_bytes() != committed[name].read_bytes():
                errors.append(f"generated report differs from retained {name}")
        # Keep temporary directories alive until cross-run comparison finishes.
        outputs["_temporary_directory"] = directory  # type: ignore[assignment]
    for name in committed:
        if generated_runs[0][name].read_bytes() != generated_runs[1][name].read_bytes():
            errors.append(f"report generation is not byte-deterministic: {name}")
    for run in generated_runs:
        run["_temporary_directory"].cleanup()  # type: ignore[union-attr]
    return errors


def main() -> int:
    errors: list[str] = []
    for command in (
        [sys.executable, str(HERE / "verify_phase8.py")],
        [sys.executable, str(ROOT / "profiles/browser_phoenix/assets/phase4/verify_profile.py"), "profiles/browser_phoenix/priv/static/bh01"],
    ):
        result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, check=False)
        if result.returncode:
            errors.append(f"{Path(command[1]).name}: {result.stderr.strip() or result.stdout.strip()}")
    errors.extend(validate_schemas())
    errors.extend(validate(inputs()))
    errors.extend(regenerate())
    revision = load(COMPLETION).get("source_revision", "")
    if subprocess.run(["git", "merge-base", "--is-ancestor", revision, "HEAD"], cwd=ROOT, check=False).returncode:
        errors.append("Phase 9 source revision is not an ancestor of the delivery")
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print("BH-01 Phase 9 measurement gate: CONDITIONAL PROCEED (active failures retained; external qualification deferred; Phase 10 not authorized)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
