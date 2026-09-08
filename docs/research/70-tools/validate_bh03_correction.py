#!/usr/bin/env python3
"""Validate current BH-03 Phase 9 correction and superseding acceptance."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys

from bh03_history import AUTH, AUTH_SHA256, BASE
import validate_bh03_profile as profile
import validate_bh03_measurements as measurements

from research_paths import REPO_ROOT as ROOT
ASSETS = "docs/research/assets/bh-03-baseline/"
CANDIDATE = "72d398017d9fe67b7017d71bfb65356ce7f7b73a"
SOURCE_ROOTS = ["js/blazex_runtime/src", "js/blazex_runtime/test",
                "packages/blazex_host_browser", "packages/blazex_runtime_popcorn",
                "profiles/browser_phoenix/assets/phase6", "profiles/browser_phoenix/lib", "integration/bh-03"]
SCENARIOS = ["stale-event-rejection", "exit-replacement-root-replay", "abort-replacement-root-replay",
             "second-loss-fallback", "intentional-shutdown-no-replacement"]


class ValidationError(ValueError):
    pass


def require(value, message):
    if not value:
        raise ValidationError(message)


def read(path):
    return json.loads((ROOT / path).read_text())


def artifact(kind):
    return read(ASSETS + f"blazex-bh-03-phase-09-{kind}-v0.1.0.json")


def digest(path):
    return hashlib.sha256((ROOT / path).read_bytes()).hexdigest()


def git(*args):
    return subprocess.check_output(["git", *args], cwd=ROOT)


def bindings(rows, expected):
    paths = [row["path"] for row in rows]
    require(len(paths) == len(set(paths)) and set(paths) == set(expected), "binding inventory differs")
    for row in rows:
        path = (ROOT / row["path"]).resolve()
        require(path.is_relative_to(ROOT) and path.is_file(), "invalid binding path")
        require(digest(row["path"]) == row["sha256"], f"stale CURRENT artifact: {row['path']}")


def validate_recovery(evidence):
    require(evidence["implementation_revision"] == CANDIDATE, "recovery revision differs")
    require(evidence["scenario_set"] == SCENARIOS, "recovery scenario inventory differs")
    require(evidence["support_state"] == "unsupported" and evidence["api_state"] == "experimental-not-stable",
            "recovery support or API promoted")
    require(evidence["harness_sha256"] == digest("js/blazex_runtime/test/browser/bh03-phase9-recovery.integration.mjs"),
            "recovery harness is stale")
    require(evidence["deferred"] == ["safari", "mobile", "physical-devices", "second-host", "manual-assistive-technology"],
            "deferred inventory differs")
    rows = evidence["results"]
    require([row["browser"] for row in rows] == ["chrome", "firefox"], "active browser missing")
    for row in rows:
        require(row["result"] == "passed" and row["failures"] == [] and row["browser_version"]
                and row["executable"], "recovery browser did not pass")
        require([item["kind"] for item in row["observations"]] == ["exit", "abort"], "failure callbacks missing")
        for item in row["observations"]:
            ready, terminal = item["recovered"], item["terminal"]
            require(ready["state"] == "ready" and ready["runtime_starts"] == 2
                    and ready["scope"]["runtime_generation"] == 2, "replacement did not become ready")
            require(ready["registry"]["metrics"]["losses"] == ready["registry"]["metrics"]["recoveries"] == 1,
                    "replacement accounting differs")
            require(ready["roots"]["states"] == {"primary-root": "ready", "secondary-root": "ready"}
                    and ready["runtime_acknowledgement_count"] == 12, "root replay evidence missing")
            require(terminal["runtime_starts"] == 2 and item["frames_after_terminal"] == 0,
                    "replacement limit or transport cleanup violated")
            require(terminal["roots"]["accepting"] is False, "terminal roots still accepting")
            if item["kind"] == "exit":
                require(terminal["state"] == "fallback" and terminal["registry"]["metrics"]["losses"] == 2,
                        "second loss did not converge")
                require(terminal["fallback"]["partial_activation"] is False
                        and terminal["fallback"]["failure_class"] == "recovery-exhausted"
                        and all(state != "ready" for state in terminal["roots"]["states"].values()),
                        "fallback exposed partial activation")
            else:
                require(terminal["state"] == "stopped" and terminal["registry"]["metrics"]["losses"] == 1
                        and terminal["shutdown"]["acknowledged"] is True, "intentional stop triggered recovery")


def validate_decision(decision):
    require(decision["candidate_revision"] == CANDIDATE
            and decision["supersedes"] == "BX-BH03-PHASE-08-REVIEW-COMPLETE-REVISE",
            "candidate or supersession differs")
    require(decision["decision"] == "accepted-with-bounded-conditions"
            and decision["closed_finding"] == "BX-BH03-FINDING-UNREPORTED-RUNTIME-LOSS"
            and decision["bh04_eligible"] is True, "correction not accepted")
    require(decision["next_authorized_work"] is None, "BH-04 prematurely authorized")
    require(decision["support_state"] == "unsupported" and decision["api_state"] == "experimental-not-stable",
            "support or public API promoted")
    entry = read(ASSETS + "blazex-bh-03-entry-ledger-v0.1.0.json")
    require(decision["required_outputs"] == [row["id"] for row in entry["required_outputs"]],
            "milestone output omitted")
    predecessor = read(ASSETS + "blazex-bh-03-phase-08-reconciliation-v0.1.0.json")
    require(decision["carried_obligations"] == predecessor["obligations"], "inherited obligation silently changed")
    require(decision["release_budgets"] == [] and decision["limitations"], "measurement limits promoted")
    require(set(decision["review_lenses"]) == {"architecture", "implementation", "conformance",
            "accessibility", "security", "packaging", "provenance"}, "review lens omitted")
    require(all(decision["review_lenses"].values()) and decision["independence"], "review explanation missing")


def validate():
    # Phase 9 conformance changes governance readers, not the accepted BH-03
    # implementation. Reproduce that exact accepted gate, never rewrite its
    # completion hashes or treat current source drift as historical evidence.
    from bh04_phase9_history import enabled, snapshot
    if enabled(ROOT):
        with snapshot(ROOT) as historical:
            subprocess.run([sys.executable, "docs/research/validate_bh03_correction.py"],
                           cwd=historical, check=True, capture_output=True)
            return json.loads((historical / ASSETS /
                "blazex-bh-03-phase-09-acceptance-v0.1.0.json").read_text())["decision"]
    require(digest(AUTH) == AUTH_SHA256, "authority changed")
    auth = read(AUTH)
    require(auth["status"] == "approved-phase-9-only" and auth["base_revision"] == BASE
            and auth["base_remote_revision"] == BASE and auth["main_synchronized"] is True,
            "authority lacks synchronized base")
    for row in auth["inputs"]:
        require(digest(row["path"]) == row["sha256"], "immutable predecessor changed")
    decision = artifact("acceptance")
    validate_decision(decision)
    inventory = git("ls-tree", "-r", "--name-only", CANDIDATE, "--", *SOURCE_ROOTS).decode().splitlines()
    bindings(decision["source_bindings"], inventory)
    for row in decision["source_bindings"]:
        require(hashlib.sha256(git("show", f"{CANDIDATE}:{row['path']}")).hexdigest() == row["sha256"],
                "source is not the observed candidate")
    validate_recovery(artifact("recovery"))
    profile.validate_evidence(artifact("profile"), expected_revision=CANDIDATE)
    measurements.validate_evidence(artifact("measurements"), expected_revision=CANDIDATE)
    completion = artifact("completion")
    require(completion["state"] == "passed" and completion["decision"] == decision["decision"],
            "completion differs from acceptance")
    required = [ASSETS + f"blazex-bh-03-phase-09-{kind}-v0.1.0.{ext}" for kind, ext in [
        ("authorization", "json"), ("acceptance", "json"), ("recovery", "json"),
        ("profile", "json"), ("measurements", "json"), ("validation-log", "txt")]]
    required += ["docs/research/validate_bh03_correction.py", "docs/research/test_validate_bh03_correction.py",
                 "docs/research/bh03_history.py", "docs/research/test_bh03_history.py"]
    required += [path for path in auth["mutable_historical_paths"] if path.startswith("docs/")]
    plan = "docs/research/60-planning/01-browser-host/bh-03-browser-execution-host-and-runtime-boot-lifecycle/"
    required += [plan + "phase-09-runtime-loss-correction-and-renewed-acceptance.md",
                 plan + "phase-09-implementation-evidence.md"]
    bindings(completion["artifact_hashes"], required)
    require("- [ ]" not in (ROOT / plan / "phase-09-runtime-loss-correction-and-renewed-acceptance.md").read_text(),
            "phase has incomplete tasks")
    require(completion["section_commits"] == [
        "fd16b2a13fd5a2ba18549f499d59448f86fe1536", "fb2838054abf23c59af5f4dba23e501068b8d1f2",
        CANDIDATE, "resolve-from-this-records-git-commit"], "section commits differ")
    git("merge-base", "--is-ancestor", CANDIDATE, "HEAD")
    return decision["decision"]


def main():
    try:
        print("BH-03 Phase 9: " + validate() + "; BH-04 eligible, not authorized; unsupported experimental state.")
    except (ValueError, KeyError, TypeError, OSError, subprocess.CalledProcessError,
            profile.ValidationError, measurements.ValidationError) as error:
        print(f"BH-03 Phase 9 validation failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
