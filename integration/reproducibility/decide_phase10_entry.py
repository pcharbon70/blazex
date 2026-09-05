#!/usr/bin/env python3
"""Generate and validate the BH-01 decision and bounded BH-02 entry manifest."""

from __future__ import annotations

import argparse
import hashlib
import json
from collections import Counter
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
RELEASE = ROOT / "docs/research/assets/bh-01-release"
SOURCE_REVISION = "04c115e317d7edc483c34cd697ac304310a14369"
BASELINE_PATH = "docs/research/assets/bh-01-release/blazex-bh-01-feasibility-baseline-v0.1.0.json"
REVIEW_PATH = "integration/reproducibility/bh01-phase10-feasibility-review.json"
AUTH_PATH = "docs/research/assets/bh-01-baseline/blazex-bh-01-phase-10-authorization-v0.1.0.json"
DECISION_PATH = "docs/research/assets/bh-01-release/blazex-bh-01-feasibility-decision-v0.1.0.json"
ENTRY_PATH = "docs/research/assets/bh-01-release/blazex-bh-02-entry-manifest-v0.1.0.json"


def load(path: str | Path) -> dict[str, Any]:
    value = Path(path)
    return json.loads((value if value.is_absolute() else ROOT / value).read_text(encoding="utf-8"))


def digest(path: str | Path) -> str:
    value = Path(path)
    return hashlib.sha256((value if value.is_absolute() else ROOT / value).read_bytes()).hexdigest()


def ref(path: str) -> dict[str, str]:
    return {"path": path, "sha256": digest(path)}


def counts(items: list[dict[str, Any]], key: str) -> dict[str, int]:
    return dict(sorted(Counter(item[key] for item in items).items()))


def build_decision() -> dict[str, Any]:
    baseline = load(BASELINE_PATH)
    review = load(REVIEW_PATH)
    closure = baseline["closure_inventory"]
    return {
        "schema_version": "1.0.0", "decision_id": "BX-BH01-PHASE10-FEASIBILITY-DECISION-0.1",
        "status": "authorized-proceed-with-bounded-conditions", "source_revision": SOURCE_REVISION,
        "baseline_ref": ref(BASELINE_PATH), "review_ref": ref(REVIEW_PATH), "authorization_ref": ref(AUTH_PATH),
        "approvals": [{"role": "repository-owner", "identity": "pcharbon70", "basis": "The explicit Phase 10 authorization includes making and immediately merging the evidence-based BH-02 entry decision."}],
        "result": "proceed-with-bounded-conditions",
        "rationale": "The candidate reconstructs exactly in two independent clean contexts on the available Linux host, executes required active semantics without violating renderer or server-authority boundaries, and retains every adverse result. Payload economics, Firefox timer behavior, exact private pins, production controls, release work, and external qualification remain bounded conditions rather than manufactured passes.",
        "proof_summary": counts(closure["proof_obligations"], "state"), "risk_summary": counts(closure["risks"], "state"), "stop_summary": counts(closure["stop_conditions"], "state"),
        "blocking_findings": [], "accepted_conditions": review["conditions"], "invalidated_evidence": [],
        "bh01_status": "decision-authorized-final-integration-pending",
        "bh02_entry": {"eligible": True, "authorized": False, "may_start": False, "required_next_action": "complete Phase 10 integration and receive explicit repository-owner BH-02 authorization"},
        "prohibited_claims": review["prohibited_claims"],
    }


def build_entry(decision: dict[str, Any]) -> dict[str, Any]:
    baseline = load(BASELINE_PATH)
    closure = baseline["closure_inventory"]
    active_proofs = [item["id"] for item in closure["proof_obligations"] if item["scope"] == "active-linux"]
    return {
        "schema_version": "1.0.0", "manifest_id": "BX-BH02-ENTRY-MANIFEST-0.1",
        "status": "ready-pending-final-integration-and-explicit-authorization", "source_revision": SOURCE_REVISION,
        "baseline_ref": ref(BASELINE_PATH), "decision_ref": {"path": DECISION_PATH, "sha256": hashlib.sha256((json.dumps(decision, indent=2, sort_keys=True) + "\n").encode()).hexdigest()},
        "activation": {"eligible": True, "authorized": False, "may_start": False, "authorization_requirement": "explicit repository-owner authorization after Phase 10 integration completion"},
        "goal": "Define the first host-neutral semantic kernel and prove that one interaction set can target headless, DOM, and a limited native-control spike without browser or toolkit objects in portable component code.",
        "repository_boundaries": ["packages/blazex_core", "packages/blazex_effects", "packages/blazex_ui_tree", "packages/blazex_renderer", "packages/blazex_renderer_headless", "packages/blazex_renderer_dom", "packages/blazex_test", "profiles/headless", "integration/conformance", "integration/fixtures", "experiments/native_renderer_spike"],
        "proven_host_facts": [
            "A checksum-governed Wasm runtime can boot a packaged Elixir application and expose bounded process, message, timer, failure, and cleanup observations.",
            "A worker-owned browser host can validate a manifest, detect prerequisites, report readiness, reject stale generations, recover, and dispose owned resources.",
            "A bounded renderer adapter can validate operations, preserve keyed identity, normalize events, reject malformed input before partial mutation, and converge on cleanup.",
            "Server-owned authentication, authorization, resource version, idempotency, rate, audit, and side effects remain independent of untrusted client presentation.",
            "Standalone DOM behavior does not require Phoenix, Plug, LiveView, or LocalLiveView; the private LiveView adapter is optional and exact-pins-only.",
            "Active Chrome and Firefox development executions agree on normalized semantics while remaining unsupported products.",
            "Immutable source and tools can reproduce runtime, AVM, profile, and report identities in two clean contexts on one Linux host."
        ],
        "neutral_contract_constraints": [
            "Represent semantic nodes independently of any concrete renderer.",
            "Make identity explicit and deterministic across update, move, replacement, and disposal.",
            "Represent events as validated semantic input rather than host callback objects.",
            "Represent effects as requested capabilities with explicit ownership and cancellation.",
            "Keep resources generation-scoped, bounded, observable, and idempotently disposable.",
            "Separate presentation state from authority-bearing decisions and side effects.",
            "Make fallback and unsupported capability outcomes explicit semantic states.",
            "Require deterministic headless traces before backend-specific conformance credit.",
            "Keep layout intent, accessibility intent, tokens, and focus/selection semantics host neutral."
        ],
        "disposable_lessons": [
            "BH-01 Elixir fixture modules and message tuples are examples, not public component APIs.",
            "BH-01 DOM operation names and JSON wire shapes are renderer experiments, not the neutral tree protocol.",
            "BH-01 Phoenix routes, session fixtures, command names, and audit shapes are not server-adapter contracts.",
            "BH-01 lifecycle state names and JavaScript callback shapes are not portable host contracts.",
            "BH-01 benchmark workloads and timing boundaries remain experimental methods.",
            "Popcorn, AtomVM, Phoenix, LiveView, browser, and toolkit implementation objects stay behind adapters."
        ],
        "limitations": baseline["limitations"], "conditions": decision["accepted_conditions"],
        "deferred_qualification": baseline["environments"]["deferred"], "repeat_obligations": active_proofs,
        "forbidden_leakage": [
            "HTML or DOM node types in portable packages", "browser event or JavaScript callback objects in semantic APIs",
            "Phoenix, Plug, LiveView, or LocalLiveView dependencies in portable packages", "Popcorn or AtomVM types in semantic packages",
            "BH-01 fixture message tuples, route paths, command strings, or JSON shapes as public contracts", "private LiveView renderer data outside its optional adapter",
            "native toolkit handles or widget classes in portable component code"
        ],
        "required_outputs": [
            "versioned semantic UI node and identity contract", "host-neutral event and action contract", "effect, capability, and resource ownership contract",
            "layout, token, accessibility, focus, selection, and file-choice intent", "renderer lifecycle and capability negotiation contract",
            "deterministic headless renderer and canonical traces", "minimal DOM lowering conforming to the same traces",
            "limited native-control portability spike conforming to the same interaction set", "automated forbidden-dependency and leakage checks"
        ],
        "support_status": "unsupported",
    }


def render_decision(decision: dict[str, Any]) -> str:
    return f"---\ntitle: \"BH-01 Feasibility Decision v0.1.0\"\nkind: note\ncreated: \"2026-09-05\"\nmaturity: stable\ntags:\n  - bh-01\n  - decision\n  - feasibility\n---\n\n# BH-01 Feasibility Decision v0.1.0\n\n- Result: **{decision['result']}**\n- Decision authorization: **recorded**\n- BH-01 status: `{decision['bh01_status']}`\n- BH-02 eligible: `{str(decision['bh02_entry']['eligible']).lower()}`\n- BH-02 authorized: `{str(decision['bh02_entry']['authorized']).lower()}`\n- Support: `unsupported`\n\n{decision['rationale']}\n\nNine accepted conditions remain binding. Final Phase 10 integration and a separate explicit repository-owner request are required before BH-02 may start.\n"


def render_entry(entry: dict[str, Any]) -> str:
    sections = ["---\ntitle: \"BH-02 Conditional Entry Manifest v0.1.0\"\nkind: note\ncreated: \"2026-09-05\"\nmaturity: stable\ntags:\n  - bh-02\n  - entry-manifest\n  - host-neutral\n---\n\n# BH-02 Conditional Entry Manifest v0.1.0\n", f"\n- Status: `{entry['status']}`\n- Authorized: `{str(entry['activation']['authorized']).lower()}`\n- May start: `{str(entry['activation']['may_start']).lower()}`\n", f"\n## Goal\n\n{entry['goal']}\n"]
    for title, key in (("Proven host facts", "proven_host_facts"), ("Neutral contract constraints", "neutral_contract_constraints"), ("Disposable BH-01 lessons", "disposable_lessons"), ("Forbidden leakage", "forbidden_leakage"), ("Required outputs", "required_outputs")):
        sections.append(f"\n## {title}\n\n" + "\n".join(f"- {item}" for item in entry[key]) + "\n")
    sections.append("\nBH-02 requires explicit owner authorization after Phase 10 integration. This manifest grants no browser, native, mobile, accessibility, security, performance, or release support.\n")
    return "".join(sections)


def validate(decision: dict[str, Any], entry: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    for schema_name, record in (("blazex-bh-01-feasibility-decision.schema.json", decision), ("blazex-bh-02-entry-manifest.schema.json", entry)):
        errors.extend(error.message for error in Draft202012Validator(load(RELEASE / schema_name)).iter_errors(record))
    for field in ("baseline_ref", "review_ref", "authorization_ref"):
        if field in decision:
            item = decision[field]
            if not (ROOT / item["path"]).is_file() or item["sha256"] != digest(item["path"]):
                errors.append(f"stale decision reference: {field}")
    if entry.get("decision_ref", {}).get("sha256") != hashlib.sha256((json.dumps(decision, indent=2, sort_keys=True) + "\n").encode()).hexdigest():
        errors.append("entry decision binding is stale")
    review = load(REVIEW_PATH)
    if {item["id"] for item in entry.get("conditions", [])} != {item["id"] for item in review["conditions"]}:
        errors.append("entry condition set differs from accepted review")
    baseline = load(BASELINE_PATH)
    if {item["id"] for item in entry.get("deferred_qualification", [])} != {item["id"] for item in baseline["environments"]["deferred"]}:
        errors.append("entry deferred qualification set is incomplete")
    active_proofs = {item["id"] for item in baseline["closure_inventory"]["proof_obligations"] if item["scope"] == "active-linux"}
    if set(entry.get("repeat_obligations", [])) != active_proofs:
        errors.append("entry repeat-proof inventory is incomplete")
    banned = ("html", "dom", "javascript", "phoenix", "plug", "liveview", "popcorn", "atomvm", "browser", "toolkit")
    for item in entry.get("neutral_contract_constraints", []):
        if any(token in item.lower() for token in banned):
            errors.append(f"backend leakage in neutral constraint: {item}")
    if decision.get("bh02_entry", {}).get("authorized") is not False or entry.get("activation", {}).get("may_start") is not False or entry.get("support_status") != "unsupported":
        errors.append("BH-02 entry over-authorizes implementation or support")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    expected_decision = build_decision()
    expected_entry = build_entry(expected_decision)
    decision = load(DECISION_PATH) if args.check else expected_decision
    entry = load(ENTRY_PATH) if args.check else expected_entry
    errors = validate(decision, entry)
    if args.check and (decision != expected_decision or entry != expected_entry):
        errors.append("decision or entry manifest is stale relative to canonical evidence")
    decision_md = render_decision(expected_decision)
    entry_md = render_entry(expected_entry)
    if args.check:
        for name, expected in (("blazex-bh-01-feasibility-decision-v0-1-0.md", decision_md), ("blazex-bh-02-entry-manifest-v0-1-0.md", entry_md)):
            path = RELEASE / name
            if not path.is_file() or path.read_text(encoding="utf-8") != expected:
                errors.append(f"generated decision view is stale: {name}")
    elif not errors:
        (ROOT / DECISION_PATH).write_text(json.dumps(decision, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        (ROOT / ENTRY_PATH).write_text(json.dumps(entry, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        (RELEASE / "blazex-bh-01-feasibility-decision-v0-1-0.md").write_text(decision_md, encoding="utf-8")
        (RELEASE / "blazex-bh-02-entry-manifest-v0-1-0.md").write_text(entry_md, encoding="utf-8")
    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        return 1
    print(f"BH-01 decision: {decision['result']}; BH-02 eligible={entry['activation']['eligible']} authorized={entry['activation']['authorized']} may_start={entry['activation']['may_start']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
