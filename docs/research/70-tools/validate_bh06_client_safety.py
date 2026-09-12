"""Validate BH-06 Phase 3 server/native client-safety evidence."""

import hashlib
import json
import sys
from pathlib import Path

from research_paths import REPO_ROOT

AUTHORITY = "docs/research/assets/bh-06-baseline/phase-03-authorization-v0.1.0.json"
POLICY = "integration/bh-06/client-safety-policy-v0.1.0.json"
REPORT = "integration/bh-06/client-safety-v0.1.0.json"
MANIFEST = "integration/bh-06/phase-03-build-manifest-v0.1.0.json"
BROWSER = "integration/bh-06/phase-03-browser-replay-v0.1.0.json"
INDEX = "integration/bh-06/index-v0.1.0.json"
COMPLETION = "docs/research/assets/bh-06-baseline/phase-03-completion-v0.1.0.json"
PLAN = "docs/research/60-planning/01-browser-host/bh-06-build-compatibility-and-client-safety-pipeline/phase-03-server-native-client-safety-gate.md"
CLOSURE = "packages/blazex_build/lib/blazex/build/client_closure.ex"
TASK = "integration/bh-06/vertical_slice/lib/mix/tasks/bh06.package.ex"
ROLES = {
    "document", "runtime-module", "runtime-wasm", "application-bundle",
    "browser-host", "reachability-report", "client-safety-report",
}
MUTABLE_BASELINES = {
    "packages/blazex_build/lib/blazex/build/beam_inventory.ex":
        "3792b2c35b3b78379a7528d0f4ae8b3092cbf884da2ca144796874572248bd25",
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
    policy = load(root, POLICY)
    report = load(root, REPORT)
    manifest = load(root, MANIFEST)
    browser = load(root, BROWSER)
    index = load(root, INDEX)
    completion = load(root, COMPLETION)

    if authority.get("authorized") is not True or authority.get("phase") != 3:
        errors.append("Phase 3 authority is invalid")
    for relative, expected in authority.get("bound_inputs", {}).items():
        if relative in MUTABLE_BASELINES:
            if expected != MUTABLE_BASELINES[relative]:
                errors.append(f"mutable baseline identity drift: {relative}")
            continue
        path = root / relative
        if not path.is_file() or digest(path) != expected:
            errors.append(f"bound input drift: {relative}")

    if report.get("phase") != 3 or report.get("status") != "complete" or report.get("violations") != []:
        errors.append("client-safety result is not a passing Phase 3 report")
    if report.get("policy_id") != policy.get("policy_id") or report.get("policy_sha256") != canonical_digest(policy):
        errors.append("client-safety report does not bind the normalized policy")

    modules = report.get("modules", [])
    externals = report.get("external_modules", [])
    if modules != sorted(modules, key=lambda row: row.get("module", "")) or len({row.get("module") for row in modules}) != len(modules):
        errors.append("classified modules are duplicate or unordered")
    if externals != sorted(externals, key=lambda row: row.get("module", "")) or len({row.get("module") for row in externals}) != len(externals):
        errors.append("classified external modules are duplicate or unordered")
    if any(row.get("classification") != "client-safe" for row in modules):
        errors.append("reachable module is not client-safe")
    if any(row.get("classification") != "runtime-safe" for row in externals):
        errors.append("external module is not runtime-safe")
    if [row.get("module") for row in modules] != ["Elixir.BlazeX.BH06.VerticalSlice.Counter"]:
        errors.append("bounded reachable classification drifted")
    if [row.get("module") for row in externals] != ["erlang"]:
        errors.append("bounded external classification drifted")

    forbidden = {
        (row.get("module"), row.get("function"), arity)
        for row in policy.get("forbidden_imports", []) for arity in row.get("arities", [])
    }
    required_forbidden = {
        ("erlang", "load_nif", 2), ("erlang", "open_port", 2),
        ("erlang", "port_command", 2), ("erlang", "port_command", 3),
        ("erlang", "port_connect", 2), ("erlang", "port_control", 3),
    }
    if forbidden != required_forbidden:
        errors.append("NIF/port forbidden primitive policy is incomplete")

    expected_summary = {
        "reachable_modules": len(modules),
        "external_modules": len(externals),
        "client_safe_modules": sum(row.get("classification") == "client-safe" for row in modules),
        "runtime_safe_externals": sum(row.get("classification") == "runtime-safe" for row in externals),
        "forbidden_primitives_checked": len(forbidden),
        "violations": len(report.get("violations", [])),
    }
    if report.get("summary") != expected_summary:
        errors.append("client-safety summary does not match its records")

    artifacts = manifest.get("artifacts", [])
    if {item.get("role") for item in artifacts} != ROLES or len(artifacts) != len(ROLES):
        errors.append("Phase 3 manifest roles are incomplete or duplicate")
    safety_assets = [item for item in artifacts if item.get("role") == "client-safety-report"]
    if len(safety_assets) != 1 or safety_assets[0].get("sha256") != canonical_digest(report):
        errors.append("manifest does not bind the canonical client-safety report")
    if browser.get("manifest_sha256") != digest(root / MANIFEST):
        errors.append("browser replay does not bind the exact Phase 3 manifest")
    if [row.get("browser") for row in browser.get("results", [])] != ["chrome", "firefox"]:
        errors.append("Phase 3 active-browser replay is incomplete or reordered")
    for row in browser.get("results", []):
        if row.get("result") != "passed" or row.get("runtime") != "atomvm-wasm" or row.get("page_errors") != []:
            errors.append(f"Phase 3 browser replay failed: {row.get('browser')}")
    if browser.get("comparison", {}).get("state") != "exact-match":
        errors.append("Phase 3 browsers did not match exactly")
    if browser.get("negative_integrity", {}).get("result") != "failed":
        errors.append("Phase 3 integrity mutation did not fail closed")

    closure = (root / CLOSURE).read_text(encoding="utf-8")
    task = (root / TASK).read_text(encoding="utf-8")
    if "ClientSafety.analyze!" not in closure or "assemble.(safety)" not in closure or closure.index("ClientSafety.analyze!") > closure.index("assemble.(safety)"):
        errors.append("client-safety authorization no longer precedes assembly")
    if "ClientClosure.authorize!" not in task:
        errors.append("candidate package bypasses the pre-assembly safety gate")

    required_evidence = {
        Path(POLICY).name, Path(REPORT).name, Path(MANIFEST).name, Path(BROWSER).name,
    }
    if index.get("phase", 0) < 3 or index.get("status") != "complete" or not required_evidence.issubset(index.get("evidence", [])):
        errors.append("BH-06 Phase 3 evidence index is incomplete")
    expected_completion = {
        "decision": "accept",
        "manifest_sha256": digest(root / MANIFEST),
        "policy_evidence_sha256": digest(root / POLICY),
        "safety_evidence_sha256": digest(root / REPORT),
        "canonical_policy_sha256": canonical_digest(policy),
        "canonical_safety_sha256": canonical_digest(report),
        "browser_evidence_sha256": digest(root / BROWSER),
    }
    if any(completion.get(key) != value for key, value in expected_completion.items()):
        errors.append("Phase 3 completion identities are stale")
    if "- [ ]" in (root / PLAN).read_text(encoding="utf-8"):
        errors.append("Phase 3 checklist is incomplete")
    return errors


if __name__ == "__main__":
    failures = validate()
    print("\n".join(failures) if failures else "BH-06 Phase 3 client safety: PASS")
    sys.exit(bool(failures))
