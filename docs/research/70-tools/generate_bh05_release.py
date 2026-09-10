"""Generate the BH-05 revision index, acceptance overlay, and BH-06 entry decision."""
import argparse
import hashlib
import json
import re
import sys
from pathlib import Path

from research_paths import REPO_ROOT

BASE = "docs/research/assets/bh-05-baseline/"
TARGETS = {
    "release": BASE + "bh-05-release-index-v0.1.0.json",
    "overlay": BASE + "bh-05-acceptance-overlay-v0.1.0.json",
    "entry": BASE + "bh-06-entry-decision-v0.1.0.json",
}
PACKAGES = ["blazex_core", "blazex_effects", "blazex_ui_tree"]
EVIDENCE = [
    BASE + "acceptance-authorization-v0.1.0.json",
    BASE + "acceptance-reconciliation-v0.1.0.json",
    "integration/bh-05/acceptance-counts-v0.1.0.json",
    "integration/bh-05/acceptance-counts-raw-v0.1.0.json",
    "integration/bh-05/acceptance-cleanup-v0.1.0.json",
    "integration/bh-05/acceptance-cleanup-raw-v0.1.0.json",
    "integration/bh-05/conformance-corpus-v0.1.0.json",
    "integration/bh-05/local-conformance-v0.1.0.json",
    "integration/bh-05/browser-conformance-v0.1.0.json",
]


def sha(path):
    return hashlib.sha256((REPO_ROOT / path).read_bytes()).hexdigest()


def source_inventory():
    rows = []
    for package in PACKAGES:
        for source in sorted((REPO_ROOT / "packages" / package / "lib").rglob("*.ex")):
            relative = source.relative_to(REPO_ROOT).as_posix()
            text = source.read_text()
            module = re.search(r"^defmodule\s+([^\s]+)\s+do", text, re.MULTILINE)
            rows.append({
                "module": module.group(1) if module else None, "path": relative,
                "sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
                "surface": "private" if re.search(r"@moduledoc\s+false", text) else "public-experimental",
            })
    return rows


def dependency_audit(inventory):
    forbidden = {name: [] for name in ["Phoenix", "Plug", ".NET"]}
    for row in inventory:
        text = (REPO_ROOT / row["path"]).read_text()
        for name in forbidden:
            if name in text:
                forbidden[name].append(row["path"])
    mix = {f"packages/{package}/mix.exs": sha(f"packages/{package}/mix.exs") for package in PACKAGES}
    return {"mix_files": mix, "forbidden_source_occurrences": forbidden,
            "dynamic_reachability": "unproven-deferred-to-bh06", "general_build": "unproven-deferred-to-bh06"}


def records():
    reconciliation = json.loads((REPO_ROOT / EVIDENCE[1]).read_text())
    inventory = source_inventory()
    evidence_hashes = {path: sha(path) for path in EVIDENCE}
    release = {
        "schema_version": "1.0.0", "milestone": "BH-05", "phase": 12,
        "candidate_kind": "revision-candidate", "decision": "revise", "support_state": "unsupported",
        "evidence_index": evidence_hashes, "implementation_inventory": inventory,
        "public_api_inventory": [row for row in inventory if row["surface"] == "public-experimental"],
        "private_api_inventory": [row for row in inventory if row["surface"] == "private"],
        "schema_inventory": [
            "packages/blazex_core/lib/blazex/component/schema.ex",
            "packages/blazex_core/lib/blazex/component/props.ex",
            "packages/blazex_core/lib/blazex/component/slots.ex",
            "packages/blazex_core/lib/blazex/component/action.ex",
        ],
        "lifecycle_inventory": [
            "packages/blazex_core/lib/blazex/component/local_view.ex",
            "packages/blazex_core/lib/blazex/component/root_process.ex",
            "packages/blazex_core/lib/blazex/component/recovery_cleanup.ex",
        ],
        "conformance_index": EVIDENCE[6:9], "benchmark_index": EVIDENCE[2:6],
        "dependency_audit": dependency_audit(inventory),
        "limitations": [
            "active Firefox cleanup terminal-state divergence",
            "fixed Phase 11 browser fixture is not a general build system",
            "public surfaces are experimental and unsupported",
            "LiveView and LocalLiveView are separately deferred",
            "BH-22 platform and manual accessibility qualification is deferred",
        ],
    }
    overlay = {
        "schema_version": "1.0.0", "registry_policy": "canonical planned registry remains immutable",
        "decision": "revise", "support_state": "unsupported",
        "outcomes": reconciliation["acceptance_outcomes"],
        "active_blockers": [row for row in reconciliation["findings"] if row["blocks_acceptance"]],
        "reconciliation_sha256": evidence_hashes[EVIDENCE[1]],
    }
    entry = {
        "schema_version": "1.0.0", "from": "BH-05", "to": "BH-06",
        "state": "ineligible", "authorized": False, "manifest_generated": False,
        "reason": "BH-05 decision is revise because active Firefox cleanup terminal state diverges",
        "reentry_requirements": [
            "retain the frozen 1000 ms cleanup threshold and resource-heavy fixture",
            "produce fresh zero-unresolved exact Chrome and Firefox terminal inventories",
            "retain all existing and new failed samples",
            "rerun all Phase 12 gates and publish a non-revise decision",
        ],
        "future_required_proofs": [
            "general build and dynamic dependency reachability", "component libraries forms and navigation",
            "Phoenix/Plug transport", "prerender and activation", "separate BH-06 authorization",
        ],
        "prohibited_dependencies": ["Phoenix", "Plug", ".NET", "LiveView", "LocalLiveView"],
        "forbidden_inferences": ["public 1.0 stability", "browser support", "platform qualification", "release support"],
    }
    return {"release": release, "overlay": overlay, "entry": entry}


def rendered():
    return {key: json.dumps(value, indent=2) + "\n" for key, value in records().items()}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    values = rendered()
    drift = []
    for key, path in TARGETS.items():
        target = REPO_ROOT / path
        if args.check:
            if not target.exists() or target.read_text() != values[key]:
                drift.append(path)
        else:
            target.write_text(values[key])
    if drift:
        print("BH-05 release drift: " + ", ".join(drift), file=sys.stderr)
        sys.exit(1)
    print("BH-05 release candidate: REVISE (" + ("exact" if args.check else "generated") + ")")
