"""Execute and publish BH-05 Phase 12 count-budget measurements."""
import argparse
import hashlib
import json
import os
import platform
import subprocess
from pathlib import Path

from research_paths import REPO_ROOT

RAW = "integration/bh-05/acceptance-counts-raw-v0.1.0.json"
REPORT = "integration/bh-05/acceptance-counts-v0.1.0.json"
IMAGE = "a2386c21edd5"


def sha(data):
    return hashlib.sha256(data).hexdigest()


def execute(command, cwd=REPO_ROOT):
    return subprocess.run(command, cwd=cwd, check=True, capture_output=True, text=True, timeout=900)


def parse_erts(output):
    rows = []
    for line in output.splitlines():
        if not line.startswith("BH05_COUNT\t"):
            continue
        fields = line.split("\t")
        rows.append({
            "sample": int(fields[1]),
            "event_backlog": {"maximum": int(fields[2]), "rejected": int(fields[3])},
            "pending_effects": {"maximum": int(fields[4]), "rejected": int(fields[5])},
            "resource_leases": {"maximum": int(fields[6]), "released": int(fields[7]), "terminal": int(fields[8])},
            "restart_intensity": {"maximum": int(fields[9]), "terminal": fields[10], "replayed": int(fields[11])},
        })
    if len(rows) != 20:
        raise ValueError("ERTS count sample cardinality")
    return rows


def valid(rows):
    return all(
        row["event_backlog"] == {"maximum": 256, "rejected": 1}
        and row["pending_effects"] == {"maximum": 128, "rejected": 1}
        and row["resource_leases"] == {"maximum": 512, "released": 512, "terminal": 0}
        and row["restart_intensity"] == {"maximum": 3, "terminal": "restart_intensity", "replayed": 0}
        for row in rows
    )


def run(args):
    if any(args.output.iterdir()) or args.output.resolve().is_relative_to(REPO_ROOT):
        raise ValueError("fresh external output required")
    bundle = args.output / "bundle"
    docker = [
        "docker", "run", "--rm", "--network", "none", "--user", f"{os.getuid()}:{os.getgid()}",
        "-v", str(REPO_ROOT) + ":/workspace:ro", "-v", str(args.output) + ":/output",
        "-e", "MIX_BUILD_PATH=/tmp/bh05-phase12", IMAGE,
    ]
    build_command = docker + ["sh", "-c", "cd /workspace/integration/bh-05/browser_conformance; MIX_ENV=prod mix format --check-formatted; MIX_ENV=prod mix bh05.browser_package --out-dir /output/bundle"]
    erts_command = docker + ["sh", "-c", "cd /workspace/integration/conformance; mix run measure_phase12_counts.exs"]
    build = execute(build_command)
    erts = execute(erts_command)
    browser_path = args.output / "browser.json"
    browser_command = ["node", "integration/bh-05/browser_conformance/run-acceptance-counts.mjs", str(browser_path), str(bundle / "bundle.avm")]
    execute(browser_command)
    browser = json.loads(browser_path.read_text())
    rows = parse_erts(erts.stdout)
    browser_rows = browser.get("results", [])
    browser_ok = (
        len(browser_rows) == 2
        and browser.get("comparison", {}).get("state") == "exact-match"
        and all(row.get("result") == "passed" and len(row.get("samples", [])) == 1 for row in browser_rows)
    )
    if not valid(rows) or not browser_ok:
        raise ValueError("active count measurement failed")
    trials = [json.loads(path.read_text()) for path in args.failed_trial]
    raw = {
        "schema_version": "1.0.0",
        "phase": 12,
        "support_state": "unsupported",
        "environment": {"python": platform.python_version(), "elixir_image": IMAGE, "node": execute(["node", "--version"]).stdout.strip()},
        "commands": {"build": build_command, "erts": erts_command, "browser": browser_command},
        "erts": {"stdout_sha256": sha(erts.stdout.encode()), "samples": rows},
        "browser": browser,
        "retained_failed_trials": trials,
        "deferred_bh22": ["Windows", "macOS", "Safari/WebKit product", "Android/iOS devices", "manual assistive-technology pairings"],
    }
    rendered = json.dumps(raw, indent=2) + "\n"
    report = {
        "schema_version": "1.0.0",
        "phase": 12,
        "result": "passed",
        "support_state": "unsupported",
        "raw_sha256": sha(rendered.encode()),
        "erts_samples_per_budget": 20,
        "browser_observations": {"chrome": 1, "firefox": 1, "comparison": "exact-match", "sha256": browser["comparison"]["sha256"]},
        "budgets": {
            "BX-BUD-RELIABILITY-EVENT-BACKLOG-COUNT": {"statistic": "maximum", "observed": 256, "threshold": 256, "result": "passed"},
            "BX-BUD-RELIABILITY-PENDING-EFFECTS-COUNT": {"statistic": "maximum", "observed": 128, "threshold": 128, "result": "passed"},
            "BX-BUD-RELIABILITY-RESOURCE-COUNT": {"statistic": "maximum", "observed": 512, "threshold": 512, "terminal": 0, "result": "passed"},
            "BX-BUD-RELIABILITY-RESTART-INTENSITY": {"statistic": "maximum", "observed": 3, "threshold": 3, "window_ms": 5000, "replayed": 0, "result": "passed"},
        },
        "failed_trials_retained": len(trials),
        "differences": [],
    }
    (args.output / "raw.json").write_text(rendered)
    (args.output / "report.json").write_text(json.dumps(report, indent=2) + "\n")
    print("BH-05 Phase 12 count measurements: PASS")


def publish(output):
    with (REPO_ROOT / RAW).open("x") as stream:
        stream.write((output / "raw.json").read_text())
    with (REPO_ROOT / REPORT).open("x") as stream:
        stream.write((output / "report.json").read_text())
    print("BH-05 Phase 12 count evidence published")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--failed-trial", type=Path, action="append", default=[])
    parser.add_argument("--publish", action="store_true")
    args = parser.parse_args()
    publish(args.output) if args.publish else run(args)
