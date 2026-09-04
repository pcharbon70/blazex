from __future__ import annotations

import copy
import importlib.util
import unittest
from pathlib import Path


TOOLCHAIN = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "verify_phase6_boundaries", TOOLCHAIN / "verify_phase6_boundaries.py"
)
VERIFY = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(VERIFY)


class Phase6BoundaryTest(unittest.TestCase):
    def setUp(self):
        self.values = list(VERIFY.inputs())

    def validate(self, index=None, value=None):
        values = copy.deepcopy(self.values)
        if index is not None:
            values[index] = value
        return VERIFY.validate(*values)

    def test_canonical_boundaries_pass(self):
        self.assertEqual([], self.validate())

    def test_fixture_dependency_drift_fails(self):
        self.assertTrue(self.validate(6, {"popcorn", "phoenix_live_view"}))

    def test_standalone_import_fails(self):
        sources = copy.deepcopy(self.values[4])
        sources["fixture.ex"] = "alias Phoenix.LiveView.Socket"
        self.assertTrue(self.validate(4, sources))

    def test_server_authority_adapter_import_fails(self):
        sources = copy.deepcopy(self.values[5])
        sources["authority.ex"] = "alias BlazeX.Renderer.DOM.LiveView"
        self.assertTrue(self.validate(5, sources))

    def test_plug_transitive_liveview_fails(self):
        plug = copy.deepcopy(self.values[1])
        plug["closure"].append("phoenix_live_view 1.2.11")
        self.assertTrue(self.validate(1, plug))

    def test_headless_browser_dependency_fails(self):
        headless = copy.deepcopy(self.values[2])
        headless["allowed_local_dependencies"].append("blazex_host_browser")
        self.assertTrue(self.validate(2, headless))

    def test_package_manifest_dependency_fails(self):
        manifests = copy.deepcopy(self.values[3])
        manifests["blazex_renderer_dom"]["dependencies"] = ["blazex_renderer_dom_liveview"]
        self.assertTrue(self.validate(3, manifests))


if __name__ == "__main__":
    unittest.main()
