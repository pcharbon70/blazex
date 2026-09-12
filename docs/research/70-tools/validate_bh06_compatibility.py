"""Validate BH-06 Phase 4 exact runtime compatibility evidence."""

import hashlib
import json
import sys
from pathlib import Path

from jsonschema import Draft202012Validator
from research_paths import REPO_ROOT

AUTHORITY = "docs/research/assets/bh-06-baseline/phase-04-authorization-v0.1.0.json"
PROFILE = "packages/blazex_runtime_popcorn/compatibility-profile-v0.1.0.json"
REQUIREMENTS = "integration/bh-06/compatibility-requirements-v0.1.0.json"
REPORT = "integration/bh-06/compatibility-v0.1.0.json"
MANIFEST = "integration/bh-06/phase-04-build-manifest-v0.1.0.json"
BROWSER = "integration/bh-06/phase-04-browser-replay-v0.1.0.json"
INDEX = "integration/bh-06/index-v0.1.0.json"
COMPLETION = "docs/research/assets/bh-06-baseline/phase-04-completion-v0.1.0.json"
PLAN = "docs/research/60-planning/01-browser-host/bh-06-build-compatibility-and-client-safety-pipeline/phase-04-exact-runtime-compatibility-profiles.md"
CLOSURE = "packages/blazex_build/lib/blazex/build/client_closure.ex"
TASK = "integration/bh-06/vertical_slice/lib/mix/tasks/bh06.package.ex"
SCHEMAS = {
    PROFILE: "integration/bh-06/compatibility-profile.schema.json",
    REQUIREMENTS: "integration/bh-06/compatibility-requirements.schema.json",
    REPORT: "integration/bh-06/compatibility-report.schema.json",
}
ROLES = {
    "document", "runtime-module", "runtime-wasm", "application-bundle",
    "browser-host", "reachability-report", "client-safety-report", "compatibility-report",
}
MUTABLE_BASELINES = {
    CLOSURE: "917f761306871b8e3aacfd0877efec6e7e8184d5212adcb09a70c4e43da20bc8",
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
    profile = load(root, PROFILE)
    requirements = load(root, REQUIREMENTS)
    report = load(root, REPORT)
    manifest = load(root, MANIFEST)
    browser = load(root, BROWSER)
    index = load(root, INDEX)
    completion = load(root, COMPLETION)

    if authority.get("authorized") is not True or authority.get("phase") != 4:
        errors.append("Phase 4 authority is invalid")
    for relative, expected in authority.get("bound_inputs", {}).items():
        if relative in MUTABLE_BASELINES:
            if expected != MUTABLE_BASELINES[relative]:
                errors.append(f"mutable baseline identity drift: {relative}")
            continue
        path = root / relative
        if not path.is_file() or digest(path) != expected:
            errors.append(f"bound input drift: {relative}")

    for data_path, schema_path in SCHEMAS.items():
        validator = Draft202012Validator(load(root, schema_path))
        found = sorted(validator.iter_errors(load(root, data_path)), key=lambda item: list(item.path))
        if found:
            errors.append(f"schema failure for {data_path}: {found[0].message}")

    if report.get("phase") != 4 or report.get("status") != "complete":
        errors.append("compatibility report is not Phase 4 complete")
    if report.get("compatible") is not True or report.get("violations") != []:
        errors.append("compatibility report is not a passing exact match")
    if report.get("profile_id") != profile.get("profile_id") or report.get("profile_sha256") != canonical_digest(profile):
        errors.append("compatibility report does not bind the normalized profile")
    if report.get("requirement_id") != requirements.get("requirement_id") or report.get("requirements_sha256") != canonical_digest(requirements):
        errors.append("compatibility report does not bind normalized requirements")

    runtime = report.get("runtime", [])
    protocols = report.get("protocols", [])
    features = report.get("features", [])
    rows = runtime + protocols + features
    if [row.get("subject") for row in runtime] != ["id", "version", "abi"]:
        errors.append("runtime compatibility decisions are incomplete or reordered")
    expected_protocols = sorted(row.get("id") for row in requirements.get("protocols", []))
    if [row.get("subject") for row in protocols] != expected_protocols:
        errors.append("protocol compatibility decisions are incomplete or reordered")
    if [row.get("subject") for row in features] != sorted(requirements.get("features", [])):
        errors.append("feature compatibility decisions are incomplete or reordered")
    if any(row.get("compatible") is not True or row.get("actual") != row.get("expected") for row in rows):
        errors.append("a required compatibility decision is not an exact match")

    required_protocols = {row.get("id") for row in requirements.get("protocols", [])}
    profile_protocols = {row.get("id") for row in profile.get("protocols", [])}
    required_features = set(requirements.get("features", []))
    profile_features = {row.get("id") for row in profile.get("features", [])}
    expected_unused = {
        "protocols": sorted(profile_protocols - required_protocols),
        "features": sorted(profile_features - required_features),
    }
    if report.get("unused_profile") != expected_unused:
        errors.append("unused provider declarations are not accounted for")
    expected_summary = {
        "runtime_requirements": 3,
        "protocol_requirements": len(protocols),
        "feature_requirements": len(features),
        "matched": len(rows),
        "violations": 0,
    }
    if report.get("summary") != expected_summary:
        errors.append("compatibility summary does not match its decisions")

    artifacts = manifest.get("artifacts", [])
    if {item.get("role") for item in artifacts} != ROLES or len(artifacts) != len(ROLES):
        errors.append("Phase 4 manifest roles are incomplete or duplicate")
    compatibility_assets = [item for item in artifacts if item.get("role") == "compatibility-report"]
    if len(compatibility_assets) != 1 or compatibility_assets[0].get("sha256") != canonical_digest(report):
        errors.append("manifest does not bind the canonical compatibility report")
    expected_manifest_compatibility = {
        "profile_id": report.get("profile_id"),
        "profile_sha256": report.get("profile_sha256"),
        "requirement_id": report.get("requirement_id"),
        "requirements_sha256": report.get("requirements_sha256"),
    }
    if manifest.get("compatibility") != expected_manifest_compatibility:
        errors.append("manifest compatibility identity is stale or incomplete")

    if [row.get("browser") for row in browser.get("results", [])] != ["chrome", "firefox"]:
        errors.append("Phase 4 active-browser replay is incomplete or reordered")
    for row in browser.get("results", []):
        if row.get("result") != "passed" or row.get("runtime") != "atomvm-wasm" or row.get("page_errors") != []:
            errors.append(f"Phase 4 browser replay failed: {row.get('browser')}")
    if browser.get("comparison", {}).get("state") != "exact-match":
        errors.append("Phase 4 browsers did not match exactly")
    if browser.get("negative_integrity", {}).get("result") != "failed":
        errors.append("Phase 4 integrity mutation did not fail closed")

    closure = (root / CLOSURE).read_text(encoding="utf-8")
    task = (root / TASK).read_text(encoding="utf-8")
    ordered = ["ClientSafety.analyze!", "Compatibility.evaluate!", "assemble.(authorization)"]
    if any(token not in closure for token in ordered) or not all(closure.index(left) < closure.index(right) for left, right in zip(ordered, ordered[1:])):
        errors.append("safety and compatibility no longer precede assembly in order")
    if "ClientClosure.authorize!(" not in task or "compatibility: compatibility" not in task:
        errors.append("candidate package bypasses compatibility enforcement or manifest binding")

    required_evidence = {Path(PROFILE).name, Path(REQUIREMENTS).name, Path(REPORT).name, Path(MANIFEST).name, Path(BROWSER).name}
    if index.get("phase", 0) < 4 or index.get("status") != "complete" or not required_evidence.issubset(index.get("evidence", [])):
        errors.append("BH-06 Phase 4 evidence index is incomplete")
    expected_completion = {
        "decision": "accept",
        "profile_evidence_sha256": digest(root / PROFILE),
        "requirements_evidence_sha256": digest(root / REQUIREMENTS),
        "compatibility_evidence_sha256": digest(root / REPORT),
        "manifest_sha256": digest(root / MANIFEST),
        "browser_evidence_sha256": digest(root / BROWSER),
        "canonical_profile_sha256": canonical_digest(profile),
        "canonical_requirements_sha256": canonical_digest(requirements),
        "canonical_compatibility_sha256": canonical_digest(report),
    }
    if any(completion.get(key) != value for key, value in expected_completion.items()):
        errors.append("Phase 4 completion identities are stale")
    if "- [ ]" in (root / PLAN).read_text(encoding="utf-8"):
        errors.append("Phase 4 checklist is incomplete")
    return errors


if __name__ == "__main__":
    failures = validate()
    print("\n".join(failures) if failures else "BH-06 Phase 4 exact compatibility: PASS")
    sys.exit(bool(failures))
