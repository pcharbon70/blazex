from __future__ import annotations

import copy
import json
import tempfile
import unittest
from pathlib import Path

import validate_bh02_activation as validator


class BH02ActivationValidatorTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.authorization = json.loads(validator.AUTHORIZATION.read_text(encoding="utf-8"))
        cls.ledger = json.loads(validator.LEDGER.read_text(encoding="utf-8"))
        cls.entry = json.loads(validator.ENTRY.read_text(encoding="utf-8"))
        cls.activation = json.loads(validator.ACTIVATION.read_text(encoding="utf-8"))

    def test_current_repository_passes(self) -> None:
        validator.validate()

    def test_rejects_missing_owner_authorization(self) -> None:
        auth = copy.deepcopy(self.authorization)
        auth["status"] = "pending"
        with self.assertRaisesRegex(validator.ValidationError, "lacks explicit approval"):
            validator.validate_authorization(auth)

    def test_rejects_incomplete_condition_handoff(self) -> None:
        ledger = copy.deepcopy(self.ledger)
        ledger["inherited_condition_ids"].pop()
        with self.assertRaisesRegex(validator.ValidationError, "conditions diverge"):
            validator.validate_ledger(ledger, self.entry)

    def test_rejects_extra_activation_boundary(self) -> None:
        activation = copy.deepcopy(self.activation)
        activation["boundaries"].append(copy.deepcopy(activation["boundaries"][0]))
        with self.assertRaisesRegex(validator.ValidationError, "exactly nine"):
            validator.validate_activation(activation)

    def test_rejects_forbidden_portable_source(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            project = Path(temporary)
            (project / "lib").mkdir()
            (project / "test").mkdir()
            (project / "mix.exs").write_text("defmodule Safe.MixProject do\nend\n", encoding="utf-8")
            (project / "lib/leak.ex").write_text("defmodule Leak do\n  @value :dom\nend\n", encoding="utf-8")
            with self.assertRaisesRegex(validator.ValidationError, "browser/server/runtime object"):
                validator.scan_forbidden_sources(project)

    def test_rejects_unapproved_mix_dependency(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            project = Path(temporary)
            (project / "mix.exs").write_text(
                "defmodule Unsafe.MixProject do\n  defp deps, do: [{:phoenix, git: \"https://example.invalid/repo\"}]\nend\n",
                encoding="utf-8",
            )
            with self.assertRaisesRegex(validator.ValidationError, "external dependency"):
                validator.validate_mix_dependencies(project, [])

    def test_rejects_native_support_overclaim(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            conformance_path = root / validator.CONFORMANCE_INDEX.relative_to(validator.REPO_ROOT)
            experiment_path = root / validator.EXPERIMENT_INDEX.relative_to(validator.REPO_ROOT)
            conformance_path.parent.mkdir(parents=True)
            experiment_path.parent.mkdir(parents=True)
            conformance = json.loads(validator.CONFORMANCE_INDEX.read_text(encoding="utf-8"))
            experiment = json.loads(validator.EXPERIMENT_INDEX.read_text(encoding="utf-8"))
            experiment["support_state"] = "supported"
            conformance_path.write_text(json.dumps(conformance), encoding="utf-8")
            experiment_path.write_text(json.dumps(experiment), encoding="utf-8")
            with self.assertRaisesRegex(validator.ValidationError, "native support is overclaimed"):
                validator.validate_evidence_indexes(root)


if __name__ == "__main__":
    unittest.main()
