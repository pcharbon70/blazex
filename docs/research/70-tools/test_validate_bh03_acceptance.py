import copy
import unittest
import validate_bh03_acceptance as gate


class AcceptanceTests(unittest.TestCase):
    def test_current_review_is_valid_but_requires_revision(self):
        self.assertEqual(gate.validate(review_only=True), "revise")

    def test_fail_closed_mutations(self):
        mutations = [
            lambda l, r: l["outputs"].pop(),
            lambda l, r: l["outputs"].append(copy.deepcopy(l["outputs"][0])),
            lambda l, r: l["outputs"][0].update(implementation="missing.js"),
            lambda l, r: l["obligations"].pop(),
            lambda l, r: l["obligations"][0].update(owner=""),
            lambda l, r: l["obligations"][0].update(pass_credit=True),
            lambda l, r: next(x for x in l["obligations"] if x["category"] == "deferred-qualification").update(state="passed"),
            lambda l, r: l.update(candidate_revision="working-tree"),
            lambda l, r: r["lenses"].pop(),
            lambda l, r: r["findings"].pop(0),
            lambda l, r: r["findings"][0].update(state="closed"),
            lambda l, r: r["findings"][0].update(severity="limitation"),
            lambda l, r: r.update(decision="accepted"),
            lambda l, r: r.update(bh04_eligible=True),
            lambda l, r: r.update(next_authorized_work="BH-04"),
            lambda l, r: r.update(support_state="supported"),
            lambda l, r: r.update(api_state="stable"),
        ]
        for index, mutate in enumerate(mutations):
            with self.subTest(mutation=index):
                ledger, review = gate.phase("reconciliation"), gate.phase("review")
                mutate(ledger, review)
                with self.assertRaises(gate.ValidationError):
                    gate.validate_review(ledger, review)

    def test_missing_and_stale_bindings_fail(self):
        for rows in [[], [{"path": gate.BASE + "blazex-bh-03-phase-08-review-v0.1.0.json", "sha256": "0" * 64}]]:
            with self.subTest(rows=rows), self.assertRaises(gate.ValidationError):
                gate.bindings(rows)

    def test_repeat_evidence_and_negative_rows(self):
        for kind, measurement in [("browser-repeat", False), ("measurement-repeat", True)]:
            evidence = gate.phase(kind)
            gate.validate_repeat(evidence, measurement)
            for mutate in [
                lambda e: e["results"].pop(),
                lambda e: e["results"][0].update(result="failed"),
                lambda e: e.update(implementation_revision="working-tree"),
                lambda e: e["deferred"][0].update(state="passed"),
            ]:
                changed = copy.deepcopy(evidence)
                mutate(changed)
                with self.assertRaises(gate.ValidationError):
                    gate.validate_repeat(changed, measurement)


if __name__ == "__main__":
    unittest.main()
