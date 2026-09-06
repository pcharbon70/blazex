from __future__ import annotations

import copy
import json
import tempfile
import unittest
from pathlib import Path

import validate_bh03_activation as validator


class BH03ActivationValidatorTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.auth = json.loads(validator.AUTHORIZATION.read_text(encoding="utf-8"))
        cls.ledger = json.loads(validator.LEDGER.read_text(encoding="utf-8"))
        cls.contract = json.loads(validator.CONTRACT.read_text(encoding="utf-8"))
        cls.activation = json.loads(validator.ACTIVATION.read_text(encoding="utf-8"))
        cls.index = json.loads(validator.INTEGRATION_INDEX.read_text(encoding="utf-8"))
        cls.completion = json.loads(validator.COMPLETION.read_text(encoding="utf-8"))
        cls.registry = json.loads(validator.REGISTRY.read_text(encoding="utf-8"))
        cls.decision = json.loads(validator.BH02_DECISION.read_text(encoding="utf-8"))
        cls.reconciliation = json.loads(validator.BH02_RECONCILIATION.read_text(encoding="utf-8"))

    def test_current_repository_passes(self) -> None:
        validator.validate()

    def test_rejects_missing_authority(self) -> None:
        auth = copy.deepcopy(self.auth)
        auth["status"] = "pending"
        with self.assertRaisesRegex(validator.ValidationError, "lacks explicit approval"):
            validator.validate_authorization(auth)

    def test_rejects_stale_input(self) -> None:
        auth = copy.deepcopy(self.auth)
        auth["approval_basis"][0]["sha256"] = "0" * 64
        with self.assertRaisesRegex(validator.ValidationError, "stale"):
            validator.validate_authorization(auth)

    def test_rejects_changed_output_set(self) -> None:
        ledger = copy.deepcopy(self.ledger)
        ledger["required_outputs"].pop()
        with self.assertRaisesRegex(validator.ValidationError, "required outputs"):
            validator.validate_ledger(ledger, self.registry, self.decision, self.reconciliation)

    def test_rejects_duplicate_boundary(self) -> None:
        activation = copy.deepcopy(self.activation)
        activation["boundaries"][-1] = copy.deepcopy(activation["boundaries"][0])
        with self.assertRaisesRegex(validator.ValidationError, "incomplete or duplicated"):
            validator.validate_activation(activation, self.contract)

    def test_rejects_implemented_contract(self) -> None:
        contract = copy.deepcopy(self.contract)
        contract["compatibility_identities"][0]["state"] = "implemented"
        with self.assertRaisesRegex(validator.ValidationError, "overclaims implementation"):
            validator.validate_contract(contract)

    def test_rejects_nonempty_execution_evidence(self) -> None:
        index = copy.deepcopy(self.index)
        index["browser_results"] = [{"result": "passed"}]
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            directory = root / "integration/bh-03"
            directory.mkdir(parents=True)
            (directory / "README.md").touch()
            (directory / "integration-index-v0.1.0.json").touch()
            with self.assertRaisesRegex(validator.ValidationError, "not empty"):
                validator.validate_integration(index, root)

    def test_rejects_support_promotion(self) -> None:
        index = copy.deepcopy(self.index)
        index["support_state"] = "supported"
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            directory = root / "integration/bh-03"
            directory.mkdir(parents=True)
            (directory / "README.md").touch()
            (directory / "integration-index-v0.1.0.json").touch()
            with self.assertRaisesRegex(validator.ValidationError, "promotes stability or support"):
                validator.validate_integration(index, root)

    def test_rejects_phase_2_authorization(self) -> None:
        activation = copy.deepcopy(self.activation)
        activation["next_authorized_work"] = "BH-03 Phase 2"
        with self.assertRaisesRegex(validator.ValidationError, "later authority"):
            validator.validate_activation(activation, self.contract)

    def test_rejects_divergent_completion(self) -> None:
        completion = copy.deepcopy(self.completion)
        completion["outcome"]["support_state"] = "supported"
        with self.assertRaisesRegex(validator.ValidationError, "promotes stability or support"):
            validator.validate_completion(completion)


if __name__ == "__main__":
    unittest.main()
