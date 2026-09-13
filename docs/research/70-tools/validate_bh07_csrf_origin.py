"""Validate BH-07 Phase 4 CSRF and canonical-origin security."""

import hashlib
import json
import re
import sys
from pathlib import Path

from research_paths import REPO_ROOT

AUTHORITY = "docs/research/assets/bh-07-baseline/phase-04-authorization-v0.1.0.json"
EVIDENCE = "integration/bh-07/phase-04-csrf-origin-evidence-v0.1.0.json"
INDEX = "integration/bh-07/index-v0.1.0.json"
COMPLETION = "docs/research/assets/bh-07-baseline/phase-04-completion-v0.1.0.json"
PLAN = "docs/research/60-planning/01-browser-host/bh-07-phoenix-integration-and-trusted-command-boundary/phase-04-csrf-and-origin-security-envelope.md"
CONTRACT = "docs/research/60-planning/01-browser-host/bh-07-phoenix-integration-and-trusted-command-boundary/csrf-origin-contract.md"
REGISTRY = "packages/blazex_phoenix/lib/blazex/phoenix/session_registry.ex"
ORIGIN = "packages/blazex_phoenix/lib/blazex/phoenix/origin_policy.ex"
BOOTSTRAP = "packages/blazex_phoenix/lib/blazex/phoenix/public_bootstrap.ex"
PLUG = "profiles/browser_phoenix/lib/blazex_browser_phoenix/session_plug.ex"
CONTROL = "profiles/browser_phoenix/lib/blazex_browser_phoenix/control_plug.ex"
ENDPOINT = "profiles/browser_phoenix/lib/blazex_browser_phoenix/endpoint.ex"
PROFILE_MIX = "profiles/browser_phoenix/mix.exs"
PROFILE_LOCK = "profiles/browser_phoenix/mix.lock"
MUTABLE = {
    REGISTRY: "6a725b34766f5b575af345e3b01efc03ceea7f59d8170f0be2bc447b2d00250c",
    PLUG: "cd9dbca3f31f8922f57e642f65f1130bdb2b0022b3019da736e2d27072a900cb",
    ENDPOINT: "2bdcc4f0a280c35cfadbebcfb90ec615bc535875d7ce01c395033cd33c215271",
}


def load(root, relative):
    return json.loads((Path(root) / relative).read_text())


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def validate(root=REPO_ROOT):
    root = Path(root)
    errors = []
    authority = load(root, AUTHORITY)
    evidence = load(root, EVIDENCE)
    index = load(root, INDEX)
    completion = load(root, COMPLETION)

    if authority.get("authorized") is not True or authority.get("phase") != 4:
        errors.append("Phase 4 authority is invalid")

    for relative, expected in authority.get("bound_inputs", {}).items():
        if relative in MUTABLE:
            if expected != MUTABLE[relative]:
                errors.append(f"mutable baseline identity drift: {relative}")
        elif not (root / relative).is_file() or digest(root / relative) != expected:
            errors.append(f"bound input drift: {relative}")

    if evidence.get("decision") != "accept" or evidence.get("support_state") != "unsupported-development-evidence":
        errors.append("CSRF/origin evidence decision drifted")

    for relative, expected in evidence.get("source_bindings", {}).items():
        if not (root / relative).is_file() or digest(root / relative) != expected:
            errors.append(f"implementation source binding drift: {relative}")

    expected_csrf = {
        "random_bytes": 32,
        "server_retention": "sha256-digest-only",
        "constant_time_compare": True,
        "session_bound": True,
        "rotation_atomic": True,
        "rotation_preserves_expiry": True,
        "old_proof_rejected": True,
        "session_invalidation_cascades": True,
        "header": "x-blazex-csrf",
    }
    if evidence.get("csrf") != expected_csrf:
        errors.append("CSRF authority contract drifted")

    origin = evidence.get("origin", {})
    if origin.get("schemes") != ["http", "https"] or origin.get("cardinality") != 1:
        errors.append("origin policy drifted")
    if origin.get("canonical_fields") != ["scheme", "host", "effective_port"]:
        errors.append("origin canonicalization drifted")

    transport = evidence.get("transport", {})
    expected_fields = ["csrf_token", "expires_at_ms", "protocol", "state", "subject"]
    expected_cookie = {"encrypted": True, "signed": True, "http_only": True, "same_site": "Strict"}
    if transport.get("authenticated_projection_fields") != expected_fields:
        errors.append("authenticated projection drifted")
    if transport.get("rotation_path") != "/bh07/csrf/rotate" or transport.get("cookie") != expected_cookie:
        errors.append("CSRF transport drifted")
    if transport.get("legacy_cookie_isolation") is not True or transport.get("cache_control") != "no-store":
        errors.append("transport isolation drifted")

    expected_capabilities = {
        "sessions": True,
        "authentication_projection": True,
        "csrf_protection": True,
        "remote_commands": False,
        "pushes": False,
        "server_mutation": False,
    }
    if evidence.get("capabilities") != expected_capabilities:
        errors.append("Phase 4 capability boundary drifted")

    gates = {item.get("gate"): item for item in evidence.get("tests", [])}
    required_gates = {
        "blazex-phoenix-package",
        "browser-phoenix-profile",
        "csrf-origin-validator-mutations",
        "research-archive",
        "dependency-boundary",
        "patch-hygiene",
    }
    if set(gates) != required_gates or any(item.get("result") != "passed" or item.get("failures", 0) != 0 for item in gates.values()):
        errors.append("Phase 4 gate evidence is incomplete")

    registry = (root / REGISTRY).read_text()
    origin_source = (root / ORIGIN).read_text()
    plug = (root / PLUG).read_text()
    control = (root / CONTROL).read_text()
    endpoint = (root / ENDPOINT).read_text()
    bootstrap = (root / BOOTSTRAP).read_text()
    mix = (root / PROFILE_MIX).read_text()
    lock = (root / PROFILE_LOCK).read_text()

    if any(term not in registry for term in ["strong_rand_bytes(32)", "csrf_digest", ":crypto.hash_equals", "rotate_csrf"]):
        errors.append("CSRF registry implementation drifted")
    if any(term not in origin_source for term in ["URI.new", "[origin]", "uri.userinfo", "uri.path", "uri.query", "uri.fragment"]):
        errors.append("origin implementation drifted")
    if any(term not in plug for term in ['@csrf_path "/bh07/csrf/rotate"', '@csrf_header "x-blazex-csrf"', "OriginPolicy.authorize", "SessionRegistry.rotate_csrf", "clear_bh07_session"]):
        errors.append("Phoenix CSRF integration drifted")
    if "delete_session(:bh01_session_id)" not in control or "clear_session()" in control:
        errors.append("legacy cookie isolation drifted")
    if '"csrf_protection" => true' not in bootstrap:
        errors.append("public capability declaration drifted")
    if 'key: "_blazex_browser_phoenix"' not in endpoint or 'same_site: "Strict"' not in endpoint or "encryption_salt" not in endpoint:
        errors.append("encrypted session cookie composition drifted")

    forbidden_dependencies = ["blazex_renderer_dom_liveview", "phoenix_live_view", "local_live_view"]
    if any(re.search(r"\{:" + re.escape(name) + r"(?:,|\})", mix) for name in forbidden_dependencies):
        errors.append("deferred dependency returned")
    if any(f'"{name}"' in lock for name in ["phoenix_live_view", "local_live_view"]):
        errors.append("deferred dependency returned")
    if authority.get("deferred") != evidence.get("deferred"):
        errors.append("deferred scope drifted")
    if index.get("status") != "complete" or Path(EVIDENCE).name not in index.get("evidence", []):
        errors.append("Phase 4 evidence index incomplete")
    if "- [ ]" in (root / PLAN).read_text():
        errors.append("Phase 4 checklist incomplete")
    if "[DEFERRED]" not in (root / CONTRACT).read_text():
        errors.append("Phase 4 deferral contract incomplete")

    expected_completion = {
        "decision": "accept",
        "authorization_sha256": digest(root / AUTHORITY),
        "evidence_sha256": digest(root / EVIDENCE),
    }
    if any(completion.get(key) != value for key, value in expected_completion.items()):
        errors.append("Phase 4 completion identities stale")

    return errors


if __name__ == "__main__":
    failures = validate()
    print("\n".join(failures) if failures else "BH-07 Phase 4 CSRF/origin boundary: ACCEPT (validated)")
    sys.exit(bool(failures))
