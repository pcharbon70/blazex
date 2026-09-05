#!/usr/bin/env python3
"""Version and validate the BH-01 reproducible feasibility baseline."""

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
SCHEMA = RELEASE / "blazex-bh-01-feasibility-baseline.schema.json"
BASELINE = RELEASE / "blazex-bh-01-feasibility-baseline-v0.1.0.json"
SOURCE_REVISION = "d4335a128f6883a8c4685b5c073a15375ac40999"

VIEW_NAMES = (
    "blazex-bh-01-release-index-v0-1-0.md",
    "blazex-bh-01-compatibility-limitations-index-v0-1-0.md",
    "blazex-bh-01-artifact-index-v0-1-0.md",
    "blazex-bh-01-benchmark-index-v0-1-0.md",
    "blazex-bh-01-proof-index-v0-1-0.md",
    "blazex-bh-01-risk-index-v0-1-0.md",
    "blazex-bh-01-finding-index-v0-1-0.md",
    "blazex-bh-01-environment-index-v0-1-0.md",
)


def load(path: str | Path) -> dict[str, Any]:
    value = Path(path)
    return json.loads((value if value.is_absolute() else ROOT / value).read_text(encoding="utf-8"))


def digest(path: str | Path) -> str:
    value = Path(path)
    return hashlib.sha256((value if value.is_absolute() else ROOT / value).read_bytes()).hexdigest()


def binding(identifier: str, role: str, state: str, path: str) -> dict[str, str]:
    return {"id": identifier, "role": role, "state": state, "path": path, "sha256": digest(path)}


def count(items: list[dict[str, Any]], key: str) -> dict[str, int]:
    return dict(sorted(Counter(str(item[key]) for item in items).items()))


def build() -> dict[str, Any]:
    phase = "docs/research/assets/bh-01-baseline/blazex-bh-01-phase-{:02d}-completion-v0.1.0.json"
    specs = [
        ("MILESTONE-LEDGER", "governance-ledger", "historical-source", "docs/research/assets/bh-01-baseline/blazex-bh-01-milestone-ledger-v0.1.0.json"),
        *[(f"PHASE-{number:02d}", "phase-completion", "accepted-history", phase.format(number)) for number in range(1, 10)],
        ("CLOSURE", "closure-ledger", "canonical", "integration/reproducibility/bh01-phase10-ledger-closure.json"),
        ("REVIEW", "multidisciplinary-review", "canonical", "integration/reproducibility/bh01-phase10-feasibility-review.json"),
        ("CLEAN-A", "clean-rebuild", "canonical", "integration/reproducibility/raw-evidence/bh01-phase10-clean-a-authoritative.json"),
        ("CLEAN-B", "clean-rebuild", "canonical", "integration/reproducibility/raw-evidence/bh01-phase10-clean-b.json"),
        ("CLEAN-COMPARISON", "reproducibility-comparison", "canonical", "integration/reproducibility/bh01-phase10-clean-rebuild-comparison.json"),
        ("ENVIRONMENT-LOCK", "toolchain-lock", "exact-pin", "profiles/browser_phoenix/toolchain/environment.lock.json"),
        ("DEPENDENCY-INVENTORY", "dependency-lock", "exact-pin", "profiles/browser_phoenix/toolchain/unified-dependency-inventory.json"),
        ("PRIVATE-API", "private-api-inventory", "exact-pins-only", "profiles/browser_phoenix/toolchain/private-api-inventory.json"),
        ("RUNTIME-PROVENANCE", "runtime-provenance", "exact-pin", "profiles/browser_phoenix/toolchain/runtime-provenance.json"),
        ("RUNTIME-ARTIFACTS", "artifact-manifest", "canonical", "docs/research/assets/bh-01-baseline/blazex-bh-01-phase-03-artifact-manifest-v0.1.0.json"),
        ("PROFILE", "profile-manifest", "canonical", "profiles/browser_phoenix/priv/static/bh01/profile-assets-manifest.json"),
        ("BROWSER-MATRIX", "compatibility", "historical-with-deferrals", "integration/fixtures/browser_matrix/matrix-report.json"),
        ("PHASE9-SUMMARY", "benchmark-summary", "canonical", "integration/benchmarks/samples/bh01-phase9-linux-desktop-summary.json"),
        ("ARTIFACT-ECONOMICS", "artifact-economics", "conditional", "integration/benchmarks/reports/bh01-phase9-artifact-economics.json"),
        ("BUDGETS", "budget-evaluation", "conditional", "integration/benchmarks/reports/bh01-phase9-budget-evaluation.json"),
        ("STOP-DECISION", "stop-decision", "conditional-go", "integration/benchmarks/reports/bh01-phase9-stop-decision.json"),
        ("DEFERRALS", "deferred-qualification", "deferred-bh22", "integration/benchmarks/reports/bh01-phase9-deferred-qualification.json"),
        ("RERUN-ATTEMPT", "timing-reproducibility", "observed-drift", "integration/benchmarks/reports/bh01-phase9-rerun-comparison-attempt-1.json"),
        ("RERUN-FINAL", "timing-reproducibility", "observed-drift", "integration/benchmarks/reports/bh01-phase9-rerun-comparison.json"),
    ]
    bindings = [binding(f"BX-BH01-BASELINE-{identifier}", role, state, path) for identifier, role, state, path in specs]
    clean_a = load("integration/reproducibility/raw-evidence/bh01-phase10-clean-a-authoritative.json")
    economics = load("integration/benchmarks/reports/bh01-phase9-artifact-economics.json")
    budgets = load("integration/benchmarks/reports/bh01-phase9-budget-evaluation.json")
    deferrals = load("integration/benchmarks/reports/bh01-phase9-deferred-qualification.json")
    ledger = load("integration/reproducibility/bh01-phase10-ledger-closure.json")
    review = load("integration/reproducibility/bh01-phase10-feasibility-review.json")
    dependency_paths = (
        "profiles/browser_phoenix/toolchain/environment.lock.json",
        "profiles/browser_phoenix/toolchain/unified-dependency-inventory.json",
        "profiles/browser_phoenix/toolchain/private-api-inventory.json",
        "profiles/browser_phoenix/toolchain/runtime-provenance.json",
        "integration/fixtures/browser_host/mix.lock",
        "js/blazex_runtime/package-lock.json",
        "packages/blazex_runtime_popcorn/runtime/build-contract.json",
    )
    dependencies = [binding(f"BX-BH01-DEPENDENCY-{index:02d}", "dependency-input", "exact-pin", path) for index, path in enumerate(dependency_paths, 1)]
    scenarios = [{key: item[key] for key in ("browser", "scenario", "status", "support_status", "semantic_sha256")} for item in clean_a["browser_scenarios"]]
    profile = economics["profile"]
    return {
        "schema_version": "1.0.0", "baseline_id": "BX-BH01-FEASIBILITY-BASELINE-0.1.0", "baseline_version": "0.1.0",
        "status": "candidate-reproducible-proceed-with-bounded-conditions", "source_revision": SOURCE_REVISION,
        "source_bindings": bindings, "tools": clean_a["tools"], "dependency_inputs": dependencies,
        "artifact_identity": {**{key: clean_a["artifacts"][key] for key in ("runtime_manifest_sha256", "browser_bundle_manifest_sha256", "profile_manifest_sha256", "profile_file_count")}, "decoded_bytes": profile["decoded_bytes"], "brotli_bytes": profile["brotli_bytes"], "request_count": profile["request_count"], "source_maps": profile["source_maps"], "dominant_cost": economics["dominant_cost"]["finding"]},
        "environments": {
            "physical_host_scope": "one-linux-host-two-independent-clean-execution-contexts",
            "active": [{"id": "BX-BH01-ENV-LINUX-CHROME", "browser": "Chrome for Testing 152.0.7977.75", "status": "observed-unsupported"}, {"id": "BX-BH01-ENV-LINUX-FIREFOX", "browser": "Playwright Firefox 153 development build", "status": "observed-unsupported"}],
            "deferred": [{"id": item["id"], "environment": item["environment"], "owner": item["owner"], "reactivation": item["reactivation"], "status": "deferred"} for item in deferrals["obligations"]],
        },
        "browser_scenarios": scenarios,
        "observations": {"budget_status_counts": budgets["status_counts"], "proof_state_counts": count(ledger["proof_obligations"], "state"), "risk_state_counts": count(ledger["risks"], "state"), "stop_state_counts": count(ledger["stop_conditions"], "state"), "finding_disposition_counts": count(ledger["findings"], "disposition"), "exceptions": 0},
        "closure_inventory": {key: ledger[key] for key in ("inputs", "proof_obligations", "risks", "stop_conditions", "findings", "exceptions")},
        "review": {"record_id": review["record_id"], "sha256": digest("integration/reproducibility/bh01-phase10-feasibility-review.json"), "result": review["decision"]["result"], "lenses": [item["id"] for item in review["lenses"]], "condition_ids": [item["id"] for item in review["conditions"]], "bh02_authorized": False},
        "limitations": [
            "Both authoritative clean executions used one physical Linux x86-64 host.",
            "Chrome and the Firefox development binary are observed development environments and remain unsupported.",
            "The unpruned application AVM fails decoded and compressed application payload budgets.",
            "Firefox development timer-event p95 exceeds the active local-event target.",
            "Representative Chrome timing reruns retain scheduler-sensitive drift.",
            "Private LiveView and LocalLiveView compatibility is exact-pins-only with standalone DOM fallback.",
            "Popcorn requires unsafe-eval and production security controls are not implemented.",
            "Physical mobile, Safari, Windows, second-machine, and manual assistive-technology qualification is deferred to BH-22.",
            "Mobile viability, accessibility conformance, production deployment, native compatibility, and release readiness are not established.",
            "BH-01 fixtures and protocols are disposable evidence rather than stable BlazeX APIs."
        ],
        "generated_views": [f"docs/research/assets/bh-01-release/{name}" for name in VIEW_NAMES],
        "supersession": {
            "immutable": True, "supersedes": None, "next_version_must_name_this_baseline": True,
            "invalidation_triggers": ["source revision", "toolchain or build path", "dependency or private API", "runtime or OTP", "browser product or engine", "operating system or device", "scenario or normalization", "mitigation or profile composition", "quality threshold or measurement boundary"],
            "rules": [
                "Preserve this baseline and every favorable and unfavorable source record.",
                "Name this baseline in any superseding record and explain every changed binding.",
                "Invalidate and repeat each active proof affected by a trigger before promotion.",
                "Reactivate deferred evidence when its environment becomes available or BH-22 begins.",
                "Rollback means selecting a prior immutable baseline, never rewriting its contents.",
                "Amendments that change meaning require a new semantic baseline version."
            ],
        },
        "support_status": "unsupported", "prohibited_claims": review["prohibited_claims"],
    }


def render_views(record: dict[str, Any]) -> dict[str, str]:
    baseline_hash = hashlib.sha256((json.dumps(record, indent=2, sort_keys=True) + "\n").encode()).hexdigest()
    def header(title: str) -> str:
        return f"---\ntitle: \"{title}\"\nkind: map\ncreated: \"2026-09-05\"\nmaturity: stable\ntags:\n  - bh-01\n  - generated-index\n  - feasibility\n---\n\n# {title}\n\n> Generated from `{record['baseline_id']}` (`{baseline_hash}`). Edit canonical evidence, not this view.\n\n"
    release = header("BlazeX BH-01 Feasibility Baseline v0.1.0") + f"- Status: `{record['status']}`\n- Source revision: `{record['source_revision']}`\n- Support: `{record['support_status']}`\n- BH-02 authorized: `{str(record['review']['bh02_authorized']).lower()}`\n- Bound sources: {len(record['source_bindings'])}\n- Review lenses: {len(record['review']['lenses'])}\n- Conditions: {len(record['review']['condition_ids'])}\n\nThis baseline accepts a reproducible feasibility result with bounded conditions. It is not a browser or product release.\n"
    compatibility = header("BH-01 Compatibility and Limitations Index") + "## Active observed environments\n\n" + "\n".join(f"- `{item['id']}` — {item['browser']}: {item['status']}" for item in record["environments"]["active"]) + "\n\n## Limitations\n\n" + "\n".join(f"- {item}" for item in record["limitations"]) + "\n"
    artifacts = header("BH-01 Artifact Index") + "\n".join(f"- {key}: `{value}`" for key, value in record["artifact_identity"].items()) + "\n"
    benchmarks = header("BH-01 Benchmark Index") + "## Budget states\n\n" + "\n".join(f"- `{key}`: {value}" for key, value in record["observations"]["budget_status_counts"].items()) + f"\n\nProfile: {record['artifact_identity']['decoded_bytes']} decoded bytes, {record['artifact_identity']['brotli_bytes']} locally computed Brotli bytes, {record['artifact_identity']['request_count']} requests.\n"
    closure = record["closure_inventory"]
    proofs = header("BH-01 Proof Index") + "\n".join(f"- `{item['id']}` — **{item['state']}** ({item['scope']}): {item['outcome']}" for item in closure["proof_obligations"]) + "\n"
    risks = header("BH-01 Risk Index") + "\n".join(f"- `{item['id']}` — **{item['state']}**, {item['likelihood']}/{item['impact']}: {item['residual_risk']} Trigger: {item['review_trigger']}" for item in closure["risks"]) + "\n"
    findings = header("BH-01 Finding Index") + "\n".join(f"- `{item['id']}` — **{item['disposition']}**: {item['finding']}" for item in closure["findings"]) + "\n"
    environments = header("BH-01 Environment Index") + "## Active\n\n" + "\n".join(f"- `{item['id']}` — {item['browser']}: {item['status']}" for item in record["environments"]["active"]) + "\n\n## Deferred to BH-22\n\n" + "\n".join(f"- `{item['id']}` — {item['environment']}; owner: {item['owner']}; reactivation: {item['reactivation']}" for item in record["environments"]["deferred"]) + "\n"
    return dict(zip(VIEW_NAMES, (release, compatibility, artifacts, benchmarks, proofs, risks, findings, environments), strict=True))


def validate(record: dict[str, Any]) -> list[str]:
    errors = [error.message for error in Draft202012Validator(load(SCHEMA)).iter_errors(record)]
    for item in record.get("source_bindings", []) + record.get("dependency_inputs", []):
        path = ROOT / item.get("path", "")
        if not path.is_file() or item.get("sha256") != digest(path):
            errors.append(f"stale or missing binding: {item.get('id')}")
    expected_deferred = {item["id"] for item in load("integration/benchmarks/reports/bh01-phase9-deferred-qualification.json")["obligations"]}
    if {item.get("id") for item in record.get("environments", {}).get("deferred", [])} != expected_deferred:
        errors.append("deferred environment set is incomplete")
    expected_scenarios = {(item["browser"], item["scenario"], item["semantic_sha256"]) for item in load("integration/reproducibility/raw-evidence/bh01-phase10-clean-a-authoritative.json")["browser_scenarios"]}
    if {(item.get("browser"), item.get("scenario"), item.get("semantic_sha256")) for item in record.get("browser_scenarios", [])} != expected_scenarios:
        errors.append("active browser scenario identity drift")
    expected_views = {f"docs/research/assets/bh-01-release/{name}" for name in VIEW_NAMES}
    if set(record.get("generated_views", [])) != expected_views:
        errors.append("generated view inventory drift")
    triggers = {"source revision", "toolchain or build path", "dependency or private API", "runtime or OTP", "browser product or engine", "operating system or device", "scenario or normalization", "mitigation or profile composition", "quality threshold or measurement boundary"}
    if set(record.get("supersession", {}).get("invalidation_triggers", [])) != triggers:
        errors.append("invalidation trigger set is incomplete")
    if record.get("support_status") != "unsupported" or record.get("review", {}).get("bh02_authorized") is not False:
        errors.append("baseline over-promotes support or BH-02 authorization")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    expected = build()
    record = load(BASELINE) if args.check else expected
    errors = validate(record)
    if args.check and record != expected:
        errors.append("feasibility baseline is stale relative to canonical inputs")
    views = render_views(expected)
    if args.check:
        for name, text in views.items():
            path = RELEASE / name
            if not path.is_file() or path.read_text(encoding="utf-8") != text:
                errors.append(f"generated view is stale: {name}")
    elif not errors:
        BASELINE.write_text(json.dumps(record, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        for name, text in views.items():
            (RELEASE / name).write_text(text, encoding="utf-8")
    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        return 1
    print(f"BH-01 Phase 10 baseline: PASS ({len(record['source_bindings'])} bindings; {len(record['generated_views'])} views; {len(record['environments']['deferred'])} deferrals)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
