"""Fail-closed BH-05 Phase 1 governance; no component implementation permitted."""
import json
from pathlib import Path
import re
import subprocess
import sys
import jsonschema
from research_paths import REPO_ROOT
from generate_bh05_activation import AREA, BASE, PLAN, DECISION, PACKAGES, GROUPS, PHASES, blob, sha, records as entry_records
from generate_bh05_boundary import GRAPH, ACTIVATION, records as boundary_records
from validate_bh04_correction import immutable_input_errors, source_files, bindings, execution_source_errors

AUTH_SHA = "40abdba6bd157dd48b5573fa836b1a03dd37946a71a448b5df0d6e49fc4a571c"
MANIFESTS = {"packages/" + p + "/blazex.project.json" for p in PACKAGES} | {"profiles/browser_phoenix/blazex.project.json"}
NEW_TOOLS = {"generate_bh05_activation.py", "generate_bh05_boundary.py", "validate_bh05_activation.py", "test_validate_bh05_activation.py", "record_bh05_phase1.py"}
INTEGRATION = {"README.md", "index-v0.1.0.json", "index.schema.json"}
GATES = {"packages", "javascript", "predecessor-acceptance", "predecessor-generator", "historical-sweep", "activation-tests", "activation-validator", "activation-generators", "archive", "json", "hygiene"}
FORBIDDEN = re.compile(r"\b(?:Phoenix|Plug|LiveView|LocalLiveView|Popcorn|AtomVM|System\.Web|Microsoft\.|Razor|Qt|wxWidgets)\b|BlazeX\.(?:Runtime|Host|Renderer\.DOM)|\b(?:document|window)\.", re.I)


def read(root, path):
    return json.loads((root / path).read_text())


def execution_sources(root):
    files = current_files(root)
    files += [AREA + name for name in ["authorization-v0.1.0.json", "entry-ledger-v0.1.0.json", "ownership-v0.1.0.json"]]
    return bindings(root, files)


def current_files(root):
    experiments = subprocess.check_output(["git", "ls-files", "--cached", "--others", "--exclude-standard", "--", "experiments"], cwd=root, text=True).splitlines()
    return sorted(set(source_files(root) + experiments))


def validate(root=REPO_ROOT, final=False):
    root = Path(root); errors = []
    def check(ok, message):
        if not ok:
            errors.append(message)
    try:
        subprocess.run(["git", "merge-base", "--is-ancestor", BASE, "HEAD"], cwd=root, check=True, capture_output=True)
        authority = read(root, AREA + "authorization-v0.1.0.json")
        check(sha((root / AREA / "authorization-v0.1.0.json").read_bytes()) == AUTH_SHA, "authority missing, modified or expanded")
        for name, expected in entry_records(root).items():
            check(read(root, AREA + name) == expected, "entry/acceptance/owner/deferral mismatch: " + name)
        for path, digest in authority["source_bindings"].items():
            check(sha((root / path).read_bytes()) == digest == sha(blob(root, path)), "stale inherited input: " + path)
        for path, digest in json.loads(blob(root, DECISION))["artifact_hashes"].items():
            check(sha((root / path).read_bytes()) == digest, "altered predecessor evidence: " + path)
        plans = sorted((root / PLAN).glob("phase-??-*.md"))
        check([int(p.name[6:8]) for p in plans] == list(range(1, 13)), "twelve ordered phase plans required")
        for p in plans:
            path = p.relative_to(root).as_posix()
            check(sha(p.read_text().replace("[x]", "[ ]").encode()) == authority["phase_plan_hashes"].get(path), "changed or broken phase plan: " + path)
            check(p.name in (root / PLAN / "README.md").read_text(), "unindexed phase plan: " + path)
            if int(p.name[6:8]) > 1:
                check("- [x]" not in p.read_text(), "premature later phase completion")
        for path, expected in boundary_records(root).items():
            check(read(root, path) == expected, "ownership or empty evidence mismatch: " + path)
        index = read(root, "integration/bh-05/index-v0.1.0.json")
        schema = read(root, "integration/bh-05/index.schema.json")
        jsonschema.Draft202012Validator.check_schema(schema)
        for error in jsonschema.Draft202012Validator(schema).iter_errors(index):
            errors.append("closed empty evidence schema: " + error.message)
        check({p.name for p in (root / "integration/bh-05").iterdir()} == INTEGRATION, "unindexed or implemented integration surface")
        allowed_artifacts = {"README.md", "authorization-v0.1.0.json", "entry-ledger-v0.1.0.json", "ownership-v0.1.0.json", "phase-01-gates-v0.1.0.json", "phase-01-completion-v0.1.0.json"}
        check({p.name for p in (root / AREA).iterdir()} <= allowed_artifacts, "unindexed or fabricated activation evidence")
        for path in MANIFESTS:
            current, previous = read(root, path), json.loads(blob(root, path))
            check(current.pop("bh05_activation", None) == ACTIVATION, "invalid activation manifest: " + path)
            check(current == previous, "package/profile contract changed: " + path)
        for package, deps in GRAPH.items():
            manifest = read(root, "packages/" + package + "/blazex.project.json")
            check(manifest["dependencies"] == deps, "forbidden direct/transitive dependency: " + package)
            mix = (root / "packages" / package / "mix.exs").read_text()
            check(re.findall(r"\{:(\w+),\s*path:", mix) == deps, "Mix dependency graph mismatch: " + package)
            # Only concrete adapter/framework imports are forbidden; inherited
            # portable validators and the abstract renderer test contract stay.
            for p in (root / "packages" / package / "lib").rglob("*.ex"):
                imports = "\n".join(line for line in p.read_text().splitlines() if re.match(r"\s*(alias|import|use|require)\s", line))
                check(not FORBIDDEN.search(imports), "host/framework/private import: " + p.relative_to(root).as_posix())
        tree = subprocess.check_output(["git", "ls-tree", "-r", BASE, "--", "packages", "js", "profiles", "experiments", "docs/research/70-tools", "docs/research/assets"], cwd=root, text=True)
        frozen = {}
        for line in tree.splitlines():
            meta, path = line.split("\t", 1)
            if path.endswith(".md") or path in MANIFESTS:
                continue
            frozen[path] = meta.split()[2]
        errors.extend(immutable_input_errors(root, frozen))
        old_paths = set(subprocess.check_output(["git", "ls-tree", "-r", "--name-only", BASE], cwd=root, text=True).splitlines())
        for path in current_files(root):
            if path in old_paths:
                continue
            allowed = (path.startswith("docs/research/70-tools/") and Path(path).name in NEW_TOOLS) or (path.startswith("integration/bh-05/") and Path(path).name in INTEGRATION)
            check(allowed, "new implementation surface forbidden: " + path)
        all_files = subprocess.check_output(["git", "ls-files", "--cached", "--others", "--exclude-standard"], cwd=root, text=True).splitlines()
        for path in all_files:
            if path not in old_paths and Path(path).suffix in {".py", ".ex", ".exs", ".js", ".mjs", ".wasm"}:
                check(path.startswith("docs/research/70-tools/") and Path(path).name in NEW_TOOLS, "executable outside Phase 1 tooling: " + path)
        check(set(PHASES) == {r["canonical"]["id"] for r in read(root, AREA + "entry-ledger-v0.1.0.json")["acceptance"]}, "nine acceptance IDs required")
        if final:
            gate = read(root, AREA + "phase-01-gates-v0.1.0.json")
            check(len(gate["results"]) == len(GATES) and {r["name"] for r in gate["results"]} == GATES, "incomplete execution gate inventory")
            check(all(r["exit_code"] == 0 and r["error"] is None for r in gate["results"]), "active gate failure")
            errors.extend(execution_source_errors(gate, execution_sources(root)))
            check(gate["predecessor_revision"] == BASE and gate["historical_revision"] == "d61e103b14595acca182611524eb4c7245906f20", "incorrect replay revision")
            done = read(root, AREA + "phase-01-completion-v0.1.0.json")
            check(done["decision"] == "phase-1-complete-governance-only" and done["phase2_eligible"] is True and done["phase2_authorized"] is False and done["bh06_eligible"] is False and done["support_state"] == "unsupported", "unsupported completion or later authority")
            expected = [AREA + p for p in ["authorization-v0.1.0.json", "entry-ledger-v0.1.0.json", "ownership-v0.1.0.json", "phase-01-gates-v0.1.0.json"]] + ["integration/bh-05/index-v0.1.0.json", "integration/bh-05/index.schema.json"]
            check(done["artifact_hashes"] == bindings(root, expected), "stale completion binding")
            check(done["behavior_implemented"] is False and done["runtime_results"] == [], "fabricated behavior/parity evidence")
    except (OSError, KeyError, TypeError, ValueError, subprocess.CalledProcessError, jsonschema.exceptions.SchemaError) as error:
        errors.append("Cannot establish BH-05 activation: " + str(error))
    return errors


if __name__ == "__main__":
    errors = validate(final="--final" in sys.argv)
    if errors:
        print("\n".join(errors)); sys.exit(1)
    print("BH-05 Phase 1 governance valid; component behavior, later authority and support remain absent.")
