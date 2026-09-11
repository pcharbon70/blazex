import copy
import hashlib
import json
import unittest

from validate_bh05_cleanup_scaling import (
    COUNTS,
    PAYLOAD_COUNTS,
    RUNTIMES,
    PHASE12_RAW_SHA256,
    digest,
    retained_repetitions,
    outcome_errors,
    validate_raw,
    validate_report,
)


def sample(runtime, payload, count, number):
    lease_pages = (count + 63) // 64
    value = {
        "runtime": runtime,
        "payload_class": payload,
        "count": count,
        "sample": number,
        "retained": True,
        "execution_state": "executed",
        "acceptance_state": "passed",
        "elapsed_ms": count,
        "exceeded_deadline": False,
        "terminal_leases": 0,
        "unresolved_identities": [],
        "lost_closed_identities": [],
        "amplification": {
            "page_size": 64,
            "maximum_page_size": 128,
            "normal_worker_starts": 1,
            "forced_worker_starts": 0,
            "total_worker_starts": 1,
            "peak_live_cleanup_workers": 1,
            "lease_pages_sent": lease_pages,
            "protocol_messages": lease_pages * 2,
            "normal_pages_sent": lease_pages,
            "forced_pages_sent": 0,
            "callbacks_attempted": count,
            "callbacks_completed": count,
            "request_bytes": count,
            "result_bytes": count,
        },
        "runtime_metrics": {"memory": "unavailable"},
        "stage_timings_ms": {"total": count},
    }
    value["raw_sha256"] = digest(value)
    return value


def valid_raw():
    samples = [
        sample(runtime, payload, count, number)
        for runtime in RUNTIMES
        for payload, counts in PAYLOAD_COUNTS.items()
        for count in counts
        for number in range(1, retained_repetitions(runtime, count) + 1)
    ]
    return {
        "schema_version": "1.0.0",
        "phase": 13,
        "support_state": "unsupported",
        "execution_state": "executed",
        "acceptance_state": "passed",
        "environment": {
            "source_revision": "phase13-test-revision",
            "browser_artifacts": {
                "atomvm_wasm_sha256": "a" * 64,
                "bundle_sha256": {"chrome": "b" * 64, "firefox": "b" * 64},
            },
        },
        "contract": {"deadline_ms": 1000, "page_size": 64, "maximum_page_size": 128, "fixture_count": 512},
        "phase12_raw_sha256": PHASE12_RAW_SHA256,
        "retained_failed_trials": [
            {"id": "phase12-a", "state": "failed"},
            {"id": "phase12-b", "state": "failed"},
            {"id": "phase12-c", "state": "failed"},
        ],
        "phase12_fixture_repeat": {
            "passed": True,
            "erts": {"acceptance_state": "passed"},
            "browser": {"comparison": {"state": "exact-match"}},
        },
        "samples": samples,
        "shape": {"method": "theil-sen", "absolute_alarm_ms": 100, "relative_alarm": 0.5, "minimum_count": 64, "alarms": []},
    }


class CleanupScalingEvidenceTest(unittest.TestCase):
    def test_compact_outcome_structure_is_page_proportional_and_unexpanded(self):
        valid = {
            "version": 1,
            "outcome_pages": 8,
            "identities": 512,
            "vectors": 0,
            "expanded_rows": 0,
            "encoded_bytes": 4096,
        }
        self.assertEqual([], outcome_errors(valid, 512))

        for key, value in [
            ("outcome_pages", 512),
            ("identities", 511),
            ("vectors", 25),
            ("expanded_rows", 512),
        ]:
            mutated = dict(valid)
            mutated[key] = value
            self.assertTrue(outcome_errors(mutated, 512))

        missing = dict(valid)
        missing.pop("identities")
        self.assertIn("compact outcome fields missing", outcome_errors(missing, 512))

    def test_complete_evidence_and_derived_report_pass(self):
        raw = valid_raw()
        self.assertEqual([], validate_raw(raw))
        raw_bytes = (json.dumps(raw, indent=2) + "\n").encode()
        report = {
            "execution_state": "executed",
            "acceptance_state": "passed",
            "result": "passed",
            "raw_sha256": hashlib.sha256(raw_bytes).hexdigest(),
            "sample_count": len(raw["samples"]),
            "shape_alarms": 0,
        }
        self.assertEqual([], validate_report(report, raw_bytes, raw))

    def test_rejects_deleted_scale_point_and_browser_row(self):
        raw = valid_raw()
        raw["samples"] = [row for row in raw["samples"] if not (row["runtime"] == "firefox" and row["count"] == 256)]
        self.assertIn("scale matrix/sample cardinality drift", validate_raw(raw))

    def test_rejects_deadline_page_and_shape_tuning(self):
        for path, value in [
            (("contract", "deadline_ms"), 2000),
            (("contract", "page_size"), 128),
            (("shape", "relative_alarm"), 5.0),
        ]:
            raw = valid_raw()
            raw[path[0]][path[1]] = value
            self.assertTrue(validate_raw(raw))

    def test_rejects_unresolved_to_lost_or_passing_relabel(self):
        raw = valid_raw()
        row = raw["samples"][0]
        row["unresolved_identities"] = ["lease-1"]
        row["lost_closed_identities"] = []
        row["raw_sha256"] = digest({key: value for key, value in row.items() if key != "raw_sha256"})
        self.assertIn("sample acceptance relabelled", validate_raw(raw))

        row["unresolved_identities"] = []
        row["lost_closed_identities"] = ["lease-1"]
        row["raw_sha256"] = digest({key: value for key, value in row.items() if key != "raw_sha256"})
        self.assertIn("sample acceptance relabelled", validate_raw(raw))

    def test_rejects_hash_counter_failure_and_endpoint_only_concealment(self):
        mutations = []
        missing_hash = valid_raw()
        missing_hash["samples"][0].pop("raw_sha256")
        mutations.append(missing_hash)
        missing_counter = valid_raw()
        missing_counter["samples"][0]["amplification"].pop("protocol_messages")
        mutations.append(missing_counter)
        relabelled_failure = valid_raw()
        relabelled_failure["retained_failed_trials"][0]["state"] = "passed"
        mutations.append(relabelled_failure)
        endpoint_only = valid_raw()
        endpoint_only["samples"] = [row for row in endpoint_only["samples"] if row["count"] == 512]
        mutations.append(endpoint_only)
        self.assertTrue(all(validate_raw(raw) for raw in mutations))


if __name__ == "__main__":
    unittest.main()
