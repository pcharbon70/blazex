#!/usr/bin/env python3
"""Validate Phase 7 adversarial payload, artifact, and authority coverage."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any


HERE = Path(__file__).resolve().parent
PAYLOAD = {"malformed-json", "unknown-field", "deep-object", "large-string", "large-array", "duplicate-operation", "out-of-order-sequence", "unicode-key", "invalid-encoding", "nonfinite-number", "unsafe-integer", "atom-key-growth", "binary-size", "decompression-mismatch", "path-traversal", "cross-origin-url", "credentialed-url", "redirect", "header-confusion", "origin-forgery", "event-target-substitution", "correlation-substitution", "idempotency-substitution", "stale-generation", "duplicate-result", "html-script-text", "host-operation-abuse"}
ARTIFACT = {"modified-wasm", "modified-beam", "modified-javascript", "modified-manifest", "unexpected-source-map", "wrong-mime", "wrong-compression", "redirected-response", "cross-origin-response", "stale-cache", "missing-integrity", "csp-conflict", "cors-conflict", "isolation-conflict", "downgrade-attempt"}
AUTHORITY = {"anonymous-direct-transport", "forged-session", "forged-csrf", "forged-role", "resource-substitution", "state-substitution", "replay", "concurrent-replay-race", "adapter-bypass", "host-operation-bypass", "result-target-substitution", "dom-target-substitution", "rate-amplification"}


def load(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def validate(matrix: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    if matrix.get("status") != "phase7-executed-contract-matrix" or matrix.get("seed") != 170701:
        errors.append("adversarial matrix identity/status drifted")
    if matrix.get("iterations_per_generated_family", 0) < 64:
        errors.append("generated adversarial iteration floor is too small")
    for field, expected in (("payload_vectors", PAYLOAD), ("artifact_vectors", ARTIFACT), ("authority_vectors", AUTHORITY)):
        if set(matrix.get(field, [])) != expected:
            errors.append(f"adversarial coverage drifted: {field}")
    outcomes = matrix.get("required_outcomes", {})
    true_outcomes = {"bounded_parse", "fail_before_artifact_execute", "cleanup_required", "correlation_required"}
    false_outcomes = {"code_execution", "html_injection", "secret_exposure", "dynamic_atom_creation", "unauthorized_effect", "hidden_downgrade"}
    if any(outcomes.get(key) is not True for key in true_outcomes) or any(outcomes.get(key) is not False for key in false_outcomes):
        errors.append("adversarial fail-closed outcomes drifted")
    review = matrix.get("specialist_review", {})
    if review.get("role") != "security-reviewer" or review.get("disposition") != "accepted-for-phase7-feasibility":
        errors.append("specialist security review is missing")
    if len(review.get("residual_assumptions", [])) < 4 or len(review.get("production_controls_not_implemented", [])) < 6:
        errors.append("security residual assumptions or production gaps are incomplete")
    if len(matrix.get("stop_conditions", [])) < 6 or "security certification" not in matrix.get("claims_not_made", []):
        errors.append("security stop/nonclaim boundary is incomplete")
    return errors


def main() -> int:
    errors = validate(load(HERE / "adversarial-matrix.json"))
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print("BH-01 Phase 7 adversarial matrix: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
