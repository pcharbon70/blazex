import copy
import unittest
import validate_bh03_correction as gate


class CorrectionTests(unittest.TestCase):
    def test_current_decision_and_recovery(self):
        gate.validate_decision(gate.artifact("acceptance"))
        gate.validate_recovery(gate.artifact("recovery"))

    def test_decision_mutations(self):
        for mutate in [
            lambda d: d.update(decision="revise"),
            lambda d: d.update(closed_finding="unrelated"),
            lambda d: d.update(next_authorized_work="BH-04"),
            lambda d: d.update(support_state="supported"),
            lambda d: d.update(api_state="stable"),
            lambda d: d["required_outputs"].pop(),
            lambda d: d["carried_obligations"].pop(),
            lambda d: d["review_lenses"].pop("security"),
            lambda d: d.update(release_budgets=["qualified"]),
        ]:
            decision = gate.artifact("acceptance")
            mutate(decision)
            with self.subTest(decision=decision["decision"]), self.assertRaises(gate.ValidationError):
                gate.validate_decision(decision)

    def test_recovery_mutations(self):
        for mutate in [
            lambda e: e.update(implementation_revision="working-tree"),
            lambda e: e["results"].pop(),
            lambda e: e["results"][0].update(result="failed"),
            lambda e: e["results"][0]["observations"].pop(),
            lambda e: e["results"][0]["observations"][0]["recovered"].update(runtime_starts=3),
            lambda e: e["results"][0]["observations"][0]["recovered"].update(runtime_acknowledgement_count=8),
            lambda e: e["results"][0]["observations"][0]["terminal"]["fallback"].update(partial_activation=True),
            lambda e: e["results"][0]["observations"][0].update(frames_after_terminal=1),
            lambda e: e["results"][0]["observations"][1]["terminal"].update(state="recovering"),
            lambda e: e.update(harness_sha256="0" * 64),
        ]:
            evidence = copy.deepcopy(gate.artifact("recovery"))
            mutate(evidence)
            with self.subTest(), self.assertRaises(gate.ValidationError):
                gate.validate_recovery(evidence)

    def test_current_bindings_never_use_historical_exceptions(self):
        path = "js/blazex_runtime/src/runtime-startup.js"
        with self.assertRaises(gate.ValidationError):
            gate.bindings([{"path": path, "sha256": "0" * 64}], [path])
        with self.assertRaises(gate.ValidationError):
            gate.bindings([], [path])


if __name__ == "__main__":
    unittest.main()
