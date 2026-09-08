from __future__ import annotations

import copy
import json
import tempfile
import unittest
from pathlib import Path

import validate_bh02_semantics as validator


class BH02SemanticsValidatorTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.authorization = json.loads(validator.AUTHORIZATION.read_text(encoding="utf-8"))
        cls.contract = json.loads(validator.CONTRACT.read_text(encoding="utf-8"))
        cls.index = json.loads(validator.CONFORMANCE_INDEX.read_text(encoding="utf-8"))
        cls.fixtures = json.loads(validator.FIXTURES.read_text(encoding="utf-8"))

    def test_current_repository_passes(self) -> None:
        validator.validate()

    def test_rejects_stale_or_missing_authorization(self) -> None:
        authorization = copy.deepcopy(self.authorization)
        authorization["status"] = "pending"
        with self.assertRaisesRegex(validator.ValidationError, "lacks explicit approval"):
            validator.validate_authorization(authorization)

    def test_rejects_expanded_node_vocabulary(self) -> None:
        contract = copy.deepcopy(self.contract)
        contract["semantic_tree"]["node_kinds"].append("browser-node")
        with self.assertRaisesRegex(validator.ValidationError, "vocabulary expanded"):
            validator.validate_contract(contract, self.authorization)

    def test_rejects_relaxed_opaque_identity_policy(self) -> None:
        contract = copy.deepcopy(self.contract)
        contract["identity"]["forbidden_key_terms"].remove("pid")
        with self.assertRaisesRegex(validator.ValidationError, "opaque identity"):
            validator.validate_contract(contract, self.authorization)

    def test_rejects_concrete_adapter_leakage(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            core = root / "packages/blazex_core/lib/blazex/core"
            tree = root / "packages/blazex_ui_tree/lib/blazex/ui_tree"
            core.mkdir(parents=True)
            tree.mkdir(parents=True)
            (core / "identity.ex").write_text("defmodule Identity do\n  @adapter Phoenix\nend\n", encoding="utf-8")
            (core / "evaluator.ex").write_text(":mount :update :replace\n", encoding="utf-8")
            (tree / "node.ex").write_text(
                "@kinds [:text, :group, :action, :field, :selection, :collection, :surface]\n"
                "defstruct [:version, :kind, :identity, :key, :content, :children]\n",
                encoding="utf-8",
            )
            for project in (root / "packages/blazex_core", root / "packages/blazex_ui_tree"):
                (project / "mix.exs").write_text("defmodule SafeProject do\nend\n", encoding="utf-8")
            with self.assertRaisesRegex(validator.ValidationError, "adapter/platform leakage"):
                validator.validate_sources(root)

    def test_rejects_missing_fixture_coverage(self) -> None:
        fixtures = copy.deepcopy(self.fixtures)
        fixtures["scenarios"].pop()
        with self.assertRaisesRegex(validator.ValidationError, "fixture coverage differs"):
            validator.validate_fixtures(self.index, fixtures)

    def test_rejects_stable_api_overclaim(self) -> None:
        contract = copy.deepcopy(self.contract)
        contract["api_state"] = "stable"
        with self.assertRaisesRegex(validator.ValidationError, "stable API"):
            validator.validate_contract(contract, self.authorization)

    def test_rejects_renderer_or_support_overclaim(self) -> None:
        index = copy.deepcopy(self.index)
        index["backend_results"] = [{"backend": "headless", "result": "passed"}]
        with self.assertRaisesRegex(validator.ValidationError, "renderer results"):
            validator.validate_fixtures(index, self.fixtures)

        index = copy.deepcopy(self.index)
        index["support_state"] = "supported"
        with self.assertRaisesRegex(validator.ValidationError, "claims support"):
            validator.validate_fixtures(index, self.fixtures)


if __name__ == "__main__":
    unittest.main()
