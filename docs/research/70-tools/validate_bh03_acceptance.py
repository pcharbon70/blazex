#!/usr/bin/env python3
"""Validate the BH-03 review record; valid records need not accept the milestone."""
import argparse
from bh03_history import phase9_historical_binding
from tooling_migration import relocated_evidence_path
import hashlib
import planning_policy
import json
import math
from pathlib import Path
import subprocess

from research_paths import REPO_ROOT as ROOT
BASE = "docs/research/assets/bh-03-baseline/"
REVISION = "34822e271ebb04f30bbfe93131c2288dc23d3057"
LENSES = {"architecture", "implementation", "conformance", "accessibility",
          "security", "packaging", "provenance"}
SOURCE_ROOTS = ["js/blazex_runtime/src", "js/blazex_runtime/test",
                "packages/blazex_host_browser", "packages/blazex_runtime_popcorn",
                "profiles/browser_phoenix/assets/phase6", "profiles/browser_phoenix/lib",
                "integration/bh-03",
                "integration/fixtures/raw-evidence/bh03-phase6-browser-matrix.json",
                "integration/fixtures/raw-evidence/bh03-phase7-measurements.json"]


class ValidationError(ValueError):
    pass


def require(value, message):
    if not value:
        raise ValidationError(message)


def read(name):
    return json.loads((ROOT / BASE / name).read_text())


def phase(kind):
    return read(f"blazex-bh-03-phase-08-{kind}-v0.1.0.json")


def git(*args):
    return subprocess.check_output(["git", *args], cwd=ROOT)


def ids(rows):
    result = [row["id"] for row in rows]
    require(len(set(result)) == len(result), "duplicate identities")
    return set(result)


def bindings(rows, expected=None):
    paths = [row["path"] for row in rows]
    require(len(set(paths)) == len(paths) and paths, "missing or duplicate bindings")
    if expected is not None:
        require(set(paths) == set(expected), "binding inventory differs")
    for row in rows:
        target = relocated_evidence_path(ROOT, row["path"]).resolve()
        require(target.is_relative_to(ROOT) and target.is_file(), "invalid evidence path")
        require(hashlib.sha256(target.read_bytes()).hexdigest() == row["sha256"]
                or planning_policy.source_amendment_is_bound(target, row["sha256"])
                or phase9_historical_binding(ROOT, row["path"], row["sha256"]),
                f"stale evidence: {row['path']}")


def validate_review(ledger, review):
    entry = read("blazex-bh-03-entry-ledger-v0.1.0.json")
    require(ledger["candidate_revision"] == review["candidate_revision"] == REVISION,
            "candidate revision differs")
    require(ids(ledger["outputs"]) == ids(entry["required_outputs"]), "output coverage differs")
    bound = {row["path"] for row in ledger["source_bindings"]}
    for row in ledger["outputs"]:
        require(row["implementation"] in bound and row["conformance"] in bound,
                "output lacks source-bound evidence")
        original = next(item for item in entry["required_outputs"] if item["id"] == row["id"])
        require(row["phase"] == original["phase"], "output ownership differs")
        require(row["state"] in {"implemented-bounded", "review-gap"} and row["limitation"],
                "output silently promoted")
    categories = {
        "inherited-condition": entry["inherited_condition_ids"],
        "inherited-finding": entry["inherited_open_finding_ids"],
        "deferred-qualification": entry["deferred_qualification_ids"],
        "acceptance-condition": entry["first_responsible_acceptance_ids"],
        "satisfied-predecessor": [entry["satisfied_predecessor_condition"]],
    }
    ids(ledger["obligations"])
    require({row["category"] for row in ledger["obligations"]} == set(categories),
            "obligation categories differ")
    for category, expected in categories.items():
        rows = [row for row in ledger["obligations"] if row["category"] == category]
        require(ids(rows) == set(expected), f"obligation coverage differs: {category}")
        for row in rows:
            require(row["owner"] and row["reactivate_by"] and row["disposition"],
                    "obligation has no owner or due point")
            require(row["pass_credit"] is False, "obligation fabricated pass credit")
            if category == "deferred-qualification":
                require(row["state"] == "deferred-unavailable" and row["reactivate_by"] == "BH-22",
                        "deferred qualification promoted")
    require(ledger["contract_surfaces"] == entry["activation_boundaries"], "ownership changed")
    require(ids(review["lenses"]) == LENSES and review["independence"], "review coverage differs")
    for row in review["lenses"]:
        require(row["state"] == "reviewed" and row["conclusion"] and row["evidence"],
                "review lacks evidence")
        require(all(relocated_evidence_path(ROOT, path).is_file() for path in row["evidence"]), "missing review source")
    require(ids(review["findings"]) == {
        "BX-BH03-FINDING-UNREPORTED-RUNTIME-LOSS",
        "BX-BH03-FINDING-MEMORY-EVIDENCE-BOUNDED",
        "BX-BH03-FINDING-HISTORICAL-RUNNER-PROVENANCE"}, "finding inventory differs")
    for row in review["findings"]:
        require(row["owner"] and row["due"] and row["required_resolution"], "unowned finding")
        require(row["pass_credit"] is False, "finding fabricated pass credit")
        require(row["evidence"] and all(relocated_evidence_path(ROOT, path).is_file() for path in row["evidence"]),
                "finding evidence missing")
    loss = next(row for row in review["findings"] if row["id"].endswith("UNREPORTED-RUNTIME-LOSS"))
    require(loss["severity"] == "blocking" and loss["state"] == "open", "known blocker hidden")
    require(review["decision"] == "revise" and review["bh04_eligible"] is False,
            "unresolved runtime loss cannot accept BH-03")
    require(review["next_authorized_work"] is None, "later work prematurely authorized")
    for record in [ledger, review]:
        require(record["support_state"] == "unsupported", "support promoted")
    require(ledger["public_api_state"] == review["api_state"] == "experimental-not-stable",
            "public API promoted")


def validate(review_only=False):
    auth, contract = phase("authorization"), phase("contract")
    require(auth["status"] == "approved-phase-8-only" and auth["approved_by"]["role"] == "repository-owner",
            "missing owner authorization")
    require(auth["activation"]["base_revision"] == auth["activation"]["base_remote_revision"] == REVISION
            and auth["activation"]["main_synchronized_before_branch"] is True, "base not synchronized")
    require(auth["activation"]["working_branch"] == "codex/bh03-phase8-acceptance", "branch differs")
    require(contract["authorization_ref"] == auth["authorization_id"]
            and set(contract["review_lenses"]) == LENSES, "contract differs")
    expected = [BASE + f"blazex-bh-03-phase-{n:02}-completion-v0.1.0.json" for n in range(1, 8)]
    expected += [BASE + "blazex-bh-03-entry-ledger-v0.1.0.json",
                 BASE + "blazex-bh-03-phase-01-contract-v0.1.0.json",
                 "docs/research/60-planning/development-environment-and-deferred-qualification-policy.md"]
    bindings(auth["approval_basis"], expected)
    ledger, review = phase("reconciliation"), phase("review")
    inventory = git("ls-tree", "-r", "--name-only", REVISION, "--", *SOURCE_ROOTS).decode().splitlines()
    bindings(ledger["source_bindings"], inventory)
    for row in ledger["source_bindings"]:
        require(hashlib.sha256(git("show", f"{REVISION}:{row['path']}")).hexdigest() == row["sha256"],
                "candidate source not from declared revision")
    validate_review(ledger, review)
    if not review_only:
        completion = phase("completion")
        require(completion["state"] == "review-complete-milestone-revise"
                and completion["decision"] == review["decision"]
                and completion["bh04_eligible"] is False
                and completion["next_authorized_work"] is None, "completion promotes acceptance")
        require(completion["support_state"] == "unsupported"
                and completion["api_state"] == "experimental-not-stable", "completion promotes support")
        required = [BASE + f"blazex-bh-03-phase-08-{kind}-v0.1.0.{ext}" for kind, ext in [
            ("authorization", "json"), ("contract", "json"), ("reconciliation", "json"),
            ("review", "json"), ("validation-log", "txt")]]
        required += ["docs/research/validate_bh03_acceptance.py",
                     "docs/research/test_validate_bh03_acceptance.py",
                     "js/blazex_runtime/test/review/bh03-phase8-runtime-loss.mjs",
                     BASE + "blazex-bh-03-phase-08-browser-repeat-v0.1.0.json",
                     BASE + "blazex-bh-03-phase-08-measurement-repeat-v0.1.0.json"]
        plan = "docs/research/60-planning/01-browser-host/bh-03-browser-execution-host-and-runtime-boot-lifecycle/"
        required += [plan + "phase-08-implementation-evidence.md",
                     plan + "phase-08-reconciliation-review-and-bh-03-acceptance.md"]
        bindings(completion["artifact_hashes"], required)
        validate_repeat(phase("browser-repeat"), measurement=False)
        validate_repeat(phase("measurement-repeat"), measurement=True)
        commits = completion["section_commits"]
        require([row["section"] for row in commits] == ["8.1", "8.2", "8.3", "8.4"],
                "section commit inventory differs")
        for row in commits[:3]:
            git("merge-base", "--is-ancestor", row["commit"], "HEAD")
        require(commits[3]["commit"] == "resolve-from-this-records-git-commit", "final commit binding differs")
        require("- [ ]" not in (ROOT / plan / "phase-08-reconciliation-review-and-bh-03-acceptance.md").read_text(),
                "phase review has open tasks")
    return review["decision"]


def validate_repeat(evidence, measurement):
    require(evidence["implementation_revision"] == REVISION, "repeat candidate differs")
    require(evidence["support_state"] == "unsupported", "repeat promotes support")
    require(evidence["captured_at"].startswith("2026-09-07"), "repeat capture date differs")
    rows = evidence["results"]
    require([row["browser"] for row in rows] == ["chrome", "firefox"], "active matrix missing")
    for row in rows:
        require(row["result"] == "passed" and row["failures"] == []
                and row["browser_version"] and row["executable"], "active row did not pass")
        require(row["scenario_set"] == evidence["scenario_set"]
                and len(row["scenario_set"]) == 5, "repeat scenarios differ")
        if measurement:
            require(len(row["samples"]) == 5 and row["warmup"]["result"] == "passed-discarded",
                    "sampling incomplete")
            for sample in row["samples"]:
                require(sample["root_count_before_shutdown"] == sample["disposed_root_count_after_shutdown"] == 10
                        and sample["runtime_iframes_after_shutdown"] == 0
                        and sample["runtime_acknowledgements"] == 43, "cleanup did not converge")
                for field in ["startup_to_ready_ms", "measurement_root_cycle_ms", "shutdown_ms"]:
                    value = sample[field]
                    require(type(value) in (int, float) and math.isfinite(value) and 0 <= value <= 60000,
                            "invalid timing observation")
            require(len(row["failure_scenarios"]) == 3 and all(
                item["result"] == "passed" and item["partial_activation"] is False
                for item in row["failure_scenarios"]), "failure convergence missing")
        else:
            positive = row["observations"]["positive"]
            require(positive["runtime_starts"] == 1 and positive["shutdown"]["released"] is True
                    and positive["shutdown"]["root_failures"] == 0, "profile lifecycle failed")
    require(len(evidence["deferred"]) == 5 and all(
        row["state"] == "deferred-unavailable" for row in evidence["deferred"]), "qualification promoted")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--review-only", action="store_true")
    parser.add_argument("--require-accepted", action="store_true")
    args = parser.parse_args()
    try:
        decision = validate(args.review_only)
        require(not args.require_accepted or decision == "accepted", "BH-03 requires revision; BH-04 is ineligible")
    except (ValidationError, OSError, KeyError, TypeError, subprocess.CalledProcessError) as exc:
        print(f"BH-03 acceptance validation failed: {exc}")
        return 1
    print(f"BH-03 review record valid: {decision}; BH-04 ineligible; unsupported experimental state.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
