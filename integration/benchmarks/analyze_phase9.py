#!/usr/bin/env python3
"""Generate BH-01 Phase 9 cost attribution and mitigation reports."""

from __future__ import annotations

import argparse
import json
from collections import defaultdict
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker

from phase9_metrics import load_json, sha256


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]


def validate(path: Path, schema: str) -> dict[str, Any]:
    value = load_json(path)
    Draft202012Validator(load_json(HERE / schema), format_checker=FormatChecker()).validate(value)
    return value


def ref(path: Path) -> dict[str, str]:
    return {"path": path.resolve().relative_to(ROOT).as_posix(), "sha256": sha256(path)}


def percent(value: int, total: int) -> float:
    return round(value / total * 100, 3) if total else 0.0


def distributions(summary: dict[str, Any], metric_id: str) -> list[dict[str, Any]]:
    return [
        {
            "environment_id": item["environment_id"],
            "scenario": item["scenario"],
            "cache_state": item["cache_state"],
            "p95": item["statistics"]["p95"],
            "unit": item["unit"],
            "variance_percent": item["statistics"]["coefficient_of_variation_percent"],
        }
        for item in summary["measurements"]
        if item["metric_id"] == metric_id
    ]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--summary", type=Path, required=True)
    parser.add_argument("--artifacts", type=Path, required=True)
    parser.add_argument("--revision", required=True)
    parser.add_argument("--economics-output", type=Path, required=True)
    parser.add_argument("--mitigations-output", type=Path, required=True)
    parser.add_argument("--economics-reference-path", type=Path)
    args = parser.parse_args()
    if len(args.revision) != 40 or any(char not in "0123456789abcdef" for char in args.revision):
        raise SystemExit("--revision must be an exact lowercase commit")

    summary = validate(args.summary, "desktop-summary.schema.json")
    artifacts = validate(args.artifacts, "artifact-run.schema.json")
    totals = artifacts["totals"]["total"]
    owner_costs = [
        {
            "owner_class": owner,
            **cost,
            "decoded_percent": percent(cost["decoded_bytes"], totals["decoded_bytes"]),
            "brotli_percent": percent(cost["brotli_bytes"], totals["brotli_bytes"]),
        }
        for owner, cost in sorted(artifacts["totals"].items())
        if owner != "total"
    ]
    owner_costs.sort(key=lambda item: item["brotli_bytes"], reverse=True)
    cache = defaultdict(lambda: {"artifact_count": 0, "decoded_bytes": 0, "brotli_bytes": 0})
    for artifact in artifacts["artifacts"]:
        row = cache[artifact["cache_class"]]
        row["artifact_count"] += 1
        row["decoded_bytes"] += artifact["decoded_bytes"]
        row["brotli_bytes"] += artifact["brotli_bytes"]

    economics = {
        "schema_version": "1.0.0",
        "report_id": "BX-BH01-PHASE9-ARTIFACT-ECONOMICS-0.1",
        "status": "observed-with-limitations",
        "source_revision": args.revision,
        "evidence_revision": summary["source_revision"],
        "generated_from_captured_at": max(summary["generated_from_captured_at"], artifacts["captured_at"]),
        "inputs": [ref(args.summary), ref(args.artifacts)],
        "profile": {
            "manifest_sha256": artifacts["profile_manifest"]["sha256"],
            "artifact_count": len(artifacts["artifacts"]),
            "decoded_bytes": totals["decoded_bytes"],
            "brotli_bytes": totals["brotli_bytes"],
            "request_count": totals["request_count"],
            "source_maps": artifacts["source_maps"],
        },
        "owner_costs": owner_costs,
        "dominant_cost": {
            "owner_class": owner_costs[0]["owner_class"],
            "finding": f"The unpruned application AVM contributes {owner_costs[0]['decoded_percent']}% of decoded bytes and {owner_costs[0]['brotli_percent']}% of Brotli bytes; its reachability boundary includes runtime and library modules and must not be interpreted as authored application code alone.",
        },
        "cache_economics": [{"cache_class": name, **values} for name, values in sorted(cache.items())],
        "runtime_phase_attribution": [
            {"phase": "navigation-through-ready", "metric_id": "BX-BH01-METRIC-STARTUP-NAVIGATION-READY-MS", "attribution": "Fetch, loader, Wasm, AVM, fixture start, and root mount are combined; no unsupported sub-phase arithmetic is performed.", "distributions": distributions(summary, "BX-BH01-METRIC-STARTUP-NAVIGATION-READY-MS")},
            {"phase": "instantiate-through-application-ready", "metric_id": "BX-BH01-METRIC-STARTUP-INSTANTIATE-READY-MS", "attribution": "Lifecycle transition interval is broader than strict runtime compilation/instantiation and is retained as such.", "distributions": distributions(summary, "BX-BH01-METRIC-STARTUP-INSTANTIATE-READY-MS")},
            {"phase": "application-ready-through-root-ready", "metric_id": "BX-BH01-METRIC-STARTUP-ROOT-READY-MS", "attribution": "Fixture activation and first root observation on an already initialized lifecycle timeline.", "distributions": distributions(summary, "BX-BH01-METRIC-STARTUP-ROOT-READY-MS")},
            {"phase": "local-event-through-paint", "metric_id": "BX-BH01-METRIC-INTERACTION-LOCAL-EVENT-PAINT-MS", "attribution": "Bridge request, Elixir fixture update, normalized effect, DOM mutation, snapshot, and next animation frame.", "distributions": distributions(summary, "BX-BH01-METRIC-INTERACTION-LOCAL-EVENT-PAINT-MS")},
            {"phase": "renderer-effect-through-dom-commit", "metric_id": "BX-BH01-METRIC-INTERACTION-DOM-COMMIT-MS", "attribution": "Synchronous fixture DOM mutation only; this is narrower than a painted-frame budget.", "distributions": distributions(summary, "BX-BH01-METRIC-INTERACTION-DOM-COMMIT-MS")},
            {"phase": "server-command-roundtrip", "metric_id": "BX-BH01-METRIC-INTERACTION-SERVER-ROUNDTRIP-MS", "attribution": "Same-host transport, Phoenix validation/authorization/effect, result projection, DOM result, and next frame; server sub-phases are not individually clock-correlated.", "distributions": distributions(summary, "BX-BH01-METRIC-INTERACTION-SERVER-ROUNDTRIP-MS")},
        ],
        "limitations": [
            "Brotli quality-11 accounting is local; the Phoenix endpoint currently serves identity bytes and transfer savings require a separate serving change and before/after network evidence.",
            "The application AVM is unpruned, so application-owned and runtime/library byte ownership cannot yet be separated below the bundle boundary.",
            "Browser timings do not provide CPU profiles or a common client/server sub-phase clock.",
            "JavaScript heap excludes Wasm and complete browser/runtime memory; no energy or thermal evidence is available.",
        ],
    }
    args.economics_output.parent.mkdir(parents=True, exist_ok=True)
    args.economics_output.write_text(json.dumps(economics, indent=2) + "\n", encoding="utf-8")
    validate(args.economics_output, "artifact-economics.schema.json")

    mitigations = {
        "schema_version": "1.0.0",
        "report_id": "BX-BH01-PHASE9-MITIGATION-ASSESSMENT-0.1",
        "status": "reviewed-candidates-no-threshold-change",
        "source_revision": args.revision,
        "artifact_economics_ref": ref(args.economics_reference_path or args.economics_output),
        "threshold_changes": [],
        "candidates": [
            {
                "id": "BX-BH01-MITIGATION-APPLICATION-AVM-REACHABILITY-0.1",
                "status": "required-bounded-experiment",
                "priority": "highest",
                "owner": "build and runtime owners",
                "target": "application-bundle-unpruned",
                "baseline": {"decoded_bytes": artifacts["totals"]["application-bundle-unpruned"]["decoded_bytes"], "brotli_bytes": artifacts["totals"]["application-bundle-unpruned"]["brotli_bytes"]},
                "expected_effect": "Remove unreachable OTP, library, and fixture modules while preserving the exact BH-01 proof inventory.",
                "tradeoff": "Requires a trustworthy module-reachability model and can produce false-small bundles if dynamic calls are missed.",
                "affected_proofs": ["runtime semantics", "local behavior", "authenticated command", "failure recovery"],
                "browser_constraints": "Must remain compatible with AtomVM/Popcorn loading and the same manifest/integrity contract.",
                "repeat_requirement": "Produce separate before/after manifests and rerun Phases 3 through 9; no estimate receives budget credit.",
                "review_trigger": "Before any release claim and when the bundle builder gains reachability pruning."
            },
            {
                "id": "BX-BH01-MITIGATION-BROTLI-TRANSFER-0.1",
                "status": "required-serving-experiment",
                "priority": "high",
                "owner": "browser profile owner",
                "target": "first-load transfer",
                "baseline": {"identity_bytes": totals["decoded_bytes"], "locally_computed_brotli_bytes": totals["brotli_bytes"]},
                "expected_effect": "Serve precompressed content-addressed artifacts with correct negotiation, MIME, integrity, cache, and isolation headers.",
                "tradeoff": "Adds deployment variants and requires CDN/proxy validation; local compression alone proves no network saving.",
                "affected_proofs": ["deployment", "artifact integrity", "fallback", "startup"],
                "browser_constraints": "Must preserve streaming Wasm behavior and never serve compressed bytes without correct Content-Encoding and Vary semantics.",
                "repeat_requirement": "Capture before/after network bytes and startup distributions in Chrome and Firefox, then repeat external qualification when available.",
                "review_trigger": "Before production-profile deployment work."
            },
            {
                "id": "BX-BH01-MITIGATION-BUNDLE-PARTITION-0.1",
                "status": "investigate-after-reachability",
                "priority": "medium",
                "owner": "build owner",
                "target": "application AVM and future optional packages",
                "baseline": {"request_count": 1, "brotli_bytes": artifacts["totals"]["application-bundle-unpruned"]["brotli_bytes"]},
                "expected_effect": "Separate required startup modules from future optional families only where AtomVM loading semantics permit deterministic lazy reachability.",
                "tradeoff": "Additional requests and lifecycle states may worsen startup or reliability and must not hide mandatory fixture code.",
                "affected_proofs": ["startup", "offline", "recovery", "reproducibility"],
                "browser_constraints": "No service-worker dependency or browser-only component semantics may enter portable packages.",
                "repeat_requirement": "Measure one exact before/after candidate after pruning, including cold/warm/offline/failure paths.",
                "review_trigger": "After the application reachability experiment establishes a truthful ownership boundary."
            },
            {
                "id": "BX-BH01-MITIGATION-BRIDGE-BATCHING-0.1",
                "status": "not-indicated-by-current-evidence",
                "priority": "low",
                "owner": "browser host and DOM renderer owners",
                "target": "bridge and DOM interaction path",
                "baseline": {"evidence": "local interaction and DOM distributions in the desktop summary"},
                "expected_effect": "Potentially reduce bridge calls only if a future representative component trace demonstrates pressure.",
                "tradeoff": "Batching can increase latency, obscure ordering, and complicate cancellation and stale-generation semantics.",
                "affected_proofs": ["event ordering", "DOM atomicity", "cancellation", "generation isolation"],
                "browser_constraints": "Must preserve the bounded closed protocol and deterministic normalized trace.",
                "repeat_requirement": "No implementation until a traced bottleneck exists; then retain before/after trace and timing evidence.",
                "review_trigger": "A future representative trace exceeds its interaction budget with bridge overhead attribution."
            }
        ],
        "rejected_approaches": [
            {"approach": "Remove required difficult scenarios or artifacts from the measured profile", "reason": "This would invalidate the BH-01 proof inventory and create a false-small candidate."},
            {"approach": "Move Elixir component behavior or presentation decisions into JavaScript or the Phoenix server", "reason": "This violates the host-neutral semantic and authority boundaries."},
            {"approach": "Lower thresholds, change metric boundaries, or reduce sample counts after seeing results", "reason": "Quality-contract changes require separate versioned review and cannot retroactively manufacture a pass."},
            {"approach": "Treat desktop emulation or Linux engine builds as mobile, Safari, Windows, or accessibility qualification", "reason": "Those obligations are explicitly deferred and non-substitutable."}
        ],
        "recommendation": {
            "active_development": "continue conditionally while the unpruned application AVM remains an explicit feasibility risk",
            "required_follow_up": "Run reachability pruning and actual Brotli serving as separately reviewed before/after experiments before release qualification.",
            "support_effect": "none; these candidates and observations grant no browser, mobile, accessibility, production, or release support"
        }
    }
    args.mitigations_output.write_text(json.dumps(mitigations, indent=2) + "\n", encoding="utf-8")
    validate(args.mitigations_output, "mitigation-assessment.schema.json")
    print(f"BH-01 Phase 9 artifact analysis: OBSERVED ({len(owner_costs)} owner classes; {len(mitigations['candidates'])} candidates)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
