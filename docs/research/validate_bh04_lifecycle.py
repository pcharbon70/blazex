#!/usr/bin/env python3
"""Current Phase 7 source binding, active evidence and independent replay gate."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys
from bh04_phase7_history import AUTH, BASE, enabled

ROOT = Path(__file__).resolve().parents[2]
ASSETS = "docs/research/assets/bh-04-baseline/"
INDEX = ASSETS + "blazex-bh-04-phase-07-source-index-v0.1.0.json"
BROWSERS = ASSETS + "blazex-bh-04-phase-07-browser-results-v0.1.0.json"
COMPLETION = ASSETS + "blazex-bh-04-phase-07-completion-v0.1.0.json"
GATES = {"elixir", "runtime-js", "dom-js", "active-browsers", "regression-browsers", "independent-replay", "research-tests", "validators", "generators", "boundary-json-hygiene"}
NAMES = {"semantic-effect-result", "focus-reorder-replace", "failure-apply", "failure-rollback", "failure-effect", "failure-timeout", "failure-ack", "negative-malformed", "negative-digest", "negative-stale", "negative-diff", "negative-duplicate", "negative-foreign", "negative-unsupported", "omit-result", "disposal-race", "repeated-lifecycle", "runtime-loss", "event-overload"}
def sha(data): return hashlib.sha256(data).hexdigest()
def read(root, path): return json.loads((Path(root) / path).read_text())
def git(root, *args): return subprocess.check_output(["git", "-C", str(root), *args], stderr=subprocess.PIPE)

def browser_errors(data):
    errors = []
    def check(ok, message):
        if not ok: errors.append(message)
    try:
        check(data["phase"] == 7 and data["platform"] == "linux", "phase/platform mismatch")
        check([r["browser"] for r in data["results"]] == ["chrome", "firefox"], "active matrix incomplete")
        for row in data["results"]:
            check(row["result"] == "passed" and row["support_state"] == "unsupported" and row["version"] and row["executable"], "result/support invalid")
            check(row["observation_window_ms"] == 1000, "observation window incomplete")
            check(row["counters"] == {"scenarios": 19, "roots": 24, "cleanup": 24}, "counters incomplete")
            check(len(row["traces"]) == 19 and {t["name"] for t in row["traces"]} == NAMES, "scenarios incomplete")
            check(len(row["cleanup"]) == len(row["late"]) == 24, "cleanup inventory incomplete")
            snapshots = row["late"] + [c["snapshot"] for c in row["cleanup"]]
            for s in snapshots:
                check(s["resources"]["active"] == 0 and s["resources"]["failures"] == 0 and s["queued"] == 0 and not s["busy"], "cleanup leak")
                inventory = s["inventory"]
                check(inventory["disposed"] and all(v == 0 for k, v in inventory.items() if isinstance(v, int) and not isinstance(v, bool)), "retained DOM resource")
                check(all(v == 0 for v in inventory["interaction"].values()), "retained interaction")
                f = s["failure"]
                check(f["retry_attempts"] == 0 and f["fallback_attempts"] <= 1 and len(f["diagnostics"]) <= 32 and s["max_depth"] <= 64 and s["resources"]["peak"] <= 64, "unbounded recovery")
            check(all(0 <= c["elapsed_ms"] < 1000 for c in row["cleanup"]), "cleanup deadline exceeded")
            for t in row["traces"]:
                if t["name"].startswith("failure-"):
                    check(t["elapsed_ms"] < 1000 and t["semantic"]["count"]["count"] == 0 and t["browser"]["resources"]["active"] == 0, "failure isolation/authority")
            check(all(r["method"] == "GET" for r in row["network"]), "interaction network leakage")
    except (KeyError, TypeError, ValueError): errors.append("malformed browser evidence")
    return errors

def validate(root=ROOT, completion=True):
    root = Path(root); errors = []
    def check(ok, message):
        if not ok: errors.append(message)
    try:
        check(enabled(root), "exact authority missing")
        auth = read(root, AUTH)
        check(auth["base_revision"] == BASE, "base mismatch")
        subprocess.run(["git", "-C", str(root), "merge-base", "--is-ancestor", BASE, "HEAD"], check=True, capture_output=True)
        index = read(root, INDEX)
        paths = set(index["source_bindings"])
        for path, expected in index["source_bindings"].items(): check(sha((root / path).read_bytes()) == expected, "source binding changed: " + path)
        for path, expected in auth["source_bindings"].items():
            check(sha(git(root, "show", BASE + ":" + path)) == expected, "base binding changed: " + path)
            if path not in paths: check(sha((root / path).read_bytes()) == expected, "inherited binding changed: " + path)
        prefixes = ("packages", "js", "integration", "profiles", "experiments")
        # Inspect the entire outgoing executable inventory, including untracked additions.
        changes = set(git(root, "diff", "--name-only", BASE, "--", *prefixes).decode().splitlines())
        changes.update(git(root, "ls-files", "--others", "--exclude-standard", "--", *prefixes).decode().splitlines())
        check(changes <= paths, "unindexed executable change")
        for path in changes:
            check(not path.endswith(("mix.exs", "mix.lock", "package.json", "package-lock.json", "blazex.project.json")) and not path.startswith("profiles/"), "dependency/profile drift")
        raw = (root / BROWSERS).read_bytes()
        check(sha(raw) == index["browser_sha256"], "browser evidence binding changed")
        errors.extend(browser_errors(json.loads(raw)))
        replay = subprocess.run(["node", "integration/bh-04/effect-conformance.mjs", str(root / BROWSERS)], cwd=root, capture_output=True, text=True)
        check(replay.returncode == 0, "independent replay failed")
        if replay.returncode == 0:
            check(json.loads(replay.stdout) == {"browsers": 2, "proposed": 188, "committed": 150, "delivered": 78, "results": 40, "result": "passed", "independent_replay": "exact"}, "replay inventory incomplete")
        if completion:
            record = read(root, COMPLETION)
            check(record["decision"] == "passed" and record["phase"] == 7 and record["base_revision"] == BASE, "completion invalid")
            check(record["next_eligible_phase"] == 8 and record["next_authorized_work"] is None and not record["bh05_eligible"] and record["support_state"] == "unsupported", "authority/support promotion")
            check({g["name"] for g in record["gates"]} == GATES and len(record["gates"]) == len(GATES) and all(g["exit_code"] == 0 for g in record["gates"]), "missing or failed gate")
            plan = "docs/research/60-planning/01-browser-host/bh-04-dom-renderer-and-interaction-transport/"
            expected = {AUTH, INDEX, BROWSERS, ASSETS + "blazex-bh-04-phase-07-validation-log-v0.1.0.txt", plan + "phase-07-lifecycle-contract.md", plan + "phase-07-implementation-evidence.md"}
            check(set(record["artifact_hashes"]) == expected, "completion artifact inventory incomplete")
            for path, expected in record["artifact_hashes"].items(): check(sha((root / path).read_bytes()) == expected, "completion binding changed: " + path)
            check([s["section"] for s in record["section_commits"]] == ["7.1", "7.2", "7.3", "7.4"], "section provenance missing")
            for row in record["section_commits"][:3]:
                check(git(root, "show", "-s", "--format=%s", row["commit"]).decode().startswith("BH-04 " + row["section"] + " "), "section commit mismatch")
                subprocess.run(["git", "-C", str(root), "merge-base", "--is-ancestor", row["commit"], "HEAD"], check=True, capture_output=True)
            check("[ ]" not in (root / (plan + "phase-07-effect-ordering-resources-disposal-and-failure-isolation.md")).read_text(), "phase checklist incomplete")
    except (OSError, KeyError, TypeError, ValueError, subprocess.CalledProcessError) as error: errors.append("Cannot establish Phase 7 evidence: " + str(error))
    return errors

if __name__ == "__main__":
    from bh04_phase9_history import enabled as phase9_enabled, run_phase7
    if phase9_enabled(ROOT):
        run_phase7(ROOT)
        sys.exit(0)
    errors = validate(completion="--candidate" not in sys.argv)
    if errors: print("\n".join(errors)); sys.exit(1)
    print("BH-04 Phase 7 gate passed; Phase 8 eligible but unauthorized.")
