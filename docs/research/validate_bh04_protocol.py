#!/usr/bin/env python3
"""Validate current BH-04 Phase 2 scope, provenance and protocol evidence."""
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

from bh04_history import AUTH, AUTH_SHA256, BASE, enabled
from validate_bh04_activation import PINS

ROOT = Path(__file__).resolve().parents[2]
ASSETS = "docs/research/assets/bh-04-baseline/"
INDEX = ASSETS + "blazex-bh-04-phase-02-source-index-v0.1.0.json"
COMPLETION = ASSETS + "blazex-bh-04-phase-02-completion-v0.1.0.json"
SOURCES = [
    "integration/bh-04/render-transaction.schema.json",
    "integration/bh-04/protocol-inventory-v0.1.0.json",
    "integration/bh-04/protocol-cases.mjs",
    "integration/bh-04/protocol-fixtures.mjs",
    "integration/bh-04/protocol-fixtures-v0.1.0.txt",
    "integration/bh-04/protocol-results-v0.1.0.txt",
    "integration/bh-04/support/protocol_runner.exs",
    "js/blazex_runtime/src/render-transaction-codec.js",
    "js/blazex_runtime/src/render-transaction-schema.js",
    "js/blazex_runtime/src/render-transaction.js",
    "js/blazex_runtime/test/render-transaction.test.js",
    "packages/blazex_renderer_dom/lib/blazex/renderer/dom/protocol.ex",
    "packages/blazex_renderer_dom/lib/blazex/renderer/dom/protocol/codec.ex",
    "packages/blazex_renderer_dom/lib/blazex/renderer/dom/protocol/schema.ex",
    "packages/blazex_renderer_dom/test/protocol_test.exs",
    "docs/research/bh04_history.py",
    "docs/research/validate_bh04_activation.py",
    "docs/research/test_validate_bh04_activation.py",
    "docs/research/validate_bh04_protocol.py",
    "docs/research/test_validate_bh04_protocol.py"
]
BEHAVIORS = ["browser", "measurement", "reconciliation", "dom_application", "event_transport", "liveview_adapter"]


def sha(data):
    return hashlib.sha256(data).hexdigest()


def read(root, path):
    return json.loads((root / path).read_text())


def git(root, *args):
    return subprocess.check_output(["git", "-C", str(root), *args], stderr=subprocess.PIPE)


def elixir(value):
    if value is None:
        return "nil"
    if isinstance(value, bool):
        return str(value).lower()
    if isinstance(value, (str, int)):
        return json.dumps(value, ensure_ascii=False).replace("#{", r"\#{")
    if isinstance(value, list):
        return "[" + ", ".join(map(elixir, value)) + "]"
    return "%{" + ", ".join(elixir(k) + " => " + elixir(v) for k, v in value.items()) + "}"


def tokens(text):
    values = re.findall(r'"(?:\\.|[^"\\])*"|=>|%\{|[{}\[\],]|nil|true|false|[0-9][0-9_]*', text)
    return [value.replace("_", "") if value[0].isdigit() else value for value in values]


def validate(root=ROOT, completion=True):
    root, errors = Path(root), []
    def check(condition, message):
        if not condition:
            errors.append(message)
    try:
        check(enabled(root), "exact Phase 2 authorization required")
        auth = read(root, AUTH)
        check(auth["base_revision"] == BASE and auth["phase"] == 2, "authority/base mismatch")
        subprocess.run(["git", "-C", str(root), "merge-base", "--is-ancestor", BASE, "HEAD"],
                       check=True, capture_output=True)
        for path, expected in auth["source_bindings"].items():
            check(sha((root / path).read_bytes()) == expected, "stale inherited input: " + path)
        for path, expected in PINS.items():
            check(sha((root / path).read_bytes()) == expected, "historical Phase 1 record changed: " + path)
        baseline = read(root, ASSETS + "blazex-bh-04-repository-activation-v0.1.0.json")
        for path, expected in baseline["baseline_files"].items():
            check(sha((root / path).read_bytes()) == expected, "historical behavior changed: " + path)
        source_index = read(root, INDEX)
        check(set(source_index["source_bindings"]) == set(SOURCES), "source inventory incomplete")
        for path, expected in source_index["source_bindings"].items():
            check(sha((root / path).read_bytes()) == expected, "protocol source binding changed: " + path)
        old = set(git(root, "ls-tree", "-r", "--name-only", BASE, "--", "packages", "js", "integration").decode().splitlines())
        current = set(git(root, "ls-files", "--cached", "--others", "--exclude-standard",
                          "--", "packages", "js", "integration").decode().splitlines())
        additions = {p for p in SOURCES if p.startswith(("packages/", "js/", "integration/"))}
        additions.add("integration/bh-04/support/README.md")
        check(current == old | additions, "unindexed executable/evidence addition")
        inventory = read(root, "integration/bh-04/protocol-inventory-v0.1.0.json")
        check(inventory["results"] == {key: [] for key in BEHAVIORS}, "premature behavior evidence")
        check(inventory["phase3_authorized"] is False and inventory["support_state"] == "unsupported"
              and inventory["api_state"] == "experimental-not-stable", "support or authority promotion")
        schema = read(root, "integration/bh-04/render-transaction.schema.json")
        check(schema["oneOf"] == [schema["$defs"][k] for k in ("transaction", "ack", "diagnostic")],
              "root schema differs from named record schemas")
        js = (root / "js/blazex_runtime/src/render-transaction-schema.js").read_text()
        check(json.loads(js.split("export const SCHEMA = ", 1)[1].rstrip(";\n")) == schema["$defs"],
              "JavaScript schema drift")
        ex = (root / "packages/blazex_renderer_dom/lib/blazex/renderer/dom/protocol/schema.ex").read_text()
        literal = ex.split("@schemas ", 1)[1].split("def schemas,", 1)[0]
        check(tokens(literal) == tokens(elixir(schema["$defs"])), "Elixir schema drift")
        for path in SOURCES:
            if path.startswith("js/blazex_runtime/src/") and not path.endswith("schema.js"):
                check(not re.search(r"document\.|window\.|fetch\(|postMessage|dispatchEvent|Phoenix|LiveView",
                                    (root / path).read_text()), "forbidden execution or framework surface")
        results = (root / "integration/bh-04/protocol-results-v0.1.0.txt").read_text().splitlines()
        fixtures = (root / "integration/bh-04/protocol-fixtures-v0.1.0.txt").read_text().splitlines()
        check(len(results) == len(fixtures) == 73, "fixture result coverage changed")
        check(len({line.split("|")[0] for line in results}) == len(results), "duplicate fixture identity")
        check(sum(line.split("|")[1] == "ok" for line in results) == 34, "positive coverage changed")
        for fixture, result in zip(fixtures, results):
            check(fixture.split("|")[:2] == result.split("|")[:2], "fixture result mismatch")
        if completion:
            record = read(root, COMPLETION)
            check(record["decision"] == "passed" and record["phase"] == 2, "completion decision missing")
            check(record["next_eligible_phase"] == 3 and record["next_authorized_work"] is None
                  and record["bh05_eligible"] is False and record["support_state"] == "unsupported"
                  and record["api_state"] == "experimental-not-stable", "completion authority/support promotion")
            required = {INDEX, AUTH, ASSETS + "blazex-bh-04-phase-02-validation-log-v0.1.0.txt",
                        "docs/research/60-planning/01-browser-host/bh-04-dom-renderer-and-interaction-transport/phase-02-implementation-evidence.md"}
            check(set(record["artifact_hashes"]) == required, "completion artifact inventory incomplete")
            for path, expected in record["artifact_hashes"].items():
                check(sha((root / path).read_bytes()) == expected, "completion hash changed: " + path)
            check(record["behavior_results"] == inventory["results"], "completion invented behavior evidence")
            check(record["cross_language"] == {"cases": 73, "positive": 34, "negative": 39, "agreement": "exact"},
                  "cross-language evidence incomplete")
            check(all(gate["exit_code"] == 0 for gate in record["gates"]), "active gate failed")
    except (OSError, ValueError, KeyError, TypeError, IndexError, subprocess.CalledProcessError) as exc:
        errors.append("Cannot establish Phase 2 evidence: " + str(exc))
    return errors


if __name__ == "__main__":
    errors = validate(completion="--candidate" not in sys.argv)
    if errors:
        print("\n".join(errors))
        sys.exit(1)
    print("BH-04 Phase 2 protocol gate passed: exact source/schema/fixture bindings; no behavior or support promotion.")
