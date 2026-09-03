from __future__ import annotations

import copy
import importlib.util
import unittest
from pathlib import Path


TOOLCHAIN = Path(__file__).resolve().parents[1]
ROOT = TOOLCHAIN.parents[2]
SPEC = importlib.util.spec_from_file_location("verify_environment", TOOLCHAIN / "verify_environment.py")
VERIFY = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(VERIFY)


class EnvironmentQualificationTest(unittest.TestCase):
    def setUp(self) -> None:
        self.environment = VERIFY.load(TOOLCHAIN / "environment.lock.json")
        self.browsers = VERIFY.load(TOOLCHAIN / "browser.lock.json")
        self.policy = VERIFY.load(TOOLCHAIN / "acquisition-policy.json")
        self.package = VERIFY.load(ROOT / "js/blazex_runtime/package.json")
        self.package_lock = VERIFY.load(ROOT / "js/blazex_runtime/package-lock.json")

    def validate(self, **changes):
        values = {
            "environment": copy.deepcopy(self.environment),
            "browsers": copy.deepcopy(self.browsers),
            "policy": copy.deepcopy(self.policy),
            "package": copy.deepcopy(self.package),
            "package_lock": copy.deepcopy(self.package_lock),
        }
        values.update(changes)
        return VERIFY.validate_all(**values)

    def test_canonical_inputs_pass(self):
        self.assertEqual([], self.validate())

    def test_floating_tool_version_fails(self):
        environment = copy.deepcopy(self.environment)
        environment["tools"][0]["version"] = "latest"
        self.assertTrue(self.validate(environment=environment))

    def test_hashless_source_fails(self):
        environment = copy.deepcopy(self.environment)
        del environment["tools"][0]["sha256"]
        self.assertTrue(self.validate(environment=environment))

    def test_unpinned_image_fails(self):
        environment = copy.deepcopy(self.environment)
        environment["images"][0]["reference"] = "hexpm/elixir:latest"
        self.assertTrue(self.validate(environment=environment))

    def test_stale_js_lock_fails(self):
        package_lock = copy.deepcopy(self.package_lock)
        package_lock["packages"][""]["devDependencies"]["esbuild"] = "0.0.0"
        self.assertTrue(self.validate(package_lock=package_lock))

    def test_managed_browser_without_engine_fingerprint_fails(self):
        browsers = copy.deepcopy(self.browsers)
        browsers["managed_fingerprint_profiles"][0]["required_per_run"].remove("engine_version")
        self.assertTrue(self.validate(browsers=browsers))

    def test_unapproved_lifecycle_entry_fails(self):
        policy = copy.deepcopy(self.policy)
        policy["npm"]["lifecycle_allowlist"].append({"package": "unknown", "version": "1.0.0"})
        self.assertTrue(self.validate(policy=policy))


if __name__ == "__main__":
    unittest.main()
