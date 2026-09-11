"""Validate the BH-06 Phase 1 deterministic browser-Wasm vertical slice."""

import hashlib
import json
import re
import sys
from pathlib import Path

from research_paths import REPO_ROOT

AUTHORITY = "docs/research/assets/bh-06-baseline/phase-01-authorization-v0.1.0.json"
MANIFEST = "integration/bh-06/candidate-build-manifest-v0.1.0.json"
BROWSER = "integration/bh-06/browser-slice-v0.1.0.json"
INDEX = "integration/bh-06/index-v0.1.0.json"
PROJECT = "packages/blazex_build/blazex.project.json"
COUNTER = "integration/bh-06/vertical_slice/lib/counter.ex"
PLAN = "docs/research/60-planning/01-browser-host/bh-06-build-compatibility-and-client-safety-pipeline/phase-01-first-continuous-browser-wasm-vertical-slice.md"

ROLES = {"document", "runtime-module", "runtime-wasm", "application-bundle", "browser-host"}
CHECKS = {
    "manifest-integrity", "atomvm-ready", "mount", "semantic-render",
    "dom-commit", "browser-interaction", "elixir-state-transition",
    "updated-dom-commit", "dispose",
}
FORBIDDEN = re.compile(r"\b(?:Popcorn|Phoenix|LiveView|LocalLiveView|document|window)\b|BlazeX\.(?:Runtime|Renderer|Host)")


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load(root: Path, relative: str):
    return json.loads((root / relative).read_text(encoding="utf-8"))


def validate(root=REPO_ROOT):
    root = Path(root)
    errors = []
    authority = load(root, AUTHORITY)
    manifest = load(root, MANIFEST)
    browser = load(root, BROWSER)
    index = load(root, INDEX)
    project = load(root, PROJECT)

    if authority.get("authorized") is not True or authority.get("base_revision") != "aa2a4d8860f05b189a49ca3315d0d3f4a1957826":
        errors.append("phase authority or base revision is invalid")
    for relative, expected in authority.get("bound_inputs", {}).items():
        path = root / relative
        if not path.is_file() or digest(path) != expected:
            errors.append(f"bound input drift: {relative}")

    artifacts = manifest.get("artifacts", [])
    roles = [item.get("role") for item in artifacts]
    paths = [item.get("path") for item in artifacts]
    if set(roles) != ROLES or len(roles) != len(ROLES) or len(paths) != len(set(paths)):
        errors.append("manifest roles or paths are incomplete or duplicate")
    for item in artifacts:
        path = item.get("path", "")
        sha = item.get("sha256", "")
        if path.startswith("/") or ".." in Path(path).parts:
            errors.append(f"manifest path escapes output: {path}")
        if item.get("cache") == "immutable" and sha not in Path(path).name:
            errors.append(f"immutable asset is not content addressed: {path}")
        if not re.fullmatch(r"[0-9a-f]{64}", sha) or not isinstance(item.get("bytes"), int) or item["bytes"] <= 0:
            errors.append(f"invalid integrity metadata: {path}")

    if digest(root / MANIFEST) != browser.get("manifest_sha256"):
        errors.append("browser evidence does not bind the candidate manifest")
    rows = browser.get("results", [])
    if [row.get("browser") for row in rows] != ["chrome", "firefox"]:
        errors.append("active browser matrix is incomplete or reordered")
    for row in rows:
        if row.get("result") != "passed" or row.get("runtime") != "atomvm-wasm" or row.get("page_errors") != []:
            errors.append(f"active browser failed: {row.get('browser')}")
        if set(row.get("checks", [])) != CHECKS:
            errors.append(f"lifecycle checks are incomplete: {row.get('browser')}")
        if [step.get("step") for step in row.get("trace", [])] != ["mount", "event", "dispose"]:
            errors.append(f"lifecycle trace is incomplete: {row.get('browser')}")
        if row.get("dom") != {"text": "Wasm counter: 1", "role": "Wasm counter"}:
            errors.append(f"DOM commit is invalid: {row.get('browser')}")
    if browser.get("comparison", {}).get("state") != "exact-match":
        errors.append("cross-browser result is not exact")
    negative = browser.get("negative_integrity", {})
    if negative.get("result") != "failed" or "integrity mismatch" not in negative.get("error", ""):
        errors.append("integrity corruption did not fail closed")

    if project.get("dependencies") != [] or project.get("activation_phase") != "BH-06 Phase 1":
        errors.append("build package ownership or dependency boundary drifted")
    if FORBIDDEN.search((root / COUNTER).read_text(encoding="utf-8")):
        errors.append("public component imports host, runtime, renderer, or server surface")
    if index.get("status") != "complete" or set(index.get("evidence", [])) != {
        "candidate-build-manifest-v0.1.0.json", "browser-slice-v0.1.0.json"
    }:
        errors.append("BH-06 evidence index is incomplete")
    plan = (root / PLAN).read_text(encoding="utf-8")
    if "- [ ]" in plan or "support_state\": \"supported" in plan:
        errors.append("phase checklist or support boundary is incomplete")
    return errors


if __name__ == "__main__":
    failures = validate()
    print("\n".join(failures) if failures else "BH-06 Phase 1 browser-Wasm vertical slice: PASS")
    sys.exit(bool(failures))
