"""Fail-closed validation for BH-05 Phase 13 cleanup scaling evidence."""
import hashlib
import json
import math
import statistics
import sys
from collections import Counter
from pathlib import Path

from research_paths import REPO_ROOT

RAW = "integration/bh-05/cleanup-scaling-raw-v0.1.0.json"
REPORT = "integration/bh-05/cleanup-scaling-v0.1.0.json"
COUNTS = [0, 1, 63, 64, 65, 127, 128, 129, 255, 256, 257, 511, 512]
PAYLOAD_COUNTS = {
    "canonical": COUNTS,
    "maximum": [64, 65, 256, 512],
    "minimal": [64, 512],
}
RUNTIMES = ["erts", "chrome", "firefox"]
PHASE12_RAW_SHA256 = "d1e4d751194589dd6b55d433762c4afd7730a9ef8207c700f88c0a4a8f7d2949"


def digest(value):
    encoded = json.dumps(value, sort_keys=True, separators=(",", ":")).encode()
    return hashlib.sha256(encoded).hexdigest()


def retained_repetitions(runtime, count):
    if runtime == "erts":
        return 100 if count == 512 else 20
    return 20 if count == 512 else 10


def expected_samples():
    return Counter(
        (runtime, payload, count, sample)
        for runtime in RUNTIMES
        for payload, counts in PAYLOAD_COUNTS.items()
        for count in counts
        for sample in range(1, retained_repetitions(runtime, count) + 1)
    )


def compute_shape_alarms(samples):
    alarms = []
    groups = {}
    for sample in samples:
        if sample.get("count", -1) >= 64:
            key = (sample.get("runtime"), sample.get("payload_class"))
            groups.setdefault(key, {}).setdefault(sample["count"], []).append(sample["elapsed_ms"])
    for (runtime, payload), counts in sorted(groups.items()):
        points = [(count, statistics.median(values)) for count, values in sorted(counts.items())]
        slopes = [
            (right_y - left_y) / (right_x - left_x)
            for left_index, (left_x, left_y) in enumerate(points)
            for right_x, right_y in points[left_index + 1:]
            if right_x != left_x
        ]
        slope = statistics.median(slopes) if slopes else 0.0
        intercept = statistics.median([value - slope * count for count, value in points])
        for count, observed in points:
            predicted = intercept + slope * count
            envelope = max(100, abs(predicted) * 0.5)
            if observed > predicted + envelope:
                alarms.append({
                    "runtime": runtime,
                    "payload_class": payload,
                    "count": count,
                    "observed_ms": observed,
                    "predicted_ms": predicted,
                    "envelope_ms": envelope,
                })
    return alarms


def structural_errors(sample):
    errors = []
    amplification = sample.get("amplification", {})
    required = {
        "page_size", "maximum_page_size", "normal_worker_starts",
        "forced_worker_starts", "total_worker_starts",
        "peak_live_cleanup_workers", "lease_pages_sent", "protocol_messages",
        "normal_pages_sent", "forced_pages_sent", "callbacks_attempted",
        "callbacks_completed", "request_bytes", "result_bytes",
    }
    if not required.issubset(amplification):
        return ["structural instrumentation missing"]
    count = sample.get("count", -1)
    expected_pages = math.ceil(count / 64)
    rules = [
        (amplification["page_size"] == 64, "page size drift"),
        (amplification["maximum_page_size"] == 128, "maximum page drift"),
        (amplification["normal_worker_starts"] <= 1, "normal worker amplification"),
        (amplification["forced_worker_starts"] <= 1, "forced worker amplification"),
        (amplification["total_worker_starts"] <= 2, "total worker amplification"),
        (amplification["peak_live_cleanup_workers"] <= 1, "concurrent worker growth"),
        (amplification["lease_pages_sent"] == expected_pages, "lease page mismatch"),
        (
            amplification["protocol_messages"]
            <= 2 * (amplification["normal_pages_sent"] + amplification["forced_pages_sent"]),
            "message amplification",
        ),
        (
            amplification["request_bytes"] == "unavailable"
            or isinstance(amplification["request_bytes"], int)
            and amplification["request_bytes"] >= 0,
            "request byte count",
        ),
        (
            amplification["result_bytes"] == "unavailable"
            or isinstance(amplification["result_bytes"], int)
            and amplification["result_bytes"] >= 0,
            "result byte count",
        ),
    ]
    errors.extend(message for valid, message in rules if not valid)
    return errors


def validate_raw(raw):
    errors = []
    required_top = {
        "schema_version", "phase", "support_state", "execution_state",
        "acceptance_state", "contract", "phase12_raw_sha256",
        "retained_failed_trials", "samples", "shape", "environment",
        "phase12_fixture_repeat",
    }
    if not required_top.issubset(raw):
        return ["raw evidence fields missing"]
    if raw["schema_version"] != "1.0.0" or raw["phase"] != 13:
        errors.append("schema/phase drift")
    if raw["support_state"] != "unsupported":
        errors.append("support state drift")
    if raw["execution_state"] != "executed":
        errors.append("harness execution incomplete")
    environment = raw.get("environment", {})
    if not environment.get("source_revision"):
        errors.append("source revision missing")
    browser_artifacts = environment.get("browser_artifacts", {})
    if not browser_artifacts.get("atomvm_wasm_sha256"):
        errors.append("AtomVM identity missing")
    if set(browser_artifacts.get("bundle_sha256", {})) != {"chrome", "firefox"}:
        errors.append("browser bundle identities missing")
    contract = raw.get("contract", {})
    if contract.get("deadline_ms") != 1000 or contract.get("page_size") != 64:
        errors.append("frozen cleanup contract drift")
    if contract.get("maximum_page_size") != 128 or contract.get("fixture_count") != 512:
        errors.append("frozen fixture/page maximum drift")
    if raw["phase12_raw_sha256"] != PHASE12_RAW_SHA256:
        errors.append("Phase 12 raw evidence drift")
    repeat = raw.get("phase12_fixture_repeat", {})
    if repeat.get("passed") is not True:
        errors.append("unchanged Phase 12 fixture repeat failed")
    if repeat.get("erts", {}).get("acceptance_state") != "passed":
        errors.append("ERTS lifecycle repeat failed")
    if repeat.get("browser", {}).get("comparison", {}).get("state") != "exact-match":
        errors.append("browser lifecycle repeat diverged")
    failures = raw.get("retained_failed_trials", [])
    if len(failures) < 3 or any(row.get("state") != "failed" for row in failures):
        errors.append("retained failures missing or relabelled")

    observed = Counter()
    required_sample = {
        "runtime", "payload_class", "count", "sample", "retained",
        "execution_state", "acceptance_state", "elapsed_ms",
        "exceeded_deadline", "terminal_leases", "unresolved_identities",
        "lost_closed_identities", "amplification", "runtime_metrics",
        "stage_timings_ms", "raw_sha256",
    }
    for sample in raw.get("samples", []):
        if not required_sample.issubset(sample):
            errors.append("sample fields missing")
            continue
        key = (sample["runtime"], sample["payload_class"], sample["count"], sample["sample"])
        observed[key] += 1
        value = dict(sample)
        claimed_hash = value.pop("raw_sha256")
        if digest(value) != claimed_hash:
            errors.append("sample hash drift")
        if sample["retained"] is not True or sample["execution_state"] != "executed":
            errors.append("sample was hidden or not executed")
        structural = structural_errors(sample)
        errors.extend(structural)
        semantic_pass = (
            not sample["exceeded_deadline"]
            and sample["terminal_leases"] == 0
            and sample["unresolved_identities"] == []
            and sample["lost_closed_identities"] == []
            and not structural
        )
        expected_state = "passed" if semantic_pass else "failed"
        if sample["acceptance_state"] != expected_state:
            errors.append("sample acceptance relabelled")
    if observed != expected_samples():
        errors.append("scale matrix/sample cardinality drift")

    shape = raw.get("shape", {})
    if shape.get("method") != "theil-sen" or shape.get("absolute_alarm_ms") != 100:
        errors.append("shape method drift")
    if shape.get("relative_alarm") != 0.5 or shape.get("minimum_count") != 64:
        errors.append("shape envelope drift")
    alarms = shape.get("alarms")
    if not isinstance(alarms, list):
        errors.append("shape alarms missing")
    elif alarms != compute_shape_alarms(raw.get("samples", [])):
        errors.append("shape alarms were not recomputed from raw samples")

    samples_pass = all(row.get("acceptance_state") == "passed" for row in raw.get("samples", []))
    expected_state = (
        "passed" if samples_pass and alarms == [] and repeat.get("passed") is True and not errors
        else "failed"
    )
    if raw["acceptance_state"] != expected_state:
        errors.append("top-level acceptance state mismatch")
    return errors


def validate_report(report, raw_bytes, raw):
    errors = []
    if report.get("raw_sha256") != hashlib.sha256(raw_bytes).hexdigest():
        errors.append("raw/report hash drift")
    expected = "passed" if not validate_raw(raw) else "failed"
    if report.get("execution_state") != "executed":
        errors.append("report execution state mismatch")
    if report.get("acceptance_state") != expected:
        errors.append("report acceptance state mismatch")
    if report.get("result") != expected:
        errors.append("compatibility result is not derived from acceptance")
    if report.get("sample_count") != len(raw.get("samples", [])):
        errors.append("report sample count mismatch")
    if report.get("shape_alarms") != len(raw.get("shape", {}).get("alarms", [])):
        errors.append("report shape alarm mismatch")
    return errors


def validate(root=REPO_ROOT):
    try:
        raw_bytes = (Path(root) / RAW).read_bytes()
        raw = json.loads(raw_bytes)
        report = json.loads((Path(root) / REPORT).read_text())
        return validate_raw(raw) + validate_report(report, raw_bytes, raw)
    except (OSError, ValueError, TypeError, KeyError) as error:
        return ["missing/malformed cleanup scaling evidence: " + type(error).__name__]


if __name__ == "__main__":
    problems = validate()
    print("\n".join(problems) if problems else "BH-05 Phase 13 cleanup scaling evidence: PASS")
    sys.exit(bool(problems))
