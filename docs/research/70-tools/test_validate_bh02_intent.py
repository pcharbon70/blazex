from __future__ import annotations

import copy
import json
import tempfile
import unittest
from pathlib import Path

import validate_bh02_intent as validator


class BH02IntentValidatorTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.authorization = json.loads(validator.AUTHORIZATION.read_text(encoding="utf-8"))
        cls.contract = json.loads(validator.CONTRACT.read_text(encoding="utf-8"))
        cls.index = json.loads(validator.CONFORMANCE_INDEX.read_text(encoding="utf-8"))
        cls.fixtures = json.loads(validator.FIXTURES.read_text(encoding="utf-8"))
        cls.completion = json.loads(validator.COMPLETION.read_text(encoding="utf-8"))

    def test_current_repository_passes(self) -> None:
        validator.validate()

    def test_rejects_stale_or_missing_authorization(self) -> None:
        authorization = copy.deepcopy(self.authorization)
        authorization["status"] = "pending"
        with self.assertRaisesRegex(validator.ValidationError, "lacks explicit approval"):
            validator.validate_authorization(authorization)

    def test_rejects_expanded_token_or_layout_vocabulary(self) -> None:
        contract = copy.deepcopy(self.contract)
        contract["token_reference"]["categories"].append("stylesheet")
        with self.assertRaisesRegex(validator.ValidationError, "token vocabulary expanded"):
            validator.validate_contract(contract, self.authorization)

        contract = copy.deepcopy(self.contract)
        contract["layout"]["modes"].append("flexbox")
        with self.assertRaisesRegex(validator.ValidationError, "layout modes expanded"):
            validator.validate_contract(contract, self.authorization)

    def test_rejects_expanded_accessibility_vocabulary(self) -> None:
        contract = copy.deepcopy(self.contract)
        contract["accessibility"]["roles"].append("platform_widget")
        with self.assertRaisesRegex(validator.ValidationError, "roles expanded"):
            validator.validate_contract(contract, self.authorization)

    def test_rejects_relaxed_annotation_ownership(self) -> None:
        contract = copy.deepcopy(self.contract)
        contract["intent_set"]["owner_rule"] = "best-effort"
        with self.assertRaisesRegex(validator.ValidationError, "ownership differs"):
            validator.validate_contract(contract, self.authorization)

    def test_rejects_concrete_layout_or_accessibility_leakage(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            for relative in (
                "packages/blazex_core/lib",
                "packages/blazex_ui_tree/lib",
                "packages/blazex_effects/lib",
            ):
                source_root = root / relative
                source_root.mkdir(parents=True)
                (source_root / "boundary.ex").write_text("defmodule SafeBoundary do\nend\n", encoding="utf-8")
            (root / "packages/blazex_ui_tree/lib/layout.ex").write_text(
                "defmodule LeakedLayout do\n  @engine Taffy\nend\n", encoding="utf-8"
            )
            with self.assertRaisesRegex(validator.ValidationError, "layout/accessibility/platform leakage"):
                validator.validate_no_concrete_leakage(root)

    def test_rejects_missing_intent_fixture_coverage(self) -> None:
        fixtures = copy.deepcopy(self.fixtures)
        fixtures["scenarios"].pop()
        with self.assertRaisesRegex(validator.ValidationError, "fixture coverage differs"):
            validator.validate_fixtures(self.index, fixtures)

    def test_rejects_geometry_or_platform_results(self) -> None:
        index = copy.deepcopy(self.index)
        index["geometry_results"] = [{"engine": "concrete", "result": "passed"}]
        with self.assertRaisesRegex(validator.ValidationError, "premature concrete result"):
            validator.validate_fixtures(index, self.fixtures)

        index = copy.deepcopy(self.index)
        index["accessibility_mapping_results"] = [{"platform": "concrete", "result": "passed"}]
        with self.assertRaisesRegex(validator.ValidationError, "premature concrete result"):
            validator.validate_fixtures(index, self.fixtures)

    def test_rejects_stable_api_or_support_overclaim(self) -> None:
        contract = copy.deepcopy(self.contract)
        contract["api_state"] = "stable"
        with self.assertRaisesRegex(validator.ValidationError, "stable API"):
            validator.validate_contract(contract, self.authorization)

        fixtures = copy.deepcopy(self.fixtures)
        fixtures["support_state"] = "supported"
        with self.assertRaisesRegex(validator.ValidationError, "claim support"):
            validator.validate_fixtures(self.index, fixtures)

    def test_rejects_phase_5_authorization_overclaim(self) -> None:
        completion = copy.deepcopy(self.completion)
        completion["outcome"]["next_phase"] = "BH-02 Phase 5 authorized"
        with self.assertRaisesRegex(validator.ValidationError, "authorization boundary"):
            validator.validate_completion(completion)


if __name__ == "__main__":
    unittest.main()
