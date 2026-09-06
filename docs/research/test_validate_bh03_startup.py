from __future__ import annotations

import copy
import json
import tempfile
import unittest
from pathlib import Path

import validate_bh03_startup as validator


class BH03StartupValidatorTest(unittest.TestCase):
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

    def test_rejects_non_atomic_contract(self) -> None:
        contract = copy.deepcopy(self.contract)
        contract["acquisition"]["publication"] = "incremental"
        with self.assertRaisesRegex(validator.ValidationError, "not atomic"):
            validator.validate_contract(contract)

    def test_rejects_corrupt_fixture_payload(self) -> None:
        fixtures = copy.deepcopy(self.fixtures)
        fixtures["artifact_payloads"][0]["base64"] = "AA=="
        with self.assertRaisesRegex(validator.ValidationError, "size diverges"):
            validator.validate_fixtures(fixtures)

    def test_rejects_later_result(self) -> None:
        index = copy.deepcopy(self.index)
        index["browser_results"] = [{"result": "passed"}]
        with self.assertRaisesRegex(validator.ValidationError, "later execution results"):
            validator.validate_index(index)

    def test_rejects_profile_artifact_drift(self) -> None:
        profile = copy.deepcopy(self.profile)
        profile["artifacts"][0]["sha256"] = "0" * 64
        with self.assertRaisesRegex(validator.ValidationError, "digest is stale"):
            validator.validate_profile_artifacts(profile)

    def test_rejects_oversized_profile_artifact(self) -> None:
        profile = copy.deepcopy(self.profile)
        profile["artifacts"][0]["bytes"] = validator.LIMITS["runtime-module"] + 1
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            static = root / "profiles/browser_phoenix/priv/static/bh01/artifacts"
            static.mkdir(parents=True)
            for artifact in profile["artifacts"]:
                path = static / Path(artifact["path"]).name
                path.write_bytes(b"x" * min(artifact["bytes"], 16))
                artifact["bytes"] = path.stat().st_size
                artifact["sha256"] = validator._sha256(path)
            profile["artifacts"][0]["bytes"] = validator.LIMITS["runtime-module"] + 1
            with self.assertRaisesRegex(validator.ValidationError, "size is stale"):
                validator.validate_profile_artifacts(profile, root)

    def test_rejects_divergent_completion(self) -> None:
        completion = copy.deepcopy(self.completion)
        completion["outcome"]["browser_results"] = 1
        with self.assertRaisesRegex(validator.ValidationError, "overclaims later evidence"):
            validator.validate_completion(completion)


if __name__ == "__main__":
    unittest.main()
