#!/usr/bin/env python3
"""Phase 5 current-source, immutable-history and active browser evidence gate."""
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
from bh04_phase5_history import AUTH, BASE, enabled

from research_paths import REPO_ROOT as ROOT
ASSETS = "docs/research/assets/bh-04-baseline/"
PLAN = "docs/research/60-planning/01-browser-host/bh-04-dom-renderer-and-interaction-transport/"
INDEX = ASSETS + "blazex-bh-04-phase-05-source-index-v0.1.0.json"
BROWSERS = ASSETS + "blazex-bh-04-phase-05-browser-results-v0.1.0.json"
COMPLETION = ASSETS + "blazex-bh-04-phase-05-completion-v0.1.0.json"
SOURCES = [
    "js/blazex_runtime/src/interaction-record.js",
    "js/blazex_runtime/src/interaction-listeners.js",
    "js/blazex_runtime/src/interaction-stream.js",
    "js/blazex_runtime/src/atomic-dom.js",
    "js/blazex_runtime/test/interaction-listeners.test.js",
    "js/blazex_runtime/test/interaction-stream.test.js",
    "packages/blazex_renderer_dom/lib/blazex/renderer/dom/interaction_session.ex",
    "packages/blazex_renderer_dom/test/interaction_session_test.exs",
    "integration/bh-04/interaction-browser.mjs",
    "integration/bh-04/interaction-scenarios.js",
    "integration/bh-04/interaction-conformance.mjs",
    "integration/bh-04/support/interaction_counter.exs",
    "integration/bh-04/support/interaction_runtime.exs",
    "integration/bh-04/interaction-usage.md",
    "integration/bh-04/README.md",
    "integration/bh-04/support/README.md",
    "docs/research/bh04_phase5_history.py",
    "docs/research/validate_bh04_dom_application.py",
    "docs/research/test_validate_bh04_dom_application.py",
    "docs/research/validate_bh04_interactions.py",
    "docs/research/test_validate_bh04_interactions.py"
]
REQUIRED_GATES = {"research-tests", "governance-validators", "generators", "elixir-packages", "runtime-js", "dom-js", "cross-language", "cross-renderer", "json-schema", "patch-hygiene", "active-browsers", "boundary-audit"}
def sha(data):
    return hashlib.sha256(data).hexdigest()
def read(root, path):
    return json.loads((Path(root) / path).read_text())
def git(root, *args):
    return subprocess.check_output(["git", "-C", str(root), *args], stderr=subprocess.PIPE)
def complete_gates(gates):
    return isinstance(gates, list) and len(gates) == len(REQUIRED_GATES) and all(isinstance(g, dict) and g.get("exit_code") == 0 for g in gates) and {g.get("name") for g in gates} == REQUIRED_GATES

def validate(root=ROOT, completion=True):
    root, errors = Path(root), []
    def check(ok, message):
        if not ok:
            errors.append(message)
    try:
        check(enabled(root), "exact Phase 5 authority required")
        auth = read(root, AUTH)
        check(auth["base_revision"] == BASE and auth["phase"] == 5, "authority/base/queue mismatch")
        subprocess.run(["git", "-C", str(root), "merge-base", "--is-ancestor", BASE, "HEAD"], check=True, capture_output=True)
        for path, expected in auth["source_bindings"].items():
            check(sha(git(root, "show", BASE + ":" + path)) == expected, "accepted base binding changed: " + path)
            if path not in SOURCES:
                check(sha((root / path).read_bytes()) == expected, "inherited source changed: " + path)
        index = read(root, INDEX)
        check(set(index["source_bindings"]) == set(SOURCES), "source inventory incomplete")
        for path, expected in index["source_bindings"].items():
            check(sha((root / path).read_bytes()) == expected, "source binding changed: " + path)
        prefixes = ("packages", "js", "integration", "profiles", "experiments")
        historical = set(git(root, "ls-tree", "-r", "--name-only", BASE, "--", *prefixes).decode().splitlines())
        current = set(git(root, "ls-files", "--cached", "--others", "--exclude-standard", "--", *prefixes).decode().splitlines())
        additions = {p for p in SOURCES if p.startswith(tuple(p + "/" for p in prefixes))}
        check(current == historical | additions, "unindexed executable/evidence addition")
        for path in historical - set(SOURCES):
            check((root / path).read_bytes() == git(root, "show", BASE + ":" + path), "historical source changed: " + path)
        previous = read(root, ASSETS + "blazex-bh-04-phase-04-source-index-v0.1.0.json")
        for path, expected in previous["source_bindings"].items():
            if path not in set(SOURCES):
                check(sha((root / path).read_bytes()) == expected, "historical Phase 4 source changed: " + path)
        for path in SOURCES[:3]:
            check(not re.search(r"innerHTML|outerHTML|eval\(|new Function|fetch\(|postMessage|dispatchEvent|querySelector|Phoenix\.|LiveView\.", (root / path).read_text()), "forbidden application surface: " + path)
        browser_bytes = (root / BROWSERS).read_bytes()
        check(sha(browser_bytes) == index["browser_sha256"], "browser evidence changed")
        results = json.loads(browser_bytes)["results"]
        check([r["browser"] for r in results] == ["chrome", "firefox"], "active browser matrix incomplete")
        check(json.loads(browser_bytes)["platform"] == "linux", "active platform mismatch")
        for result in results:
            check(result["result"] == "passed" and result["support_state"] == "unsupported" and result["version"] and result["executable"], "browser result/support invalid")
            counters, traces = result["counters"], result["traces"]
            check(counters == {"mappings": 13, "rejected": 17, "roots": 3, "dom_commits": 18, "cleanup": 3, "max_queue": 64, "trusted_clicks": 1, "no_render_events": 2}, "browser counters incomplete")
            mapped = [t for t in traces if t.get("semantic")]
            check({t["semantic"] for t in mapped} == {"activate", "change", "submit", "select", "expand", "dismiss", "move", "reorder", "increment", "decrement", "request_open", "request_close", "request_page"} and len(mapped) == 13 and all(t["default_prevented"] for t in mapped), "mapping evidence incomplete")
            check(all(item["method"] == "GET" for item in result["network"]), "local interaction network traffic")
            check(all(pair.get("request") is not None and pair.get("response") is not None for pair in result["runtime"]), "runtime trace incomplete")
            check(len(result["runtime"]) == 75, "runtime trace count incomplete")
            check(len(result["listener_cleanup"]) == 3 and all(r["listeners"] == 0 and r["disposed"] for r in result["listener_cleanup"]), "listener cleanup incomplete")
            check(len(result["stream_cleanup"]) == 3 and all(r["queued"] == 0 and r["disposed"] for r in result["stream_cleanup"]), "stream cleanup incomplete")
        if completion:
            record = read(root, COMPLETION)
            check(record["phase"] == 5 and record["decision"] == "passed" and record["base_revision"] == BASE, "completion decision missing")
            check(record["next_eligible_phase"] == 6 and record["next_authorized_work"] is None and record["bh05_eligible"] is False and record["support_state"] == "unsupported", "authority/support promotion")
            check(complete_gates(record["gates"]), "active gate failed or missing")
            expected = {AUTH, INDEX, BROWSERS, ASSETS + "blazex-bh-04-phase-05-validation-log-v0.1.0.txt", PLAN + "phase-05-implementation-evidence.md", PLAN + "phase-05-interaction-contract.md"}
            check(set(record["artifact_hashes"]) == expected, "completion artifact inventory incomplete")
            for path, expected in record["artifact_hashes"].items():
                check(sha((root / path).read_bytes()) == expected, "completion artifact changed: " + path)
            check([s["section"] for s in record["section_commits"]] == ["5.1", "5.2", "5.3", "5.4"], "section provenance missing")
            for row in record["section_commits"][:3]:
                check(git(root, "show", "-s", "--format=%s", row["commit"]).decode().startswith("BH-04 " + row["section"] + " "), "section commit mismatch")
                subprocess.run(["git", "-C", str(root), "merge-base", "--is-ancestor", row["commit"], "HEAD"], check=True, capture_output=True)
            check("[ ]" not in (root / (PLAN + "phase-05-semantic-event-normalization-and-interaction-transport.md")).read_text(), "phase checklist incomplete")
    except (OSError, ValueError, KeyError, TypeError, IndexError, subprocess.CalledProcessError) as exc:
        errors.append("Cannot establish Phase 5 evidence: " + str(exc))
    return errors

if __name__ == "__main__":
    from bh04_phase6_history import enabled as phase6_enabled, run_phase5
    if phase6_enabled(ROOT):
        run_phase5(ROOT)
        sys.exit(0)
    errors = validate(completion="--candidate" not in sys.argv)
    if errors:
        print("\n".join(errors)); sys.exit(1)
    print("BH-04 Phase 5 gate passed; Phase 6 eligible but unauthorized.")
