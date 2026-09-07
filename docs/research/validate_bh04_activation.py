#!/usr/bin/env python3
"""Fail-closed BH-04 Phase 1 activation gate; stdlib only.

Phase 1 is deliberately immutable. Later behavior needs an explicitly versioned
successor gate, never a silent relaxation of this historical activation record.
"""
from __future__ import annotations

import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ASSETS = "docs/research/assets/bh-04-baseline/"
AUTH = ASSETS + "blazex-bh-04-phase-01-authorization-v0.1.0.json"
LEDGER = ASSETS + "blazex-bh-04-entry-ledger-v0.1.0.json"
ACTIVATION = ASSETS + "blazex-bh-04-repository-activation-v0.1.0.json"
COMPLETION = ASSETS + "blazex-bh-04-phase-01-completion-v0.1.0.json"
INDEX = "integration/bh-04/integration-index-v0.1.0.json"
SCHEMA = "integration/bh-04/activation-index.schema.json"
BASE = "12158e343a4634e65d58a8743bc53903620dc834"
PINS = {
    "docs/research/assets/bh-04-baseline/blazex-bh-04-entry-ledger-v0.1.0.json": "7bba11ac034d81a6db1b753b3f99ab3b2747667bf784d0fc41d3634e744f8f56",
    "docs/research/assets/bh-04-baseline/blazex-bh-04-phase-01-authorization-v0.1.0.json": "1fb5b90fd892a19bd947d7a46a628875da73a9246cd8e11953e240c59dc6ef8c",
    "docs/research/assets/bh-04-baseline/blazex-bh-04-repository-activation-v0.1.0.json": "5500b40fb2836d9e90b43ac8dc3c3444fe0bf41a1ab953e0bd3ffea4cecf1531",
    "integration/bh-04/activation-index.schema.json": "df43c7c60b0927ba14d8a9b027a83c633c34ec8055b95bae6587bf2a1c96de76",
    "integration/bh-04/integration-index-v0.1.0.json": "20ba4dc278c49562e1e55410db7f0dfc6aa2a53eea4fc8c3008bf610feb15005"
}
FORBIDDEN = re.compile(
    r"\b(?:Phoenix|Plug|LiveView|LocalLiveView|Popcorn|AtomVM|HTMLElement|"
    r"HTMLInputElement|wxWidgets|QWidget|Qt|BlazeX\.Host|BlazeX\.Runtime)\b"
    r"|\b(?:window\.|document\.(?:createElement|querySelector|getElementById))"
)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def git(root, *args):
    return subprocess.check_output(["git", "-C", str(root), *args],
                                   stderr=subprocess.PIPE)


def read(root, path):
    return json.loads((root / path).read_text())


def validate(root=ROOT, require_completion=True):
    root = Path(root)
    errors = []

    def check(condition, message):
        if not condition:
            errors.append(message)

    try:
        for path, expected in PINS.items():
            check(digest((root / path).read_bytes()) == expected,
                  f"immutable activation record changed: {path}")
        auth, ledger, activation = [read(root, p) for p in (AUTH, LEDGER, ACTIVATION)]
        check(auth["authorized_by"] == "repository-owner" and auth["authorized_phase"] == 1,
              "missing exact Phase 1 authority")
        check(auth["base_revision"] == BASE, "synchronized base identity changed")
        subprocess.run(["git", "-C", str(root), "merge-base", "--is-ancestor", BASE, "HEAD"],
                       check=True, capture_output=True)
        for path, expected in auth["source_bindings"].items():
            check(digest((root / path).read_bytes()) == expected,
                  f"stale authority/handoff input: {path}")
            check(digest(git(root, "show", f"{BASE}:{path}")) == expected,
                  f"authority rebound away from synchronized base: {path}")

        predecessor = read(root, "docs/research/assets/bh-03-baseline/"
                           "blazex-bh-03-phase-09-acceptance-v0.1.0.json")
        check(predecessor["decision"] == "accepted-with-bounded-conditions"
              and predecessor["bh04_eligible"] is True,
              "BH-03 entry is not accepted")
        check(ledger["predecessor_handoff"] == predecessor,
              "handoff changed: outputs, findings, obligations or deferrals")
        for binding in predecessor["source_bindings"]:
            path, expected = binding["path"], binding["sha256"]
            check(digest((root / path).read_bytes()) == expected,
                  f"accepted BH-03 source changed: {path}")
        registry = read(root, "docs/research/assets/quality-acceptance/"
                        "blazex-acceptance-registry-v0.1.0.json")
        rows = [r for r in registry["acceptance_conditions"]
                if r["responsible_milestone"] == "BH-04"]
        check(len(rows) == 5 and ledger["acceptance_records"] == rows,
              "five canonical acceptance identities/states must match")
        check(len(ledger["schedule"]) == 5, "acceptance schedule incomplete")
        for row, schedule in zip(rows, ledger["schedule"]):
            check(schedule["id"] == row["id"]
                  and schedule["owner"] == row["evidence_owner"]
                  and schedule["suite"] == row["integration_suite"],
                  "acceptance owner or suite mismatch")

        plans = auth["planned_phases"]
        check(len(plans) == 10 and len(set(plans)) == 10,
              "phase decomposition must contain ten unique phases")
        actual_plans = {str(p.relative_to(root))
                        for p in (root / plans[0]).parent.glob("phase-*.md")
                        if "implementation-evidence" not in p.name}
        check(actual_plans == set(plans), "unindexed or missing phase plan")
        for path in plans:
            check((root / path).is_file(), f"missing phase plan: {path}")
        for path, expected in auth["later_plan_bindings"].items():
            check(digest((root / path).read_bytes()) == expected,
                  f"later phase modified or prematurely authorized: {path}")

        # Baseline inventory is independently reconstructed from the base Git
        # tree. Editing a hash and its ledger cannot launder new runtime code.
        roots = activation["baseline_roots"]
        tree = set(git(root, "ls-tree", "-r", "--name-only", BASE, "--", *roots)
                   .decode().splitlines())
        baseline = activation["baseline_files"]
        check(set(baseline) == tree - set(activation["mutable_indexes"]),
              "historical source inventory incomplete")
        # Batch immutable Git blobs, avoiding hundreds of subprocesses.
        paths = list(baseline)
        objects = subprocess.run(
            ["git", "-C", str(root), "cat-file", "--batch"],
            input="".join(f"{BASE}:{p}\n" for p in paths).encode(),
            capture_output=True, check=True).stdout
        position = 0
        for path in paths:
            end = objects.index(b"\n", position)
            header = objects[position:end].split()
            size = int(header[2])
            original = objects[end + 1:end + 1 + size]
            position = end + size + 2
            check(digest(original) == baseline[path],
                  f"historical source rebound: {path}")
            check((root / path).is_file()
                  and digest((root / path).read_bytes()) == baseline[path],
                  f"historical source/behavior changed: {path}")
        current = set(git(root, "ls-files", "--cached", "--others", "--exclude-standard",
                          "--", *roots).decode().splitlines())
        expected = tree | set(activation["new_boundary_files"])
        check(current == expected, "unindexed source/evidence files: "
              + ", ".join(sorted(current ^ expected)))
        boundary = {str(p.relative_to(root))
                    for p in (root / "integration/bh-04").rglob("*") if p.is_file()}
        check(boundary == set(activation["new_boundary_files"]),
              "unindexed BH-04 evidence file")

        observed = {}
        for package, allowed in activation["allowed_dependencies"].items():
            manifest = (root / "packages" / package / "mix.exs").read_text()
            observed[package] = re.findall(r"\{\s*:(\w+)\s*,", manifest)
            check(observed[package] == allowed,
                  f"unauthorized direct dependency: {package}")
        for package in observed:
            pending, seen = list(observed[package]), set()
            while pending:
                dependency = pending.pop()
                if dependency in seen:
                    continue
                seen.add(dependency)
                check(dependency in observed and dependency != "blazex_renderer_dom_liveview",
                      f"unauthorized transitive dependency: {package} -> {dependency}")
                pending.extend(observed.get(dependency, []))
            if package != "blazex_renderer_dom_liveview":
                for path in (root / "packages" / package / "lib").rglob("*.ex"):
                    check(not FORBIDDEN.search(path.read_text()),
                          f"portable source token leakage: {path.relative_to(root)}")

        index, schema = read(root, INDEX), read(root, SCHEMA)
        # JSON Schema const is sufficient and exact: no coercions, extra keys,
        # result rows or invented evidence classes can pass.
        check(index == schema["const"], "evidence index violates fixed-value schema")
        check(all(value == [] for value in index["results"].values()),
              "premature renderer/browser/measurement/acceptance evidence")
        for record in (auth, index, activation):
            check(record["support_state"] == "unsupported"
                  and record["api_state"] == "experimental-not-stable",
                  "public API/support promotion forbidden")
        check(auth["phase2_authorized"] is False and index["phase2_authorized"] is False,
              "Phase 2 authority forbidden")
        check(auth["bh05_eligible"] is False and index["bh05_eligible"] is False,
              "BH-05 eligibility forbidden")
        allowed_assets = {Path(p).name for p in (AUTH, LEDGER, ACTIVATION, COMPLETION)}
        allowed_assets |= {"README.md", "blazex-bh-04-phase-01-validation-log-v0.1.0.txt"}
        actual_assets = {p.name for p in (root / ASSETS).iterdir()}
        check(actual_assets <= allowed_assets,
              "unindexed BH-04 authority or evidence artifact")
        if require_completion:
            validate_completion(root, check)
    except (OSError, ValueError, KeyError, TypeError, IndexError,
            subprocess.CalledProcessError) as exc:
        errors.append(f"activation gate cannot establish evidence: {exc}")
    return errors


def validate_completion(root, check):
    completion = read(root, COMPLETION)
    check(completion["record_id"] == "BH-04-PHASE-01-COMPLETION"
          and completion["decision"] == "passed"
          and completion["phase"] == 1,
          "missing Phase 1 completion decision")
    check(completion["next_eligible_phase"] == 2
          and completion["next_authorized_work"] is None
          and completion["bh05_eligible"] is False
          and completion["support_state"] == "unsupported"
          and completion["api_state"] == "experimental-not-stable"
          and completion["renderer_behavior"] == "unchanged",
          "completion promotes unauthorized behavior or support")
    required = set(PINS) | {
        "docs/research/validate_bh04_activation.py",
        "docs/research/test_validate_bh04_activation.py",
        ASSETS + "blazex-bh-04-phase-01-validation-log-v0.1.0.txt",
        "docs/research/60-planning/01-browser-host/"
        "bh-04-dom-renderer-and-interaction-transport/phase-01-implementation-evidence.md",
    }
    check(set(completion["source_bindings"]) == required,
          "completion bindings missing or unexpected")
    for path, expected in completion["source_bindings"].items():
        check(digest((root / path).read_bytes()) == expected,
              f"completion artifact changed: {path}")
    check(completion["active_gate_failures"] == []
          and completion["result_sets"] == read(root, INDEX)["results"],
          "completion contains failures or fabricated results")
    check([r["section"] for r in completion["section_commits"]] == ["1.1", "1.2", "1.3", "1.4"],
          "section delivery provenance incomplete")
    for row in completion["section_commits"][:3]:
        subject = git(root, "show", "-s", "--format=%s", row["commit"]).decode().strip()
        check(subject.startswith("BH-04 " + row["section"] + ":"),
              "section commit identity mismatch")
        subprocess.run(["git", "-C", str(root), "merge-base", "--is-ancestor",
                        row["commit"], "HEAD"], check=True, capture_output=True)
    check(completion["section_commits"][3]["commit"] == "resolve-from-completion-record-commit",
          "final section must resolve from the commit introducing completion")
    required_gates = {"research-tests", "validators", "generators", "package-tests-and-formats",
                      "runtime-js-build-and-tests", "dom-js-build-and-tests", "clean-candidate",
                      "json-parse", "patch-hygiene"}
    check(set(completion["gates"]) == required_gates
          and all(value["exit_code"] == 0 for value in completion["gates"].values()),
          "completion active gate inventory incomplete or failed")


if __name__ == "__main__":
    from bh04_history import enabled, run_phase1

    if enabled(ROOT):
        run_phase1(ROOT)
        sys.exit(0)
    errors = validate(require_completion="--candidate" not in sys.argv)
    if errors:
        print("\n".join("BH-04 activation: " + error for error in errors))
        sys.exit(1)
    print("BH-04 Phase 1 activation passed; renderer unchanged; unsupported; "
          "Phase 2 not authorized; BH-05 ineligible.")
