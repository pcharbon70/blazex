"""Execute and publish the frozen BH-05 Phase 13 cleanup scaling matrix."""
import argparse
import hashlib
import json
import os
import platform
import subprocess
from pathlib import Path

from research_paths import REPO_ROOT
from validate_bh05_cleanup_scaling import (
    RAW,
    REPORT,
    PHASE12_RAW_SHA256,
    compute_shape_alarms,
    digest,
    validate_raw,
    validate_report,
)

IMAGE = "a2386c21edd5"
PHASE12_RAW = "integration/bh-05/acceptance-cleanup-raw-v0.1.0.json"
PHASE13_ATTEMPTS = "integration/bh-05/cleanup-scaling-attempts-v0.1.0.json"


def execute(command, check=True, timeout=1200):
    return subprocess.run(
        command,
        cwd=REPO_ROOT,
        check=check,
        capture_output=True,
        text=True,
        timeout=timeout,
    )


def sha(data):
    return hashlib.sha256(data).hexdigest()


def parse_erts(output):
    rows = [line.split("\t", 1)[1] for line in output.splitlines() if line.startswith("BH05_PHASE13_JSON\t")]
    if len(rows) != 1:
        raise ValueError("ERTS Phase 13 output cardinality")
    return json.loads(rows[0])


def source_tree_sha256():
    paths = [
        "packages/blazex_core/lib/blazex/component/recovery_cleanup.ex",
        "packages/blazex_core/lib/blazex/component/recovery_port.ex",
        "packages/blazex_core/lib/blazex/component/action_ledger.ex",
        "packages/blazex_core/lib/blazex/component/root_port.ex",
        "packages/blazex_effects/lib/blazex/effects/action_bridge.ex",
        "integration/bh-05/browser_conformance/lib/acceptance_cleanup.ex",
        "integration/bh-05/browser_conformance/lib/cleanup_scaling.ex",
        "integration/bh-05/browser_conformance/lib/browser.ex",
        "integration/bh-05/browser_conformance/run-acceptance-counts.mjs",
        "integration/conformance/measure_phase13_cleanup.exs",
        PHASE13_ATTEMPTS,
    ]
    value = hashlib.sha256()
    for path in paths:
        value.update(path.encode() + b"\0")
        value.update((REPO_ROOT / path).read_bytes())
    return value.hexdigest()


def add_identity(sample, runtime):
    value = dict(sample)
    value["runtime"] = runtime
    value["raw_sha256"] = digest(value)
    return value


def run(args):
    if any(args.output.iterdir()) or args.output.resolve().is_relative_to(REPO_ROOT):
        raise ValueError("fresh external output required")

    docker = [
        "docker", "run", "--rm", "--network", "none", "--user",
        f"{os.getuid()}:{os.getgid()}", "-v", str(REPO_ROOT) + ":/workspace:ro",
        "-v", str(args.output) + ":/output", "-e",
        "MIX_BUILD_PATH=/tmp/bh05-phase13", IMAGE,
    ]
    build_command = docker + [
        "sh", "-c",
        "cd /workspace/integration/bh-05/browser_conformance; MIX_ENV=prod mix format --check-formatted; MIX_ENV=prod mix bh05.browser_package --out-dir /output/bundle",
    ]
    erts_command = docker + [
        "sh", "-c",
        "cd /workspace/integration/conformance; mix run measure_phase13_cleanup.exs",
    ]
    execute(build_command)
    erts_run = execute(erts_command)
    erts = parse_erts(erts_run.stdout)

    scale_path = args.output / "browser-scaling.json"
    repeat_path = args.output / "browser-phase12-repeat.json"
    bundle = args.output / "bundle" / "bundle.avm"
    browser_scale_command = [
        "node", "integration/bh-05/browser_conformance/run-acceptance-counts.mjs",
        str(scale_path), str(bundle), "measure-cleanup-scaling",
    ]
    browser_repeat_command = [
        "node", "integration/bh-05/browser_conformance/run-acceptance-counts.mjs",
        str(repeat_path), str(bundle), "measure-cleanup",
    ]
    scale_run = execute(browser_scale_command, check=False)
    repeat_run = execute(browser_repeat_command, check=False)
    browser_scale = json.loads(scale_path.read_text())
    browser_repeat = json.loads(repeat_path.read_text())

    samples = [add_identity(row, "erts") for row in erts["scaling"]["samples"]]
    for browser in browser_scale.get("results", []):
        samples.extend(
            add_identity(row, browser["browser"])
            for row in (browser.get("samples") or [])
        )

    alarms = compute_shape_alarms(samples)
    phase12 = json.loads((REPO_ROOT / PHASE12_RAW).read_text())
    phase13_attempts = json.loads((REPO_ROOT / PHASE13_ATTEMPTS).read_text())
    retained_failures = phase12["retained_failed_trials"] + phase13_attempts["attempts"]
    repeat_rows = browser_repeat.get("results", [])
    repeat_pass = (
        repeat_run.returncode == 0
        and browser_repeat.get("comparison", {}).get("state") == "exact-match"
        and all(row.get("acceptance_state") == "passed" for row in repeat_rows)
        and erts["phase12_fixture_repeat"]["acceptance_state"] == "passed"
        and all(
            sample["unexpected_growth"] == 0
            for sample in erts["phase12_fixture_repeat"]["process_growth"]
        )
    )
    sample_pass = all(row["acceptance_state"] == "passed" for row in samples)
    matrix_complete = (
        len(browser_scale.get("results", [])) == 2
        and scale_run.returncode == 0
        and all(browser.get("samples") for browser in browser_scale["results"])
    )
    accepted = sample_pass and not alarms and repeat_pass and matrix_complete
    bundle_hash = browser_scale["runtime"]["bundle_sha256"]

    raw = {
        "schema_version": "1.0.0",
        "phase": 13,
        "support_state": "unsupported",
        "execution_state": "executed",
        "acceptance_state": "passed" if accepted else "failed",
        "environment": {
            "source_revision": execute(["git", "rev-parse", "HEAD"]).stdout.strip(),
            "source_tree_sha256": source_tree_sha256(),
            "python": platform.python_version(),
            "node": execute(["node", "--version"]).stdout.strip(),
            "elixir_image": IMAGE,
            "browser_artifacts": {
                "atomvm_wasm_sha256": browser_scale["runtime"]["atomvm_wasm_sha256"],
                "bundle_sha256": {"chrome": bundle_hash, "firefox": bundle_hash},
                "versions": {row["browser"]: row["version"] for row in browser_scale["results"]},
            },
        },
        "contract": {"deadline_ms": 1000, "page_size": 64, "maximum_page_size": 128, "fixture_count": 512},
        "phase12_raw_sha256": PHASE12_RAW_SHA256,
        "retained_failed_trials": retained_failures,
        "samples": samples,
        "shape": {"method": "theil-sen", "absolute_alarm_ms": 100, "relative_alarm": 0.5, "minimum_count": 64, "alarms": alarms},
        "phase12_fixture_repeat": {
            "erts": erts["phase12_fixture_repeat"],
            "browser": browser_repeat,
            "passed": repeat_pass,
        },
        "commands": {
            "build": build_command,
            "erts": erts_command,
            "browser_scaling": browser_scale_command,
            "browser_phase12_repeat": browser_repeat_command,
        },
        "command_outputs": {
            "erts_stdout_sha256": sha(erts_run.stdout.encode()),
            "browser_scaling_exit": scale_run.returncode,
            "browser_scaling_stdout_sha256": sha(scale_run.stdout.encode()),
            "browser_repeat_exit": repeat_run.returncode,
            "browser_repeat_stdout_sha256": sha(repeat_run.stdout.encode()),
        },
    }
    errors = validate_raw(raw)
    if errors:
        raw["acceptance_state"] = "failed"
    rendered = json.dumps(raw, indent=2) + "\n"
    report = {
        "schema_version": "1.0.0",
        "phase": 13,
        "support_state": "unsupported",
        "execution_state": "executed",
        "acceptance_state": "passed" if not errors and accepted else "failed",
        "result": "passed" if not errors and accepted else "failed",
        "raw_sha256": sha(rendered.encode()),
        "sample_count": len(samples),
        "shape_alarms": len(alarms),
        "phase12_fixture_repeat": "passed" if repeat_pass else "failed",
        "validation_errors": errors,
    }
    report_errors = validate_report(report, rendered.encode(), raw)
    if report_errors:
        report["acceptance_state"] = "failed"
        report["result"] = "failed"
        report["validation_errors"] = errors + report_errors
    (args.output / "raw.json").write_text(rendered)
    (args.output / "report.json").write_text(json.dumps(report, indent=2) + "\n")
    print("BH-05 Phase 13 cleanup scaling: " + report["acceptance_state"].upper())


def publish(output):
    with (REPO_ROOT / RAW).open("x") as stream:
        stream.write((output / "raw.json").read_text())
    with (REPO_ROOT / REPORT).open("x") as stream:
        stream.write((output / "report.json").read_text())
    print("BH-05 Phase 13 cleanup scaling evidence published")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--publish", action="store_true")
    options = parser.parse_args()
    publish(options.output) if options.publish else run(options)
