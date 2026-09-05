#!/usr/bin/env python3
"""Build and validate the BH-01 Phase 10 closure ledger."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
SOURCE_REVISION = "7071e0f358903aea4a86c50db982c3fb1086584d"
MILESTONE_LEDGER = "docs/research/assets/bh-01-baseline/blazex-bh-01-milestone-ledger-v0.1.0.json"
PHASE = "docs/research/assets/bh-01-baseline/blazex-bh-01-phase-{:02d}-completion-v0.1.0.json"


def load(path: str | Path) -> dict[str, Any]:
    value = Path(path)
    return json.loads((value if value.is_absolute() else ROOT / value).read_text(encoding="utf-8"))


def closure(identifier: str, owner: str, state: str, evidence: list[str], outcome: str, effect: str) -> dict[str, Any]:
    return {"id": identifier, "owner": owner, "state": state, "evidence": evidence, "outcome": outcome, "decision_effect": effect}


def build() -> dict[str, Any]:
    source = load(MILESTONE_LEDGER)
    input_details = {
        "BX-BH01-INPUT-ARTIFACTS": ("closed-conditional", [PHASE.format(3), "integration/benchmarks/reports/bh01-phase9-artifact-economics.json", "integration/reproducibility/bh01-phase10-clean-rebuild-comparison.json"], "All runtime, AVM, JavaScript, map, profile, hash, provenance, and size identities are accounted for; the unpruned application AVM remains over budget.", "Continue only with the reachability and serving conditions; no release claim."),
        "BX-BH01-INPUT-BEHAVIORS": ("closed-passed", [PHASE.format(5), PHASE.format(6), PHASE.format(7), "integration/fixtures/browser_matrix/matrix-report.json"], "Runtime, state, nesting, form, timer/message, DOM, command, failure, recovery, and cleanup behavior passed the active Linux evidence boundary.", "Supports review of a host-neutral contract, not stabilization of fixture protocols."),
        "BX-BH01-INPUT-BROWSERS": ("closed-with-deferred-qualification", [PHASE.format(8), "integration/benchmarks/reports/bh01-phase9-deferred-qualification.json", "integration/reproducibility/bh01-phase10-clean-rebuild-comparison.json"], "Chrome and Firefox development evidence is complete for Linux; unavailable product/platform/device/manual rows remain deferred to BH-22.", "Does not block BH-02 review and grants no browser support."),
        "BX-BH01-INPUT-MEASUREMENTS": ("closed-conditional", [PHASE.format(9), "integration/benchmarks/reports/bh01-phase9-budget-evaluation.json", "integration/benchmarks/reports/bh01-phase9-rerun-comparison.json"], "Active measurements are retained with payload and Firefox timer failures plus scheduler-sensitive rerun drift; mobile remains undecided and deferred.", "Requires bounded follow-up before release qualification; no threshold changed."),
        "BX-BH01-INPUT-PRIVATE-API": ("closed-exact-pins-only", [PHASE.format(2), PHASE.format(6), "profiles/browser_phoenix/toolchain/private-api-inventory.json"], "LiveView and LocalLiveView private surfaces are inventoried, exact-pinned, isolated, and fail to standalone DOM on mismatch.", "Optional adapter may inform BH-02 but cannot define portable semantics."),
        "BX-BH01-INPUT-PROFILE-SLICE": ("closed-passed", [PHASE.format(6), "profiles/browser_phoenix/priv/static/bh01/profile-assets-manifest.json"], "The disposable Phoenix/browser profile composes the required vertical slice while standalone DOM, Plug, and headless dependency boundaries remain isolated.", "Profile facts may be consumed; fixture contracts remain disposable."),
        "BX-BH01-INPUT-STOP-CONDITIONS": ("closed-conditional", [PHASE.format(9), "integration/benchmarks/reports/bh01-phase9-stop-decision.json", "integration/reproducibility/bh01-phase10-clean-rebuild-comparison.json"], "All five binding stop conditions are evaluated; none requires stopping active framework exploration, while two retain bounded conditions.", "Eligible for multidisciplinary review with all conditions visible."),
        "BX-BH01-INPUT-TOOLCHAIN": ("closed-passed", [PHASE.format(2), "profiles/browser_phoenix/toolchain/environment.lock.json", "integration/reproducibility/bh01-phase10-clean-rebuild-comparison.json"], "Pinned tool, archive, dependency, and container identities rebuilt the baseline in two independent clean execution contexts on one Linux host.", "Satisfies active reproducibility input; cross-machine qualification remains limited."),
    }
    inputs = [closure(item["id"], item["owner"], *input_details[item["id"]]) for item in source["inputs"]]

    common_behavior = ["integration/fixtures/browser_matrix/matrix-report.json", "integration/reproducibility/bh01-phase10-clean-rebuild-comparison.json"]
    proof_details = {
        "BX-BH01-PROOF-ARTIFACT-ACCOUNTING": ("closed-conditional", "active-linux", [PHASE.format(3), "integration/benchmarks/reports/bh01-phase9-artifact-economics.json"] + common_behavior, "Artifact identity and origin are complete, but the unpruned application AVM fails both application payload budgets.", "Proof is satisfied for accounting and conditional for economics; release claims remain prohibited.", True),
        "BX-BH01-PROOF-AUTHENTICATED-COMMAND": ("closed-passed", "active-linux", [PHASE.format(6), "integration/fixtures/raw-evidence/bh01-phase7-resilience-security-resource.json"] + common_behavior, "Positive, denied, forged, stale, replayed, disconnected, retried, and disposed command cases preserve server authority with zero unauthorized effects.", "Supports neutral command/effect design while production security remains future work.", True),
        "BX-BH01-PROOF-BROWSER-FALLBACK": ("closed-with-deferred-qualification", "active-linux", [PHASE.format(4), "integration/fixtures/browser_matrix/matrix-report.json"], "Missing Wasm, isolation, manifest, integrity, and JavaScript prerequisites produce bounded accessible fallback in active development browsers.", "Active proof passes; unavailable product/browser/device/manual qualification remains BH-22.", True),
        "BX-BH01-PROOF-BUILD-REPRODUCIBILITY": ("closed-passed", "active-linux", ["integration/reproducibility/raw-evidence/bh01-phase10-clean-a-authoritative.json", "integration/reproducibility/raw-evidence/bh01-phase10-clean-b.json", "integration/reproducibility/bh01-phase10-clean-rebuild-comparison.json"], "Two cache-empty archive executions produce exact runtime, AVM, profile, and canonical report identities after the canonical fixture-root correction.", "Active clean-build proof passes on one physical Linux host.", True),
        "BX-BH01-PROOF-DOM-UPDATE": ("closed-passed", "active-linux", [PHASE.format(5)] + common_behavior, "Local, nested, form, timer, and command outcomes produce bounded validated DOM operations with negative operations rejected before partial mutation.", "Supports renderer contract exploration without making the DOM protocol public.", True),
        "BX-BH01-PROOF-FORM-EVENT": ("closed-passed", "active-linux", [PHASE.format(5), "integration/fixtures/raw-evidence/bh01-phase6-trust-and-isolation.json"] + common_behavior, "Input, change, blur, rapid/composition-like, validation, disabled, read-only, and programmatic-update paths execute with canonical semantics.", "Supports event-normalization exploration; fixtures remain disposable.", True),
        "BX-BH01-PROOF-MOBILE-MEASUREMENT": ("closed-with-deferred-qualification", "deferred-bh22", ["integration/benchmarks/reports/bh01-phase9-deferred-qualification.json"], "No representative physical Android or iOS/iPadOS environment was available; mobile viability remains explicitly undecided.", "Not an active BH-02 blocker and not a pass; reactivates at BH-22.", False),
        "BX-BH01-PROOF-NESTED-STATE": ("closed-passed", "active-linux", [PHASE.format(5), "integration/fixtures/raw-evidence/bh01-phase7-resilience-security-resource.json"] + common_behavior, "Keyed child identity, parent state, replacement generation, failure recovery, and disposal preserve state boundaries in active runs.", "Supports neutral identity/lifecycle exploration without freezing fixture messages.", True),
        "BX-BH01-PROOF-RUNTIME-BOOT": ("closed-passed", "active-linux", [PHASE.format(3), PHASE.format(4)] + common_behavior, "The pinned Popcorn/AtomVM runtime boots the governed AVM and fails intentionally on prerequisite, network, and integrity negatives.", "Runtime viability passes for active Linux development only.", True),
        "BX-BH01-PROOF-TIMER-MESSAGE": ("closed-conditional", "active-linux", [PHASE.format(3), PHASE.format(5), "integration/benchmarks/reports/bh01-phase9-budget-evaluation.json"] + common_behavior, "Delivery, cancellation generation checks, duplicate drain, and cleanup pass functionally; Firefox development timer-event p95 exceeds the active target.", "Functional proof passes with a measured Firefox optimization/retest condition.", True),
    }
    proofs = []
    for item in source["proof_obligations"]:
        state, scope, evidence, outcome, effect, executed = proof_details[item["id"]]
        value = closure(item["id"], item["owner"], state, evidence, outcome, effect)
        value.update({"scope": scope, "stop_on_failure": item["stop_on_failure"], "budget_refs": item["budget_refs"], "acceptance_refs": item["acceptance_refs"], "positive_and_negative_executed": executed})
        proofs.append(value)

    risk_details = {
        "BX-BH01-RISK-AUTHENTICATED-COMMAND": ("accepted-residual", "low", "critical", [PHASE.format(6), PHASE.format(7)], "Keep browser state untrusted and retain server-side authentication, authorization, version, idempotency, rate, and audit checks.", "Production identity, persistence, distributed limits, TLS, audit sinks, and penetration testing are not established.", "Before production authority or authentication design", "Does not block BH-02 neutral effect contracts."),
        "BX-BH01-RISK-BROWSER-PREREQUISITES": ("accepted-residual", "medium", "high", [PHASE.format(4), "integration/benchmarks/reports/bh01-phase9-deferred-qualification.json"], "Retain manifest/prerequisite fail-closed behavior and carry unavailable products, platforms, and manual pairings to BH-22.", "Only exact Linux Chrome and a Firefox development binary have current evidence; all remain unsupported.", "Browser pin, prerequisite, deployment, or BH-22 change", "Does not block active abstraction work; blocks support claims."),
        "BX-BH01-RISK-DEPENDENCY-ACCESS": ("accepted-residual", "low", "high", [PHASE.format(2), "integration/reproducibility/raw-evidence/bh01-phase10-clean-a-authoritative.json"], "Keep locks, checksums, immutable images, provenance, license records, and explicit acquisition-only network stages.", "Upstream availability and registries remain external dependencies despite retained identities.", "Any dependency source, checksum, license, or registry change", "Does not block BH-02 under current exact pins."),
        "BX-BH01-RISK-MOBILE-PERFORMANCE": ("deferred-bh22", "unknown-deferred", "unknown-deferred", ["integration/benchmarks/reports/bh01-phase9-deferred-qualification.json"], "Execute representative physical-device startup, memory, lifecycle, thermal, power, input, and accessibility qualification at BH-22.", "Mobile viability is undecided; desktop or emulated evidence cannot reduce this uncertainty.", "Representative Android or iOS/iPadOS environment becomes available or BH-22 starts", "Neither pass nor active blocker; prohibits mobile and release claims."),
        "BX-BH01-RISK-PRIVATE-API-COUPLING": ("accepted-residual", "high", "high", [PHASE.format(2), PHASE.format(6), "profiles/browser_phoenix/toolchain/private-api-inventory.json"], "Keep private APIs exact-pinned inside the optional LiveView adapter and fail to standalone DOM on mismatch.", "No adjacent package range is qualified; upgrades can disable the optional adapter.", "Phoenix, LiveView, LocalLiveView, or adapter pin changes", "Does not block BH-02 if portable semantics remain independent."),
        "BX-BH01-RISK-RUNTIME-SEMANTICS": ("accepted-residual", "medium", "high", [PHASE.format(3), PHASE.format(5), PHASE.format(7)], "Preserve generation checks, closed bridges, bounded resources, duplicate drain, recovery, and repeat all proofs after runtime changes.", "AtomVM timer cancellation reports false and scale/fairness/long-soak coverage remains experimental.", "Runtime/Popcorn/OTP change or semantic-contract design", "Supports BH-02 with explicit lifecycle constraints."),
        "BX-BH01-RISK-TOOLCHAIN-REPRODUCIBILITY": ("accepted-residual", "low", "critical", ["integration/reproducibility/bh01-phase10-clean-rebuild-comparison.json", "integration/reproducibility/raw-evidence/bh01-phase10-clean-a-attempt-1.json"], "Use immutable tools and the canonical fixture container root; fail on hidden caches, mutable inputs, or undeclared tools.", "Both authoritative runs used one physical Linux host, and Elixir macro literals remain path-sensitive outside the canonical root.", "Tool identity, build path contract, source revision, or second-machine availability changes", "Active proof passes; cross-machine claims remain excluded."),
        "BX-BH01-RISK-WASM-ARTIFACT-ACCOUNTING": ("accepted-residual", "high", "high", [PHASE.format(3), "integration/benchmarks/reports/bh01-phase9-artifact-economics.json"], "Retain full manifests and run the application AVM reachability plus actual Brotli-serving experiments before release qualification.", "The unpruned application AVM dominates payload and fails decoded and compressed application budgets.", "Before release/profile hardening or any runtime/bundle composition change", "Does not block BH-02 semantics; conditions packaging and release work."),
    }
    risks = []
    for item in source["risks"]:
        state, likelihood, impact, evidence, mitigation, residual, trigger, effect = risk_details[item["id"]]
        risks.append({"id": item["id"], "owner": item["owner"], "state": state, "likelihood": likelihood, "impact": impact, "evidence": evidence, "mitigation": mitigation, "residual_risk": residual, "review_trigger": trigger, "decision_effect": effect})

    stop_details = {
        "BX-BH01-STOP-REPRODUCIBILITY": ("not-triggered", ["integration/reproducibility/bh01-phase10-clean-rebuild-comparison.json"], "Independent clean contexts produce equivalent explainable artifacts and reports under the corrected canonical build-root contract."),
        "BX-BH01-STOP-RUNTIME-SEMANTICS": ("not-triggered", [PHASE.format(3), PHASE.format(5), PHASE.format(7)], "Required active semantics execute without moving DOM, browser, Phoenix, or authority concerns into host-neutral contracts."),
        "BX-BH01-STOP-ADAPTER-ISOLATION": ("not-triggered", [PHASE.format(6)], "Phoenix authority and exact-pinned private LiveView integration remain isolated from standalone DOM, Plug, headless, and future portable packages."),
        "BX-BH01-STOP-PRODUCT-VIABILITY": ("conditionally-not-triggered", ["integration/benchmarks/reports/bh01-phase9-stop-decision.json", "integration/benchmarks/reports/bh01-phase9-mitigation-assessment.json"], "Active payload and Firefox timer failures have bounded, owned experiments; mobile and unavailable product qualification remain undecided and deferred."),
        "BX-BH01-STOP-ARTIFACT-ACCOUNTING": ("conditionally-not-triggered", ["integration/benchmarks/reports/bh01-phase9-artifact-economics.json", "integration/reproducibility/bh01-phase10-clean-rebuild-comparison.json"], "Artifact origin, integrity, licenses, size, and identity are explained, while payload failures continue to prohibit support and release claims."),
    }
    stops = [{"id": item["id"], "owner": item["owner"], "state": stop_details[item["id"]][0], "evidence": stop_details[item["id"]][1], "outcome": stop_details[item["id"]][2]} for item in source["stop_conditions"]]

    findings: list[dict[str, Any]] = []
    phase_raw = {
        4: "integration/fixtures/raw-evidence/bh01-phase4-browser.json",
        5: "integration/fixtures/raw-evidence/bh01-phase5-local-browser.json",
        6: "integration/fixtures/raw-evidence/bh01-phase6-trust-and-isolation.json",
        7: "integration/fixtures/raw-evidence/bh01-phase7-resilience-security-resource.json",
    }
    special_dispositions = {(4, 4): "accepted-bounded-condition", (6, 1): "resolved-and-retested", (6, 5): "accepted-bounded-condition", (7, 5): "accepted-residual-limitation"}
    for phase, path in phase_raw.items():
        for index, text in enumerate(load(path)["findings"], 1):
            disposition = special_dispositions.get((phase, index), "closed-active-pass")
            findings.append({"id": f"BX-BH01-PHASE{phase}-FINDING-{index:02d}", "source": path, "finding": text, "disposition": disposition, "owner": "bh01-owner", "decision_effect": "Retained as active evidence and carried to review."})
    phase8_path = "integration/fixtures/browser_matrix/matrix-report.json"
    for item in load(phase8_path)["findings"]:
        disposition = {"BX-BH01-PHASE8-FINDING-REQUIRED-ENVIRONMENTS": "deferred-bh22", "BX-BH01-PHASE8-FINDING-MANUAL-ACCESSIBILITY": "deferred-bh22", "BX-BH01-PHASE8-FINDING-EXACT-PINS": "accepted-bounded-condition", "BX-BH01-PHASE8-FINDING-PROBES": "informational"}[item["id"]]
        findings.append({"id": item["id"], "source": phase8_path, "finding": item["result"], "disposition": disposition, "owner": item["owner"], "decision_effect": "Deferred items reactivate at BH-22; exact pins and probes grant no support range."})
    phase9_path = "integration/benchmarks/reports/bh01-phase9-stop-decision.json"
    for item in load(phase9_path)["active_failures"]:
        findings.append({"id": f"BX-BH01-PHASE9-FINDING-{item['budget_id']}", "source": phase9_path, "finding": item["finding"], "disposition": "accepted-bounded-condition", "owner": "quality-owner", "decision_effect": item["disposition"]})
    for attempt, path in ((1, "integration/benchmarks/reports/bh01-phase9-rerun-comparison-attempt-1.json"), (2, "integration/benchmarks/reports/bh01-phase9-rerun-comparison.json")):
        drift_count = sum(item["status"] == "drift" for item in load(path)["comparisons"])
        findings.append({"id": f"BX-BH01-PHASE9-FINDING-RERUN-{attempt}", "source": path, "finding": f"Representative rerun comparison {attempt} retained {drift_count} timing distributions outside development tolerance.", "disposition": "accepted-residual-limitation", "owner": "quality-owner", "decision_effect": "Prevents a strong cross-run performance-reproducibility claim and requires future controlled measurement."})
    for attempt in range(1, 4):
        path = f"integration/reproducibility/raw-evidence/bh01-phase10-clean-a-attempt-{attempt}.json"
        item = load(path)
        findings.append({"id": item["record_id"], "source": path, "finding": item["root_cause"], "disposition": "resolved-and-retested", "owner": "bh01-owner", "decision_effect": item["resolution"]["change"]})

    record = {
        "schema_version": "1.0.0", "record_id": "BX-BH01-PHASE10-LEDGER-CLOSURE-0.1",
        "status": "closed-with-bounded-conditions-and-deferrals", "source_revision": SOURCE_REVISION,
        "policy": {"active_environment": "Linux x86-64 with Chrome and Firefox development evidence", "deferred_milestone": "BH-22", "deferred_is_pass": False, "deferred_is_active_blocker": False},
        "counts": {"inputs": len(inputs), "proof_obligations": len(proofs), "risks": len(risks), "stop_conditions": len(stops), "findings": len(findings), "exceptions": 0},
        "inputs": inputs, "proof_obligations": proofs, "risks": risks, "stop_conditions": stops, "findings": findings, "exceptions": [],
        "decision_effect": "eligible-for-multidisciplinary-review-with-bounded-conditions", "support_status": "unsupported",
    }
    return record


def validate(record: dict[str, Any]) -> list[str]:
    errors = [error.message for error in Draft202012Validator(load(HERE / "ledger-closure.schema.json")).iter_errors(record)]
    source = load(MILESTONE_LEDGER)
    for field in ("inputs", "proof_obligations", "risks", "stop_conditions"):
        expected = {item["id"] for item in source[field]}
        actual = {item.get("id") for item in record.get(field, [])}
        if expected != actual:
            errors.append(f"{field} identity set differs from the BH-01 milestone ledger")
    source_owners = {item["id"]: item["owner"] for field in ("inputs", "proof_obligations", "risks", "stop_conditions") for item in source[field]}
    for field in ("inputs", "proof_obligations", "risks", "stop_conditions"):
        for item in record.get(field, []):
            if source_owners.get(item.get("id")) != item.get("owner"):
                errors.append(f"owner drift for {item.get('id')}")
            for path in item.get("evidence", []):
                if not (ROOT / path).is_file():
                    errors.append(f"missing evidence for {item.get('id')}: {path}")
    source_proofs = {item["id"]: item for item in source["proof_obligations"]}
    for item in record.get("proof_obligations", []):
        original = source_proofs.get(item.get("id"), {})
        if item.get("budget_refs") != original.get("budget_refs") or item.get("acceptance_refs") != original.get("acceptance_refs"):
            errors.append(f"proof requirement trace drift for {item.get('id')}")
        if item.get("scope") == "deferred-bh22" and item.get("positive_and_negative_executed") is not False:
            errors.append(f"deferred proof represented as executed: {item.get('id')}")
    for finding in record.get("findings", []):
        if not (ROOT / finding.get("source", "")).is_file():
            errors.append(f"missing finding source: {finding.get('source')}")
    if record.get("exceptions"):
        errors.append("Phase 10 closure permits no unreviewed exceptions")
    if any(item.get("state") == "triggered" for item in record.get("stop_conditions", [])):
        errors.append("an active stop condition is triggered")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    expected = build()
    if args.check:
        record = load(args.output)
        errors = validate(record)
        if record != expected:
            errors.append("closure ledger is stale relative to canonical source evidence")
    else:
        record = expected
        errors = validate(record)
        if not errors:
            args.output.write_text(json.dumps(record, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        return 1
    print(f"BH-01 Phase 10 ledgers: PASS ({record['counts']['inputs']} inputs; {record['counts']['proof_obligations']} proofs; {record['counts']['risks']} risks; {record['counts']['stop_conditions']} stops; {record['counts']['findings']} findings; 0 exceptions)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
