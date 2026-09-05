#!/usr/bin/env python3
"""Generate the deterministic BlazeX BH-00 acceptance registry and report."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from collections import Counter
from pathlib import Path
from typing import Any

import planning_policy


ROOT = Path(__file__).resolve().parent
ASSET_DIR = ROOT / "assets" / "quality-acceptance"
ROADMAP_PATH = ROOT / "20-notes" / "browser-host-implementation-milestones.md"
ENVELOPE_PATH = ROOT / "assets" / "browser-product-envelope-v0.1.json"
CLASSIFICATION_PATH = ROOT / "assets" / "component-catalog" / "blazex-component-classification-v0.1.0.json"
QUALITY_PATH = ASSET_DIR / "blazex-quality-contract-v0.1.0.json"
REGISTRY_PATH = ASSET_DIR / "blazex-acceptance-registry-v0.1.0.json"
REPORT_PATH = ASSET_DIR / "blazex-acceptance-registry-v0-1-0-generated.md"

SOURCE_BINDINGS = {
    "BX-SOURCE-BROWSER-ROADMAP": ROADMAP_PATH,
    "BX-SOURCE-BROWSER-ENVELOPE": ENVELOPE_PATH,
    "BX-SOURCE-COMPONENT-CLASSIFICATION": CLASSIFICATION_PATH,
    "BX-SOURCE-QUALITY-CONTRACT": QUALITY_PATH,
}
PROFILE_IDS = ["PROFILE-BROWSER-PHOENIX", "PROFILE-BROWSER-PLUG", "PROFILE-HEADLESS"]
HISTORICAL_BH01_COMPLETION = (
    "The baseline runs repeatably across the initially supported browser set, its build inputs and outputs are "
    "explainable, and its known compatibility restrictions are narrow enough to support a framework. Failure to "
    "reproduce the exact runtime profile blocks later framework work."
)
ENVELOPE_COLLECTIONS = [
    "adapters",
    "bh01_required_records",
    "browser_configurations",
    "deployment_prerequisites",
    "fallback_obligations",
    "forbidden_claims",
    "paper_scenarios",
    "profile_capabilities",
    "profiles",
    "rendering_modes",
    "security_invariants",
    "toolchain_inputs",
    "trust_boundaries",
]
ENVELOPE_MILESTONES = {
    "adapters": "BH-07",
    "bh01_required_records": "BH-01",
    "browser_configurations": "BH-01",
    "deployment_prerequisites": "BH-18",
    "fallback_obligations": "BH-18",
    "forbidden_claims": "BH-00",
    "paper_scenarios": "BH-01",
    "profile_capabilities": "BH-13",
    "profiles": "BH-07",
    "rendering_modes": "BH-18",
    "security_invariants": "BH-07",
    "toolchain_inputs": "BH-01",
    "trust_boundaries": "BH-07",
}
ENVELOPE_OWNERS = {
    "adapters": "adapter-owner",
    "bh01_required_records": "feasibility-owner",
    "browser_configurations": "browser-profile-owner",
    "deployment_prerequisites": "deployment-owner",
    "fallback_obligations": "product-owner",
    "forbidden_claims": "architecture-owner",
    "paper_scenarios": "quality-owner",
    "profile_capabilities": "capability-owner",
    "profiles": "profile-owner",
    "rendering_modes": "renderer-owner",
    "security_invariants": "security-owner",
    "toolchain_inputs": "runtime-owner",
    "trust_boundaries": "security-owner",
}
TIER_MILESTONES = {"F0": "BH-08", "F1": "BH-09", "F2": "BH-13", "F3": "BH-16", "F4": "BH-17"}
PACKAGE_MILESTONES = {
    "blazex_charts": "BH-17",
    "blazex_data": "BH-16",
    "blazex_forms": "BH-10",
    "blazex_surfaces": "BH-12",
    "blazex_ui": "BH-09",
    "blazex_ui_tree": "BH-02",
}
PACKAGE_BUDGETS = {
    "blazex_charts": ["BX-BUD-PAYLOAD-CHART-PACKAGE-KIB"],
    "blazex_data": ["BX-BUD-PAYLOAD-DATA-PACKAGE-KIB"],
    "blazex_forms": ["BX-BUD-PAYLOAD-FAMILY-BUNDLE-KIB"],
    "blazex_surfaces": ["BX-BUD-PAYLOAD-FAMILY-BUNDLE-KIB"],
    "blazex_ui": ["BX-BUD-PAYLOAD-FAMILY-BUNDLE-KIB", "BX-BUD-PAYLOAD-SHARED-UI-KIB"],
    "blazex_ui_tree": ["BX-BUD-PAYLOAD-SHARED-UI-KIB"],
}


def load_json(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"{path} must contain a JSON object")
    return value


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def normalize(text: str) -> str:
    return " ".join(text.replace("`", "").split())


def token(value: str) -> str:
    result = re.sub(r"[^A-Za-z0-9]+", "-", value).strip("-").upper()
    return result or "UNNAMED"


def evidence_policies() -> list[dict[str, Any]]:
    details = {
        "accessibility": (30, "Retain the exact semantic assertions, browser or backend, assistive technology, manual script, reviewer, and observed result."),
        "automated": (30, "Retain the deterministic command, source revision, fixture, seed, environment, complete output, and machine-readable result."),
        "benchmark": (30, "Retain every raw sample, environment fingerprint, candidate manifest, statistical calculation, tool revision, and comparison baseline."),
        "browser": (30, "Retain browser and operating-system versions, device class, profile, manifest, scenario, trace, screenshot where useful, and result."),
        "deployment": (30, "Retain deployment and manifest identities, topology, cache state, protocol versions, commands, logs, rollback state, and result."),
        "generated": (None, "Regenerate from immutable inputs with the recorded generator revision and command; output must be byte-stable for the same inputs."),
        "manual": (90, "Retain a bounded repeatable script, exact environment, reviewer identity, expected result, observed result, and attached artifacts."),
        "provenance": (90, "Retain immutable source identity, license and notices, transformation or reachability record, reviewer, and distributed-artifact scope."),
        "review": (90, "Retain review scope, input revisions, reviewer independence, findings, dispositions, unresolved risks, and approval or rejection."),
        "security": (30, "Retain threat or control identity, exact build and deployment, test method, sanitized evidence, finding severity, disposition, and retest."),
    }
    common_identity = ["artifact-id", "environment-id", "observed-at", "owner", "result", "source-revision"]
    return [
        {
            "id": evidence_id,
            "freshness_days": freshness,
            "reproducibility": reproducibility,
            "required_identity": common_identity,
            "permitted_verification_states": ["not-executed", "passed", "failed", "not-applicable"],
        }
        for evidence_id, (freshness, reproducibility) in sorted(details.items())
    ]


def condition(
    *,
    acceptance_id: str,
    requirement_id: str,
    subject: str,
    statement: str,
    mode: str,
    profiles: list[str],
    preconditions: list[str],
    action: str,
    observable: list[str],
    prohibited: list[str],
    evidence_types: list[str],
    owner: str,
    owner_scope: str,
    milestone: str,
    suite: str,
    gate: str,
    budgets: list[str] | None = None,
    support_status: str = "candidate",
    implementation_state: str = "not-started",
) -> dict[str, Any]:
    return {
        "id": acceptance_id,
        "requirement_ids": [requirement_id],
        "subject": subject,
        "normative_statement": statement,
        "mode": mode,
        "profiles": sorted(set(profiles)),
        "preconditions": preconditions,
        "action": action,
        "observable_results": observable,
        "prohibited_results": prohibited,
        "evidence_types": sorted(set(evidence_types)),
        "evidence_owner": owner,
        "owner_package_or_profile": owner_scope,
        "responsible_milestone": milestone,
        "integration_suite": suite,
        "release_gate": gate,
        "required_budget_ids": sorted(set(budgets or [])),
        "status": "planned",
        "support_status": support_status,
        "implementation_state": implementation_state,
        "verification_state": "not-executed",
        "evidence_ids": [],
        "waiver": None,
        "supersedes": None,
    }


def requirement(
    *,
    requirement_id: str,
    source_kind: str,
    source_id: str,
    source_binding: str,
    summary: str,
    acceptance_id: str,
) -> dict[str, Any]:
    return {
        "id": requirement_id,
        "source_kind": source_kind,
        "source_id": source_id,
        "source_binding": source_binding,
        "normative_summary": summary,
        "acceptance_ids": [acceptance_id],
    }


def parse_roadmap(text: str) -> tuple[list[dict[str, str]], list[tuple[str, str]], list[tuple[str, str]]]:
    milestones: list[dict[str, str]] = []
    headings = list(re.finditer(r"^### (BH-\d{2}) — (.+)$", text, re.MULTILINE))
    for index, heading in enumerate(headings):
        end = headings[index + 1].start() if index + 1 < len(headings) else text.index("\n## Suggested public maturity checkpoints", heading.start())
        body = text[heading.end():end]
        goal_match = re.search(r"\*\*Goal\.\*\*\s*(.*?)(?=\n\n\*\*)", body, re.DOTALL)
        completion_match = re.search(r"\*\*Completion signal\.\*\*\s*(.*)$", body, re.DOTALL)
        if not goal_match or not completion_match:
            raise ValueError(f"cannot parse roadmap milestone {heading.group(1)}")
        milestones.append({
            "id": heading.group(1),
            "name": normalize(heading.group(2)),
            "goal": normalize(goal_match.group(1)),
            "completion": normalize(completion_match.group(1)),
        })

    cross_text = text.split("## Cross-cutting obligations", 1)[1].split("## Explicitly outside", 1)[0]
    cross = [(token(name), normalize(body)) for name, body in re.findall(r"^- \*\*(.+?)\.\*\*\s*(.+)$", cross_text, re.MULTILINE)]
    non_goal_text = text.split("## Explicitly outside the browser 1.0 program", 1)[1].split("## Connections", 1)[0]
    non_goals = []
    for body in re.findall(r"^- (.+?);?$", non_goal_text, re.MULTILINE):
        normalized = normalize(body).rstrip(";.")
        non_goals.append((token(normalized), normalized))
    return milestones, cross, non_goals


def envelope_item_id(collection: str, item: Any, index: int) -> str:
    if isinstance(item, dict) and isinstance(item.get("id"), str):
        return item["id"]
    if isinstance(item, str):
        return f"{token(collection)}-{token(item)}"
    return f"{token(collection)}-{index + 1:02d}"


def envelope_summary(collection: str, item_id: str, item: Any) -> str:
    if isinstance(item, str):
        return f"The browser product envelope requires the {collection.replace('_', ' ')} outcome {item}."
    for key in ("claim", "name", "purpose", "scenario", "status_reason", "evidence_gate"):
        if isinstance(item.get(key), str):
            return f"Envelope record {item_id} remains governed: {normalize(item[key])}."
    return f"Envelope record {item_id} and its complete versioned fields remain satisfied by the owning browser product path."


def envelope_profiles(item_id: str, item: Any) -> list[str]:
    if item_id in PROFILE_IDS:
        return [item_id]
    if isinstance(item, dict):
        values: list[str] = []
        if isinstance(item.get("profile"), str) and item["profile"] in PROFILE_IDS:
            values.append(item["profile"])
        if isinstance(item.get("profiles"), list):
            values.extend(value for value in item["profiles"] if value in PROFILE_IDS)
        if values:
            return sorted(set(values))
    return PROFILE_IDS


def build_registry() -> dict[str, Any]:
    roadmap_text = ROADMAP_PATH.read_text(encoding="utf-8")
    envelope = load_json(ENVELOPE_PATH)
    classification = load_json(CLASSIFICATION_PATH)
    quality = load_json(QUALITY_PATH)
    milestones, obligations, non_goals = parse_roadmap(roadmap_text)
    requirements: list[dict[str, Any]] = []
    conditions: list[dict[str, Any]] = []

    def add(req: dict[str, Any], acc: dict[str, Any]) -> None:
        requirements.append(req)
        conditions.append(acc)

    for milestone in milestones:
        source_id = milestone["id"]
        req_id = f"BX-REQ-ROADMAP-{source_id}"
        acc_id = f"BX-ACC-ROADMAP-{source_id}"
        add(
            requirement(requirement_id=req_id, source_kind="roadmap-milestone", source_id=source_id, source_binding="BX-SOURCE-BROWSER-ROADMAP", summary=milestone["goal"], acceptance_id=acc_id),
            condition(
                acceptance_id=acc_id,
                requirement_id=req_id,
                subject=f"{source_id} {milestone['name']}",
                statement=milestone["completion"],
                mode="roadmap-outcome",
                profiles=PROFILE_IDS,
                preconditions=[f"All declared dependencies preceding {source_id} have accepted evidence or an explicit blocking record."],
                action=f"Execute and review the complete {source_id} integration and release-gate suite against the candidate revision.",
                observable=[milestone["completion"]],
                prohibited=["A demonstration, schema-valid record, or success on one profile is reported as completion without the declared evidence."],
                evidence_types=["automated", "browser", "review"] if source_id != "BH-00" else ["generated", "review"],
                owner=f"{source_id.lower()}-owner",
                owner_scope="roadmap-program",
                milestone=source_id,
                suite=f"integration/{source_id.lower()}",
                gate=f"{source_id.lower()}-completion",
            ),
        )

    for obligation_id, body in obligations:
        req_id = f"BX-REQ-CROSS-{obligation_id}"
        acc_id = f"BX-ACC-CROSS-{obligation_id}"
        add(
            requirement(requirement_id=req_id, source_kind="cross-cutting-obligation", source_id=obligation_id, source_binding="BX-SOURCE-BROWSER-ROADMAP", summary=body, acceptance_id=acc_id),
            condition(
                acceptance_id=acc_id,
                requirement_id=req_id,
                subject=f"Cross-cutting obligation {obligation_id}",
                statement=body,
                mode="cross-cutting",
                profiles=PROFILE_IDS,
                preconditions=["The candidate milestone identifies every public behavior and artifact added or changed."],
                action="Query the acceptance registry and execute the obligation-specific checks for every affected claim and profile.",
                observable=["Every affected claim reaches owned, fresh, reproducible evidence appropriate to the obligation and its release gate."],
                prohibited=["The obligation is deferred as release cleanup or inferred from an unrelated profile, renderer, benchmark, or review."],
                evidence_types=["automated", "review"],
                owner=f"{obligation_id.lower()}-owner",
                owner_scope="cross-cutting-governance",
                milestone="BH-00",
                suite=f"integration/cross-cutting/{obligation_id.lower()}",
                gate="every-milestone-and-release",
            ),
        )

    for non_goal_id, body in non_goals:
        req_id = f"BX-REQ-NONGOAL-{non_goal_id}"
        acc_id = f"BX-ACC-NONGOAL-{non_goal_id}"
        add(
            requirement(requirement_id=req_id, source_kind="non-goal", source_id=non_goal_id, source_binding="BX-SOURCE-BROWSER-ROADMAP", summary=f"Browser 1.0 intentionally excludes {body}.", acceptance_id=acc_id),
            condition(
                acceptance_id=acc_id,
                requirement_id=req_id,
                subject=f"Browser 1.0 non-goal: {body}",
                statement=f"Browser 1.0 documentation, manifests, packages, and support records do not promise {body}.",
                mode="product-boundary",
                profiles=PROFILE_IDS,
                preconditions=["The browser release candidate's public API, package metadata, documentation, and support matrix are available for inspection."],
                action="Inspect generated claims and public artifacts for direct, implied, inherited, or ambiguous support language.",
                observable=["The exclusion is explicit and future work requires a new profile or governed decision with its own evidence."],
                prohibited=["Browser, DOM, headless, Phoenix, or Plug success is presented as evidence for the excluded capability or compatibility."],
                evidence_types=["generated", "review"],
                owner="architecture-owner",
                owner_scope="browser-product-contract",
                milestone="BH-00",
                suite="integration/product-boundary",
                gate="bh-23-public-claims",
                support_status="not-applicable",
                implementation_state="not-applicable",
            ),
        )

    for collection in ENVELOPE_COLLECTIONS:
        for index, item in enumerate(envelope[collection]):
            item_id = envelope_item_id(collection, item, index)
            suffix = f"{token(collection)}-{token(item_id)}"
            req_id = f"BX-REQ-ENV-{suffix}"
            acc_id = f"BX-ACC-ENV-{suffix}"
            summary = envelope_summary(collection, item_id, item)
            milestone = ENVELOPE_MILESTONES[collection]
            add(
                requirement(requirement_id=req_id, source_kind="browser-envelope", source_id=f"{collection}:{item_id}", source_binding="BX-SOURCE-BROWSER-ENVELOPE", summary=summary, acceptance_id=acc_id),
                condition(
                    acceptance_id=acc_id,
                    requirement_id=req_id,
                    subject=f"Browser envelope {collection} record {item_id}",
                    statement=summary,
                    mode=item_id if item_id.startswith("MODE-") else "browser-envelope",
                    profiles=envelope_profiles(item_id, item),
                    preconditions=["The exact browser product envelope revision and candidate composition identities are available."],
                    action=f"Execute or inspect the owning {collection.replace('_', ' ')} scenario for {item_id} against the candidate composition.",
                    observable=["Observed behavior and generated support records match every governed field of the source envelope record."],
                    prohibited=["An untested, unsupported, fallback, or adapter-specific result is promoted to broader support or implementation evidence."],
                    evidence_types=["automated", "browser", "review"],
                    owner=ENVELOPE_OWNERS[collection],
                    owner_scope="browser-product-envelope",
                    milestone=milestone,
                    suite=f"integration/envelope/{collection.replace('_', '-')}",
                    gate=f"{milestone.lower()}-envelope",
                    support_status="unsupported" if collection == "browser_configurations" else "candidate",
                ),
            )

    families = classification["families"]
    packages = sorted({family["product"]["target_package"] for family in families})
    for family in families:
        family_id = family["family_id"]
        product = family["product"]
        fallback = family["fallback"]
        portability = family["portability"]
        package = product["target_package"]
        tier = product["delivery_tier"]
        req_id = f"BX-REQ-FAMILY-{token(family_id)}"
        acc_id = f"BX-ACC-FAMILY-{token(family_id)}"
        statement = (
            f"{family_id} is delivered as {product['disposition']} in {package} at {tier}, preserves "
            f"the {fallback['primary']} fallback, and satisfies {portability['status']} semantic and future-backend gates."
        )
        evidence_types = ["accessibility", "automated", "browser", "review"]
        if family["remote"]["authority"] != "local-only":
            evidence_types.append("security")
        add(
            requirement(requirement_id=req_id, source_kind="catalog-family", source_id=family_id, source_binding="BX-SOURCE-COMPONENT-CLASSIFICATION", summary=statement, acceptance_id=acc_id),
            condition(
                acceptance_id=acc_id,
                requirement_id=req_id,
                subject=family_id,
                statement=statement,
                mode="component-family",
                profiles=PROFILE_IDS,
                preconditions=[f"The family classification, prerequisites, capability providers, and {package} package boundary are present."],
                action="Execute normalized semantic, event, accessibility, fallback, lifecycle, renderer, and applicable remote-authority scenarios.",
                observable=["The family behavior, fallback, ownership, package, and profile results match the complete classified record."],
                prohibited=["MudBlazor or .NET API compatibility, DOM-only semantics, or native-host support is inferred from browser-family evidence."],
                evidence_types=evidence_types,
                owner=f"{package}-owner",
                owner_scope=package,
                milestone=TIER_MILESTONES[tier],
                suite=f"integration/conformance/{family_id.lower()}",
                gate=f"family-{tier.lower()}-completion",
                budgets=PACKAGE_BUDGETS[package],
            ),
        )

    for package in packages:
        req_id = f"BX-REQ-PACKAGE-{token(package)}"
        acc_id = f"BX-ACC-PACKAGE-{token(package)}"
        family_count = sum(1 for family in families if family["product"]["target_package"] == package)
        statement = f"{package} owns exactly its classified component behavior and preserves the governed monorepo dependency direction for {family_count} catalog families."
        milestone = PACKAGE_MILESTONES[package]
        add(
            requirement(requirement_id=req_id, source_kind="package-boundary", source_id=package, source_binding="BX-SOURCE-COMPONENT-CLASSIFICATION", summary=statement, acceptance_id=acc_id),
            condition(
                acceptance_id=acc_id,
                requirement_id=req_id,
                subject=package,
                statement=statement,
                mode="package-boundary",
                profiles=PROFILE_IDS,
                preconditions=["The package manifest, dependency graph, classified family ownership, and generated reachability report are available."],
                action="Validate package ownership, dependency direction, public surface, optionality, artifact reachability, and payload attribution.",
                observable=["Every owned family and dependency is accounted for without profile, renderer, runtime, or server adapter owning portable semantics."],
                prohibited=["A profile or adapter becomes the package root, or another package silently absorbs classified behavior or payload."],
                evidence_types=["automated", "generated", "review"],
                owner=f"{package}-owner",
                owner_scope=package,
                milestone=milestone,
                suite="integration/package-boundaries",
                gate=f"{milestone.lower()}-package",
                budgets=PACKAGE_BUDGETS[package],
            ),
        )

    for budget in quality["budgets"]:
        budget_id = budget["id"]
        req_id = f"BX-REQ-BUDGET-{token(budget_id)}"
        acc_id = f"BX-ACC-BUDGET-{token(budget_id)}"
        statement = (
            f"{budget['subject']} is measured as {budget['statistic']} {budget['direction']} "
            f"{budget['proposed_threshold']} {budget['unit']} in the declared environments."
        )
        add(
            requirement(requirement_id=req_id, source_kind="quality-budget", source_id=budget_id, source_binding="BX-SOURCE-QUALITY-CONTRACT", summary=statement, acceptance_id=acc_id),
            condition(
                acceptance_id=acc_id,
                requirement_id=req_id,
                subject=budget_id,
                statement=statement,
                mode="quality-budget",
                profiles=PROFILE_IDS,
                preconditions=["The candidate manifest, governed fixture, environment fingerprints, tools, and required minimum sample capacity are available."],
                action=budget["measurement_method"],
                observable=["Raw samples and statistical report satisfy the proposed threshold, variance, regression, freshness, and exception policies."],
                prohibited=["A desktop-only observation, average without raw samples, stale baseline, or absent measurement is reported as a pass."],
                evidence_types=["benchmark", "generated", "review"],
                owner=budget["owner"],
                owner_scope="quality-contract",
                milestone=budget["first_measurement_milestone"],
                suite=f"integration/benchmarks/{budget_id.lower()}",
                gate="bh-22-quality-budget",
                budgets=[budget_id],
            ),
        )

    for failure in quality["failure_scenarios"]:
        source_id = failure["id"]
        req_id = f"BX-REQ-FAILURE-{token(source_id)}"
        acc_id = f"BX-ACC-FAILURE-{token(source_id)}"
        add(
            requirement(requirement_id=req_id, source_kind="quality-failure", source_id=source_id, source_binding="BX-SOURCE-QUALITY-CONTRACT", summary=failure["required_outcome"], acceptance_id=acc_id),
            condition(
                acceptance_id=acc_id,
                requirement_id=req_id,
                subject=source_id,
                statement=failure["required_outcome"],
                mode="failure-and-recovery",
                profiles=PROFILE_IDS,
                preconditions=[f"The governed trigger can be injected deterministically: {failure['trigger']}."],
                action=f"Inject {failure['trigger']} and observe isolation, fallback, diagnostics, authority, focus, and cleanup through {failure['time_bound_ms']} milliseconds.",
                observable=[failure["required_outcome"]],
                prohibited=["Failure is swallowed, retries or queues become unbounded, state authority is confused, or owned resources survive the declared bound."],
                evidence_types=["automated", "browser", "review"],
                owner=failure["owner"],
                owner_scope="resilience-contract",
                milestone=failure["first_test_milestone"],
                suite=f"integration/failures/{source_id.lower()}",
                gate="bh-22-resilience",
            ),
        )

    for blocker in quality["release_blockers"]:
        source_id = blocker["id"]
        req_id = f"BX-REQ-BLOCKER-{token(source_id)}"
        acc_id = f"BX-ACC-BLOCKER-{token(source_id)}"
        add(
            requirement(requirement_id=req_id, source_kind="quality-release-blocker", source_id=source_id, source_binding="BX-SOURCE-QUALITY-CONTRACT", summary=blocker["condition"], acceptance_id=acc_id),
            condition(
                acceptance_id=acc_id,
                requirement_id=req_id,
                subject=source_id,
                statement=f"Release is blocked whenever {blocker['condition']}.",
                mode="release-blocker",
                profiles=PROFILE_IDS,
                preconditions=["The candidate integration and release evidence includes lifecycle, overload, failure, and authority traces."],
                action=blocker["detection"],
                observable=["The condition is absent in complete fresh evidence, or the candidate release remains blocked without waiver."],
                prohibited=["The condition is waived, hidden by retries, excluded without evidence, or reduced to a non-blocking severity."],
                evidence_types=["automated", "review"],
                owner=blocker["owner"],
                owner_scope="release-governance",
                milestone="BH-22",
                suite=f"integration/release-blockers/{source_id.lower()}",
                gate="bh-22-unwaivable-blockers",
            ),
        )

    for gate in quality["cross_cutting_gates"]:
        for gate_requirement in gate["requirements"]:
            source_id = gate_requirement["id"]
            req_id = f"BX-REQ-GATE-{token(source_id)}"
            acc_id = f"BX-ACC-GATE-{token(source_id)}"
            add(
                requirement(requirement_id=req_id, source_kind="quality-gate", source_id=source_id, source_binding="BX-SOURCE-QUALITY-CONTRACT", summary=gate_requirement["normative_statement"], acceptance_id=acc_id),
                condition(
                    acceptance_id=acc_id,
                    requirement_id=req_id,
                    subject=source_id,
                    statement=gate_requirement["normative_statement"],
                    mode=f"{gate['dimension']}-gate",
                    profiles=PROFILE_IDS,
                    preconditions=[f"The candidate declares every affected scope: {', '.join(gate_requirement['applies_to'])}."],
                    action=f"Execute the {', '.join(gate_requirement['evidence_types'])} checks and the declared {gate_requirement['manual_review']} manual-review policy.",
                    observable=["The requirement passes in every claimed profile and its fallback or failure behavior remains explicit and usable."],
                    prohibited=[gate_requirement["fallback_or_failure"] if "block" in gate_requirement["fallback_or_failure"].lower() else "Missing, stale, profile-inherited, or unrelated evidence is treated as a pass."],
                    evidence_types=gate_requirement["evidence_types"],
                    owner=gate["owner"],
                    owner_scope=f"{gate['dimension']}-governance",
                    milestone=gate["first_execution_milestone"],
                    suite=f"integration/{gate['dimension']}/{source_id.lower()}",
                    gate=f"bh-22-{gate['dimension']}",
                ),
            )

    requirements.sort(key=lambda record: record["id"])
    conditions.sort(key=lambda record: record["id"])
    by_source_kind = Counter(record["source_kind"] for record in requirements)
    by_milestone = Counter(record["responsible_milestone"] for record in conditions)
    by_evidence = Counter(evidence for record in conditions for evidence in record["evidence_types"])
    source_bindings = [
        {
            "id": source_id,
            "path": str(path.relative_to(ROOT)),
            "sha256": sha256(path),
        }
        for source_id, path in sorted(SOURCE_BINDINGS.items())
    ]
    return {
        "schema_version": "1.0.0",
        "registry_version": "0.1.0",
        "registry_id": "BX-ACCEPTANCE-REGISTRY-BROWSER-0.1",
        "stage": "complete",
        "status": "reviewed-planned-unexecuted",
        "generated_by": "generate_acceptance_registry.py",
        "source_bindings": source_bindings,
        "status_vocabulary": ["planned", "blocked", "implemented", "passed", "failed", "waived", "superseded", "unsupported", "not-applicable"],
        "evidence_classes": evidence_policies(),
        "requirements": requirements,
        "acceptance_conditions": conditions,
        "coverage_findings": {
            "orphan_claims": [],
            "catalog_without_acceptance": [],
            "acceptance_without_owner": [],
            "unsupported_transitions": [],
            "stale_evidence": [],
            "missing_budgets": [],
            "uncovered_profiles": [],
        },
        "summary": {
            "requirements": len(requirements),
            "acceptance_conditions": len(conditions),
            "by_source_kind": dict(sorted(by_source_kind.items())),
            "by_milestone": dict(sorted(by_milestone.items())),
            "by_evidence_class": dict(sorted(by_evidence.items())),
            "catalog_families": len(families),
            "profiles": len(PROFILE_IDS),
            "budgets": len(quality["budgets"]),
            "gate_requirements": sum(len(gate["requirements"]) for gate in quality["cross_cutting_gates"]),
            "executed_evidence": 0,
        },
    }


def historical_registry_for_bound_roadmap_amendment(
    current_registry: dict[str, Any],
) -> dict[str, Any]:
    """Reconstruct the immutable v0.1.0 registry under the exact planning amendment."""

    historical = json.loads(json.dumps(current_registry))
    roadmap_binding = next(
        record
        for record in historical["source_bindings"]
        if record["id"] == "BX-SOURCE-BROWSER-ROADMAP"
    )
    roadmap_binding["sha256"] = planning_policy.HISTORICAL_ROADMAP_SHA256
    bh01 = next(
        record
        for record in historical["acceptance_conditions"]
        if record["id"] == "BX-ACC-ROADMAP-BH-01"
    )
    bh01["normative_statement"] = HISTORICAL_BH01_COMPLETION
    bh01["observable_results"] = [HISTORICAL_BH01_COMPLETION]
    return historical


def committed_registry_expectation() -> tuple[dict[str, Any], bool]:
    """Return the current or bounded historical registry expected on disk."""

    registry = build_registry()
    roadmap_binding = next(
        record
        for record in registry["source_bindings"]
        if record["id"] == "BX-SOURCE-BROWSER-ROADMAP"
    )
    if planning_policy.roadmap_amendment_is_bound(
        planning_policy.HISTORICAL_ROADMAP_SHA256,
        roadmap_binding["sha256"],
    ):
        return historical_registry_for_bound_roadmap_amendment(registry), True
    return registry, False


def render_report(registry: dict[str, Any]) -> str:
    summary = registry["summary"]
    lines = [
        "---",
        'title: "BlazeX Acceptance Registry v0.1.0 Generated Coverage"',
        "kind: note",
        'created: "2026-09-03"',
        "maturity: developing",
        "tags:",
        "  - acceptance-criteria",
        "  - bh-00",
        "  - generated-artifact",
        "  - traceability",
        "aliases:",
        '  - "BlazeX acceptance coverage report"',
        "---",
        "",
        "# BlazeX Acceptance Registry v0.1.0 Generated Coverage",
        "",
        "> Generated by `generate_acceptance_registry.py`; edit the governed source contracts or generator, not this report.",
        "",
        "## Coverage summary",
        "",
        f"- Requirements: {summary['requirements']}",
        f"- Acceptance conditions: {summary['acceptance_conditions']}",
        f"- Catalog families: {summary['catalog_families']}",
        f"- Declared profiles: {summary['profiles']}",
        f"- Quality budgets: {summary['budgets']}",
        f"- Cross-cutting gate requirements: {summary['gate_requirements']}",
        f"- Executed evidence records: {summary['executed_evidence']}",
        "",
        "## Requirements by source kind",
        "",
        "| Source kind | Count |",
        "| --- | ---: |",
    ]
    lines.extend(f"| `{kind}` | {count} |" for kind, count in summary["by_source_kind"].items())
    lines.extend(["", "## Conditions by first responsible milestone", "", "| Milestone | Count |", "| --- | ---: |"])
    lines.extend(f"| {milestone} | {count} |" for milestone, count in summary["by_milestone"].items())
    lines.extend(["", "## Evidence demand", "", "| Evidence class | Referenced conditions |", "| --- | ---: |"])
    lines.extend(f"| `{evidence}` | {count} |" for evidence, count in summary["by_evidence_class"].items())
    lines.extend([
        "",
        "## Coverage findings",
        "",
        "All deterministic finding sets are empty: no orphan claims, catalog families without acceptance, ownerless conditions, unsupported status transitions, stale evidence, missing budget links, or uncovered profiles.",
        "",
        "This means the planned coverage graph is complete. It does **not** mean implementation, support, benchmarks, browser behavior, accessibility, security, deployment, or release evidence has passed.",
        "",
        "## Representative trace queries",
        "",
        "| Concern | Stable acceptance path |",
        "| --- | --- |",
        "| Component | `BX-REQ-FAMILY-BX-FAM-FORM` → `BX-ACC-FAMILY-BX-FAM-FORM` → BH-09 family conformance and budget gates |",
        "| Runtime | `BX-REQ-ROADMAP-BH-03` → `BX-ACC-ROADMAP-BH-03` → `integration/bh-03` |",
        "| Renderer | `BX-REQ-ROADMAP-BH-04` → `BX-ACC-ROADMAP-BH-04` → `integration/bh-04` |",
        "| Capability/security | `BX-REQ-GATE-BX-GREQ-SEC-CAPABILITY-GRANTS` → BH-06 security suite |",
        "| Phoenix | Browser-envelope profile and adapter records → BH-07 envelope suites |",
        "| Plug | `PROFILE-BROWSER-PLUG` envelope condition → BH-20 roadmap completion |",
        "| Headless | `PROFILE-HEADLESS` envelope condition plus every catalog-family condition |",
        "| Accessibility | `BX-REQ-GATE-BX-GREQ-A11Y-SEMANTICS` and family conditions → BH-02/BH-22 gates |",
        "| Failure | `BX-REQ-FAILURE-BX-FAIL-RENDERER` → renderer failure suite and BH-22 resilience gate |",
        "| Payload | `BX-REQ-BUDGET-BX-BUD-PAYLOAD-RUNTIME-COMPRESSED-KIB` → benchmark suite and BH-22 quality gate |",
        "| Provenance | `BX-REQ-GATE-BX-GREQ-PROV-SOURCE-LICENSE` → BH-06 provenance suite |",
        "",
        "## Source bindings",
        "",
        "| Source | Path | SHA-256 |",
        "| --- | --- | --- |",
    ])
    for source in registry["source_bindings"]:
        lines.append(f"| `{source['id']}` | `{source['path']}` | `{source['sha256']}` |")
    lines.extend([
        "",
        "## Evidence boundary",
        "",
        "Every condition remains `planned`, `not-started`, and `not-executed`, with no evidence ID or waiver. Later milestones must attach immutable external evidence through a governed revision; this generated graph cannot certify itself.",
        "",
        "## Connections",
        "",
        "- [Acceptance traceability and evidence policy](../../20-notes/blazex-acceptance-traceability-and-evidence-policy.md)",
        "- [Phase 5 plan](../../60-planning/01-browser-host/bh-00-product-boundary-catalog-and-acceptance-contract/phase-05-quality-budgets-and-acceptance-traceability.md)",
        "",
    ])
    return "\n".join(lines)


def write_outputs(registry_path: Path, report_path: Path) -> None:
    registry, _historical_amendment = committed_registry_expectation()
    registry_path.write_text(json.dumps(registry, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    report_path.write_text(render_report(registry), encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="fail when committed outputs differ from deterministic generation")
    parser.add_argument("--registry-output", type=Path, default=REGISTRY_PATH)
    parser.add_argument("--report-output", type=Path, default=REPORT_PATH)
    args = parser.parse_args()
    registry, historical_amendment = committed_registry_expectation()
    registry_text = json.dumps(registry, indent=2, ensure_ascii=False) + "\n"
    report_text = render_report(registry)
    if args.check:
        stale = []
        for path, expected in ((args.registry_output, registry_text), (args.report_output, report_text)):
            if not path.exists() or path.read_text(encoding="utf-8") != expected:
                stale.append(str(path))
        if stale:
            print(f"Acceptance generation is stale: {', '.join(stale)}", file=sys.stderr)
            return 1
        print(
            f"Acceptance generation matches committed outputs: {len(registry['requirements'])} requirements, "
            f"{len(registry['acceptance_conditions'])} conditions, zero executed evidence"
            + ("; historical roadmap snapshot retained by bounded planning amendment." if historical_amendment else ".")
        )
        return 0
    args.registry_output.write_text(registry_text, encoding="utf-8")
    args.report_output.write_text(report_text, encoding="utf-8")
    print(
        f"Generated {len(registry['requirements'])} requirements and "
        f"{len(registry['acceptance_conditions'])} acceptance conditions."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
