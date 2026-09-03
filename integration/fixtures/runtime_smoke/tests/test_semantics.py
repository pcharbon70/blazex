from __future__ import annotations

import copy
import importlib.util
import unittest
from pathlib import Path


HERE = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("run_probe", HERE / "run_probe.py")
PROBE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(PROBE)


class RuntimeSemanticsContractTest(unittest.TestCase):
    def setUp(self):
        self.contract = PROBE.load(HERE / "semantics-contract.json")
        self.evidence = PROBE.load(HERE.parent / "raw-evidence/bh01-phase3-runtime-semantics.json")
        self.manifest = PROBE.load(HERE / "bundle-manifest.json")
        self.output = "\n".join(
            [
                f"{{bxtrace,[{{sequence,{index}}},{{result,{result}}},{{cleanup,pending}}]}}"
                for index, result in enumerate(self.contract["required_results"][:-1], 1)
            ]
            + [
                f"{{bxtrace,[{{sequence,{len(self.contract['required_results'])}}},{{result,shutdown}},{{cleanup,complete}}]}}",
                '{bxidentity,[{machine,"ATOM"}]}',
                "{bxobservation,[{message_queue_len,0}]}",
                "Return value: ok",
                "BXHARNESS|memory_pages=256",
            ]
        )

    def test_canonical_output_passes(self):
        self.assertEqual([], PROBE.validate_output(copy.deepcopy(self.contract), self.output, 0))

    def test_missing_result_fails(self):
        self.assertTrue(PROBE.validate_output(self.contract, self.output.replace("worker_restarted", "missing"), 0))

    def test_failed_trace_fails(self):
        self.assertTrue(PROBE.validate_output(self.contract, self.output + "\n{result,failed}", 0))

    def test_nonzero_runtime_fails(self):
        self.assertTrue(PROBE.validate_output(self.contract, self.output, 1))

    def test_canonical_evidence_passes(self):
        self.assertEqual([], PROBE.validate_evidence(self.contract, self.evidence, self.manifest))

    def test_evidence_bundle_drift_fails(self):
        evidence = copy.deepcopy(self.evidence)
        evidence["tool_identities"][2]["sha256"] = "0" * 64
        self.assertTrue(PROBE.validate_evidence(self.contract, evidence, self.manifest))


if __name__ == "__main__":
    unittest.main()
