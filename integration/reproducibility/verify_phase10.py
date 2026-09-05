#!/usr/bin/env python3
"""Validate the complete BH-01 Phase 10 acceptance boundary."""

from __future__ import annotations

import hashlib
import importlib.util
import json
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
RAW = HERE / "raw-evidence"
BASELINE_ASSETS = ROOT / "docs/research/assets/bh-01-baseline"
RELEASE_ASSETS = ROOT / "docs/research/assets/bh-01-release"
PLAN_DIR = ROOT / "docs/research/60-planning/01-browser-host/bh-01-reproducible-browser-feasibility-baseline"

CLEAN_A = RAW / "bh01-phase10-clean-a-authoritative.json"
CLEAN_B = RAW / "bh01-phase10-clean-b.json"
COMPARISON = HERE / "bh01-phase10-clean-rebuild-comparison.json"
CLOSURE = HERE / "bh01-phase10-ledger-closure.json"
REVIEW = HERE / "bh01-phase10-feasibility-review.json"
BASELINE = RELEASE_ASSETS / "blazex-bh-01-feasibility-baseline-v0.1.0.json"
DECISION = RELEASE_ASSETS / "blazex-bh-01-feasibility-decision-v0.1.0.json"
ENTRY = RELEASE_ASSETS / "blazex-bh-02-entry-manifest-v0.1.0.json"
COMPLETION = BASELINE_ASSETS / "blazex-bh-01-phase-10-completion-v0.1.0.json"

PLAN = PLAN_DIR / "phase-10-clean-rebuild-review-and-feasibility-decision.md"
MILESTONE = PLAN_DIR / "README.md"
BROWSER_PLAN = PLAN_DIR.parent / "README.md"
ROADMAP = ROOT / "docs/research/20-notes/browser-host-implementation-milestones.md"
EVIDENCE = PLAN_DIR / "phase-10-implementation-evidence.md"


def load(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def canonical_bytes(value: Any) -> bytes:
    return (json.dumps(value, indent=2, sort_keys=True) + "\n").encode()


def module(name: str):
    spec = importlib.util.spec_from_file_location(name, HERE / f"{name}.py")
    value = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(value)
    return value


COMPARE = module("compare_clean_rebuilds")
LEDGERS = module("close_phase10_ledgers")
REVIEWS = module("conduct_phase10_reviews")
BASELINES = module("version_phase10_baseline")
DECISIONS = module("decide_phase10_entry")


def inputs() -> dict[str, Any]:
    return {
        "clean_a": load(CLEAN_A),
        "clean_b": load(CLEAN_B),
        "comparison": load(COMPARISON),
        "failed_attempts": [load(RAW / f"bh01-phase10-clean-a-attempt-{number}.json") for number in range(1, 4)],
        "closure": load(CLOSURE),
        "review": load(REVIEW),
        "baseline": load(BASELINE),
        "decision": load(DECISION),
        "entry": load(ENTRY),
        "completion": load(COMPLETION),
        "plan": PLAN.read_text(encoding="utf-8"),
        "milestone": MILESTONE.read_text(encoding="utf-8"),
        "browser_plan": BROWSER_PLAN.read_text(encoding="utf-8"),
        "roadmap": ROADMAP.read_text(encoding="utf-8"),
        "evidence": EVIDENCE.read_text(encoding="utf-8"),
    }


def schema_errors(record: dict[str, Any], schema: Path) -> list[str]:
    validator = Draft202012Validator(load(schema), format_checker=FormatChecker())
    return [error.message for error in validator.iter_errors(record)]


def validate(value: dict[str, Any]) -> list[str]:
    errors: list[str] = []

    for name in ("clean_a", "clean_b"):
        errors.extend(f"{name}: {error}" for error in schema_errors(value[name], HERE / "clean-rebuild.schema.json"))
    for index, attempt in enumerate(value["failed_attempts"], 1):
        errors.extend(f"attempt {index}: {error}" for error in schema_errors(attempt, HERE / "clean-rebuild-failure.schema.json"))

    expected_comparison, comparison_errors = COMPARE.compare(value["clean_a"], value["clean_b"])
    errors.extend(f"clean rebuild: {error}" for error in comparison_errors)
    if value["comparison"] != expected_comparison:
        errors.append("clean-rebuild comparison is stale")

    for name, record, builder, validator in (
        ("closure", value["closure"], LEDGERS.build, LEDGERS.validate),
        ("review", value["review"], REVIEWS.build, REVIEWS.validate),
        ("baseline", value["baseline"], BASELINES.build, BASELINES.validate),
    ):
        first = builder()
        second = builder()
        if canonical_bytes(first) != canonical_bytes(second):
            errors.append(f"{name} regeneration is nondeterministic")
        if record != first:
            errors.append(f"{name} is stale relative to canonical inputs")
        errors.extend(f"{name}: {error}" for error in validator(record))

    expected_views_a = BASELINES.render_views(BASELINES.build())
    expected_views_b = BASELINES.render_views(BASELINES.build())
    if expected_views_a != expected_views_b:
        errors.append("baseline view regeneration is nondeterministic")
    for name, expected in expected_views_a.items():
        path = RELEASE_ASSETS / name
        if not path.is_file() or path.read_text(encoding="utf-8") != expected:
            errors.append(f"baseline view is stale: {name}")

    expected_decision_a = DECISIONS.build_decision()
    expected_entry_a = DECISIONS.build_entry(expected_decision_a)
    expected_decision_b = DECISIONS.build_decision()
    expected_entry_b = DECISIONS.build_entry(expected_decision_b)
    if canonical_bytes(expected_decision_a) != canonical_bytes(expected_decision_b) or canonical_bytes(expected_entry_a) != canonical_bytes(expected_entry_b):
        errors.append("decision or entry regeneration is nondeterministic")
    if value["decision"] != expected_decision_a or value["entry"] != expected_entry_a:
        errors.append("decision or entry manifest is stale relative to canonical inputs")
    errors.extend(f"decision: {error}" for error in DECISIONS.validate(value["decision"], value["entry"]))
    for name, expected in (
        ("blazex-bh-01-feasibility-decision-v0-1-0.md", DECISIONS.render_decision(expected_decision_a)),
        ("blazex-bh-02-entry-manifest-v0-1-0.md", DECISIONS.render_entry(expected_entry_a)),
    ):
        path = RELEASE_ASSETS / name
        if not path.is_file() or path.read_text(encoding="utf-8") != expected:
            errors.append(f"decision view is stale: {name}")

    closure = value["closure"]
    expected_counts = {"inputs": 8, "proof_obligations": 10, "risks": 8, "stop_conditions": 5, "findings": 30, "exceptions": 0}
    for key, count in expected_counts.items():
        if len(closure.get(key, [])) != count:
            errors.append(f"closure inventory mismatch: expected {count} {key}")
    if len(value["review"].get("lenses", [])) != 11 or len(value["review"].get("conditions", [])) != 9:
        errors.append("multidisciplinary review inventory is incomplete")

    for name, clean, directory in (
        ("clean A", value["clean_a"], RAW / "bh01-phase10-clean-a-authoritative-logs"),
        ("clean B", value["clean_b"], RAW / "bh01-phase10-clean-b-logs"),
    ):
        logs = list(directory.glob("[0-9][0-9]-*.log"))
        if len(clean.get("commands", [])) != 38 or len(logs) != 38:
            errors.append(f"{name} does not retain all 38 command logs")
            continue
        by_suffix = {path.name.split("-", 1)[1][:-4]: path for path in logs}
        for command in clean["commands"]:
            path = by_suffix.get(command["id"])
            if path is None or sha256(path) != command["log_sha256"]:
                errors.append(f"{name} command log hash mismatch: {command['id']}")

    completion = value["completion"]
    errors.extend(
        f"completion: {error}"
        for error in schema_errors(completion, BASELINE_ASSETS / "blazex-bh-01-evidence-record.schema.json")
    )
    if completion.get("record_id") != "BX-BH01-DECISION-PHASE-10-CONDITIONAL" or completion.get("state") != "conditional":
        errors.append("Phase 10 completion is not the accepted conditional decision")
    if completion.get("review", {}).get("disposition") != "accepted":
        errors.append("Phase 10 completion lacks accepted owner review")
    for record in completion.get("input_hashes", []) + completion.get("output_hashes", []):
        path = ROOT / record.get("path", "")
        if not path.is_file() or record.get("sha256") != sha256(path):
            errors.append(f"completion hash is stale: {record.get('path')}")
    for path in completion.get("raw_evidence_refs", []):
        if not (ROOT / path).exists():
            errors.append(f"completion raw evidence is missing: {path}")

    if "- [ ]" in value["plan"] or "- [x] 10 Phase" not in value["plan"] or "- [x] 10.6 Section" not in value["plan"]:
        errors.append("Phase 10 checklist contains open active work")
    required_plan_text = {
        "milestone": "Phase 10 is complete with a proceed-with-bounded-conditions decision",
        "browser_plan": "BH-01 is complete with a proceed-with-bounded-conditions decision",
        "evidence": "## Section 10.6 — Milestone integration and final acceptance",
    }
    for key, text in required_plan_text.items():
        if text not in " ".join(value[key].split()):
            errors.append(f"{key} does not publish final BH-01 state")

    decision = value["decision"]
    entry = value["entry"]
    if decision.get("bh01_status") != "complete-proceed-with-bounded-conditions":
        errors.append("decision does not mark BH-01 complete")
    if decision.get("bh02_entry", {}).get("authorized") is not False or decision.get("bh02_entry", {}).get("may_start") is not False:
        errors.append("decision over-authorizes BH-02")
    if entry.get("activation") != {
        "eligible": True,
        "authorized": False,
        "may_start": False,
        "authorization_requirement": "explicit repository-owner authorization after BH-01 completion",
    }:
        errors.append("BH-02 activation boundary drifted")
    if value["baseline"].get("support_status") != "unsupported" or entry.get("support_status") != "unsupported":
        errors.append("Phase 10 over-promotes browser or product support")
    return errors


def main() -> int:
    errors = validate(inputs())
    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        return 1
    print(
        "BH-01 Phase 10: PASS "
        "(2 clean rebuilds; 76 command logs; 10 proofs; 8 risks; "
        "5 stops; 30 findings; 0 exceptions; BH-02 unauthorized)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
