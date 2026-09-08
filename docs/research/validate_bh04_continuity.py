#!/usr/bin/env python3
"""Phase 6 current-source, immutable-history and active browser evidence gate."""
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
from bh04_phase6_history import AUTH, BASE, enabled

ROOT = Path(__file__).resolve().parents[2]
ASSETS = "docs/research/assets/bh-04-baseline/"
PLAN = "docs/research/60-planning/01-browser-host/bh-04-dom-renderer-and-interaction-transport/"
INDEX = ASSETS + "blazex-bh-04-phase-06-source-index-v0.1.0.json"
BROWSERS = ASSETS + "blazex-bh-04-phase-06-browser-results-v0.1.0.json"
COMPLETION = ASSETS + "blazex-bh-04-phase-06-completion-v0.1.0.json"
SOURCES = [
    "js/blazex_runtime/src/continuity-wire.js",
    "js/blazex_runtime/src/form-continuity.js",
    "js/blazex_runtime/src/focus-continuity.js",
    "js/blazex_runtime/src/atomic-dom.js",
    "js/blazex_runtime/src/dom-root-queue.js",
    "js/blazex_runtime/src/interaction-listeners.js",
    "js/blazex_runtime/src/interaction-stream.js",
    "js/blazex_runtime/test/form-continuity.test.js",
    "js/blazex_runtime/test/focus-continuity.test.js",
    "packages/blazex_ui_tree/lib/blazex/ui_tree/form_state.ex",
    "packages/blazex_ui_tree/lib/blazex/ui_tree/form_output.ex",
    "packages/blazex_ui_tree/lib/blazex/ui_tree/form_evaluator.ex",
    "packages/blazex_ui_tree/test/form_state_test.exs",
    "packages/blazex_renderer_dom/lib/blazex/renderer/dom/continuity_session.ex",
    "packages/blazex_renderer_dom/lib/blazex/renderer/dom/continuity_renderer.ex",
    "packages/blazex_renderer_dom/test/continuity_session_test.exs",
    "integration/bh-04/continuity-browser.mjs",
    "integration/bh-04/continuity-conformance.mjs",
    "integration/bh-04/continuity-scenarios.js",
    "integration/bh-04/continuity-usage.md",
    "integration/bh-04/support/continuity_component.exs",
    "integration/bh-04/support/continuity_runtime.exs",
    "integration/bh-04/README.md",
    "integration/bh-04/support/README.md",
    "docs/research/bh04_phase6_history.py",
    "docs/research/validate_bh04_interactions.py",
    "docs/research/test_validate_bh04_interactions.py",
    "docs/research/validate_bh04_continuity.py",
    "docs/research/test_validate_bh04_continuity.py"
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
        check(enabled(root), "exact Phase 6 authority required")
        auth = read(root, AUTH)
        check(auth["base_revision"] == BASE and auth["phase"] == 6, "authority/base/queue mismatch")
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
        previous = read(root, ASSETS + "blazex-bh-04-phase-05-source-index-v0.1.0.json")
        for path, expected in previous["source_bindings"].items():
            if path not in set(SOURCES):
                check(sha((root / path).read_bytes()) == expected, "historical Phase 5 source changed: " + path)
        for path in SOURCES[:3]:
            check(not re.search(r"innerHTML|outerHTML|eval\(|new Function|fetch\(|postMessage|dispatchEvent|querySelector|Phoenix\.|LiveView\.", (root / path).read_text()), "forbidden application surface: " + path)
        browser_bytes = (root / BROWSERS).read_bytes()
        check(sha(browser_bytes) == index["browser_sha256"], "browser evidence changed")
        results = json.loads(browser_bytes)["results"]
        check([r["browser"] for r in results] == ["chrome", "firefox"], "active browser matrix incomplete")
        check(json.loads(browser_bytes)["platform"] == "linux", "active platform mismatch")
        for result in results:
            check(result["result"] == "passed" and result["support_state"] == "unsupported" and result["version"] and result["executable"], "browser result/support invalid")
            check(result["counters"] == {"scenarios": 16, "roots": 2, "cleanup": 2}, "browser counters incomplete")
            traces = result["traces"]
            names = {"typed", "keyed-move", "redundant-value", "explicit-range", "pending-edit", "composition", "keyboard-submit", "checkbox-validation", "multiple-selection", "single-selection", "focus-authority", "remove-replace-disabled", "negative-manifests", "file-policy", "rollback", "cleanup"}
            check(len(traces) == 16 and {t["name"] for t in traces} == names, "scenario evidence incomplete")
            check(len(result["cleanup"]) == 2 and all(c == {"controls": 0, "composing": 0, "listeners": 0, "disposed": True} for c in result["cleanup"]), "cleanup incomplete")
            check(result["network"] and all(item["method"] == "GET" for item in result["network"]), "local interaction network traffic")
            named = {t["name"]: t for t in traces}
            check(named["redundant-value"]["writes"] == 0 and named["file-policy"]["delivered"] == 0 and named["negative-manifests"]["no_mutation"], "privacy/continuity evidence failed")
        replay = subprocess.run(["node", "integration/bh-04/continuity-conformance.mjs", str(root / BROWSERS)], cwd=root, text=True, capture_output=True)
        check(replay.returncode == 0, "independent replay failed")
        if replay.returncode == 0:
            check(json.loads(replay.stdout) == {"browsers": 2, "proposed": 66, "committed": 64, "delivered": 22, "result": "passed", "independent_replay": "exact"}, "replay counters incomplete")
        if completion:
            record = read(root, COMPLETION)
            check(record["phase"] == 6 and record["decision"] == "passed" and record["base_revision"] == BASE, "completion decision missing")
            check(record["next_eligible_phase"] == 7 and record["next_authorized_work"] is None and record["bh05_eligible"] is False and record["support_state"] == "unsupported", "authority/support promotion")
            check(complete_gates(record["gates"]), "active gate failed or missing")
            expected = {AUTH, INDEX, BROWSERS, ASSETS + "blazex-bh-04-phase-06-validation-log-v0.1.0.txt", PLAN + "phase-06-implementation-evidence.md", PLAN + "phase-06-continuity-contract.md"}
            check(set(record["artifact_hashes"]) == expected, "completion artifact inventory incomplete")
            for path, expected in record["artifact_hashes"].items():
                check(sha((root / path).read_bytes()) == expected, "completion artifact changed: " + path)
            check([s["section"] for s in record["section_commits"]] == ["6.1", "6.2", "6.3", "6.4"], "section provenance missing")
            for row in record["section_commits"][:3]:
                check(git(root, "show", "-s", "--format=%s", row["commit"]).decode().startswith("BH-04 " + row["section"] + " "), "section commit mismatch")
                subprocess.run(["git", "-C", str(root), "merge-base", "--is-ancestor", row["commit"], "HEAD"], check=True, capture_output=True)
            check("[ ]" not in (root / (PLAN + "phase-06-form-value-focus-and-selection-continuity.md")).read_text(), "phase checklist incomplete")
    except (OSError, ValueError, KeyError, TypeError, IndexError, subprocess.CalledProcessError) as exc:
        errors.append("Cannot establish Phase 6 evidence: " + str(exc))
    return errors

if __name__ == "__main__":
    from bh04_phase7_history import enabled as phase7_enabled, run_phase6
    if phase7_enabled(ROOT):
        run_phase6(ROOT)
        sys.exit(0)
    errors = validate(completion="--candidate" not in sys.argv)
    if errors:
        print("\n".join(errors)); sys.exit(1)
    print("BH-04 Phase 6 gate passed; Phase 7 eligible but unauthorized.")
