#!/usr/bin/env python3
"""Verify BH-01 Phase 6 standalone, Plug, headless, and import boundaries."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent


def load(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def declared_mix_dependencies(path: Path) -> set[str]:
    text = path.read_text(encoding="utf-8")
    return set(re.findall(r"\{:(\w+),", text))


def source_text(paths: list[Path]) -> dict[str, str]:
    result: dict[str, str] = {}
    for root in paths:
        if not root.exists():
            continue
        for pattern in ("lib/**/*.ex", "lib/**/*.exs", "js/**/*.js"):
            for path in root.glob(pattern):
                result[str(path.relative_to(ROOT))] = path.read_text(encoding="utf-8")
    return result


def validate(
    standalone: dict[str, Any],
    plug: dict[str, Any],
    headless: dict[str, Any],
    project_manifests: dict[str, dict[str, Any]],
    standalone_sources: dict[str, str],
    authority_sources: dict[str, str],
    fixture_dependencies: set[str],
    dom_dependencies: set[str],
) -> list[str]:
    errors: list[str] = []

    if standalone.get("status") != "phase6-verified":
        errors.append("standalone browser boundary is not verified")
    if fixture_dependencies != set(standalone.get("fixture_dependencies", [])):
        errors.append("browser fixture dependency graph drifted")
    if dom_dependencies != set(standalone.get("standalone_dom_dependencies", [])):
        errors.append("standalone DOM dependency graph drifted")

    expected_proofs = {
        "BX-BH01-PROOF-NESTED-STATE",
        "BX-BH01-PROOF-FORM-EVENT",
        "BX-BH01-PROOF-TIMER-MESSAGE",
        "BX-BH01-PROOF-DOM-UPDATE",
    }
    if set(standalone.get("phase5_fixture_proofs_retained", [])) != expected_proofs:
        errors.append("standalone comparison omits a Phase 5 local proof")
    if standalone.get("phase6_server_enhancement") != ["authenticated-counter-command"]:
        errors.append("server-enhanced scenario scope drifted")

    forbidden_imports = tuple(standalone.get("forbidden_imports", []))
    for path, text in standalone_sources.items():
        for token in forbidden_imports:
            if token in text:
                errors.append(f"standalone source imports optional adapter surface: {path}: {token}")
    for path, text in authority_sources.items():
        if "BlazeX.Renderer.DOM.LiveView" in text:
            errors.append(f"server authority imports optional renderer adapter: {path}")

    plug_closure = {item.split()[0] for item in plug.get("closure", [])}
    plug_forbidden = set(plug.get("forbidden_direct_or_transitive", []))
    if plug.get("status") != "qualified-not-activated" or plug_closure & plug_forbidden:
        errors.append("qualified Plug closure contains a forbidden dependency")
    if "executable Plug profile" not in standalone.get("claims_not_made", []):
        errors.append("Plug qualification is represented as executable")

    headless_allowed = set(headless.get("allowed_local_dependencies", []))
    headless_forbidden = set(headless.get("forbidden_direct_or_transitive", []))
    if headless.get("status") != "boundary-only-not-activated" or headless_allowed & headless_forbidden:
        errors.append("headless boundary contains a forbidden dependency")

    expected_manifest_dependencies = {
        "blazex_host_browser": set(),
        "blazex_renderer_dom": set(),
        "blazex_renderer_dom_liveview": set(),
        "blazex_phoenix": set(),
        "blazex_runtime_popcorn": set(),
    }
    for package, expected in expected_manifest_dependencies.items():
        manifest = project_manifests.get(package, {})
        if set(manifest.get("dependencies", [])) != expected:
            errors.append(f"package dependency manifest drifted: {package}")

    return errors


def inputs() -> tuple[Any, ...]:
    manifest_paths = list((ROOT / "packages").glob("*/blazex.project.json"))
    manifests = {load(path).get("id"): load(path) for path in manifest_paths}
    standalone_sources = source_text(
        [
            ROOT / "integration/fixtures/browser_host",
            ROOT / "packages/blazex_renderer_dom",
            ROOT / "packages/blazex_host_browser",
        ]
    )
    authority_sources = source_text([ROOT / "packages/blazex_phoenix"])
    return (
        load(ROOT / "integration/fixtures/browser_host/standalone-boundary.json"),
        load(ROOT / "profiles/browser_plug/dependency-contract.json"),
        load(ROOT / "profiles/headless/dependency-contract.json"),
        manifests,
        standalone_sources,
        authority_sources,
        declared_mix_dependencies(ROOT / "integration/fixtures/browser_host/mix.exs"),
        declared_mix_dependencies(ROOT / "packages/blazex_renderer_dom/mix.exs"),
    )


def main() -> int:
    errors = validate(*inputs())
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print("BH-01 Phase 6 standalone and dependency boundaries: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
