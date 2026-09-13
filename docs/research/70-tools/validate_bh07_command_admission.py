"""Validate BH-07 Phase 5 typed, authorized, non-executing command admission."""

import hashlib
import json
import re
import sys
from pathlib import Path

from research_paths import REPO_ROOT

AUTHORITY = "docs/research/assets/bh-07-baseline/phase-05-authorization-v0.1.0.json"
EVIDENCE = "integration/bh-07/phase-05-command-admission-evidence-v0.1.0.json"
INDEX = "integration/bh-07/index-v0.1.0.json"
COMPLETION = "docs/research/assets/bh-07-baseline/phase-05-completion-v0.1.0.json"
PLAN = "docs/research/60-planning/01-browser-host/bh-07-phoenix-integration-and-trusted-command-boundary/phase-05-typed-command-admission-and-authorization.md"
CONTRACT = "docs/research/60-planning/01-browser-host/bh-07-phoenix-integration-and-trusted-command-boundary/command-admission-contract.md"
REGISTRY = "packages/blazex_phoenix/lib/blazex/phoenix/session_registry.ex"
ADMISSION = "packages/blazex_phoenix/lib/blazex/phoenix/command_admission.ex"
BOOTSTRAP = "packages/blazex_phoenix/lib/blazex/phoenix/public_bootstrap.ex"
PLUG = "profiles/browser_phoenix/lib/blazex_browser_phoenix/admission_plug.ex"
SESSION_PLUG = "profiles/browser_phoenix/lib/blazex_browser_phoenix/session_plug.ex"
APPLICATION = "profiles/browser_phoenix/lib/blazex_browser_phoenix/application.ex"
ENDPOINT = "profiles/browser_phoenix/lib/blazex_browser_phoenix/endpoint.ex"
PROFILE_MIX = "profiles/browser_phoenix/mix.exs"
PROFILE_LOCK = "profiles/browser_phoenix/mix.lock"
MUTABLE = {
    REGISTRY: "f434719f8272b7d06bad4d20d44da174d62e9ed3ede30713fde2152865d5497a",
    SESSION_PLUG: "f7f75f7017c62b27d1a39377997c5bac99fa49c95cf43620d29f34f0a2020023",
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

    if authority.get("authorized") is not True or authority.get("phase") != 5:
        errors.append("Phase 5 authority is invalid")

    for relative, expected in authority.get("bound_inputs", {}).items():
        if relative in MUTABLE:
            if expected != MUTABLE[relative]:
                errors.append(f"mutable baseline identity drift: {relative}")
        elif not (root / relative).is_file() or digest(root / relative) != expected:
            errors.append(f"bound input drift: {relative}")

    if evidence.get("decision") != "accept" or evidence.get("support_state") != "unsupported-development-evidence":
        errors.append("command-admission evidence decision drifted")
    for relative, expected in evidence.get("source_bindings", {}).items():
        if not (root / relative).is_file() or digest(root / relative) != expected:
            errors.append(f"implementation source binding drift: {relative}")

    admission = evidence.get("admission", {})
    expected_fields = ["command", "correlation_id", "expected_revision", "idempotency_key", "payload", "protocol", "schema"]
    expected_bounds = {
        "max_body_bytes": 2048,
        "max_admissions": 256,
        "max_per_session": 32,
        "max_declarations": 32,
        "max_subjects": 64,
        "max_payload_fields": 16,
    }
    if admission.get("protocol") != "blazex.bh07.command-intent/1" or admission.get("exact_fields") != expected_fields:
        errors.append("command envelope drifted")
    if any(admission.get(key) != value for key, value in expected_bounds.items()):
        errors.append("command admission bounds drifted")
    if admission.get("payload_types") != ["boolean", "integer", "string"]:
        errors.append("payload schema drifted")
    if any(admission.get(key) is not False for key in ["dynamic_handler_resolution", "command_execution", "server_mutation"]):
        errors.append("non-execution boundary drifted")

    authorization = evidence.get("authorization", {})
    required_authorization = {
        "session_context_server_owned": True,
        "csrf_reauthenticated": True,
        "subject_grants_server_owned": True,
        "unknown_subject_denied": True,
        "client_authority_hints_rejected": True,
        "generalized_roles_or_permissions": False,
    }
    if authorization != required_authorization:
        errors.append("command authorization boundary drifted")

    idempotency = evidence.get("idempotency", {})
    if idempotency.get("scope") != ["opaque_session", "idempotency_key"] or idempotency.get("retention") != "sha256-fingerprint-and-bounded-receipt-only":
        errors.append("idempotency retention drifted")
    if idempotency.get("concurrent_exact_replay_single_record") is not True or idempotency.get("session_cleanup") is not True:
        errors.append("idempotency behavior drifted")

    transport = evidence.get("transport", {})
    required_transport = ["canonical-same-origin", "application-json", "encrypted-session", "current-csrf"]
    if transport.get("path") != "/bh07/commands/admit" or transport.get("method") != "POST":
        errors.append("command transport route drifted")
    if transport.get("requires") != required_transport or transport.get("receipt_executed") is not False:
        errors.append("command transport security drifted")
    if transport.get("cache_control") != "no-store" or transport.get("nosniff") is not True:
        errors.append("command response policy drifted")

    expected_capabilities = {
        "sessions": True,
        "csrf_protection": True,
        "command_admission": True,
        "remote_commands": False,
        "pushes": False,
        "server_mutation": False,
    }
    if evidence.get("capabilities") != expected_capabilities:
        errors.append("Phase 5 capability boundary drifted")

    gates = {item.get("gate"): item for item in evidence.get("tests", [])}
    required_gates = {
        "blazex-phoenix-package",
        "browser-phoenix-profile",
        "command-admission-validator-mutations",
        "research-archive",
        "dependency-boundary",
        "patch-hygiene",
    }
    if set(gates) != required_gates or any(item.get("result") != "passed" or item.get("failures", 0) != 0 for item in gates.values()):
        errors.append("Phase 5 gate evidence is incomplete")

    registry_source = (root / REGISTRY).read_text()
    admission_source = (root / ADMISSION).read_text()
    plug = (root / PLUG).read_text()
    session_plug = (root / SESSION_PLUG).read_text()
    application = (root / APPLICATION).read_text()
    endpoint = (root / ENDPOINT).read_text()
    bootstrap = (root / BOOTSTRAP).read_text()
    mix = (root / PROFILE_MIX).read_text()
    lock = (root / PROFILE_LOCK).read_text()

    if "def authority_context" not in registry_source or "subject_id: record.subject_id" not in registry_source:
        errors.append("server-owned session context drifted")
    required_admission_terms = ["@default_max_admissions 256", "@default_max_per_session 32", "validate_envelope", "validate_payload", "authorization-denied", "idempotency-conflict", "executed\" => false", ":crypto.hash(:sha256"]
    if any(term not in admission_source for term in required_admission_terms):
        errors.append("command admission implementation drifted")
    forbidden_execution_terms = ["apply(", "spawn(", "Task.start", "Code.eval", "Module.concat"]
    if any(term in admission_source for term in forbidden_execution_terms):
        errors.append("dynamic execution entered command admission")
    if "FixtureAuthority" in admission_source or "FixtureAuthority" in plug:
        errors.append("disposable BH-01 authority entered Phase 5")
    if any(term not in plug for term in ['@path "/bh07/commands/admit"', "OriginPolicy.authorize", "CommandAdmission.admit", "@max_body_bytes 2_048", '"executed" => false']):
        errors.append("Phoenix admission integration drifted")
    if "CommandAdmission.revoke_session" not in session_plug or "CommandAdmission.reset" not in session_plug:
        errors.append("admission lifecycle cleanup drifted")
    if '"counter.increment"' not in application or "grants:" not in application:
        errors.append("static command registration drifted")
    if endpoint.find("AdmissionPlug") < endpoint.find("SessionPlug") or "AdmissionPlug" not in endpoint:
        errors.append("command endpoint composition drifted")
    if '"command_admission" => true' not in bootstrap or '"remote_commands" => false' not in bootstrap:
        errors.append("public admission capability drifted")

    forbidden_dependencies = ["blazex_renderer_dom_liveview", "phoenix_live_view", "local_live_view"]
    if any(re.search(r"\{:" + re.escape(name) + r"(?:,|\})", mix) for name in forbidden_dependencies):
        errors.append("deferred dependency returned")
    if any(f'"{name}"' in lock for name in ["phoenix_live_view", "local_live_view"]):
        errors.append("deferred dependency returned")
    if authority.get("deferred") != evidence.get("deferred"):
        errors.append("deferred scope drifted")
    if index.get("status") != "complete" or Path(EVIDENCE).name not in index.get("evidence", []):
        errors.append("Phase 5 evidence index incomplete")
    if "- [ ]" in (root / PLAN).read_text():
        errors.append("Phase 5 checklist incomplete")
    if "[DEFERRED]" not in (root / CONTRACT).read_text():
        errors.append("Phase 5 deferral contract incomplete")

    expected_completion = {
        "decision": "accept",
        "authorization_sha256": digest(root / AUTHORITY),
        "evidence_sha256": digest(root / EVIDENCE),
    }
    if any(completion.get(key) != value for key, value in expected_completion.items()):
        errors.append("Phase 5 completion identities stale")
    return errors


if __name__ == "__main__":
    failures = validate()
    print("\n".join(failures) if failures else "BH-07 Phase 5 command admission: ACCEPT (validated)")
    sys.exit(bool(failures))
