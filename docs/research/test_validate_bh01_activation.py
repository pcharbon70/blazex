#!/usr/bin/env python3
"""Focused fail-closed tests for BH-01 Phase 1 activation governance."""

from __future__ import annotations

import copy
import unittest

import validate_bh01_activation as validator


class BH01ActivationValidationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.authorization = validator._load_json(validator.AUTHORIZATION)
        cls.ledger = validator._load_json(validator.LEDGER)
        cls.bh00 = validator._load_json(validator.BH00_GOVERNANCE)
        cls.quality = validator._load_json(validator.QUALITY_CONTRACT)
        cls.acceptance = validator._load_json(validator.ACCEPTANCE_REGISTRY)
        cls.evidence_governance = validator._load_json(validator.EVIDENCE_GOVERNANCE)
        cls.activation = validator._load_json(validator.REPOSITORY_ACTIVATION)

    def tearDown(self) -> None:
        for boundary_record in self.activation["boundaries"]:
            boundary = validator.REPO_ROOT / boundary_record["path"]
            for prohibited in (
                "mix.lock",
                "package-lock.json",
                "yarn.lock",
                "pnpm-lock.yaml",
                "deps",
                "node_modules",
            ):
                self.assertFalse(
                    (boundary / prohibited).exists(),
                    f"negative test acquired dependency output: {boundary_record['path']}/{prohibited}",
                )

    def test_repository_activation_passes(self) -> None:
        validator.validate()

    def test_rejects_missing_approval(self) -> None:
        authorization = copy.deepcopy(self.authorization)
        authorization["status"] = "not-approved"
        with self.assertRaisesRegex(validator.ValidationError, "lacks explicit approval"):
            validator._validate_authorization(authorization, self.bh00)

    def test_rejects_stale_main_revision(self) -> None:
        authorization = copy.deepcopy(self.authorization)
        authorization["activation"]["base_revision"] = "0" * 40
        authorization["activation"]["base_remote_revision"] = "0" * 40
        with self.assertRaisesRegex(validator.ValidationError, "cat-file.*failed"):
            validator._validate_authorization(authorization, self.bh00)

    def test_rejects_stale_bh00_source(self) -> None:
        governance = copy.deepcopy(self.bh00)
        governance["source_bindings"][0]["sha256"] = "0" * 64
        with self.assertRaisesRegex(validator.ValidationError, "bound BH-00 source is stale"):
            validator._validate_bound_sources(governance)

    def test_rejects_incomplete_ledger(self) -> None:
        ledger = copy.deepcopy(self.ledger)
        ledger["inputs"].pop()
        with self.assertRaisesRegex(validator.ValidationError, "exactly eight BH-01 inputs"):
            validator._validate_ledger(ledger, self.bh00, self.quality, self.acceptance)

    def test_rejects_unowned_blocker_domain(self) -> None:
        ledger = copy.deepcopy(self.ledger)
        ledger["owner_assignments"] = [
            record for record in ledger["owner_assignments"] if record["role"] != "build-owner"
        ]
        with self.assertRaisesRegex(validator.ValidationError, "unowned BH-01 records"):
            validator._validate_ledger(ledger, self.bh00, self.quality, self.acceptance)

    def test_rejects_unreviewed_plan_change(self) -> None:
        governance = copy.deepcopy(self.evidence_governance)
        governance["reapproval_triggers"].pop()
        with self.assertRaisesRegex(validator.ValidationError, "evidence governance schema failure"):
            validator._validate_evidence_governance(self.bh00, self.ledger, governance)

    def test_rejects_collapsed_evidence_state(self) -> None:
        governance = copy.deepcopy(self.evidence_governance)
        governance["state_vocabulary"].remove("invalidated")
        with self.assertRaisesRegex(validator.ValidationError, "evidence governance schema failure"):
            validator._validate_evidence_governance(self.bh00, self.ledger, governance)

    def test_rejects_missing_activated_boundary(self) -> None:
        activation = copy.deepcopy(self.activation)
        activation["boundaries"].pop()
        with self.assertRaisesRegex(validator.ValidationError, "repository activation schema failure"):
            validator._validate_repository_activation(self.ledger, activation)

    def test_rejects_unapproved_graph_edge(self) -> None:
        activation = copy.deepcopy(self.activation)
        standalone_dom = next(
            record for record in activation["boundaries"] if record["id"] == "blazex_renderer_dom"
        )
        standalone_dom["allowed_planned_dependencies"] = ["blazex_phoenix"]
        with self.assertRaisesRegex(validator.ValidationError, "planned dependency graph changed"):
            validator._validate_repository_activation(self.ledger, activation)

    def test_exact_project_metadata_has_no_acquired_dependency(self) -> None:
        for boundary_record in self.activation["boundaries"]:
            metadata = validator._load_json(
                validator.REPO_ROOT / boundary_record["path"] / "blazex.project.json"
            )
            self.assertEqual(metadata["dependencies"], [])
            self.assertEqual(
                metadata["planned_dependencies"],
                boundary_record["allowed_planned_dependencies"],
            )

    def test_fixture_and_benchmark_indexes_remain_unexecuted(self) -> None:
        fixtures = validator._load_json(validator.REPO_ROOT / "integration/fixtures/fixture-index.json")
        benchmarks = validator._load_json(
            validator.REPO_ROOT / "integration/benchmarks/benchmark-index.json"
        )
        self.assertEqual(fixtures["scenarios"], [])
        self.assertFalse(fixtures["production_import_allowed"])
        self.assertEqual(benchmarks["environments"], [])
        self.assertEqual(benchmarks["measurements"], [])
        self.assertEqual(benchmarks["samples"], [])
        self.assertEqual(benchmarks["reports"], [])
        self.assertEqual(benchmarks["budget_state"], "proposed-unmeasured")


if __name__ == "__main__":
    unittest.main()
