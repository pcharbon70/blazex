"""Validate BH-07 Phase 6 atomic trusted command execution."""

import hashlib
import json
import re
import sys
from pathlib import Path

from research_paths import REPO_ROOT

AUTHORITY = "docs/research/assets/bh-07-baseline/phase-06-authorization-v0.1.0.json"
EVIDENCE = "integration/bh-07/phase-06-trusted-execution-evidence-v0.1.0.json"
INDEX = "integration/bh-07/index-v0.1.0.json"
COMPLETION = "docs/research/assets/bh-07-baseline/phase-06-completion-v0.1.0.json"
PLAN = "docs/research/60-planning/01-browser-host/bh-07-phoenix-integration-and-trusted-command-boundary/phase-06-atomic-trusted-command-execution.md"
CONTRACT = "docs/research/60-planning/01-browser-host/bh-07-phoenix-integration-and-trusted-command-boundary/trusted-execution-contract.md"
ADMISSION = "packages/blazex_phoenix/lib/blazex/phoenix/command_admission.ex"
EXECUTION = "packages/blazex_phoenix/lib/blazex/phoenix/command_execution.ex"
BOOTSTRAP = "packages/blazex_phoenix/lib/blazex/phoenix/public_bootstrap.ex"
PLUG = "profiles/browser_phoenix/lib/blazex_browser_phoenix/execution_plug.ex"
SESSION_PLUG = "profiles/browser_phoenix/lib/blazex_browser_phoenix/session_plug.ex"
ENDPOINT = "profiles/browser_phoenix/lib/blazex_browser_phoenix/endpoint.ex"
PROFILE_MIX = "profiles/browser_phoenix/mix.exs"
PROFILE_LOCK = "profiles/browser_phoenix/mix.lock"
MUTABLE = {
    ENDPOINT: "6f115e8f334ff0b2ef2ceb0f7413c04482228517e3847dbe37ecfae0e0ea4ffc",
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

    if authority.get("authorized") is not True or authority.get("phase") != 6:
        errors.append("Phase 6 authority is invalid")
    for relative, expected in authority.get("bound_inputs", {}).items():
        if relative in MUTABLE:
            if expected != MUTABLE[relative]:
                errors.append(f"mutable baseline identity drift: {relative}")
        elif not (root / relative).is_file() or digest(root / relative) != expected:
            errors.append(f"bound input drift: {relative}")

    if evidence.get("decision") != "accept" or evidence.get("support_state") != "unsupported-development-evidence":
        errors.append("trusted-execution evidence decision drifted")
    for relative, expected in evidence.get("source_bindings", {}).items():
        if not (root / relative).is_file() or digest(root / relative) != expected:
            errors.append(f"implementation source binding drift: {relative}")

    execution = evidence.get("execution", {})
    expected_execution = {
        "command": "counter.increment",
        "schema": "counter.increment",
        "resource_id": "counter",
        "operation": "bounded-integer-increment",
        "amount_range": [1, 10],
        "result_protocol": "blazex.bh07.command-result/1",
        "server_owned_revision": True,
        "atomic_serialization": True,
        "dynamic_handler_resolution": False,
        "browser_effect_emission": False,
        "external_resource_mutation": False,
    }
    if execution != expected_execution:
        errors.append("closed execution boundary drifted")

    authorization = evidence.get("authorization", {})
    if authorization != {
        "phase_5_admission_reused": True,
        "session_context_server_owned": True,
        "csrf_reauthenticated": True,
        "subject_grants_server_owned": True,
        "client_resource_or_handler_selection": False,
    }:
        errors.append("execution authorization boundary drifted")

    idempotency = evidence.get("idempotency", {})
    if idempotency.get("scope") != ["opaque_session", "idempotency_key"]:
        errors.append("execution idempotency scope drifted")
    if idempotency.get("max_executions") != 256 or idempotency.get("max_per_session") != 32:
        errors.append("execution capacity bounds drifted")
    if idempotency.get("retention") != "sha256-fingerprint-and-bounded-outcome-only":
        errors.append("execution retention drifted")
    for key in ["concurrent_exact_replay_single_mutation", "session_cleanup"]:
        if idempotency.get(key) is not True:
            errors.append("execution replay behavior drifted")
    if "first-error" not in idempotency.get("exact_stale_replay", ""):
        errors.append("stale replay retention drifted")

    audit = evidence.get("audit", {})
    expected_audit_fields = ["command", "correlation_id", "idempotency_digest", "mutation_applied", "outcome", "protocol", "resource_revision", "sequence"]
    if audit.get("max_entries") != 64 or audit.get("retained_fields") != expected_audit_fields:
        errors.append("execution audit bound drifted")
    if audit.get("monotonic_sequence") is not True or audit.get("secrets_or_command_bodies") is not False:
        errors.append("execution audit redaction drifted")

    transport = evidence.get("transport", {})
    required_transport = ["canonical-same-origin", "application-json", "encrypted-session", "current-csrf", "phase-5-admission"]
    if transport.get("path") != "/bh07/commands/execute" or transport.get("method") != "POST":
        errors.append("execution transport route drifted")
    if transport.get("max_body_bytes") != 2048 or transport.get("requires") != required_transport:
        errors.append("execution transport security drifted")
    if transport.get("cache_control") != "no-store" or transport.get("nosniff") is not True:
        errors.append("execution response policy drifted")

    expected_capabilities = {
        "sessions": True,
        "csrf_protection": True,
        "command_admission": True,
        "trusted_command_execution": True,
        "remote_commands": True,
        "pushes": False,
        "server_mutation": True,
    }
    if evidence.get("capabilities") != expected_capabilities:
        errors.append("Phase 6 capability boundary drifted")

    gates = {item.get("gate"): item for item in evidence.get("tests", [])}
    required_gates = {
        "blazex-phoenix-package",
        "browser-phoenix-profile",
        "trusted-execution-validator-mutations",
        "research-archive",
        "dependency-boundary",
        "patch-hygiene",
    }
    if set(gates) != required_gates or any(item.get("result") != "passed" or item.get("failures", 0) != 0 for item in gates.values()):
        errors.append("Phase 6 gate evidence is incomplete")

    admission_source = (root / ADMISSION).read_text()
    execution_source = (root / EXECUTION).read_text()
    plug = (root / PLUG).read_text()
    session_plug = (root / SESSION_PLUG).read_text()
    endpoint = (root / ENDPOINT).read_text()
    bootstrap = (root / BOOTSTRAP).read_text()
    mix = (root / PROFILE_MIX).read_text()
    lock = (root / PROFILE_LOCK).read_text()

    if "CommandAdmission.admit" not in execution_source or "validate_envelope" not in admission_source:
        errors.append("Phase 5 admission reuse drifted")
    required_execution_terms = ["@default_max_executions 256", "@default_max_per_session 32", "@default_max_audit 64", 'resource: %{id: "counter", value: 0, revision: 0}', "retain_stale", "state-stale", "idempotency-conflict", "mutation_applied", ":crypto.hash(:sha256"]
    if any(term not in execution_source for term in required_execution_terms):
        errors.append("trusted execution implementation drifted")
    forbidden_dynamic_terms = ["apply(", "Code.eval", "Module.concat", "String.to_atom", "binary_to_term"]
    if any(term in execution_source for term in forbidden_dynamic_terms):
        errors.append("dynamic execution entered trusted authority")
    if "FixtureAuthority" in execution_source or "FixtureAuthority" in plug:
        errors.append("historical BH-01 authority entered Phase 6")
    if any(term not in plug for term in ['@path "/bh07/commands/execute"', "OriginPolicy.authorize", "CommandExecution.execute", "@max_body_bytes 2_048", '"cache-control", "no-store"']):
        errors.append("Phoenix execution integration drifted")
    if "CommandExecution.revoke_session" not in session_plug or "CommandExecution.reset" not in session_plug:
        errors.append("execution lifecycle cleanup drifted")
    if not (endpoint.find("SessionPlug") < endpoint.find("ExecutionPlug") < endpoint.find("AdmissionPlug")):
        errors.append("execution endpoint composition drifted")
    for term in ['"trusted_command_execution" => true', '"remote_commands" => true', '"server_mutation" => true', '"pushes" => false']:
        if term not in bootstrap:
            errors.append("public execution capability drifted")

    forbidden_dependencies = ["blazex_renderer_dom_liveview", "phoenix_live_view", "local_live_view"]
    if any(re.search(r"\{:" + re.escape(name) + r"(?:,|\})", mix) for name in forbidden_dependencies):
        errors.append("deferred dependency returned")
    if any(f'"{name}"' in lock for name in ["phoenix_live_view", "local_live_view"]):
        errors.append("deferred dependency returned")
    if authority.get("deferred") != evidence.get("deferred"):
        errors.append("deferred scope drifted")
    if index.get("status") != "complete" or index.get("phase") != 6 or Path(EVIDENCE).name not in index.get("evidence", []):
        errors.append("Phase 6 evidence index incomplete")
    if "- [ ]" in (root / PLAN).read_text():
        errors.append("Phase 6 checklist incomplete")
    if "[DEFERRED]" not in (root / CONTRACT).read_text():
        errors.append("Phase 6 deferral contract incomplete")

    expected_completion = {
        "decision": "accept",
        "authorization_sha256": digest(root / AUTHORITY),
        "evidence_sha256": digest(root / EVIDENCE),
    }
    if any(completion.get(key) != value for key, value in expected_completion.items()):
        errors.append("Phase 6 completion identities stale")
    return errors


if __name__ == "__main__":
    failures = validate()
    print("\n".join(failures) if failures else "BH-07 Phase 6 trusted execution: ACCEPT (validated)")
    sys.exit(bool(failures))
