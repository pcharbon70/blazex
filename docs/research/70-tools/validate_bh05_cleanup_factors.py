"""Fail-closed validation for BH-05 Phase 16 factorized cleanup observations."""
import math
import sys
from pathlib import Path

from research_paths import REPO_ROOT

PROFILES = [
    "inventory_only",
    "payload_only",
    "identifier_only",
    "owner_depth_only",
    "distribution_only",
    "outcome_retention",
    "maximum",
]
COUNTS = [256, 512]


def validate_result(result):
    errors = []
    if not isinstance(result, dict):
        return ["factor result missing"]
    if result.get("execution_state") != "executed":
        errors.append("factor execution incomplete")
    if result.get("factor_profiles") != PROFILES:
        errors.append("factor profile matrix drift")
    samples = result.get("samples")
    if not isinstance(samples, list):
        return errors + ["factor samples missing"]

    indexed = {}
    for sample in samples:
        if not isinstance(sample, dict):
            errors.append("factor sample malformed")
            continue
        key = (sample.get("payload_class"), sample.get("count"))
        if key in indexed:
            errors.append("duplicate factor sample")
        indexed[key] = sample
        errors.extend(sample_errors(sample))

    expected = {(profile, count) for profile in PROFILES for count in COUNTS}
    if set(indexed) != expected:
        errors.append("factor sample matrix drift")

    for count in COUNTS:
        equal_width = [
            indexed.get((profile, count), {}).get("outcome_format", {}).get(
                "retained_outcome_bytes"
            )
            for profile in [
                "payload_only",
                "owner_depth_only",
                "distribution_only",
                "outcome_retention",
            ]
        ]
        available = [value for value in equal_width if isinstance(value, int)]
        if available and len(set(available)) != 1:
            errors.append("successful outcome still scales with owner or payload shape")
    return errors


def sample_errors(sample):
    errors = []
    required = {
        "payload_class",
        "count",
        "execution_state",
        "acceptance_state",
        "elapsed_ms",
        "exceeded_deadline",
        "terminal_leases",
        "unresolved_identities",
        "amplification",
        "stage_timings_ms",
        "outcome_format",
    }
    if not required.issubset(sample):
        return ["factor sample fields missing"]
    outcome = sample["outcome_format"]
    amplification = sample["amplification"]
    count = sample["count"]
    if not isinstance(outcome, dict) or not isinstance(amplification, dict):
        return ["factor structural fields malformed"]
    rules = [
        (sample["execution_state"] == "executed", "factor sample not executed"),
        (sample["acceptance_state"] == "passed", "factor sample relabelled"),
        (isinstance(sample["elapsed_ms"], int) and sample["elapsed_ms"] <= 1000,
         "factor deadline exceeded"),
        (sample["exceeded_deadline"] is False, "factor deadline flag concealed"),
        (sample["terminal_leases"] == 0, "factor terminal leases remain"),
        (sample["unresolved_identities"] == [], "factor unresolved identities remain"),
        (outcome.get("version") == 2, "sparse outcome version drift"),
    ]
    rules.extend([
        (outcome.get("owner_records") == 0, "successful owner records retained"),
        (outcome.get("retained_owner_records") == 0, "retained owner metric drift"),
        (outcome.get("outcome_pages") == math.ceil(count / 64),
         "factor outcome page amplification"),
        (outcome.get("identities") == count, "factor outcome identity mismatch"),
        (outcome.get("expanded_rows") == 0, "factor expanded rows retained"),
        (outcome.get("retained_outcome_bytes") == outcome.get("encoded_bytes"),
         "retained outcome byte mismatch"),
        (amplification.get("page_size") == 64, "factor page size drift"),
        (amplification.get("maximum_page_size") == 128, "factor maximum page drift"),
        (amplification.get("runtime_owned_inventory") is True,
         "factor runtime ownership missing"),
        (amplification.get("inventory_before") == count,
         "factor initial inventory mismatch"),
        (amplification.get("inventory_after") == 0,
         "factor inventory did not converge"),
        (amplification.get("normal_worker_starts") == 0,
         "factor disposal started worker"),
    ])
    return [message for valid, message in rules if not valid]


def validate_browser(record):
    errors = []
    if record.get("phase") != 16 or record.get("support_state") != "unsupported":
        errors.append("factor browser envelope drift")
    results = record.get("results", [])
    if [row.get("browser") for row in results] != ["chrome", "firefox"]:
        errors.append("factor browser matrix drift")
    for row in results:
        errors.extend(f"{row.get('browser', 'unknown')}: {error}" for error in validate_result(row))
    return errors


if __name__ == "__main__":
    import json
    target = Path(sys.argv[1]) if len(sys.argv) > 1 else REPO_ROOT / "integration/bh-05/cleanup-factor-v0.1.0.json"
    errors = validate_browser(json.loads(target.read_text()))
    if errors:
        print("\n".join(errors), file=sys.stderr)
        raise SystemExit(1)
    print("BH-05 Phase 16 cleanup factor validation passed.")
