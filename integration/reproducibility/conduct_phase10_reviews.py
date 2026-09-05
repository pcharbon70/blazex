#!/usr/bin/env python3
"""Generate and validate discipline-separated BH-01 feasibility reviews."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
SOURCE_REVISION = "e40476cd6f531bfa8a5405c8363508b48be03ac9"
LEDGER = "integration/reproducibility/bh01-phase10-ledger-closure.json"


def load(path: str | Path) -> dict[str, Any]:
    value = Path(path)
    return json.loads((value if value.is_absolute() else ROOT / value).read_text(encoding="utf-8"))


def sha(path: str) -> str:
    return hashlib.sha256((ROOT / path).read_bytes()).hexdigest()


def lens(identifier: str, discipline: str, role: str, scope: str, evidence: list[str], favorable: list[str], challenges: list[str], alternatives: list[str], conditions: list[str], conclusion: str = "acceptable-with-conditions") -> dict[str, Any]:
    return {"id": identifier, "discipline": discipline, "reviewer_role": role, "scope": scope, "evidence": evidence, "favorable_observations": favorable, "challenges": challenges, "alternatives_considered": alternatives, "conditions": conditions, "conclusion": conclusion}


def build() -> dict[str, Any]:
    completion = "docs/research/assets/bh-01-baseline/blazex-bh-01-phase-{:02d}-completion-v0.1.0.json"
    economics = "integration/benchmarks/reports/bh01-phase9-artifact-economics.json"
    budget = "integration/benchmarks/reports/bh01-phase9-budget-evaluation.json"
    deferral = "integration/benchmarks/reports/bh01-phase9-deferred-qualification.json"
    clean = "integration/reproducibility/bh01-phase10-clean-rebuild-comparison.json"
    lenses = [
        lens("BX-BH01-REVIEW-PRODUCT", "product-value", "product-owner", "Whether the active Linux slice provides enough value to justify neutral framework work.", [completion.format(9), budget, LEDGER], ["Local state, forms, timers, DOM updates, fallback, and one server-authorized command work end to end."], ["The application AVM is far over both payload targets, mobile value is unknown, and no support range exists."], ["block the stack", "continue with bounded optimization"], ["BX-BH01-CONDITION-AVM-REACHABILITY", "BX-BH01-CONDITION-BH22-QUALIFICATION"]),
        lens("BX-BH01-REVIEW-ARCHITECTURE", "host-neutral-architecture", "architecture-owner", "Whether proven facts can inform neutral contracts without importing browser or Phoenix details.", [completion.format(5), completion.format(6), LEDGER], ["Standalone DOM, optional LiveView, Phoenix authority, runtime, and fixture ownership remain separated."], ["BH-01 messages and DOM operations are disposable and too implementation-specific to become public contracts."], ["derive neutral contracts in BH-02", "promote fixture protocols"], ["BX-BH01-CONDITION-FIXTURE-DISPOSABILITY"]),
        lens("BX-BH01-REVIEW-RUNTIME", "runtime-viability", "runtime-owner", "Whether AtomVM and Popcorn expose sufficient bounded process, message, timer, and lifecycle behavior.", [completion.format(3), completion.format(7), clean], ["Boot, process/message behavior, recovery, generation isolation, and bounded cleanup pass repeated active scenarios."], ["Timer cancellation reports false, Popcorn requires unsafe-eval, and long-soak/fairness evidence remains incomplete."], ["retain exact pins", "replace or fork runtime when a trigger fails"], ["BX-BH01-CONDITION-RUNTIME-REPEAT"]),
        lens("BX-BH01-REVIEW-IMPLEMENTATION", "implementation-complexity", "bh01-owner", "Whether the build, host, bridge, profile, and evidence burden remains manageable for framework exploration.", [completion.format(4), clean, LEDGER], ["Two clean contexts rebuild and exercise the whole baseline noninteractively with deterministic derived reports."], ["The build is multi-language, path-sensitive without a canonical mount, and expensive enough to demand strict automation."], ["retain reproducible pipeline", "replace the runtime toolchain"], ["BX-BH01-CONDITION-RUNTIME-REPEAT"]),
        lens("BX-BH01-REVIEW-ALTERNATIVES", "candidate-alternatives", "architecture-owner", "Whether replacement, pinning, forking, adapter removal, profile revision, or blocking is more justified.", [LEDGER, economics, "integration/benchmarks/reports/bh01-phase9-mitigation-assessment.json"], ["No active semantic or isolation stop condition is triggered, so immediate replacement would discard validated capability."], ["High payload and private-API risk can still make later replacement, adapter removal, or a fork preferable."], ["replace AtomVM/Popcorn", "fork exact dependencies", "drop LiveView adapter", "revise profile", "block candidate"], ["BX-BH01-CONDITION-AVM-REACHABILITY", "BX-BH01-CONDITION-PRIVATE-API-PINS"]),
        lens("BX-BH01-REVIEW-SECURITY", "security-trust", "security-owner", "Whether current trust, integrity, adversarial, diagnostics, and cleanup evidence is sufficient for BH-02 input.", [completion.format(6), completion.format(7), clean], ["Client claims are rejected, authority is server-owned, integrity drift fails before readiness, and retained diagnostics are redacted."], ["Production identity, TLS/proxy, persistence, distributed limits, CSP removal, audit sinks, and penetration testing are absent."], ["continue with untrusted-client invariant", "move authority into the client"], ["BX-BH01-CONDITION-PRODUCTION-SECURITY"]),
        lens("BX-BH01-REVIEW-ACCESSIBILITY", "accessibility-input", "accessibility-owner", "Whether automated fallback, keyboard, focus, names, roles, fields, and unavailable manual evidence are represented truthfully.", [completion.format(5), completion.format(8), deferral], ["Required fallback content and automated keyboard/focus/field observations pass in active development evidence."], ["No screen-reader pairing, physical mobile input, virtual keyboard, touch, rotation, or accessibility conformance review executed."], ["defer unavailable qualification to BH-22", "pretend automation establishes conformance"], ["BX-BH01-CONDITION-BH22-QUALIFICATION"], "acceptable-with-deferred-qualification"),
        lens("BX-BH01-REVIEW-COMPATIBILITY", "browser-and-private-api-compatibility", "compatibility-owner", "Whether browser prerequisites and private package surfaces have a bounded compatibility posture.", [completion.format(8), deferral, "profiles/browser_phoenix/toolchain/private-api-inventory.json"], ["Active Chrome and Firefox development runs agree semantically; private mismatch disables the optional adapter."], ["Only exact package pins and one Linux host are evidenced; Firefox is a development binary and Safari/mobile are absent."], ["keep exact pins", "drop optional adapter", "claim a compatibility range"], ["BX-BH01-CONDITION-PRIVATE-API-PINS", "BX-BH01-CONDITION-BH22-QUALIFICATION"], "acceptable-exact-pins-only"),
        lens("BX-BH01-REVIEW-QUALITY", "quality-and-statistics", "quality-owner", "Whether measurement methods, negative outcomes, resource observations, and rerun variance support the decision.", [completion.format(9), budget, "integration/benchmarks/reports/bh01-phase9-rerun-comparison.json"], ["Raw samples, unchanged thresholds, deterministic reports, failures, and representative reruns are retained."], ["Payload and Firefox timer budgets fail; Chrome reruns drift; heap/process observations and long-soak methods are incomplete."], ["keep conditional result", "lower thresholds", "repeat after attribution"], ["BX-BH01-CONDITION-FIREFOX-TIMER", "BX-BH01-CONDITION-AVM-REACHABILITY"]),
        lens("BX-BH01-REVIEW-BUILD-RELEASE", "build-packaging-provenance", "build-owner", "Whether artifact origin, reachability, licenses, integrity, maps, serving, rollback, and release gaps are visible.", [completion.format(2), economics, clean], ["Exact archives, locks, licenses, manifests, artifact hashes, source-map policy, and stale-artifact recovery are recorded."], ["AVM reachability is unpruned and actual Brotli negotiation, CDN/proxy behavior, production rollback, and SBOM release automation remain future work."], ["prune reachability", "serve precompressed artifacts", "retain unpruned bundle"], ["BX-BH01-CONDITION-AVM-REACHABILITY", "BX-BH01-CONDITION-BROTLI-SERVING", "BX-BH01-CONDITION-RELEASE-CONTROLS"]),
        lens("BX-BH01-REVIEW-EVIDENCE", "evidence-reproducibility", "bh01-owner", "Whether the final evidence is source-bound, reciprocal, reproducible, failure-preserving, and honest about scope.", [LEDGER, clean, "integration/reproducibility/raw-evidence/bh01-phase10-clean-a-attempt-1.json"], ["A/B authoritative runs agree exactly or semantically and all three failed attempts remain separate from the pass."], ["Both authoritative contexts share one physical host and browser timings remain scheduler-sensitive observations."], ["accept one-host clean contexts", "require unavailable platforms before BH-02"], ["BX-BH01-CONDITION-RUNTIME-REPEAT", "BX-BH01-CONDITION-BH22-QUALIFICATION"]),
    ]
    conditions = [
        {"id": "BX-BH01-CONDITION-AVM-REACHABILITY", "owner": "build-owner", "trigger": "Before release qualification or material bundle composition change", "required_action": "Run a sound module-reachability experiment with before/after manifests and repeat affected Phases 3–10 proofs.", "blocks": ["release readiness", "application payload pass"], "expiry": "Expires when superseded by accepted measured reachability evidence."},
        {"id": "BX-BH01-CONDITION-BROTLI-SERVING", "owner": "browser-profile-owner", "trigger": "Before production profile deployment or transfer-size claim", "required_action": "Verify actual precompressed serving, negotiation, MIME, integrity, cache, isolation, proxy, and CDN behavior.", "blocks": ["production deployment", "transfer-size claim"], "expiry": "Expires when an accepted production-serving profile supersedes the local estimate."},
        {"id": "BX-BH01-CONDITION-FIREFOX-TIMER", "owner": "quality-owner", "trigger": "Before stable Firefox support or interaction-budget promotion", "required_action": "Attribute harness/runtime phases, optimize without changing semantics, and repeat the same timer distribution in a stable Firefox product.", "blocks": ["Firefox support", "local interaction budget pass"], "expiry": "Expires only on accepted same-boundary stable-product evidence."},
        {"id": "BX-BH01-CONDITION-PRIVATE-API-PINS", "owner": "liveview-adapter-owner", "trigger": "Any Phoenix, LiveView, LocalLiveView, or optional adapter change", "required_action": "Repeat private-surface inventory and compatibility probes while retaining standalone DOM fallback and neutral package isolation.", "blocks": ["optional adapter compatibility", "package upgrade"], "expiry": "Reevaluated at every private dependency revision."},
        {"id": "BX-BH01-CONDITION-RUNTIME-REPEAT", "owner": "runtime-owner", "trigger": "Any runtime, OTP, Popcorn, toolchain, bridge, or canonical build-root change", "required_action": "Repeat affected runtime, browser, behavior, resilience, measurement, and clean-rebuild proofs from immutable inputs.", "blocks": ["baseline supersession", "runtime compatibility claim"], "expiry": "Reevaluated at every named runtime or toolchain change."},
        {"id": "BX-BH01-CONDITION-PRODUCTION-SECURITY", "owner": "security-owner", "trigger": "Before production authentication, deployment, or security claim", "required_action": "Design and validate production identity, TLS/proxy, persistence, distributed limits, CSP, audit, monitoring, and penetration-test controls.", "blocks": ["production security", "production deployment"], "expiry": "Expires only through an accepted production security gate."},
        {"id": "BX-BH01-CONDITION-BH22-QUALIFICATION", "owner": "quality-owner", "trigger": "BH-22 start or availability of representative external environments", "required_action": "Execute non-substitutable platform, stable-browser, physical-device, mobile, and manual assistive-technology qualification.", "blocks": ["browser support", "mobile viability", "cross-platform support", "accessibility conformance", "release readiness"], "expiry": "Remains open until BH-22 qualification accepts or rejects each deferred row."},
        {"id": "BX-BH01-CONDITION-FIXTURE-DISPOSABILITY", "owner": "architecture-owner", "trigger": "During BH-02 semantic, renderer, capability, effect, or resource contract design", "required_action": "Derive neutral contracts from observable facts and prohibit BH-01 messages, DOM operations, Phoenix routes, and profile fixtures from becoming public APIs by default.", "blocks": ["public API stabilization", "host-neutral contract acceptance"], "expiry": "Expires only when BH-02 accepts independently reviewed neutral contracts."},
        {"id": "BX-BH01-CONDITION-RELEASE-CONTROLS", "owner": "build-owner", "trigger": "Before package publication or release-readiness claim", "required_action": "Complete SBOM, license/notice, signing, source-map, reachability, production serving, rollback, provenance, and release invalidation gates.", "blocks": ["package publication", "release readiness"], "expiry": "Expires only through an accepted release gate."},
    ]
    alternatives = [
        {"id": "BX-BH01-ALT-CONTINUE", "option": "Continue the exact candidate stack into host-neutral BH-02 contract design", "disposition": "selected-for-bh02-input", "rationale": "Active semantics, isolation, recovery, and reproducibility pass while known failures have bounded conditions.", "revisit_trigger": "Any active stop condition becomes triggered."},
        {"id": "BX-BH01-ALT-REPLACE-RUNTIME", "option": "Replace AtomVM or Popcorn before BH-02", "disposition": "reserve-if-triggered", "rationale": "Immediate replacement is not justified by current active proofs, but runtime semantics, security, or build failure can trigger it.", "revisit_trigger": "Runtime proof failure, unsafe bridge dead end, or unbounded resource behavior."},
        {"id": "BX-BH01-ALT-FORK", "option": "Fork or patch a pinned dependency", "disposition": "reserve-if-triggered", "rationale": "A fork adds maintenance burden and is justified only when an owned upstream limitation blocks a required proof or condition.", "revisit_trigger": "Pinned upstream cannot satisfy a required bounded mitigation."},
        {"id": "BX-BH01-ALT-DROP-LIVEVIEW", "option": "Drop the optional LiveView/LocalLiveView adapter", "disposition": "viable-fallback", "rationale": "Standalone DOM and Phoenix authority boundaries remain independent, so private API incompatibility need not block the core browser host.", "revisit_trigger": "Private pins drift or adapter maintenance outweighs demonstrated value."},
        {"id": "BX-BH01-ALT-REVISE-PROFILE", "option": "Revise the profile through AVM pruning and actual compressed serving", "disposition": "required-later-experiment", "rationale": "The current unpruned application bundle is the dominant payload and fails both active application limits.", "revisit_trigger": "Before any release or production profile claim."},
        {"id": "BX-BH01-ALT-BLOCK", "option": "Block and archive the candidate browser stack", "disposition": "not-selected", "rationale": "No active semantic, isolation, reproducibility, or accounting stop condition is triggered after bounded conditions are applied.", "revisit_trigger": "A condition cannot be satisfied without violating neutral or authority boundaries."},
    ]
    return {
        "schema_version": "1.0.0", "record_id": "BX-BH01-PHASE10-FEASIBILITY-REVIEW-0.1", "status": "reviewed-proceed-with-bounded-conditions", "source_revision": SOURCE_REVISION,
        "ledger_ref": {"path": LEDGER, "sha256": sha(LEDGER)},
        "method": {"review_model": "discipline-separated-evidence-review", "human_independence_claimed": False, "owner_acceptance_required_for_decision": True},
        "lenses": lenses, "conditions": conditions, "alternatives": alternatives, "blocking_findings": [],
        "accepted_findings": [item["id"] for item in conditions],
        "decision": {"result": "proceed-with-bounded-conditions", "rationale": "The active Linux evidence proves the candidate can support neutral framework exploration, clean rebuilding, bounded lifecycle behavior, isolated server authority, and disposable rendering experiments. Payload, Firefox timing, private API, production, release, and external qualification gaps remain explicit owned conditions rather than hidden passes.", "bh02_eligibility": "eligible-pending-entry-record-and-owner-authorization", "bh02_authorized": False, "support_status": "unsupported"},
        "prohibited_claims": ["browser support", "mobile viability", "accessibility conformance", "production security", "performance budget pass", "native compatibility", "release readiness"],
    }


def validate(record: dict[str, Any]) -> list[str]:
    errors = [error.message for error in Draft202012Validator(load(HERE / "feasibility-review.schema.json")).iter_errors(record)]
    expected_disciplines = {"product-value", "host-neutral-architecture", "runtime-viability", "implementation-complexity", "candidate-alternatives", "security-trust", "accessibility-input", "browser-and-private-api-compatibility", "quality-and-statistics", "build-packaging-provenance", "evidence-reproducibility"}
    actual_disciplines = {item.get("discipline") for item in record.get("lenses", [])}
    if actual_disciplines != expected_disciplines:
        errors.append("required multidisciplinary lens set is incomplete or duplicated")
    condition_ids = {item.get("id") for item in record.get("conditions", [])}
    for item in record.get("lenses", []):
        if not item.get("challenges") or not item.get("alternatives_considered"):
            errors.append(f"review lens lacks challenge or alternative: {item.get('id')}")
        if not set(item.get("conditions", [])).issubset(condition_ids):
            errors.append(f"review lens references an unknown condition: {item.get('id')}")
        for path in item.get("evidence", []):
            if not (ROOT / path).is_file():
                errors.append(f"missing review evidence: {path}")
    ref = record.get("ledger_ref", {})
    if ref.get("path") != LEDGER or ref.get("sha256") != sha(LEDGER):
        errors.append("review ledger binding is stale")
    decision = record.get("decision", {})
    if decision.get("support_status") != "unsupported" or decision.get("bh02_authorized") is not False:
        errors.append("review over-promotes support or BH-02 authorization")
    if record.get("blocking_findings"):
        errors.append("blocking findings require revise-or-block rather than proceed")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    expected = build()
    record = load(args.output) if args.check else expected
    errors = validate(record)
    if args.check and record != expected:
        errors.append("feasibility review is stale relative to canonical review inputs")
    if not args.check and not errors:
        args.output.write_text(json.dumps(record, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        return 1
    print(f"BH-01 Phase 10 multidisciplinary review: PASS ({len(record['lenses'])} lenses; {len(record['conditions'])} conditions; {len(record['alternatives'])} alternatives)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
