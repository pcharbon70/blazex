from __future__ import annotations

import copy
import importlib.util
import unittest
from pathlib import Path


RUNTIME = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("verify_runtime_build", RUNTIME / "verify_runtime_build.py")
VERIFY = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(VERIFY)


class RuntimeBuildContractTest(unittest.TestCase):
    def setUp(self):
        self.contract = VERIFY.load(RUNTIME / "build-contract.json")
        self.patches = VERIFY.load(RUNTIME / "patches/manifest.json")
        self.manifest = VERIFY.load(RUNTIME / "runtime-binary-manifest.json")
        self.classification = VERIFY.load(RUNTIME / "adapter-classification.json")

    def validate(self, contract=None, patches=None, manifest=False, classification=None):
        observed = copy.deepcopy(self.manifest) if manifest is True else manifest or None
        return VERIFY.validate(
            contract or copy.deepcopy(self.contract),
            patches or copy.deepcopy(self.patches),
            observed,
            classification or copy.deepcopy(self.classification),
        )

    def test_canonical_contract_passes_without_observed_manifest(self):
        self.assertEqual([], self.validate())

    def test_canonical_observed_manifest_passes(self):
        self.assertEqual([], self.validate(manifest=True))

    def test_floating_image_fails(self):
        contract = copy.deepcopy(self.contract)
        contract["image"]["reference"] = "emscripten/emsdk:latest"
        self.assertTrue(self.validate(contract=contract))

    def test_hashless_discovered_tool_fails(self):
        contract = copy.deepcopy(self.contract)
        contract["inputs"]["gperf"]["sha256"] = ""
        self.assertTrue(self.validate(contract=contract))

    def test_networked_build_fails(self):
        contract = copy.deepcopy(self.contract)
        contract["environment"]["network_during_cache_seed_configure_compile_link_package"] = True
        self.assertTrue(self.validate(contract=contract))

    def test_deployable_node_probe_fails(self):
        contract = copy.deepcopy(self.contract)
        contract["modes"][2]["deployable"] = True
        self.assertTrue(self.validate(contract=contract))

    def test_undeclared_import_module_fails(self):
        manifest = copy.deepcopy(self.manifest)
        manifest["wasm_inspections"][0]["import_modules"].append("surprise")
        self.assertTrue(self.validate(manifest=manifest))

    def test_unbounded_memory_fails(self):
        manifest = copy.deepcopy(self.manifest)
        manifest["wasm_inspections"][0]["memory_imports"][0]["limits"]["maximum"] = None
        self.assertTrue(self.validate(manifest=manifest))

    def test_missing_adapter_classification_fails(self):
        classification = copy.deepcopy(self.classification)
        classification["surfaces"].pop()
        self.assertTrue(self.validate(classification=classification))


if __name__ == "__main__":
    unittest.main()
