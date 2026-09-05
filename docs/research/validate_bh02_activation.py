#!/usr/bin/env python3
"""Validate BH-02 Phase 1 authorization, handoff, activation, and leakage."""

from __future__ import annotations

import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any


RESEARCH_ROOT = Path(__file__).resolve().parent
REPO_ROOT = RESEARCH_ROOT.parent.parent
BASELINE_ROOT = RESEARCH_ROOT / "assets/bh-02-baseline"
AUTHORIZATION = BASELINE_ROOT / "blazex-bh-02-authorization-v0.1.0.json"
LEDGER = BASELINE_ROOT / "blazex-bh-02-entry-ledger-v0.1.0.json"
ACTIVATION = BASELINE_ROOT / "blazex-bh-02-repository-activation-v0.1.0.json"
ENTRY = RESEARCH_ROOT / "assets/bh-01-release/blazex-bh-02-entry-manifest-v0.1.0.json"
CONFORMANCE_INDEX = REPO_ROOT / "integration/conformance/conformance-index-v0.1.0.json"
EXPERIMENT_INDEX = REPO_ROOT / "experiments/native_renderer_spike/experiment-index-v0.1.0.json"

EXPECTED_OUTPUT_IDS = [
    "semantic-ui-node-identity",
    "event-action-contract",
    "effect-capability-resource-contract",
    "layout-token-accessibility-focus-selection-file-intent",
    "renderer-lifecycle-capability-negotiation",
    "deterministic-headless-renderer-traces",
    "minimal-dom-lowering",
    "limited-direct-native-control-spike",
    "forbidden-dependency-leakage-checks",
]

FORBIDDEN_SOURCE_PATTERNS = {
    "browser/server/runtime object": re.compile(
        r"\b(?:dom|javascript|phoenix|plug|liveview|local_live_view|popcorn|atomvm)\b",
        re.IGNORECASE,
    ),
    "excluded toolkit": re.compile(r"\b(?:qt|wxwidgets)\b", re.IGNORECASE),
    "platform object": re.compile(
        r"\b(?:hwnd|nsview|nscontrol|win32|appkit|gtk_widget|gtk4?)\b",
        re.IGNORECASE,
    ),
}


class ValidationError(Exception):
    """Raised when BH-02 activation must fail closed."""


def _load_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ValidationError(f"cannot load {path}: {exc}") from exc
    if not isinstance(value, dict):
        raise ValidationError(f"{path} must contain a JSON object")
    return value


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _require(condition: bool, message: str) -> None:
    if not condition:
        raise ValidationError(message)


def validate_authorization(auth: dict[str, Any], repo_root: Path = REPO_ROOT) -> None:
    _require(auth.get("authorization_id") == "BX-BH02-AUTHORIZATION-0.1", "authorization ID is missing")
    _require(auth.get("status") == "approved-phase-1-only", "BH-02 Phase 1 lacks explicit approval")
    approver = auth.get("approved_by", {})
    _require(approver.get("identity") and approver.get("role") == "repository-owner", "repository-owner approval is incomplete")
    activation = auth.get("activation", {})
    base = str(activation.get("base_revision", ""))
    _require(base == activation.get("base_remote_revision") and len(base) == 40, "synchronized base revision is invalid")
    _require(activation.get("main_synchronized_before_branch") is True, "main synchronization is not recorded")
    _require(str(activation.get("working_branch", "")).startswith("codex/"), "dedicated codex branch is not recorded")
    rules = auth.get("delivery_rules", {})
    for rule in ("sections_in_order", "commit_per_section", "single_pull_request", "return_to_synchronized_main_after_delivery", "delete_local_feature_branch_after_delivery"):
        _require(rules.get(rule) is True, f"delivery rule is missing: {rule}")
    not_authorized = " ".join(auth.get("not_authorized", [])).lower()
    for phrase in ("phases 2 through 8", "stable", "product component", "support claims"):
        _require(phrase in not_authorized, f"authorization does not exclude {phrase}")
    for binding in auth.get("approval_basis", []):
        path = repo_root / str(binding.get("path", ""))
        _require(path.is_file(), f"authorization input is missing: {path}")
        _require(_sha256(path) == binding.get("sha256"), f"authorization input is stale: {path}")
    result = subprocess.run(
        ["git", "merge-base", "--is-ancestor", base, "HEAD"],
        cwd=repo_root,
        check=False,
        capture_output=True,
        text=True,
    )
    _require(result.returncode == 0, "current work does not descend from the synchronized authorized base")


def validate_ledger(ledger: dict[str, Any], entry: dict[str, Any]) -> None:
    _require(ledger.get("authorization_ref") == "BX-BH02-AUTHORIZATION-0.1", "ledger authorization link is missing")
    outputs = ledger.get("required_outputs", [])
    _require([record.get("id") for record in outputs] == EXPECTED_OUTPUT_IDS, "required-output ledger is incomplete or reordered")
    _require(all(record.get("state") == "planned-unimplemented" for record in outputs[:-1]), "future output overclaims implementation")
    _require(outputs[-1].get("state") == "phase-1-in-progress", "Phase 1 validation output has an invalid state")
    _require(ledger.get("inherited_condition_ids") == [record["id"] for record in entry["conditions"]], "inherited conditions diverge")
    _require(ledger.get("repository_boundaries") == entry["repository_boundaries"], "repository boundary handoff diverges")
    _require(ledger.get("inherited_forbidden_leakage") == entry["forbidden_leakage"], "forbidden-leakage handoff diverges")
    _require(ledger.get("inherited_limitations") == entry["limitations"], "limitation handoff diverges")
    _require(ledger.get("repeat_obligations") == entry["repeat_obligations"], "repeat obligations diverge")
    _require(ledger.get("deferred_qualification_ids") == [record["id"] for record in entry["deferred_qualification"]], "deferred qualification diverges")
    evidence = ledger.get("evidence_boundary", {})
    _require(evidence.get("semantic_contracts") == "unimplemented", "semantic contracts are overclaimed")
    _require(evidence.get("component_behavior") == "unimplemented", "component behavior is overclaimed")
    _require(evidence.get("support") == "unsupported", "support is overclaimed")


def validate_mix_dependencies(project_path: Path, expected: list[str]) -> None:
    mix_path = project_path / "mix.exs"
    _require(mix_path.is_file(), f"missing Mix manifest: {mix_path}")
    text = mix_path.read_text(encoding="utf-8")
    actual = re.findall(r"\{:\s*([a-z0-9_]+)\s*,\s*path:", text)
    _require(actual == expected, f"Mix dependencies differ for {project_path}: {actual} != {expected}")
    _require(not re.search(r"\b(?:git|github|hex):", text), f"external dependency source found in {mix_path}")
    _require(not (project_path / "mix.lock").exists(), f"unexpected lockfile: {project_path / 'mix.lock'}")


def scan_forbidden_sources(project_path: Path) -> None:
    files = [project_path / "mix.exs", *sorted((project_path / "lib").rglob("*.ex")), *sorted((project_path / "test").rglob("*.exs"))]
    for path in files:
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8")
        for label, pattern in FORBIDDEN_SOURCE_PATTERNS.items():
            match = pattern.search(text)
            _require(match is None, f"{label} leaked into {path}: {match.group(0) if match else ''}")


def validate_activation(activation: dict[str, Any], repo_root: Path = REPO_ROOT) -> None:
    boundaries = activation.get("boundaries", [])
    _require(len(boundaries) == 9, "activation must contain exactly nine boundaries")
    _require(len({record.get("id") for record in boundaries}) == 9, "activation contains duplicate boundaries")
    for boundary in boundaries:
        path = repo_root / boundary["path"]
        manifest = path / boundary["manifest"]
        _require(path.is_dir() and manifest.is_file(), f"activated boundary is incomplete: {path}")
        if boundary["kind"] not in {"elixir-package", "executable-profile"}:
            continue
        metadata = _load_json(path / "blazex.project.json")
        for key in ("id", "path", "kind", "owner_role", "manifest", "dependencies"):
            _require(metadata.get(key) == boundary.get(key), f"activation metadata differs for {boundary['id']}: {key}")
        _require(metadata.get("activation_phase") == "BH-02 Phase 1", f"wrong activation phase: {boundary['id']}")
        _require(metadata.get("public_api_state") == "experimental-unimplemented", f"API state overclaim: {boundary['id']}")
        validate_mix_dependencies(path, boundary["dependencies"])
        scan_forbidden_sources(path)
    evidence = activation.get("evidence_boundary", {})
    _require(evidence.get("external_dependencies") == "none-acquired", "external dependency acquisition is overclaimed")
    _require(evidence.get("semantic_contracts") == "unimplemented", "semantic implementation is overclaimed")
    _require(evidence.get("renderer_behavior") == "unimplemented", "renderer implementation is overclaimed")
    _require(evidence.get("support") == "unsupported", "support is overclaimed")


def validate_evidence_indexes(repo_root: Path = REPO_ROOT) -> None:
    conformance = _load_json(repo_root / CONFORMANCE_INDEX.relative_to(REPO_ROOT))
    _require(conformance.get("status") == "activated-no-semantic-fixtures-or-results", "conformance index overclaims results")
    _require(conformance.get("fixture_sets") == [] and conformance.get("canonical_traces") == [] and conformance.get("backend_results") == [], "conformance index is not empty")
    _require(conformance.get("support_state") == "unsupported", "conformance support is overclaimed")
    experiment = _load_json(repo_root / EXPERIMENT_INDEX.relative_to(REPO_ROOT))
    _require(experiment.get("status") == "activated-boundary-no-controls-implemented", "native experiment overclaims implementation")
    _require(experiment.get("implemented_controls") == [] and experiment.get("evidence") == [], "native experiment contains premature evidence")
    _require(experiment.get("excluded_direct_or_transitive") == ["qt", "wxwidgets"], "excluded native systems are not enforced")
    _require(experiment.get("support_state") == "unsupported", "native support is overclaimed")


def validate(repo_root: Path = REPO_ROOT, research_root: Path = RESEARCH_ROOT) -> None:
    auth = _load_json(research_root / AUTHORIZATION.relative_to(RESEARCH_ROOT))
    ledger = _load_json(research_root / LEDGER.relative_to(RESEARCH_ROOT))
    activation = _load_json(research_root / ACTIVATION.relative_to(RESEARCH_ROOT))
    entry = _load_json(research_root / ENTRY.relative_to(RESEARCH_ROOT))
    validate_authorization(auth, repo_root)
    _require(_sha256(research_root / ENTRY.relative_to(RESEARCH_ROOT)) == ledger["entry_manifest"]["sha256"], "ledger entry-manifest hash is stale")
    baseline = repo_root / ledger["feasibility_baseline"]["path"]
    _require(baseline.is_file() and _sha256(baseline) == ledger["feasibility_baseline"]["sha256"], "feasibility baseline hash is stale")
    validate_ledger(ledger, entry)
    validate_activation(activation, repo_root)
    validate_evidence_indexes(repo_root)


def main() -> int:
    try:
        validate()
    except ValidationError as exc:
        print(f"BH-02 activation validation failed: {exc}", file=sys.stderr)
        return 1
    print("BH-02 activation validation passed: authorization, handoff, nine boundaries, dependency graph, leakage scans, and evidence limits checked.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
