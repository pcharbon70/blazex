from __future__ import annotations

import copy
import importlib.util
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("conduct_phase10_reviews", ROOT / "conduct_phase10_reviews.py")
REVIEWS = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(REVIEWS)


class FeasibilityReviewTest(unittest.TestCase):
    def setUp(self):
        self.record = REVIEWS.build()

    def test_canonical_review_passes(self):
        self.assertEqual([], REVIEWS.validate(self.record))

    def test_missing_lens_fails(self):
        value = copy.deepcopy(self.record)
        value["lenses"].pop()
        self.assertTrue(REVIEWS.validate(value))

    def test_lens_without_challenge_fails(self):
        value = copy.deepcopy(self.record)
        value["lenses"][0]["challenges"] = []
        self.assertTrue(REVIEWS.validate(value))

    def test_unknown_condition_fails(self):
        value = copy.deepcopy(self.record)
        value["lenses"][0]["conditions"] = ["unknown"]
        self.assertTrue(REVIEWS.validate(value))

    def test_support_or_bh02_promotion_fails(self):
        value = copy.deepcopy(self.record)
        value["decision"]["support_status"] = "supported"
        value["decision"]["bh02_authorized"] = True
        self.assertTrue(REVIEWS.validate(value))


if __name__ == "__main__":
    unittest.main()
