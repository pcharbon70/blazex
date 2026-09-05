#!/usr/bin/env python3
"""Deterministic statistics and validation helpers for BH-01 Phase 9."""

from __future__ import annotations

import hashlib
import json
import math
import statistics
from collections import defaultdict
from pathlib import Path
from typing import Any, Iterable


def load_json(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"{path} must contain a JSON object")
    return value


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def nearest_rank(values: Iterable[float], percentile: float) -> float:
    ordered = sorted(float(value) for value in values)
    if not ordered:
        raise ValueError("a percentile requires at least one value")
    if not 0 < percentile <= 100:
        raise ValueError("percentile must be greater than zero and at most one hundred")
    return ordered[max(0, math.ceil(percentile / 100 * len(ordered)) - 1)]


def summarize(values: Iterable[float]) -> dict[str, float | int]:
    samples = [float(value) for value in values]
    if not samples or any(not math.isfinite(value) or value < 0 for value in samples):
        raise ValueError("summary values must be finite, non-negative, and non-empty")
    mean = statistics.fmean(samples)
    deviation = statistics.pstdev(samples)
    rounded = lambda value: round(float(value), 6)
    return {
        "count": len(samples),
        "minimum": rounded(min(samples)),
        "maximum": rounded(max(samples)),
        "mean": rounded(mean),
        "median": rounded(statistics.median(samples)),
        "p95": rounded(nearest_rank(samples, 95)),
        "coefficient_of_variation_percent": rounded(0 if mean == 0 else deviation / mean * 100),
    }


def validate_measurements(
    measurements: list[dict[str, Any]],
    definitions: dict[str, dict[str, Any]],
) -> None:
    seen: set[tuple[str, str, str, int]] = set()
    for measurement in measurements:
        metric_id = measurement.get("metric_id")
        if metric_id not in definitions:
            raise ValueError(f"unknown metric: {metric_id}")
        definition = definitions[metric_id]
        if measurement.get("unit") != definition["unit"]:
            raise ValueError(f"metric unit mismatch: {metric_id}")
        cache_state = measurement.get("cache_state")
        if cache_state not in definition["cache_states"]:
            raise ValueError(f"metric cache state mismatch: {metric_id}")
        scenario = measurement.get("scenario")
        if not isinstance(scenario, str) or not scenario:
            raise ValueError(f"missing measurement scenario: {metric_id}")
        for sample in measurement.get("samples", []):
            value = sample.get("value")
            iteration = sample.get("iteration")
            key = (metric_id, scenario, cache_state, iteration)
            if key in seen:
                raise ValueError(f"duplicate sample identity: {key}")
            seen.add(key)
            if not isinstance(iteration, int) or iteration < 1:
                raise ValueError(f"invalid sample iteration: {metric_id}")
            if not isinstance(value, (int, float)) or not math.isfinite(value) or value < 0:
                raise ValueError(f"invalid sample value: {metric_id}")


def summarize_measurements(
    measurements: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    grouped: dict[tuple[str, str, str, str], list[float]] = defaultdict(list)
    for measurement in measurements:
        key = (
            measurement["metric_id"],
            measurement["scenario"],
            measurement["unit"],
            measurement["cache_state"],
        )
        grouped[key].extend(float(sample["value"]) for sample in measurement["samples"])
    return [
        {
            "metric_id": metric_id,
            "scenario": scenario,
            "unit": unit,
            "cache_state": cache_state,
            "statistics": summarize(values),
        }
        for (metric_id, scenario, unit, cache_state), values in sorted(grouped.items())
    ]
