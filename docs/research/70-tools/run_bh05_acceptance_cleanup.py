"""Execute and publish BH-05 Phase 12 cleanup, growth, and failure-gate evidence."""
import argparse
import hashlib
import json
import math
import os
import platform
import subprocess
from pathlib import Path

from research_paths import REPO_ROOT

RAW = "integration/bh-05/acceptance-cleanup-raw-v0.1.0.json"
REPORT = "integration/bh-05/acceptance-cleanup-v0.1.0.json"
IMAGE = "a2386c21edd5"


def sha(data):
    return hashlib.sha256(data).hexdigest()


def execute(command, check=True):
    return subprocess.run(
        command, cwd=REPO_ROOT, check=check, capture_output=True, text=True, timeout=900
    )


def parse_erts(output):
    cleanup, growth = [], []
    for line in output.splitlines():
        fields = line.split("\t")
        if fields[0] == "BH05_CLEANUP":
            cleanup.append({
                "sample": int(fields[1]), "elapsed_ms": int(fields[2]),
                "requested": int(fields[3]), "unresolved": int(fields[4]),
                "forced": int(fields[5]), "terminal_leases": int(fields[6]),
                "late_results": int(fields[7]),
            })
        elif fields[0] == "BH05_PROCESS":
            growth.append({
                "sample": int(fields[1]), "cycles": int(fields[2]),
                "baseline": int(fields[3]), "terminal": int(fields[4]),
                "unexpected_growth": int(fields[5]), "late_results": int(fields[6]),
            })
    if len(cleanup) != 100 or len(growth) != 10:
        raise ValueError("ERTS cleanup/process sample cardinality")
    return cleanup, growth


def parse_failure(output):
    values = {}
    for line in output.splitlines():
        marker = line.find("RECOVERY_")
        if marker >= 0:
            key, value = line[marker:].split(" ", 1)
            values[key] = value.strip()
    required = {
        "RECOVERY_FAILURE_CASES", "RECOVERY_FAILURE_SHA256",
        "RECOVERY_CLEANUP_MS", "RECOVERY_CLEANUP_SHA256",
        "RECOVERY_RESTART_COUNTS", "RECOVERY_RESTART_SHA256",
    }
    if not required.issubset(values):
        raise ValueError("failure-gate output incomplete")
    return values


def nearest_rank(values, percentile):
    return sorted(values)[math.ceil(percentile * len(values)) - 1]


def cleanup_valid(rows):
    return len(rows) == 100 and all(
        row["requested"] == 513 and row["unresolved"] == 0
        and row["terminal_leases"] == 0 and row["late_results"] == 0
        for row in rows
    ) and nearest_rank([row["elapsed_ms"] for row in rows], 0.95) <= 1000


def growth_valid(rows):
    return len(rows) == 10 and all(
        row["cycles"] == 100 and row["unexpected_growth"] == 0
        and row["terminal"] == row["baseline"] and row["late_results"] == 0
        for row in rows
    )


def browser_terminal(row):
    return [{key: item[key] for key in (
        "requested", "unresolved", "forced", "terminal_leases", "late_results"
    )} for item in row.get("cleanup", [])]


def run(args):
    if any(args.output.iterdir()) or args.output.resolve().is_relative_to(REPO_ROOT):
        raise ValueError("fresh external output required")
    docker = [
        "docker", "run", "--rm", "--network", "none", "--user",
        f"{os.getuid()}:{os.getgid()}", "-v", str(REPO_ROOT) + ":/workspace:ro",
        "-e", "MIX_BUILD_PATH=/tmp/bh05-phase12-cleanup", IMAGE,
    ]
    erts_command = docker + ["sh", "-c", "cd /workspace/integration/conformance; mix run measure_phase12_cleanup.exs"]
    failure_command = docker + ["sh", "-c", "cd /workspace/integration/conformance; mix test test/bh05_recovery_test.exs --trace"]
    erts = execute(erts_command)
    failure = execute(failure_command)
    cleanup, growth = parse_erts(erts.stdout)
    failure_values = parse_failure(failure.stdout)
    browser = json.loads(args.browser_evidence.read_text())
    browsers = browser.get("results", [])
    browser_exact = (
        [row.get("browser") for row in browsers] == ["chrome", "firefox"]
        and all(row.get("result") == "passed" for row in browsers)
        and browser_terminal(browsers[0]) == browser_terminal(browsers[1])
        and browser.get("comparison", {}).get("state") == "exact-match"
    )
    cleanup_pass = cleanup_valid(cleanup)
    growth_pass = growth_valid(growth)
    active_pass = cleanup_pass and growth_pass and browser_exact
    retained = [
        {
            "id": "terminal-guardian-growth-before-release-api",
            "state": "failed", "runtime": "ERTS", "samples": 10, "cycles_per_sample": 100,
            "observed_unexpected_growth": 100,
            "cause": "terminal LocalView guardians remained intentionally inspectable without an explicit release operation",
            "correction": "LocalView.release_terminal/2 removes only a matching terminal guardian and is idempotent after absence",
        },
        {
            "id": "browser-operation-forwarding-harness-failure",
            "state": "failed", "runtimes": ["chrome", "firefox"],
            "cause": "the selected operation was not passed into page.evaluate",
            "correction": "operation is now an explicit page.evaluate argument",
        },
        {
            "id": "firefox-cleanup-before-linear-row-accumulation",
            "state": "failed", "runtime": "firefox", "elapsed_ms": 2756,
            "requested": 513, "unresolved": 445,
            "correction": "row accumulation changed from quadratic append to constant-time prepend plus one canonical reverse",
            "disposition": "superseded by a fresh trial which remained failed; the optimization was not claimed as resolution",
        },
    ]
    raw = {
        "schema_version": "1.0.0", "phase": 12, "support_state": "unsupported",
        "environment": {"python": platform.python_version(), "elixir_image": IMAGE},
        "commands": {"erts": erts_command, "failure_gates": failure_command,
                     "browser_source": str(args.browser_evidence)},
        "erts": {"stdout_sha256": sha(erts.stdout.encode()), "cleanup": cleanup, "process_growth": growth},
        "failure_gates": {"stdout_sha256": sha(failure.stdout.encode()), "values": failure_values},
        "browser": browser, "retained_failed_trials": retained,
        "active_blockers": [] if active_pass else [{
            "id": "BH05-ACTIVE-FIREFOX-CLEANUP-DIVERGENCE", "owner": "BH-05",
            "due": "BH-05 re-entry", "blocks": ["BH-05 acceptance", "BH-06 eligibility"],
            "condition": "Firefox must release the complete 513-request inventory within the frozen cleanup deadline and match Chrome terminal state",
        }],
    }
    rendered = json.dumps(raw, indent=2) + "\n"
    p95 = nearest_rank([row["elapsed_ms"] for row in cleanup], 0.95)
    report = {
        "schema_version": "1.0.0", "phase": 12,
        "result": "passed" if active_pass else "failed", "decision": "accept" if active_pass else "revise",
        "support_state": "unsupported", "raw_sha256": sha(rendered.encode()),
        "budgets": {
            "BX-BUD-RESOURCE-CLEANUP-MS": {"statistic": "p95-nearest-rank", "samples": 100,
                "observed": p95, "threshold": 1000, "result": "passed" if cleanup_pass else "failed"},
            "BX-BUD-RESOURCE-PROCESS-GROWTH-COUNT": {"statistic": "maximum", "samples": 10,
                "cycles_per_sample": 100, "observed": max(row["unexpected_growth"] for row in growth),
                "threshold": 0, "result": "passed" if growth_pass else "failed"},
        },
        "failure_gates": {
            "BX-ACC-FAILURE-BX-FAIL-COMPONENT": {"result": "passed", "cases": int(failure_values["RECOVERY_FAILURE_CASES"])},
            "BX-ACC-FAILURE-BX-FAIL-RESOURCE-CLEANUP": {"result": "passed", "cleanup_sha256": failure_values["RECOVERY_CLEANUP_SHA256"]},
        },
        "active_runtime_gate": {"result": "passed" if browser_exact else "failed",
            "comparison": browser.get("comparison", {}).get("state"),
            "chrome": browser_terminal(browsers[0]) if len(browsers) > 0 else [],
            "firefox": browser_terminal(browsers[1]) if len(browsers) > 1 else []},
        "retained_failed_trials": len(retained),
        "active_blockers": raw["active_blockers"],
    }
    (args.output / "raw.json").write_text(rendered)
    (args.output / "report.json").write_text(json.dumps(report, indent=2) + "\n")
    print("BH-05 Phase 12 cleanup measurements: " + ("PASS" if active_pass else "REVISE"))


def publish(output):
    with (REPO_ROOT / RAW).open("x") as stream:
        stream.write((output / "raw.json").read_text())
    with (REPO_ROOT / REPORT).open("x") as stream:
        stream.write((output / "report.json").read_text())
    print("BH-05 Phase 12 cleanup evidence published")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--browser-evidence", type=Path)
    parser.add_argument("--publish", action="store_true")
    options = parser.parse_args()
    if options.publish:
        publish(options.output)
    elif not options.browser_evidence:
        parser.error("--browser-evidence is required for measurement")
    else:
        run(options)
