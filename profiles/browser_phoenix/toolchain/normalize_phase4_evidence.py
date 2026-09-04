#!/usr/bin/env python3
"""Normalize an actual BH-01 Phase 4 browser capture for retention."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from urllib.parse import urlsplit


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def scenario(record: dict) -> dict:
    lifecycle = record.get("lifecycle")
    if lifecycle:
        lifecycle = {
            "protocol": lifecycle.get("protocol"),
            "state": lifecycle.get("state"),
            "generation": lifecycle.get("generation"),
            "attempt": lifecycle.get("attempt"),
            "failure": lifecycle.get("failure"),
            "resources": lifecycle.get("resources"),
            "metrics": {
                key: value
                for key, value in lifecycle.get("metrics", {}).items()
                if key != "cleanup_ms"
            },
        }
    result = {
        "scenario": record["scenario"],
        "state": record["state"],
        "prerequisite_decision": (record.get("prerequisites") or {}).get("decision"),
        "missing_prerequisites": (record.get("prerequisites") or {}).get("missing", []),
        "activation_generation": record.get("activation_generation"),
        "manifest_generation": record.get("manifest_generation"),
        "echo": record.get("echo"),
        "error": record.get("error"),
        "lifecycle": lifecycle,
        "frame_count": record.get("frame_count"),
        "event_count": len(record.get("events", [])),
    }
    if record["scenario"] in {"cold", "missing-isolation-policy"}:
        result["environment"] = record.get("environment")
        result["prerequisites"] = record.get("prerequisites")
    return result


def normalize_url(url: str) -> str:
    parsed = urlsplit(url)
    return "blob:<runtime-worker-module>" if parsed.scheme == "blob" else parsed.path


def normalize_network(records: list[dict]) -> list[dict]:
    unique = {}
    for record in records:
        value = {
            "phase": record["phase"],
            "type": record["type"],
            "path": normalize_url(record["url"]),
        }
        for key in ("method", "status", "mime", "cache_control"):
            if record.get(key) is not None:
                value[key] = record[key]
        unique[json.dumps(value, sort_keys=True)] = value
    return [unique[key] for key in sorted(unique)]


def event_sequence(record: dict, generation: int) -> list[str]:
    sequence = []
    for event in record.get("events", []):
        if event.get("generation") not in (None, generation):
            continue
        if event.get("from") or event.get("to"):
            value = f"{event.get('from')}->{event.get('to')}"
        else:
            value = event.get("stage") or event.get("type") or event.get("protocol")
        if value and value not in sequence:
            sequence.append(value)
    return sequence


def normalize(raw_path: Path, profile_path: Path) -> dict:
    raw = json.loads(raw_path.read_text(encoding="utf-8"))
    profile = json.loads(profile_path.read_text(encoding="utf-8"))
    artifacts = {item["path"]: item for item in profile["artifacts"]}
    observed = []
    for item in raw["deployment"]["observed"]:
        declared = artifacts[item["path"]]
        observed.append(
            {
                **item,
                "sha256": declared["sha256"],
                "mime": declared["mime"],
                "owner": "profiles/browser_phoenix",
            }
        )
    cold = next(item for item in raw["positive_scenarios"] if item["scenario"] == "cold")
    stopped = next(item for item in raw["positive_scenarios"] if item["scenario"] == "stop-1")
    return {
        "schema_version": raw["schema_version"],
        "evidence_id": raw["evidence_id"],
        "captured_at": raw["captured_at"],
        "implementation_parent_revision": raw["implementation_parent_revision"],
        "status": raw["status"],
        "support_status": raw["support_status"],
        "source_capture": {
            "sha256": sha256(raw_path),
            "bytes": raw_path.stat().st_size,
            "normalization": [
                "Replace random blob-worker URLs with blob:<runtime-worker-module>.",
                "Deduplicate repeated network observations while retaining method, status, MIME, and cache policy.",
                "Remove nondeterministic cleanup duration while retaining transition, failure, stale-drop, and cleanup-failure counts.",
                "Retain scenario outcomes and canonical cold/start-stop event sequences instead of cumulative duplicate event histories.",
                "Enrich deployment observations with declared SHA-256, MIME, and owner from the verified profile asset manifest.",
            ],
        },
        "toolchain": raw["toolchain"],
        "deployment": {
            **{key: value for key, value in raw["deployment"].items() if key != "observed"},
            "observed": observed,
        },
        "positive_scenarios": [scenario(item) for item in raw["positive_scenarios"]],
        "negative_scenarios": [scenario(item) for item in raw["negative_scenarios"]],
        "canonical_event_sequences": {
            "cold_generation_1": event_sequence(cold, 1),
            "stop_generation_1": event_sequence(stopped, 1),
        },
        "network": normalize_network(raw["network"]),
        "findings": raw["findings"],
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--raw", type=Path, required=True)
    parser.add_argument("--profile", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    result = normalize(args.raw, args.profile)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(f"Normalized BH-01 Phase 4 browser evidence: {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
