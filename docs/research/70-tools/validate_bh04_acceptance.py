"""Validate the Phase 10 evidence candidate; --require-accepted gates downstream work."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys
from bh04_phase10_history import AUTH, BASE, enabled
from tooling_migration import historical_binding_bytes, historical_gate_names, is_migrated_caller

from research_paths import REPO_ROOT as ROOT
PREFIX = "docs/research/assets/bh-04-baseline/blazex-bh-04-phase-10-"
def read(root, name):
    return json.loads((root / (PREFIX + name + "-v0.1.0.json")).read_text())

def decision_errors(record):
    errors = []
    try:
        if record["decision"] != "revise" or record["bh05_eligible"] or record["next_authorized_work"] is not None:
            errors.append("unsupported acceptance or downstream authority")
        if record["support_state"] != "unsupported" or record["canonical_registry_modified"]:
            errors.append("support or canonical registry promotion")
        if len(record["conditions"]) != 5 or len({r["id"] for r in record["conditions"]}) != 5:
            errors.append("five conditions required")
        if any(r["release_pass_credit"] for r in record["conditions"]):
            errors.append("release credit forbidden")
        if {r["id"] for r in record["open_blockers"]} != {"BH04-10-PAINT", "BH04-10-INDEPENDENCE"}:
            errors.append("hidden active blocker")
        if not all(r["owner"] and r["due"] and r["mitigation"] and r["blocks_acceptance"] and r["blocks_bh05"] for r in record["open_blockers"]):
            errors.append("unowned or bypassed blocker")
    except (KeyError, TypeError, ValueError):
        errors.append("malformed decision")
    return errors

def validate(root=ROOT, final=True):
    root = Path(root)
    errors = []
    def check(ok, message):
        if not ok:
            errors.append(message)
    def bindings(values):
        for file, expected in values.items():
            check(hashlib.sha256(historical_binding_bytes(root, file)).hexdigest() == expected, "stale binding: " + file)
    try:
        check(enabled(root), "missing authority")
        auth = json.loads((root / AUTH).read_text())
        check(auth["base_revision"] == BASE, "base mismatch")
        subprocess.run(["git", "merge-base", "--is-ancestor", BASE, "HEAD"], cwd=root, check=True, capture_output=True)
        bindings(auth["source_bindings"])
        bindings(read(root, "measurements")["source_hashes"])
        for name in ["statistics", "acceptance-overlay", "release-index", "reconciliation"]:
            bindings(read(root, name)["source_hashes"])
        overlay = read(root, "acceptance-overlay")
        errors.extend(decision_errors(overlay))
        entry = json.loads((root / "docs/research/assets/bh-04-baseline/blazex-bh-04-entry-ledger-v0.1.0.json").read_text())
        reconciliation = read(root, "reconciliation")
        check(reconciliation["inherited_obligations"] == entry["predecessor_handoff"]["carried_obligations"], "lost inherited obligation")
        check({r["id"] for r in overlay["conditions"]} == {r["id"] for r in entry["acceptance_records"]}, "changed acceptance inventory")
        for group in reconciliation["outputs"].values():
            check(bool(group["source_hashes"]), "empty output binding")
            bindings(group["source_hashes"])
        review = read(root, "review")
        check(not review["independent"] and not review["approval"], "invented review independence")
        check([r["lens"] for r in review["lenses"]] == auth["review_lenses"], "review coverage")
        check(all(r["owner"] and not r["pass_credit"] for r in review["deferred"]), "deferral promotion")
        for command in ["acceptance-report.mjs", "acceptance-release.mjs", "acceptance-corpora.mjs"]:
            subprocess.run(["node", "integration/bh-04/" + command], cwd=root, check=True, capture_output=True)
        changed = subprocess.check_output(["git", "diff", "--name-only", BASE, "--", "packages", "js", "profiles", "experiments"], cwd=root, text=True).splitlines()
        check(all(is_migrated_caller(root, path) for path in changed),
              "runtime/package/profile change outside measurement scope")
        if final:
            gates = read(root, "gate-log")["results"]
            required = {"elixir", "javascript", "atomic-browser", "interaction-browser", "interaction-replay", "continuity-browser", "continuity-replay", "effect-browser", "effect-replay", "semantic-browser", "isolation", "research-tests", "patch-hygiene"}
            required |= historical_gate_names(root)
            check({r["name"] for r in gates} == required and len(gates) == len(required), "gate inventory")
            check(all(r["exit_code"] == 0 and r["error"] is None for r in gates), "active execution failure")
            execution = read(root, "execution-index")
            check(execution["result"] == "passed", "execution not passed")
            bindings(execution["source_hashes"])
            files = subprocess.check_output(["git", "ls-files", "--cached", "--others", "--exclude-standard", "--", "packages", "js", "integration"], cwd=root, text=True).splitlines()
            current_sources = {p for p in files if "node_modules" not in p and (root / p).is_file()}
            check(current_sources == set(execution["source_hashes"]), "unindexed executable source")
            completion = read(root, "completion")
            check(completion["decision"] == "revise" and not completion["bh04_accepted"] and not completion["bh05_eligible"], "false completion")
            bindings(completion["artifact_hashes"])
            check([s["section"] for s in completion["section_commits"]] == ["10.1", "10.2", "10.3", "10.4", "10.5"], "section provenance")
            for section in completion["section_commits"][:4]:
                subject = subprocess.check_output(["git", "show", "-s", "--format=%s", section["commit"]], cwd=root, text=True)
                check(subject.startswith("BH-04 " + section["section"] + " "), "section subject mismatch")
                subprocess.run(["git", "merge-base", "--is-ancestor", section["commit"], "HEAD"], cwd=root, check=True, capture_output=True)
    except (OSError, KeyError, TypeError, ValueError, subprocess.CalledProcessError) as error:
        errors.append("Cannot establish candidate: " + str(error))
    return errors

if __name__ == "__main__":
    errors = validate(final="--candidate" not in sys.argv)
    if errors:
        print("\n".join(errors)); sys.exit(1)
    print("Phase 10 evidence candidate valid: REVISE; BH-04 not accepted; BH-05 ineligible and unauthorized.")
    if "--require-accepted" in sys.argv:
        print("Blocked: compositor-paint evidence and independent review required.")
        sys.exit(1)
