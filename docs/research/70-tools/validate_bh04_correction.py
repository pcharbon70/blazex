"""Validate the current BH-04 successor, preserving Phase 10 and migration v1."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys

from research_paths import REPO_ROOT
from tooling_migration import validate_migration

BASE = "d61e103b14595acca182611524eb4c7245906f20"
AREA = "docs/research/assets/bh-04-correction/"
OLD = "docs/research/assets/bh-04-baseline/blazex-bh-04-phase-10-"
REVIEW = ".spec/reviews/2026-09-08T13-01-15-0400-parallel-code-review-bh04-correction.md"
CURRENT_GATES = {"elixir", "javascript", "current-tool-tests", "atomic-browser", "interaction-browser", "interaction-replay", "continuity-browser", "continuity-replay", "effect-browser", "effect-replay", "semantic-browser", "isolation", "archive", "migration", "patch-hygiene"}
CONDITIONS = {"BX-ACC-BUDGET-BX-BUD-INTERACTION-DOM-UPDATE-MS", "BX-ACC-BUDGET-BX-BUD-RELIABILITY-RENDERER-QUEUE-COUNT", "BX-ACC-BUDGET-BX-BUD-RELIABILITY-STALE-REJECTION-PERCENT", "BX-ACC-FAILURE-BX-FAIL-RENDERER", "BX-ACC-ROADMAP-BH-04"}


def read(root, name):
    return json.loads((root / name).read_text())


def source_files(root):
    files = subprocess.check_output(["git", "ls-files", "--cached", "--others", "--exclude-standard", "--", "packages", "js", "integration", "profiles", "docs/research/70-tools"], cwd=root, text=True).splitlines()
    return sorted({p for p in files if "node_modules" not in Path(p).parts and (root / p).is_file()})


def bindings(root, files):
    return {p: hashlib.sha256((root / p).read_bytes()).hexdigest() for p in sorted(files)}


def evidence_files(root):
    files = [p.relative_to(root).as_posix() for p in (root / AREA).iterdir() if p.is_file() and p.name not in {"decision.json", "README.md"}]
    files += [REVIEW, OLD + "acceptance-overlay-v0.1.0.json", OLD + "reconciliation-v0.1.0.json", OLD + "review-v0.1.0.json"]
    return sorted(files)


def gate_errors(rows, required):
    errors = []
    if len(rows) != len(required) or {r.get("name") for r in rows} != required:
        errors.append("incomplete gate inventory")
    if any(r.get("exit_code") != 0 or r.get("error") is not None for r in rows):
        errors.append("failed execution gate")
    return errors


def execution_source_errors(record, current):
    if not current or record.get("source_hashes") != current or record.get("final_source_hashes") != current:
        return ["execution source closure changed or was not recorded"]
    return []


def immutable_input_errors(root, entries):
    errors = []
    for path, expected_blob in entries.items():
        data = (root / path).read_bytes()
        actual = hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest()
        if actual != expected_blob:
            errors.append("altered inherited input: " + path)
    return errors


def prerequisites(root):
    validate_migration(root)
    subprocess.run(["git", "merge-base", "--is-ancestor", BASE, "HEAD"], cwd=root, check=True, capture_output=True)
    # The complete frozen sweep executes in a detached baseline worktree, not
    # against corrected bytes. No historical record or tooling hash is rewritten.
    historical = read(root, AREA + "historical-gates.json")
    assert historical["revision"] == BASE
    names = subprocess.check_output(["git", "ls-tree", "--name-only", BASE + ":docs/research/70-tools"], cwd=root, text=True).splitlines()
    required = {"tests"} | {p for p in names if p.endswith(".py") and p.startswith(("validate_", "generate_"))}
    assert not gate_errors(historical["results"], required), "historical execution failed"
    current = read(root, AREA + "current-gates.json")
    assert not gate_errors(current["results"], CURRENT_GATES), "current execution failed"
    assert not execution_source_errors(current, bindings(root, source_files(root))), "stale execution source closure"
    assert subprocess.check_output(["git", "rev-parse", "--show-object-format"], cwd=root, text=True).strip() == "sha1"
    tree = subprocess.check_output(["git", "ls-tree", "-r", BASE, "--", "docs/research/assets"], cwd=root, text=True)
    entries = {line.split("\t", 1)[1]: line.split()[2] for line in tree.splitlines() if not line.endswith(".md")}
    assert not immutable_input_errors(root, entries), "historical artifact changed"
    review = read(root, AREA + "review-status.json")
    assert review["independent_agents"] == ["review_architecture", "review_qa", "review_security"]
    assert review["implementation_by_reviewers"] is False and review["human_review_claim"] is False
    assert review["open_blockers"] == [] and review["final_delta_approved"] is True
    assert review["lenses"] == [r["lens"] for r in read(root, OLD + "review-v0.1.0.json")["lenses"]]
    assert review["variance"]["disposition"] == "bounded-development-only"
    assert review["variance"]["owner"] and review["variance"]["repeat_at"] == ["BH-22 governed hardware qualification", "material renderer/runtime changes"]
    subprocess.run(["node", "integration/bh-04/corrective-verify.mjs"], cwd=root, check=True, capture_output=True)
    subprocess.run(["node", "integration/bh-04/acceptance-corpora.mjs", AREA + "current-"], cwd=root, check=True, capture_output=True)


def candidate(root=REPO_ROOT):
    root = Path(root)
    prerequisites(root)
    old = read(root, OLD + "acceptance-overlay-v0.1.0.json")
    assert len(old["conditions"]) == 5 and {r["id"] for r in old["conditions"]} == CONDITIONS
    reconciliation = read(root, OLD + "reconciliation-v0.1.0.json")
    review = read(root, OLD + "review-v0.1.0.json")
    return {"schema_version": "1.0.0", "baseline_revision": BASE, "decision": "accepted-development-only", "bh04_accepted": True, "bh05_eligible": True,
            "support_state": "unsupported", "canonical_registry_modified": False,
            "conditions": [{**row, "state": "active-development-evidence-release-unqualified", "evidence": [AREA + "presentation.json", AREA + "stale-queue.json.gz", AREA + "current-gates.json", REVIEW]} for row in old["conditions"]],
            "inherited_obligations": reconciliation["inherited_obligations"], "deferred": review["deferred"], "open_blockers": [],
            "source_hashes": bindings(root, source_files(root)), "artifact_hashes": bindings(root, evidence_files(root))}


def validate(root=REPO_ROOT):
    try:
        actual = read(Path(root), AREA + "decision.json")
        expected = candidate(root)
        return [] if actual == expected else ["stale or altered corrective decision/source closure"]
    except (OSError, KeyError, TypeError, ValueError, AssertionError, subprocess.CalledProcessError) as error:
        return ["Cannot establish current BH-04 acceptance: " + str(error)]


if __name__ == "__main__":
    if "--sources" in sys.argv:
        print(json.dumps(bindings(REPO_ROOT, source_files(REPO_ROOT)), sort_keys=True)); sys.exit(0)
    errors = validate()
    if errors:
        print("\n".join(errors)); sys.exit(1)
    print("BH-04 corrective successor accepted for development; BH-05 eligible; release support remains unsupported.")
