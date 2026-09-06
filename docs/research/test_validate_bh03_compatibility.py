from __future__ import annotations

import copy
import hashlib
import json
import tempfile
import unittest
from pathlib import Path

import validate_bh03_compatibility as validator


class BH03CompatibilityValidatorTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.authorization = json.loads(validator.AUTHORIZATION.read_text(encoding="utf-8"))
        cls.contract = json.loads(validator.CONTRACT.read_text(encoding="utf-8"))
        cls.fixtures = json.loads(validator.FIXTURES.read_text(encoding="utf-8"))
        cls.index = json.loads(validator.INTEGRATION_INDEX.read_text(encoding="utf-8"))
        cls.profile = json.loads(validator.PROFILE_MANIFEST.read_text(encoding="utf-8"))
        cls.completion = json.loads(validator.COMPLETION.read_text(encoding="utf-8"))

    def test_current_repository_passes(self) -> None:
        validator.validate()

    def test_rejects_missing_authority(self) -> None:
        authorization = copy.deepcopy(self.authorization)
        authorization["status"] = "pending"
        with self.assertRaisesRegex(validator.ValidationError, "lacks explicit approval"):
            validator.validate_authorization(authorization)

    def test_rejects_stale_predecessor(self) -> None:
        authorization = copy.deepcopy(self.authorization)
        authorization["approval_basis"][0]["sha256"] = "0" * 64
        with self.assertRaisesRegex(validator.ValidationError, "stale"):
            validator.validate_authorization(authorization)

    def test_rejects_changed_identity_table(self) -> None:
        contract = copy.deepcopy(self.contract)
        contract["compatibility"]["required"]["renderer"] = "blazex.renderer/2"
        with self.assertRaisesRegex(validator.ValidationError, "identity table"):
            validator.validate_contract(contract)

    def test_rejects_fixture_execution_overclaim(self) -> None:
        fixtures = copy.deepcopy(self.fixtures)
        fixtures["evidence_boundary"]["runtime_starts"] = 1
        with self.assertRaisesRegex(validator.ValidationError, "overclaims execution"):
            validator.validate_fixtures(fixtures, self.contract)

    def test_rejects_profile_fixture_divergence(self) -> None:
        profile = copy.deepcopy(self.profile)
        profile["generation"] = 2
        with self.assertRaisesRegex(validator.ValidationError, "canonical fixture"):
            validator.validate_profile_manifest(profile, self.fixtures)

    def test_rejects_later_phase_result(self) -> None:
        index = copy.deepcopy(self.index)
        index["browser_results"] = [{"result": "passed"}]
        with self.assertRaisesRegex(validator.ValidationError, "later-phase results"):
            validator.validate_index(index)

    def test_rejects_later_phase_authorization(self) -> None:
        index = copy.deepcopy(self.index)
        index["next_authorized_work"] = "BH-03 Phase 3"
        with self.assertRaisesRegex(validator.ValidationError, "authorizes later work"):
            validator.validate_index(index)

    def test_rejects_stale_artifact_declaration(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            data = b"fixture"
            path = root / "artifact.bin"
            path.write_bytes(data)
            manifest = {"artifacts": [{"id": "fixture", "path": "artifact.bin", "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()}]}
            validator.validate_artifact_declarations(manifest, root)
            manifest["artifacts"][0]["sha256"] = "0" * 64
            with self.assertRaisesRegex(validator.ValidationError, "digest is stale"):
                validator.validate_artifact_declarations(manifest, root)

    def test_rejects_divergent_completion(self) -> None:
        completion = copy.deepcopy(self.completion)
        completion["outcome"]["artifacts_acquired"] = 1
        with self.assertRaisesRegex(validator.ValidationError, "overclaims later-phase evidence"):
            validator.validate_completion(completion)


if __name__ == "__main__":
    unittest.main()
