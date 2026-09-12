"""Validate BH-06 Phase 2 entrypoints, reachability, and exact replay evidence."""

import hashlib
import json
import re
import sys
from pathlib import Path

from research_paths import REPO_ROOT

AUTHORITY = "docs/research/assets/bh-06-baseline/phase-02-authorization-v0.1.0.json"
REPORT = "integration/bh-06/reachability-v0.1.0.json"
MANIFEST = "integration/bh-06/phase-02-build-manifest-v0.1.0.json"
BROWSER = "integration/bh-06/phase-02-browser-replay-v0.1.0.json"
INDEX = "integration/bh-06/index-v0.1.0.json"
COMPLETION = "docs/research/assets/bh-06-baseline/phase-02-completion-v0.1.0.json"
PLAN = "docs/research/60-planning/01-browser-host/bh-06-build-compatibility-and-client-safety-pipeline/phase-02-explicit-entrypoints-and-deterministic-reachability.md"
SHA256 = re.compile(r"[0-9a-f]{64}")
ENTRYPOINT = {"id": "counter", "module": "Elixir.BlazeX.BH06.VerticalSlice.Counter"}
MUTABLE_BOUND_INPUTS = {"packages/blazex_build/lib/blazex/build/pipeline.ex"}
MUTABLE_BASELINES = {
    "packages/blazex_build/lib/blazex/build/pipeline.ex":
        "de4ebf41ad9a0831109ecb02f2ab5f93a7d34c54980ec56ec366c5240b015a16",
}
ROLES = {
    "document", "runtime-module", "runtime-wasm", "application-bundle",
    "browser-host", "reachability-report",
}


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load(root: Path, relative: str):
    return json.loads((root / relative).read_text(encoding="utf-8"))


def canonical_digest(value) -> str:
    body = json.dumps(value, sort_keys=True, separators=(",", ":")) + "\n"
    return hashlib.sha256(body.encode()).hexdigest()


def validate(root=REPO_ROOT):
    root = Path(root)
    errors = []
    authority = load(root, AUTHORITY)
    report = load(root, REPORT)
    manifest = load(root, MANIFEST)
    browser = load(root, BROWSER)
    index = load(root, INDEX)
    completion = load(root, COMPLETION)

    if authority.get("authorized") is not True or authority.get("phase") != 2:
        errors.append("Phase 2 authority is invalid")
    for relative, expected in authority.get("bound_inputs", {}).items():
        if relative in MUTABLE_BOUND_INPUTS:
            if expected != MUTABLE_BASELINES[relative]:
                errors.append(f"mutable baseline identity drift: {relative}")
            continue
        path = root / relative
        if not path.is_file() or digest(path) != expected:
            errors.append(f"bound input drift: {relative}")

    if report.get("schema_version") != "1.0.0" or report.get("phase") != 2 or report.get("status") != "complete":
        errors.append("reachability result is not complete Phase 2 evidence")
    if report.get("entrypoints") != [ENTRYPOINT]:
        errors.append("explicit entrypoint declaration drifted")

    rows = report.get("modules", [])
    modules = {row.get("module"): row for row in rows}
    if len(modules) != len(rows) or list(modules) != sorted(modules):
        errors.append("reachable modules are duplicate or unordered")
    for module, row in modules.items():
        chain = row.get("reason_chain", [])
        imports = row.get("known_imports", [])
        if not SHA256.fullmatch(str(row.get("sha256", ""))):
            errors.append(f"invalid module digest: {module}")
        if not chain or chain[-1] != module or chain[0] != ENTRYPOINT["module"]:
            errors.append(f"module lacks an entrypoint-rooted reason: {module}")
        for source, target in zip(chain, chain[1:]):
            if target not in modules.get(source, {}).get("known_imports", []):
                errors.append(f"reason chain lacks a known edge: {source} -> {target}")
        if imports != sorted(set(imports)):
            errors.append(f"known imports are duplicate or unordered: {module}")

    unused = report.get("unused_modules", [])
    if unused != sorted(set(unused)) or set(unused) & set(modules):
        errors.append("unused modules are duplicate, unordered, or reachable")
    if unused != ["Elixir.BlazeX.BH06.VerticalSlice.Unused"]:
        errors.append("unused-module exclusion sentinel is missing")
    external = report.get("external_references", [])
    external_key = lambda row: (row.get("from"), row.get("module"), row.get("function"), row.get("arity"))
    if external != sorted(external, key=external_key) or len({external_key(row) for row in external}) != len(external):
        errors.append("external references are duplicate or unordered")
    if report.get("dynamic_allowances") != []:
        errors.append("unexpected dynamic-dispatch allowance")

    expected_summary = {
        "dynamic_allowances": len(report.get("dynamic_allowances", [])),
        "entrypoints": len(report.get("entrypoints", [])),
        "external_references": len(external),
        "inventory_modules": len(rows) + len(unused),
        "known_edges": sum(len(row.get("known_imports", [])) for row in rows),
        "reachable_modules": len(rows),
        "unused_modules": len(unused),
    }
    if report.get("summary") != expected_summary:
        errors.append("reachability summary does not match its records")

    artifacts = manifest.get("artifacts", [])
    if {item.get("role") for item in artifacts} != ROLES or len(artifacts) != len(ROLES):
        errors.append("Phase 2 manifest roles are incomplete or duplicate")
    reachability = [item for item in artifacts if item.get("role") == "reachability-report"]
    if len(reachability) != 1 or reachability[0].get("sha256") != canonical_digest(report):
        errors.append("manifest does not bind the canonical reachability report")
    if browser.get("manifest_sha256") != digest(root / MANIFEST):
        errors.append("browser replay does not bind the exact Phase 2 manifest")
    if [row.get("browser") for row in browser.get("results", [])] != ["chrome", "firefox"]:
        errors.append("Phase 2 active-browser replay is incomplete or reordered")
    for row in browser.get("results", []):
        if row.get("result") != "passed" or row.get("runtime") != "atomvm-wasm" or row.get("page_errors") != []:
            errors.append(f"Phase 2 browser replay failed: {row.get('browser')}")
    if browser.get("comparison", {}).get("state") != "exact-match":
        errors.append("Phase 2 browsers did not match exactly")
    if browser.get("negative_integrity", {}).get("result") != "failed":
        errors.append("Phase 2 integrity mutation did not fail closed")

    expected_evidence = {
        "candidate-build-manifest-v0.1.0.json", "browser-slice-v0.1.0.json",
        Path(MANIFEST).name, Path(BROWSER).name, Path(REPORT).name,
    }
    if index.get("phase", 0) < 2 or index.get("status") != "complete" or not expected_evidence.issubset(index.get("evidence", [])):
        errors.append("BH-06 Phase 2 evidence index is incomplete")
    expected_completion = {
        "decision": "accept",
        "manifest_sha256": digest(root / MANIFEST),
        "reachability_evidence_sha256": digest(root / REPORT),
        "canonical_reachability_sha256": canonical_digest(report),
        "browser_evidence_sha256": digest(root / BROWSER),
    }
    if any(completion.get(key) != value for key, value in expected_completion.items()):
        errors.append("Phase 2 completion identities are stale")
    if "- [ ]" in (root / PLAN).read_text(encoding="utf-8"):
        errors.append("Phase 2 checklist is incomplete")
    return errors


if __name__ == "__main__":
    failures = validate()
    print("\n".join(failures) if failures else "BH-06 Phase 2 reachability: PASS")
    sys.exit(bool(failures))
