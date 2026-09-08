"""Phase 9 exact-source, raw-evidence and active/deferred conformance gate."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys

from bh04_phase9_history import AUTH, BASE, enabled
from validate_bh04_lifecycle import browser_errors as effect_errors

ROOT = Path(__file__).resolve().parents[2]
ASSETS = "docs/research/assets/bh-04-baseline/"
PREFIX = ASSETS + "blazex-bh-04-phase-09-"
LEDGER = PREFIX + "conformance-ledger-v0.1.0.json"
INDEX = PREFIX + "source-index-v0.1.0.json"
COMPLETION = PREFIX + "completion-v0.1.0.json"

def sha(data):
    return hashlib.sha256(data).hexdigest()

def read(path):
    return json.loads(Path(path).read_text())

def ledger_errors(data):
    errors = []
    def check(condition, message):
        if not condition:
            errors.append(message)
    try:
        check(data["phase"] == 9 and data["schema_version"] == "1.0.0", "ledger identity")
        check(data["result"] == "passed" and data["support_state"] == "unsupported", "result/support promotion")
        check(data["active_rows"] == len(data["ledger"]) == 263, "active inventory")
        check(all(r["result"] == "passed" for r in data["ledger"]), "active mismatch")
        check({r["path"] for r in data["ledger"]} == {"headless", "chrome", "firefox"}, "path inventory")
        check([r["browser"] for r in data["browsers"]] == ["chrome", "firefox"] and all(r["version"] for r in data["browsers"]), "browser inventory")
        check(len(data["deferred"]) == 2 and all(r["owner"] and r["reactivation"] for r in data["deferred"]), "unowned deferral")
        check(any("LiveView" in r["scope"] for r in data["deferred"]), "framework scope drift")
        check(len(data["not_applicable"]) == 1 and data["not_applicable"][0]["path"] == "headless", "headless observation limits")
        check(data["next_eligible_phase"] == 10 and data["next_authorized_work"] is None, "authority promotion")
        check(len(data["source_hashes"]) == 7, "raw input inventory")
        check("not platform accessibility" in data["accessibility_method"], "accessibility overclaim")
        identities = [(r["scenario"], r["path"], r.get("repeat")) for r in data["ledger"]]
        check(len(set(identities)) == 263, "duplicate evidence row")
    except (KeyError, TypeError, ValueError):
        errors.append("malformed ledger")
    return errors

def validate(root=ROOT, completion=True):
    root = Path(root)
    errors = []
    def check(condition, message):
        if not condition:
            errors.append(message)
    try:
        check(enabled(root), "exact phase authority missing")
        auth = read(root / AUTH)
        check(auth["base_revision"] == BASE, "base mismatch")
        subprocess.run(["git", "merge-base", "--is-ancestor", BASE, "HEAD"], cwd=root, check=True, capture_output=True)
        for file, expected in auth["source_bindings"].items():
            check(sha((root / file).read_bytes()) == expected, "inherited binding changed: " + file)
        index = read(root / INDEX)
        for file, expected in index["source_bindings"].items():
            check(sha((root / file).read_bytes()) == expected, "source binding changed: " + file)
        prefixes = ["packages", "js", "integration", "profiles", "experiments"]
        changed = set(subprocess.check_output(["git", "diff", "--name-only", BASE, "--", *prefixes], cwd=root, text=True).splitlines())
        changed.update(subprocess.check_output(["git", "ls-files", "--others", "--exclude-standard", "--", *prefixes], cwd=root, text=True).splitlines())
        check(changed <= set(index["source_bindings"]), "unindexed implementation change")
        check(all(file.startswith("integration/bh-04/") for file in changed), "unexpected runtime/package/profile change")
        ledger = read(root / LEDGER)
        errors.extend(ledger_errors(ledger))
        for file, expected in ledger["source_hashes"].items():
            actual = root / ("integration/bh-04/" if file.startswith("conformance-fixtures") else ASSETS) / file
            check(sha(actual.read_bytes()) == expected, "raw evidence changed: " + file)
        errors.extend(effect_errors(read(root / (PREFIX + "effect-browser-v0.1.0.json"))))
        for command in [
            ["node", "integration/bh-04/conformance-test.mjs"],
            ["node", "integration/bh-04/conformance-report.mjs"],
            *[["node", "integration/bh-04/" + name + "-conformance.mjs", PREFIX + name + "-browser-v0.1.0.json"] for name in ["interaction", "continuity", "effect"]],
        ]:
            run = subprocess.run(command, cwd=root, capture_output=True, text=True)
            check(run.returncode == 0, "replay/comparison failed: " + " ".join(command))
        if completion:
            record = read(root / COMPLETION)
            check(record["phase"] == 9 and record["decision"] == "passed" and record["base_revision"] == BASE, "completion identity")
            check(record["next_eligible_phase"] == 10 and record["next_authorized_work"] is None and not record["bh05_eligible"] and record["support_state"] == "unsupported", "completion authority/support")
            required = {"elixir", "javascript", "browser-corpora", "independent-replay", "isolation", "research-tests", "validators", "generators", "json-hygiene"}
            check({r["name"] for r in record["gates"]} == required and all(r["exit_code"] == 0 for r in record["gates"]), "missing/failed gate")
            for file, expected in record["artifact_hashes"].items():
                check(sha((root / file).read_bytes()) == expected, "completion artifact changed: " + file)
            check({AUTH, INDEX, LEDGER} <= set(record["artifact_hashes"]), "completion artifacts missing")
            check([r["section"] for r in record["section_commits"]] == ["9.1", "9.2", "9.3", "9.4", "9.5"], "section provenance")
            for section in record["section_commits"][:4]:
                subject = subprocess.check_output(["git", "show", "-s", "--format=%s", section["commit"]], cwd=root, text=True)
                check(subject.startswith("BH-04 " + section["section"] + " "), "section subject")
                subprocess.run(["git", "merge-base", "--is-ancestor", section["commit"], "HEAD"], cwd=root, check=True, capture_output=True)
            plan = (root / "docs/research/60-planning/01-browser-host/bh-04-dom-renderer-and-interaction-transport/phase-09-cross-path-accessibility-and-browser-conformance.md").read_text()
            check(all("[DEFERRED]" in line for line in plan.splitlines() if "[ ]" in line), "active checklist incomplete")
    except (OSError, KeyError, TypeError, ValueError, subprocess.CalledProcessError) as error:
        errors.append("Cannot establish Phase 9 evidence: " + str(error))
    return errors

if __name__ == "__main__":
    from bh04_phase10_history import enabled as phase10_enabled, run_phase9
    if phase10_enabled(ROOT):
        run_phase9(ROOT)
        sys.exit(0)
    errors = validate(completion="--candidate" not in sys.argv)
    if errors:
        print("\n".join(errors)); sys.exit(1)
    print("BH-04 Phase 9 conformance passed; Phase 10 eligible but unauthorized; framework integration deferred.")
