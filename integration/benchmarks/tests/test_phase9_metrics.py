from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("phase9_metrics", ROOT / "phase9_metrics.py")
METRICS = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(METRICS)


class Phase9MetricTests(unittest.TestCase):
    def setUp(self) -> None:
        self.definitions = {
            "BX-BH01-METRIC-TEST": {
                "unit": "milliseconds",
                "cache_states": ["warm"],
            }
        }
        self.measurements = [{
            "metric_id": "BX-BH01-METRIC-TEST",
            "unit": "milliseconds",
            "cache_state": "warm",
            "samples": [
                {"iteration": 1, "value": 1.0},
                {"iteration": 2, "value": 2.0},
                {"iteration": 3, "value": 20.0},
            ],
        }]

    def test_nearest_rank_is_deterministic(self) -> None:
        self.assertEqual(20.0, METRICS.nearest_rank([2, 20, 1], 95))

    def test_summary_retains_tail_and_variance(self) -> None:
        summary = METRICS.summarize([1, 2, 20])
        self.assertEqual(3, summary["count"])
        self.assertEqual(2.0, summary["median"])
        self.assertEqual(20.0, summary["p95"])
        self.assertGreater(summary["coefficient_of_variation_percent"], 100)

    def test_measurement_contract_passes(self) -> None:
        METRICS.validate_measurements(self.measurements, self.definitions)

    def test_unknown_metric_fails(self) -> None:
        self.measurements[0]["metric_id"] = "BX-BH01-METRIC-UNKNOWN"
        with self.assertRaisesRegex(ValueError, "unknown metric"):
            METRICS.validate_measurements(self.measurements, self.definitions)

    def test_duplicate_sample_fails(self) -> None:
        self.measurements[0]["samples"].append({"iteration": 1, "value": 3.0})
        with self.assertRaisesRegex(ValueError, "duplicate sample"):
            METRICS.validate_measurements(self.measurements, self.definitions)

    def test_negative_sample_fails(self) -> None:
        self.measurements[0]["samples"][0]["value"] = -1
        with self.assertRaisesRegex(ValueError, "invalid sample value"):
            METRICS.validate_measurements(self.measurements, self.definitions)


if __name__ == "__main__":
    unittest.main()
