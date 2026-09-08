#!/usr/bin/env python3
"""Current Phase 3 gate; predecessor gates reproduce immutable Git snapshots."""
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
from bh04_phase3_history import AUTH, BASE, enabled
from validate_bh04_protocol import elixir, tokens

from research_paths import REPO_ROOT as ROOT
ASSETS = "docs/research/assets/bh-04-baseline/"
INDEX = ASSETS + "blazex-bh-04-phase-03-source-index-v0.1.0.json"
COMPLETION = ASSETS + "blazex-bh-04-phase-03-completion-v0.1.0.json"
PLAN = "docs/research/60-planning/01-browser-host/bh-04-dom-renderer-and-interaction-transport/"
SOURCES = [
    "integration/bh-04/README.md",
    "integration/bh-04/support/README.md",
    "integration/bh-04/reconciliation-usage.md",
    "integration/bh-04/render-transaction-v2.schema.json",
    "integration/bh-04/reconciliation-fixtures.mjs",
    "integration/bh-04/reconciliation-fixtures-v0.1.0.txt",
    "integration/bh-04/reconciliation-protocol-fixtures-v0.1.0.txt",
    "integration/bh-04/reconciliation-protocol-results-v0.1.0.txt",
    "integration/bh-04/support/reconciliation_cases.exs",
    "integration/bh-04/support/reconciliation_runner.exs",
    "integration/bh-04/support/reconciliation_protocol_runner.exs",
    "integration/conformance/test/incremental_renderer_conformance_test.exs",
    "js/blazex_runtime/src/render-transaction-v2.js",
    "js/blazex_runtime/src/render-transaction-v2-schema.js",
    "js/blazex_runtime/src/render-intent-data.js",
    "js/blazex_runtime/test/render-transaction-v2.test.js",
    "packages/blazex_renderer_dom/lib/blazex/renderer/dom/protocol_v2.ex",
    "packages/blazex_renderer_dom/lib/blazex/renderer/dom/protocol_v2/schema.ex",
    "packages/blazex_renderer_dom/lib/blazex/renderer/dom/protocol_v2/intent_data.ex",
    "packages/blazex_renderer_dom/lib/blazex/renderer/dom/retained.ex",
    "packages/blazex_renderer_dom/lib/blazex/renderer/dom/reconciler.ex",
    "packages/blazex_renderer_dom/lib/blazex/renderer/dom/replay.ex",
    "packages/blazex_renderer_dom/lib/blazex/renderer/dom/incremental.ex",
    "packages/blazex_renderer_dom/lib/blazex/renderer/dom/reconciled_session.ex",
    "packages/blazex_renderer_dom/test/reconciler_test.exs",
    "packages/blazex_renderer_dom/test/reconciled_session_test.exs",
    "docs/research/bh04_phase3_history.py",
    "docs/research/validate_bh04_protocol.py",
    "docs/research/test_validate_bh04_protocol.py",
    "docs/research/validate_bh04_reconciliation.py",
    "docs/research/test_validate_bh04_reconciliation.py"
]
REQUIRED_GATES = {"research-tests", "governance-validators", "generators", "elixir-packages",
                  "runtime-js", "dom-js", "cross-language", "cross-renderer", "json-schema", "patch-hygiene"}

def sha(data):
    return hashlib.sha256(data).hexdigest()

def read(root, path):
    return json.loads((root / path).read_text())

def git(root, *args):
    return subprocess.check_output(["git", "-C", str(root), *args], stderr=subprocess.PIPE)

def complete_gates(gates):
    return (isinstance(gates, list) and len(gates) == len(REQUIRED_GATES)
            and all(isinstance(g, dict) and g.get("exit_code") == 0 for g in gates)
            and {g.get("name") for g in gates} == REQUIRED_GATES)

def validate(root=ROOT, completion=True):
    root, errors = Path(root), []
    def check(ok, message):
        if not ok:
            errors.append(message)
    try:
        check(enabled(root), "exact Phase 3 authority required")
        auth = read(root, AUTH)
        check(auth["base_revision"] == BASE and auth["phase"] == 3, "authority/base mismatch")
        subprocess.run(["git", "-C", str(root), "merge-base", "--is-ancestor", BASE, "HEAD"], check=True, capture_output=True)
        for path, expected in auth["source_bindings"].items():
            check(sha((root / path).read_bytes()) == expected, "stale inherited input: " + path)
        bindings = read(root, INDEX)["source_bindings"]
        check(set(bindings) == set(SOURCES), "source inventory incomplete")
        for path, expected in bindings.items():
            check(sha((root / path).read_bytes()) == expected, "source binding changed: " + path)
        prefixes = ("packages", "js", "integration", "profiles", "experiments")
        historical = set(git(root, "ls-tree", "-r", "--name-only", BASE, "--", *prefixes).decode().splitlines())
        current = set(git(root, "ls-files", "--cached", "--others", "--exclude-standard", "--", *prefixes).decode().splitlines())
        additions = {p for p in SOURCES if p.startswith(tuple(p + "/" for p in prefixes))}
        check(current == historical | additions, "unindexed executable/evidence addition")
        for path in historical - set(SOURCES):
            check((root / path).read_bytes() == git(root, "show", BASE + ":" + path), "historical source changed: " + path)
        previous = read(root, ASSETS + "blazex-bh-04-phase-02-source-index-v0.1.0.json")
        for path, expected in previous["source_bindings"].items():
            if path not in {"docs/research/validate_bh04_protocol.py", "docs/research/test_validate_bh04_protocol.py"}:
                check(sha((root / path).read_bytes()) == expected, "historical Phase 2 source changed: " + path)
        schema = read(root, "integration/bh-04/render-transaction-v2.schema.json")
        check(schema["oneOf"] == [schema["$defs"][k] for k in ("transaction", "ack", "diagnostic")], "root schema drift")
        js = (root / "js/blazex_runtime/src/render-transaction-v2-schema.js").read_text()
        check(json.loads(js.split("export const SCHEMA = ", 1)[1].rstrip(";\n")) == schema["$defs"], "JavaScript schema drift")
        ex = (root / "packages/blazex_renderer_dom/lib/blazex/renderer/dom/protocol_v2/schema.ex").read_text()
        check(tokens(ex.split("@schemas ", 1)[1].split("def schemas,", 1)[0]) == tokens(elixir(schema["$defs"])), "Elixir schema drift")
        for path in SOURCES:
            if path.startswith(("js/blazex_runtime/src/", "packages/blazex_renderer_dom/lib/")) and not path.endswith(("schema.ex", "schema.js")):
                check(not re.search(r"document\.|window\.|fetch\(|postMessage|dispatchEvent|Phoenix\.|LiveView\.|Process\.|spawn\(", (root / path).read_text()), "forbidden host/execution surface: " + path)
        fixtures = (root / "integration/bh-04/reconciliation-protocol-fixtures-v0.1.0.txt").read_text().splitlines()
        results = (root / "integration/bh-04/reconciliation-protocol-results-v0.1.0.txt").read_text().splitlines()
        traces = (root / "integration/bh-04/reconciliation-fixtures-v0.1.0.txt").read_text().splitlines()
        check(len(traces) == 50 and len(fixtures) == len(results) == 116, "fixture coverage changed")
        check(len({line.split("|")[0] for line in results}) == 116, "duplicate fixture identity")
        check(sum(line.split("|")[1] == "ok" for line in results) == 100, "positive coverage changed")
        check([line.split("|")[:2] for line in fixtures] == [line.split("|")[:2] for line in results], "fixture result mismatch")
        if completion:
            record = read(root, COMPLETION)
            check(record["phase"] == 3 and record["decision"] == "passed" and record["base_revision"] == BASE, "completion decision missing")
            check(record["next_eligible_phase"] == 4 and record["next_authorized_work"] is None and record["bh05_eligible"] is False and record["support_state"] == "unsupported" and record["api_state"] == "experimental-not-stable", "authority/support promotion")
            check(record["cross_language"] == {"traces": 50, "cases": 116, "positive": 100, "negative": 16, "agreement": "exact"}, "cross-language evidence incomplete")
            check(complete_gates(record["gates"]), "active gate failed or missing")
            expected = {AUTH, INDEX, ASSETS + "blazex-bh-04-phase-03-validation-log-v0.1.0.txt", PLAN + "phase-03-implementation-evidence.md", PLAN + "phase-03-reconciliation-contract.md"}
            check(set(record["artifact_hashes"]) == expected, "completion artifact inventory incomplete")
            for path, digest in record["artifact_hashes"].items():
                check(sha((root / path).read_bytes()) == digest, "completion artifact changed: " + path)
            check([s["section"] for s in record["section_commits"]] == ["3.1", "3.2", "3.3", "3.4"], "section provenance missing")
            for row in record["section_commits"][:3]:
                check(git(root, "show", "-s", "--format=%s", row["commit"]).decode().startswith("BH-04 " + row["section"] + " "), "section commit mismatch")
                subprocess.run(["git", "-C", str(root), "merge-base", "--is-ancestor", row["commit"], "HEAD"], check=True, capture_output=True)
            check("[ ]" not in (root / (PLAN + "phase-03-keyed-incremental-reconciliation-and-deterministic-diffing.md")).read_text(), "phase checklist incomplete")
    except (OSError, ValueError, KeyError, TypeError, IndexError, subprocess.CalledProcessError) as exc:
        errors.append("Cannot establish Phase 3 evidence: " + str(exc))
    return errors

if __name__ == "__main__":
    from bh04_phase4_history import enabled as phase4_enabled, run_phase3
    if phase4_enabled(ROOT):
        run_phase3(ROOT)
        sys.exit(0)
    errors = validate(completion="--candidate" not in sys.argv)
    if errors:
        print("\n".join(errors))
        sys.exit(1)
    print("BH-04 Phase 3 gate passed: exact history/source/schema/fixture bindings; no browser or support promotion.")
