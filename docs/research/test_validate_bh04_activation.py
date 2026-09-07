"""Mutation tests for the immutable BH-04 Phase 1 activation candidate."""
import contextlib
import json
import shutil
import tempfile
import unittest
from pathlib import Path

import validate_bh04_activation as gate


class ActivationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temporary = tempfile.TemporaryDirectory(prefix="bh04-activation-test-")
        cls.root = Path(cls.temporary.name)
        # Copy, never hard-link: mutation tests must not edit user source.
        files = gate.git(gate.ROOT, "ls-files", "--cached", "--others",
                         "--exclude-standard").decode().splitlines()
        for name in files:
            source = gate.ROOT / name
            if source.is_file():
                target = cls.root / name
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(source, target)
        git_dir = gate.git(gate.ROOT, "rev-parse", "--absolute-git-dir").decode().strip()
        (cls.root / ".git").write_text(f"gitdir: {git_dir}\n")

    @classmethod
    def tearDownClass(cls):
        cls.temporary.cleanup()

    @contextlib.contextmanager
    def changed(self, name, transform):
        path = self.root / name
        original = path.read_bytes() if path.exists() else None
        path.parent.mkdir(parents=True, exist_ok=True)
        try:
            replacement = transform(original)
            if replacement is None:
                path.unlink(missing_ok=True)
            else:
                path.write_bytes(replacement)
            yield
        finally:
            if original is None:
                path.unlink(missing_ok=True)
            else:
                path.write_bytes(original)

    def reject_json(self, name, mutate, diagnostic):
        def transform(raw):
            data = json.loads(raw)
            mutate(data)
            return (json.dumps(data, indent=2) + "\n").encode()
        with self.changed(name, transform):
            errors = gate.validate(self.root, require_completion=False)
            self.assertTrue(errors)
            self.assertIn(diagnostic, "\n".join(errors))

    def test_candidate_is_deterministic(self):
        self.assertEqual([], gate.validate(self.root, require_completion=False))
        self.assertEqual([], gate.validate(self.root, require_completion=False))

    def test_missing_authority(self):
        with self.changed(gate.AUTH, lambda _: None):
            self.assertTrue(gate.validate(self.root, require_completion=False))

    def test_malformed_authority(self):
        with self.changed(gate.AUTH, lambda _: b"not-json"):
            self.assertTrue(gate.validate(self.root, require_completion=False))

    def test_missing_owner(self):
        self.reject_json(gate.ACTIVATION,
                         lambda d: d["owner_boundaries"]["packages/blazex_renderer"].pop("owner"),
                         "immutable activation record changed")

    def test_wrong_acceptance_id(self):
        self.reject_json(gate.LEDGER,
                         lambda d: d["acceptance_records"][0].update(id="invented"),
                         "canonical acceptance")

    def test_wrong_schedule_owner(self):
        self.reject_json(gate.LEDGER,
                         lambda d: d["schedule"][0].update(owner=""),
                         "owner or suite mismatch")

    def test_missing_deferral(self):
        self.reject_json(gate.LEDGER,
                         lambda d: d["predecessor_handoff"]["carried_obligations"].pop(),
                         "handoff changed")

    def test_stale_handoff(self):
        path = "docs/research/assets/bh-03-baseline/blazex-bh-03-phase-09-acceptance-v0.1.0.json"
        self.reject_json(path, lambda d: d.update(decision="revise"), "stale authority/handoff")

    def test_rebound_source_hash(self):
        self.reject_json(gate.ACTIVATION,
                         lambda d: d["baseline_files"].update({"packages/blazex_core/mix.exs": "0" * 64}),
                         "historical source rebound")

    def test_direct_framework_dependency(self):
        path = "packages/blazex_renderer_dom/mix.exs"
        with self.changed(path, lambda b: b.replace(b"deps: [", b"deps: [{:phoenix, []},")):
            self.assertIn("unauthorized direct dependency",
                          "\n".join(gate.validate(self.root, require_completion=False)))

    def test_transitive_framework_dependency(self):
        path = "packages/blazex_core/mix.exs"
        with self.changed(path, lambda b: b.replace(b"deps: []", b"deps: [{:plug, []}]")):
            self.assertIn("unauthorized transitive dependency",
                          "\n".join(gate.validate(self.root, require_completion=False)))

    def test_portable_token_leakage(self):
        path = "packages/blazex_renderer/lib/forbidden.ex"
        with self.changed(path, lambda _: b"defmodule Forbidden do\n  alias Phoenix.LiveView\nend\n"):
            self.assertIn("portable source token leakage",
                          "\n".join(gate.validate(self.root, require_completion=False)))

    def test_new_incremental_source(self):
        path = "js/blazex_runtime/src/incremental.js"
        with self.changed(path, lambda _: b"export const applyPatch = () => {};\n"):
            self.assertIn("unindexed source/evidence",
                          "\n".join(gate.validate(self.root, require_completion=False)))

    def test_unindexed_evidence(self):
        with self.changed("integration/bh-04/fake.json", lambda _: b"{}"):
            self.assertIn("unindexed BH-04 evidence",
                          "\n".join(gate.validate(self.root, require_completion=False)))

    def test_historical_fixture_rewrite(self):
        activation = gate.read(self.root, gate.ACTIVATION)
        path = next(p for p in activation["baseline_files"]
                    if p.startswith("integration/conformance/") and p.endswith(".json"))
        with self.changed(path, lambda b: b + b"\n"):
            self.assertIn("historical source/behavior changed",
                          "\n".join(gate.validate(self.root, require_completion=False)))

    def test_fabricated_browser_pass(self):
        self.reject_json(gate.INDEX,
                         lambda d: d["results"]["browser"].append({"result": "passed"}),
                         "premature renderer/browser")

    def test_fabricated_measurement(self):
        self.reject_json(gate.INDEX,
                         lambda d: d["results"]["measurement"].append({"p95": 1}),
                         "premature renderer/browser")

    def test_schema_and_index_cannot_be_relaxed_together(self):
        def schema(raw):
            d = json.loads(raw)
            d["const"]["results"]["browser"].append({"result": "passed"})
            return json.dumps(d).encode()
        with self.changed(gate.SCHEMA, schema):
            self.reject_json(gate.INDEX,
                             lambda d: d["results"]["browser"].append({"result": "passed"}),
                             "immutable activation record changed")

    def test_support_promotion(self):
        self.reject_json(gate.INDEX, lambda d: d.update(support_state="supported"),
                         "support promotion forbidden")

    def test_stable_api(self):
        self.reject_json(gate.AUTH, lambda d: d.update(api_state="stable"),
                         "support promotion forbidden")

    def test_phase2_authority(self):
        self.reject_json(gate.AUTH, lambda d: d.update(phase2_authorized=True),
                         "Phase 2 authority forbidden")

    def test_bh05_eligibility(self):
        self.reject_json(gate.INDEX, lambda d: d.update(bh05_eligible=True),
                         "BH-05 eligibility forbidden")

    def test_wrong_base(self):
        self.reject_json(gate.AUTH, lambda d: d.update(base_revision="0" * 40),
                         "synchronized base identity changed")

    def test_later_plan_rewrite(self):
        path = gate.read(self.root, gate.AUTH)["planned_phases"][1]
        with self.changed(path, lambda b: b.replace(b"[ ]", b"[x]", 1)):
            self.assertIn("later phase modified",
                          "\n".join(gate.validate(self.root, require_completion=False)))

    def test_missing_completion_is_not_a_pass(self):
        with self.changed(gate.COMPLETION, lambda _: None):
            self.assertTrue(gate.validate(self.root))

    def test_extra_phase_is_not_authority(self):
        plan = Path(gate.read(self.root, gate.AUTH)["planned_phases"][0]).parent
        with self.changed(str(plan / "phase-11-extra.md"), lambda _: b"# unauthorized"):
            self.assertIn("unindexed or missing phase plan",
                          "\n".join(gate.validate(self.root, require_completion=False)))

    def test_new_authority_file_is_rejected(self):
        path = gate.ASSETS + "blazex-bh-04-phase-02-authorization-v0.1.0.json"
        with self.changed(path, lambda _: b'{"authorized": true}'):
            self.assertIn("unindexed BH-04 authority",
                          "\n".join(gate.validate(self.root, require_completion=False)))


if __name__ == "__main__":
    unittest.main()
