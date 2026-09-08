from __future__ import annotations

import copy
import json
import tempfile
import unittest
from pathlib import Path

import validate_bh02_effects as validator


class BH02EffectsValidatorTest(unittest.TestCase):
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

    def test_rejects_expanded_event_vocabulary(self) -> None:
        contract = copy.deepcopy(self.contract)
        contract["semantic_event"]["names"].append("click")
        with self.assertRaisesRegex(validator.ValidationError, "vocabulary expanded"):
            validator.validate_contract(contract, self.authorization)

    def test_rejects_expanded_capability_operations(self) -> None:
        contract = copy.deepcopy(self.contract)
        contract["capabilities"]["operations"]["time"].append("wall_clock")
        with self.assertRaisesRegex(validator.ValidationError, "operations differ"):
            validator.validate_contract(contract, self.authorization)

    def test_rejects_relaxed_resource_ownership(self) -> None:
        contract = copy.deepcopy(self.contract)
        contract["resource"]["transfer"] = "implicit-any-generation"
        with self.assertRaisesRegex(validator.ValidationError, "transfer ownership"):
            validator.validate_contract(contract, self.authorization)

    def test_rejects_concrete_provider_leakage(self) -> None:
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
            (root / "packages/blazex_effects/lib/provider.ex").write_text(
                "defmodule LeakedProvider do\n  @native HWND\nend\n", encoding="utf-8"
            )
            with self.assertRaisesRegex(validator.ValidationError, "provider/platform leakage"):
                validator.validate_no_concrete_leakage(root)

    def test_rejects_missing_lifecycle_fixture_coverage(self) -> None:
        fixtures = copy.deepcopy(self.fixtures)
        fixtures["scenarios"].pop()
        with self.assertRaisesRegex(validator.ValidationError, "fixture coverage differs"):
            validator.validate_fixtures(self.index, fixtures)

    def test_rejects_provider_or_renderer_results(self) -> None:
        index = copy.deepcopy(self.index)
        index["provider_results"] = [{"provider": "concrete", "result": "passed"}]
        with self.assertRaisesRegex(validator.ValidationError, "results exist prematurely"):
            validator.validate_fixtures(index, self.fixtures)

    def test_rejects_stable_api_or_support_overclaim(self) -> None:
        contract = copy.deepcopy(self.contract)
        contract["api_state"] = "stable"
        with self.assertRaisesRegex(validator.ValidationError, "stable API"):
            validator.validate_contract(contract, self.authorization)

        index = copy.deepcopy(self.index)
        index["support_state"] = "supported"
        with self.assertRaisesRegex(validator.ValidationError, "claims support"):
            validator.validate_fixtures(index, self.fixtures)

    def test_rejects_phase_4_authorization_overclaim(self) -> None:
        completion = copy.deepcopy(self.completion)
        completion["outcome"]["next_phase"] = "BH-02 Phase 4 authorized"
        with self.assertRaisesRegex(validator.ValidationError, "authorization boundary"):
            validator.validate_completion(completion)


if __name__ == "__main__":
    unittest.main()
