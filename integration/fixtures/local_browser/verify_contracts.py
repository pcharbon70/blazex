#!/usr/bin/env python3
"""Validate disposable BH-01 Phase 5 behavior contracts and leakage guards."""

from __future__ import annotations

import json
import sys
from pathlib import Path

from jsonschema import Draft202012Validator


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
SCHEMA = HERE / "behavior-protocol.schema.json"
CATALOG = HERE / "scenario-catalog.json"
NORMALIZATION = HERE / "normalization-policy.json"


def load(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def sample_records() -> list[dict]:
    base = {
        "protocol": "blazex.bh01.fixture/0.1",
        "scenario_id": "BX-BH01-SCENARIO-NESTED-STATE",
        "generation": 1,
        "sequence": 1,
    }
    return [
        {**base, "record_type": "scenario", "status": "ready"},
        {**base, "record_type": "command", "command": "child.increment", "payload": {"key": "alpha"}},
        {**base, "record_type": "event", "node_id": "bx-field", "event": "input", "payload": {"value": "hello"}},
        {**base, "record_type": "state-snapshot", "state": {"count": 1}, "resources": {"timers": 0}},
        {**base, "record_type": "trace", "stage": "runtime-transition", "result": "updated"},
        {**base, "record_type": "error", "code": "fixture-stale-generation", "message": "stale", "retryable": False},
        {**base, "record_type": "disposal", "reason": "test-complete", "resources": {}},
    ]


def validate_contracts(schema: dict, catalog: dict, normalization: dict, production_text: str) -> list[str]:
    errors: list[str] = []
    validator = Draft202012Validator(schema)
    for index, record in enumerate(sample_records()):
        errors.extend(f"sample {index}: {error.message}" for error in validator.iter_errors(record))
    scenarios = catalog.get("scenarios", [])
    if catalog.get("status") != "experimental-non-public" or catalog.get("production_import_allowed") is not False:
        errors.append("fixture catalog is not explicitly experimental and non-public")
    if len(scenarios) != 4 or len({item.get("scenario_id") for item in scenarios}) != 4:
        errors.append("fixture scenario identities are incomplete or duplicated")
    required_proofs = {
        "BX-BH01-PROOF-NESTED-STATE",
        "BX-BH01-PROOF-FORM-EVENT",
        "BX-BH01-PROOF-TIMER-MESSAGE",
        "BX-BH01-PROOF-DOM-UPDATE",
    }
    observed_proofs = {proof for item in scenarios for proof in item.get("proofs", [])}
    if not required_proofs <= observed_proofs:
        errors.append("scenario catalog does not cover all Phase 5 proofs")
    for item in scenarios:
        for field in ("owner", "proofs", "risks", "acceptance", "positive", "negative", "cleanup", "budgets", "evidence"):
            if not item.get(field):
                errors.append(f"scenario {item.get('scenario_id')} lacks {field}")
    if normalization.get("status") != "reviewed-experimental":
        errors.append("normalization policy is not reviewed")
    for protected in ("sequence or causal order", "generation or semantic identity", "artifact bytes"):
        if not any(protected in item for item in normalization.get("never_normalize", [])):
            errors.append(f"normalization does not protect {protected}")
    for forbidden in ("integration/fixtures/local_browser", "BlazeX.BH01.LocalBrowser"):
        if forbidden in production_text:
            errors.append(f"production/profile source imports fixture-only boundary: {forbidden}")
    return errors


def production_source_text() -> str:
    paths: list[Path] = []
    for root in (ROOT / "packages", ROOT / "profiles"):
        paths.extend(
            path
            for path in root.rglob("*")
            if path.is_file()
            and path.suffix in {".ex", ".exs", ".js", ".mjs"}
            and not {"generated", "deps", "_build", "test", "tests", "toolchain"} & set(path.parts)
        )
    return "\n".join(path.read_text(encoding="utf-8", errors="ignore") for path in paths)


def inputs() -> tuple[dict, dict, dict, str]:
    return load(SCHEMA), load(CATALOG), load(NORMALIZATION), production_source_text()


def main() -> int:
    errors = validate_contracts(*inputs())
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print("BH-01 Phase 5 fixture behavior and observation contracts: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
