#!/usr/bin/env python3
"""Validate the exact Phoenix/LiveView/LocalLiveView qualification contract."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
SHA256 = re.compile(r"^[0-9a-f]{64}$")
LOCK_ENTRY = re.compile(
    r'^\s+"([^"]+)": \{:hex, :[^,]+, "([^"]+)",.*"hexpm", "([0-9a-f]{64})"\},?$'
)


def load(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as stream:
        return json.load(stream)


def parse_lock(text: str) -> dict[str, tuple[str, str]]:
    result: dict[str, tuple[str, str]] = {}
    for line in text.splitlines():
        match = LOCK_ENTRY.match(line)
        if match:
            result[match.group(1)] = (match.group(2), match.group(3))
    return result


def validate(
    dependencies: dict[str, Any],
    boundaries: dict[str, Any],
    inventory: dict[str, Any],
    fixture: dict[str, Any],
    prerequisites: dict[str, Any],
    lock_text: str,
    mix_text: str,
    portable_sources: dict[str, str],
) -> list[str]:
    errors: list[str] = []

    if dependencies.get("candidate_status") != "pinned_uncompiled":
        errors.append("server dependency candidate must remain pinned_uncompiled in Phase 2")
    if dependencies.get("resolver", {}).get("canonical_elixir") != "1.17.3":
        errors.append("server resolver does not use the Popcorn-compatible Elixir pin")

    expected: dict[str, tuple[str, str]] = {}
    for package in dependencies.get("packages", []):
        if len(package) != 4:
            errors.append("server package entry must contain name, version, checksum, and license")
            continue
        name, version, checksum, license_id = package
        if name in expected:
            errors.append(f"duplicate server package {name}")
        if not SHA256.fullmatch(checksum):
            errors.append(f"server package {name} has no valid Hex SHA-256")
        if license_id not in dependencies.get("license_policy", {}).get("allowed", []):
            errors.append(f"server package {name} has an unapproved license")
        expected[name] = (version, checksum)

    actual = parse_lock(lock_text)
    if actual != expected:
        missing = sorted(set(expected) - set(actual))
        unexpected = sorted(set(actual) - set(expected))
        changed = sorted(name for name in set(actual) & set(expected) if actual[name] != expected[name])
        if missing:
            errors.append(f"Mix lock is missing canonical packages: {', '.join(missing)}")
        if unexpected:
            errors.append(f"Mix lock has stale/unexpected packages: {', '.join(unexpected)}")
        if changed:
            errors.append(f"Mix lock has changed identities: {', '.join(changed)}")
    if dependencies.get("license_policy", {}).get("unknown") != []:
        errors.append("server dependency inventory contains unknown licenses")
    if not dependencies.get("rejected_alternatives") or not dependencies.get("optional_edges_not_selected"):
        errors.append("resolver alternatives or optional edges are not documented")

    if 'elixir: "== 1.17.3"' not in mix_text:
        errors.append("browser Phoenix profile does not exactly pin Elixir 1.17.3")
    for root in dependencies.get("roots", []):
        requirement = f'{{:{root["name"]}, "{root["requirement"]}"'
        if requirement not in mix_text:
            errors.append(f"profile root {root['name']} is not exact in mix.exs")

    plug = boundaries.get("plug_boundary", {})
    closure_names = {item.split()[0] for item in plug.get("closure", [])}
    if closure_names & set(plug.get("forbidden", [])):
        errors.append("qualified Plug closure contains Phoenix/LiveView/LocalLiveView")
    if boundaries.get("standalone_dom", {}).get("dependency_count") != 0:
        errors.append("standalone DOM is not dependency-free")
    forbidden = tuple(boundaries.get("forbidden_portable_dependencies", []))
    for path, source in portable_sources.items():
        for token in forbidden:
            if token in source:
                errors.append(f"portable source {path} imports forbidden dependency {token}")
    if boundaries.get("private_api_owner") != "packages/blazex_renderer_dom_liveview":
        errors.append("private LiveView coupling has the wrong owner")

    defaults = inventory.get("entry_defaults", {})
    for field in ("owner", "fallback", "fixture"):
        if not defaults.get(field):
            errors.append(f"private API entry default {field} is missing")
    if defaults.get("owner") != boundaries.get("private_api_owner"):
        errors.append("private API inventory and package boundary disagree on ownership")
    entries = inventory.get("entries", [])
    expected_ids = {
        "plv-diff-engine", "plv-renderer", "plv-utils-state", "plv-lifecycle",
        "plv-session-struct", "plv-socket-struct", "plv-diff-wire-schema",
        "llv-popcorn-bridge"
    }
    if {entry.get("id") for entry in entries} != expected_ids:
        errors.append("private/version-sensitive API inventory is incomplete")
    for entry in entries:
        for field in ("source", "visibility", "shape", "call_site", "pin_sensitivity", "upgrade_trigger", "risk"):
            if not entry.get(field):
                errors.append(f"private API {entry.get('id')} lacks {field}")
    decision = inventory.get("confinement_decision", {})
    if decision.get("accepted_for_feasibility") is not True or not decision.get("stop_condition"):
        errors.append("private API confinement has no explicit accept/stop decision")
    if fixture.get("phoenix_live_view") != "1.2.11" or fixture.get("local_live_view") != "0.1.0":
        errors.append("private API fixture versions do not match the selected pair")
    required_surfaces = {"diff", "renderer", "utils", "lifecycle", "session_fields", "socket_fields", "bridge_actions"}
    if set(fixture.get("surfaces", {})) != required_surfaces:
        errors.append("private API fixture surfaces are incomplete")

    isolation = prerequisites.get("profile_prerequisites", {}).get("cross_origin_isolation", {})
    expected_headers = {
        "Cross-Origin-Opener-Policy": "same-origin",
        "Cross-Origin-Embedder-Policy": "require-corp",
        "Cross-Origin-Resource-Policy": "same-origin",
    }
    if isolation.get("required") is not True or isolation.get("headers") != expected_headers:
        errors.append("server prerequisites do not enforce the runtime isolation contract")
    content_types = prerequisites.get("profile_prerequisites", {}).get("content_types", {})
    if content_types.get(".wasm") != "application/wasm":
        errors.append("server prerequisites omit the WebAssembly MIME type")
    if not prerequisites.get("proxy_invariants") or not prerequisites.get("deployment_work_deferred"):
        errors.append("proxy invariants or deferred deployment work are not separated")

    return errors


def inputs() -> tuple[Any, ...]:
    portable_sources: dict[str, str] = {}
    for relative in load(HERE / "profile-boundaries.json").get("portable_packages", []):
        root = ROOT / relative
        for pattern in ("mix.exs", "lib/**/*.ex", "lib/**/*.exs"):
            for path in root.glob(pattern):
                portable_sources[str(path.relative_to(ROOT))] = path.read_text(encoding="utf-8")
    return (
        load(HERE / "server-dependencies.json"),
        load(HERE / "profile-boundaries.json"),
        load(HERE / "private-api-inventory.json"),
        load(HERE / "private-api-contract.fixture.json"),
        load(HERE / "server-prerequisites.json"),
        (ROOT / "profiles/browser_phoenix/mix.lock").read_text(encoding="utf-8"),
        (ROOT / "profiles/browser_phoenix/mix.exs").read_text(encoding="utf-8"),
        portable_sources,
    )


def main() -> int:
    errors = validate(*inputs())
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print("BH-01 Phase 2 Phoenix/LiveView/LocalLiveView qualification: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
