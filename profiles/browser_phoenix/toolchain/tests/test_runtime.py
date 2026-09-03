from __future__ import annotations

import copy
import importlib.util
import unittest
from pathlib import Path


TOOLCHAIN = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("verify_runtime", TOOLCHAIN / "verify_runtime.py")
VERIFY = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(VERIFY)


class RuntimeQualificationTest(unittest.TestCase):
    def setUp(self):
        self.runtime = VERIFY.load(TOOLCHAIN / "runtime.lock.json")
        self.provenance = VERIFY.load(TOOLCHAIN / "runtime-provenance.json")
        self.environment = VERIFY.load(TOOLCHAIN / "environment.lock.json")

    def validate(self, runtime=None, provenance=None, environment=None):
        return VERIFY.validate(
            runtime or copy.deepcopy(self.runtime),
            provenance or copy.deepcopy(self.provenance),
            environment or copy.deepcopy(self.environment),
        )

    def test_canonical_runtime_passes(self):
        self.assertEqual([], self.validate())

    def test_floating_commit_fails(self):
        runtime = copy.deepcopy(self.runtime)
        runtime["sources"][1]["commit"] = "main"
        self.assertTrue(self.validate(runtime=runtime))

    def test_networked_fetchcontent_fails(self):
        runtime = copy.deepcopy(self.runtime)
        runtime["build_contract"]["cmake_options"]["FETCHCONTENT_FULLY_DISCONNECTED"] = "OFF"
        self.assertTrue(self.validate(runtime=runtime))

    def test_missing_runtime_asset_hash_fails(self):
        runtime = copy.deepcopy(self.runtime)
        runtime["packaged_runtime_assets"][0]["sha256"] = ""
        self.assertTrue(self.validate(runtime=runtime))

    def test_missing_thread_requirement_fails(self):
        runtime = copy.deepcopy(self.runtime)
        runtime["wasm_requirements"]["threads"] = False
        self.assertTrue(self.validate(runtime=runtime))

    def test_unknown_license_fails(self):
        provenance = copy.deepcopy(self.provenance)
        provenance["license_disposition"]["unknown_licenses"].append("mystery")
        self.assertTrue(self.validate(provenance=provenance))


if __name__ == "__main__":
    unittest.main()
