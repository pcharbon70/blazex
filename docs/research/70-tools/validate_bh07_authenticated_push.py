"""Validate BH-07 Phase 7 authenticated push and cursor resynchronization."""

import hashlib
import json
import re
import sys
from pathlib import Path

from research_paths import REPO_ROOT

AUTHORITY = "docs/research/assets/bh-07-baseline/phase-07-authorization-v0.1.0.json"
EVIDENCE = "integration/bh-07/phase-07-authenticated-push-evidence-v0.1.0.json"
INDEX = "integration/bh-07/index-v0.1.0.json"
COMPLETION = "docs/research/assets/bh-07-baseline/phase-07-completion-v0.1.0.json"
PLAN = "docs/research/60-planning/01-browser-host/bh-07-phoenix-integration-and-trusted-command-boundary/phase-07-authenticated-server-push-and-resynchronization.md"
CONTRACT = "docs/research/60-planning/01-browser-host/bh-07-phoenix-integration-and-trusted-command-boundary/server-push-contract.md"
EXECUTION = "packages/blazex_phoenix/lib/blazex/phoenix/command_execution.ex"
BOOTSTRAP = "packages/blazex_phoenix/lib/blazex/phoenix/public_bootstrap.ex"
SOCKET = "profiles/browser_phoenix/lib/blazex_browser_phoenix/socket.ex"
CHANNEL = "profiles/browser_phoenix/lib/blazex_browser_phoenix/counter_channel.ex"
ENDPOINT = "profiles/browser_phoenix/lib/blazex_browser_phoenix/endpoint.ex"
APPLICATION = "profiles/browser_phoenix/lib/blazex_browser_phoenix/application.ex"
CONFIG = "profiles/browser_phoenix/config/config.exs"
PROFILE_MIX = "profiles/browser_phoenix/mix.exs"
PROFILE_LOCK = "profiles/browser_phoenix/mix.lock"
MUTABLE = {
    EXECUTION: "672022c5ece963f54aed5621bd6665c3ef4aa661e39814bc8a5056e523d50123",
    ENDPOINT: "cfc7effc75c2d0db9aca0175af5f973a68e1e144a038eec5b070724b0afea769",
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

    if authority.get("authorized") is not True or authority.get("phase") != 7:
        errors.append("Phase 7 authority is invalid")
    for relative, expected in authority.get("bound_inputs", {}).items():
        if relative in MUTABLE:
            if expected != MUTABLE[relative]:
                errors.append(f"mutable baseline identity drift: {relative}")
        elif not (root / relative).is_file() or digest(root / relative) != expected:
            errors.append(f"bound input drift: {relative}")

    if evidence.get("decision") != "accept" or evidence.get("support_state") != "unsupported-development-evidence":
        errors.append("authenticated-push evidence decision drifted")
    for relative, expected in evidence.get("source_bindings", {}).items():
        if not (root / relative).is_file() or digest(root / relative) != expected:
            errors.append(f"implementation source binding drift: {relative}")

    stream = evidence.get("stream", {})
    expected_stream = {
        "event_protocol": "blazex.bh07.counter-update/1",
        "sync_protocol": "blazex.bh07.push-sync/1",
        "max_events": 64,
        "max_subscribers": 64,
        "monotonic_sequence": True,
        "fresh_success_emits_once": True,
        "exact_command_replay_emits": False,
        "failed_command_emits": False,
        "subscriber_process_monitored": True,
        "expired_before_broadcast_pruned": True,
        "session_revocation_cleanup": True,
    }
    if stream != expected_stream:
        errors.append("bounded push stream drifted")

    sync = evidence.get("resynchronization", {})
    expected_sync = {
        "cursor_field": "after_sequence",
        "retained_cursor": "ordered-missing-event-replay",
        "current_cursor": "empty-replay",
        "evicted_cursor": "current-resource-snapshot",
        "future_cursor": "push-cursor-invalid",
        "durable_history": False,
        "offline_command_queue": False,
    }
    if sync != expected_sync:
        errors.append("cursor resynchronization drifted")

    transport = evidence.get("transport", {})
    expected_transport = {
        "socket_path": "/bh07/socket",
        "topic": "bh07:counter",
        "connect_protocol": "blazex.bh07.push-connect/1",
        "join_protocol": "blazex.bh07.push-join/1",
        "push_event": "counter",
        "max_frame_bytes": 2048,
        "phoenix_origin_check": True,
        "encrypted_session_connect_info": True,
        "blazex_current_csrf_required": True,
        "client_channel_events": "deny-all",
        "arbitrary_topics": False,
    }
    if transport != expected_transport:
        errors.append("Phoenix push transport drifted")

    redaction = evidence.get("redaction", {})
    if redaction.get("public_event_fields") != ["protocol", "resource", "sequence"]:
        errors.append("push event schema drifted")
    if redaction.get("public_resource_fields") != ["id", "revision", "value"]:
        errors.append("push resource schema drifted")
    for key in ["opaque_session_id", "csrf_proof", "subject_grants", "command_body", "idempotency_key"]:
        if redaction.get(key) is not False:
            errors.append("push redaction drifted")

    expected_capabilities = {
        "sessions": True,
        "csrf_protection": True,
        "command_admission": True,
        "trusted_command_execution": True,
        "remote_commands": True,
        "server_push": True,
        "pushes": True,
        "server_mutation": True,
    }
    if evidence.get("capabilities") != expected_capabilities:
        errors.append("Phase 7 capability boundary drifted")

    gates = {item.get("gate"): item for item in evidence.get("tests", [])}
    required_gates = {
        "blazex-phoenix-package",
        "browser-phoenix-profile",
        "authenticated-push-validator-mutations",
        "research-archive",
        "dependency-boundary",
        "patch-hygiene",
    }
    if set(gates) != required_gates or any(item.get("result") != "passed" or item.get("failures", 0) != 0 for item in gates.values()):
        errors.append("Phase 7 gate evidence is incomplete")

    execution = (root / EXECUTION).read_text()
    bootstrap = (root / BOOTSTRAP).read_text()
    socket = (root / SOCKET).read_text()
    channel = (root / CHANNEL).read_text()
    endpoint = (root / ENDPOINT).read_text()
    application = (root / APPLICATION).read_text()
    config = (root / CONFIG).read_text()
    mix = (root / PROFILE_MIX).read_text()
    lock = (root / PROFILE_LOCK).read_text()

    execution_terms = ["@default_max_events 64", "@default_max_subscribers 64", "def subscribe", "Process.monitor", "{:DOWN", "prune_expired_subscribers", "push-cursor-invalid", "blazex.bh07.counter-update/1", "blazex.bh07.push-sync/1"]
    if any(term not in execution for term in execution_terms):
        errors.append("push stream implementation drifted")
    if execution.count("|> publish(resource, now_ms)") != 1:
        errors.append("fresh-only push emission drifted")
    if any(term not in socket for term in ["bh07:counter", "blazex.bh07.push-connect/1", "SessionRegistry.authority_context", "bh07_session_id", "bh07_csrf_token", "def id(_socket), do: nil"]):
        errors.append("authenticated socket implementation drifted")
    if any(term not in channel for term in ["blazex.bh07.push-join/1", "CommandExecution.subscribe", "push-client-event-denied", "blazex_counter_update", 'push(socket, "counter", event)', "CommandExecution.unsubscribe"]):
        errors.append("counter channel implementation drifted")
    endpoint_terms = ['socket("/bh07/socket"', "connect_info: [session: @session_options]", "check_csrf: false", "max_frame_size: 2_048"]
    if any(term not in endpoint for term in endpoint_terms) or "check_origin: false" in endpoint:
        errors.append("socket origin/session composition drifted")
    if "Phoenix.PubSub" not in application or "BlazeXBrowserPhoenix.PubSub" not in config:
        errors.append("local PubSub composition drifted")
    for term in ['"server_push" => true', '"pushes" => true']:
        if term not in bootstrap:
            errors.append("public push capability drifted")

    forbidden_dependencies = ["blazex_renderer_dom_liveview", "phoenix_live_view", "local_live_view"]
    if any(re.search(r"\{:" + re.escape(name) + r"(?:,|\})", mix) for name in forbidden_dependencies):
        errors.append("deferred dependency returned")
    if any(f'"{name}"' in lock for name in ["phoenix_live_view", "local_live_view"]):
        errors.append("deferred dependency returned")
    if '{:phoenix_pubsub, "== 2.3.0"}' not in mix:
        errors.append("Phoenix PubSub dependency is not explicit")
    if authority.get("deferred") != evidence.get("deferred"):
        errors.append("deferred scope drifted")
    if index.get("status") != "complete" or index.get("phase") != 7 or Path(EVIDENCE).name not in index.get("evidence", []):
        errors.append("Phase 7 evidence index incomplete")
    if "- [ ]" in (root / PLAN).read_text():
        errors.append("Phase 7 checklist incomplete")
    if "[DEFERRED]" not in (root / CONTRACT).read_text():
        errors.append("Phase 7 deferral contract incomplete")

    expected_completion = {
        "decision": "accept",
        "authorization_sha256": digest(root / AUTHORITY),
        "evidence_sha256": digest(root / EVIDENCE),
    }
    if any(completion.get(key) != value for key, value in expected_completion.items()):
        errors.append("Phase 7 completion identities stale")
    return errors


if __name__ == "__main__":
    failures = validate()
    print("\n".join(failures) if failures else "BH-07 Phase 7 authenticated push: ACCEPT (validated)")
    sys.exit(bool(failures))
