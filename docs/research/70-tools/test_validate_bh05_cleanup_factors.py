import copy
import unittest

from validate_bh05_cleanup_factors import COUNTS, PROFILES, validate_browser, validate_result


def sample(profile, count):
    bytes_by_width = 36000 if profile in ["identifier_only", "maximum"] else 20000
    if profile == "inventory_only":
        bytes_by_width = 5600
    return {
        "payload_class": profile,
        "count": count,
        "execution_state": "executed",
        "acceptance_state": "passed",
        "elapsed_ms": 50,
        "exceeded_deadline": False,
        "terminal_leases": 0,
        "unresolved_identities": [],
        "amplification": {
            "page_size": 64,
            "maximum_page_size": 128,
            "runtime_owned_inventory": True,
            "inventory_before": count,
            "inventory_after": 0,
            "normal_worker_starts": 0,
        },
        "stage_timings_ms": {"total": 50},
        "outcome_format": {
            "version": 2,
            "outcome_pages": (count + 63) // 64,
            "identities": count,
            "vectors": 0,
            "owner_records": 0,
            "expanded_rows": 0,
            "encoded_bytes": bytes_by_width,
            "retained_outcome_bytes": bytes_by_width,
            "retained_owner_records": 0,
        },
    }


def result():
    return {
        "execution_state": "executed",
        "acceptance_state": "passed",
        "factor_profiles": PROFILES,
        "samples": [sample(profile, count) for profile in PROFILES for count in COUNTS],
    }


class CleanupFactorEvidenceTest(unittest.TestCase):
    def test_complete_factor_matrix_passes(self):
        self.assertEqual([], validate_result(result()))

    def test_missing_factor_or_count_fails(self):
        value = result()
        value["samples"].pop()
        self.assertIn("factor sample matrix drift", validate_result(value))

    def test_owner_retention_and_size_dependence_fail(self):
        value = result()
        target = next(row for row in value["samples"] if row["payload_class"] == "owner_depth_only")
        target["outcome_format"]["owner_records"] = 512
        target["outcome_format"]["retained_owner_records"] = 512
        target["outcome_format"]["encoded_bytes"] = 99999
        target["outcome_format"]["retained_outcome_bytes"] = 99999
        errors = validate_result(value)
        self.assertIn("successful owner records retained", errors)
        self.assertIn("successful outcome still scales with owner or payload shape", errors)

    def test_deadline_unresolved_and_inventory_drift_fail(self):
        for path, replacement in [
            (("elapsed_ms",), 1001),
            (("unresolved_identities",), ["lease-1"]),
            (("amplification", "inventory_after"), 1),
            (("amplification", "page_size"), 128),
        ]:
            value = result()
            row = value["samples"][0]
            if len(path) == 1:
                row[path[0]] = replacement
            else:
                row[path[0]][path[1]] = replacement
            self.assertTrue(validate_result(value), path)

    def test_browser_matrix_and_support_state_fail_closed(self):
        record = {
            "phase": 16,
            "support_state": "unsupported",
            "results": [dict(result(), browser="chrome"), dict(result(), browser="firefox")],
        }
        self.assertEqual([], validate_browser(record))
        for mutation in [
            lambda value: value.update(support_state="supported"),
            lambda value: value["results"].pop(),
        ]:
            changed = copy.deepcopy(record)
            mutation(changed)
            self.assertTrue(validate_browser(changed))


if __name__ == "__main__":
    unittest.main()
