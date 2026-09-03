from __future__ import annotations

import copy
import importlib.util
import unittest
from pathlib import Path


TOOLCHAIN = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("verify_server", TOOLCHAIN / "verify_server.py")
VERIFY = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(VERIFY)


class ServerQualificationTest(unittest.TestCase):
    def setUp(self):
        self.values = list(VERIFY.inputs())

    def validate(self, index=None, value=None):
        values = copy.deepcopy(self.values)
        if index is not None:
            values[index] = value
        return VERIFY.validate(*values)

    def test_canonical_server_graph_passes(self):
        self.assertEqual([], self.validate())

    def test_stale_lock_entry_fails(self):
        lock = self.values[5].replace("%{", '%{\n  "stale": {:hex, :stale, "1.0.0", "x", [:mix], [], "hexpm", "' + "a" * 64 + '"},', 1)
        self.assertTrue(self.validate(5, lock))

    def test_changed_package_checksum_fails(self):
        dependencies = copy.deepcopy(self.values[0])
        dependencies["packages"][0][2] = "0" * 64
        self.assertTrue(self.validate(0, dependencies))

    def test_unknown_license_fails(self):
        dependencies = copy.deepcopy(self.values[0])
        dependencies["packages"][0][3] = "UNKNOWN"
        self.assertTrue(self.validate(0, dependencies))

    def test_phoenix_in_plug_closure_fails(self):
        boundaries = copy.deepcopy(self.values[1])
        boundaries["plug_boundary"]["closure"].append("phoenix 1.8.13")
        self.assertTrue(self.validate(1, boundaries))

    def test_private_api_owner_drift_fails(self):
        inventory = copy.deepcopy(self.values[2])
        inventory["entry_defaults"]["owner"] = "packages/blazex_core"
        self.assertTrue(self.validate(2, inventory))

    def test_missing_private_surface_fails(self):
        fixture = copy.deepcopy(self.values[3])
        del fixture["surfaces"]["diff"]
        self.assertTrue(self.validate(3, fixture))

    def test_missing_isolation_header_fails(self):
        prerequisites = copy.deepcopy(self.values[4])
        del prerequisites["profile_prerequisites"]["cross_origin_isolation"]["headers"]["Cross-Origin-Embedder-Policy"]
        self.assertTrue(self.validate(4, prerequisites))


if __name__ == "__main__":
    unittest.main()
