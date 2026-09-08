"""Mutate a disposable checkout, never the user's source or evidence."""
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from research_paths import REPO_ROOT
from generate_bh05_activation import AREA, BASE, PLAN
from validate_bh05_activation import validate, execution_sources
from validate_bh04_correction import execution_source_errors


class ActivationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory(prefix="bh05-negative-")
        cls.root = Path(cls.temp.name) / "checkout"
        subprocess.run(["git", "clone", "--shared", "--no-checkout", str(REPO_ROOT), str(cls.root)], check=True, capture_output=True)
        subprocess.run(["git", "checkout", "--detach", BASE], cwd=cls.root, check=True, capture_output=True)
        changed = subprocess.check_output(["git", "diff", "--name-only", BASE], cwd=REPO_ROOT, text=True).splitlines()
        added = subprocess.check_output(["git", "ls-files", "--others", "--exclude-standard"], cwd=REPO_ROOT, text=True).splitlines()
        for name in set(changed + added):
            src, dst = REPO_ROOT / name, cls.root / name
            if src.is_file():
                dst.parent.mkdir(parents=True, exist_ok=True); shutil.copyfile(src, dst)

    @classmethod
    def tearDownClass(cls):
        cls.temp.cleanup()

    def mutation(self, name, transform, expected):
        path = self.root / name; original = path.read_bytes() if path.exists() else None
        path.parent.mkdir(parents=True, exist_ok=True)
        try:
            if original is None:
                path.write_text(transform(""))
            else:
                path.write_text(transform(original.decode()))
            self.assertTrue(any(expected in e for e in validate(self.root)), expected)
        finally:
            if original is None:
                path.unlink()
            else:
                path.write_bytes(original)

    def json_mutation(self, name, mutate, expected):
        def transform(text):
            data = json.loads(text); mutate(data); return json.dumps(data)
        self.mutation(name, transform, expected)

    def test_clean_unimplemented_checkout_passes_deterministically(self):
        self.assertEqual(validate(self.root), []); self.assertEqual(validate(self.root), [])

    def test_authority_scope_support_and_missing_authority(self):
        for field, value in [("phase2_authorized", True), ("public_api_stable", True), ("support_state", "supported"), ("behavior_implemented", True), ("bh06_eligible", True)]:
            with self.subTest(field=field):
                self.json_mutation(AREA + "authorization-v0.1.0.json", lambda r: r.update({field: value}), "authority")
        self.mutation(AREA + "authorization-v0.1.0.json", lambda _: "{}", "authority")

    def test_absent_authority_file_is_rejected(self):
        path = self.root / AREA / "authorization-v0.1.0.json"; original = path.read_bytes()
        try:
            path.unlink()
            self.assertTrue(any("Cannot establish" in e for e in validate(self.root)))
        finally:
            path.write_bytes(original)

    def test_nine_conditions_owners_and_hidden_deferral(self):
        for mutate in [lambda r: r["acceptance"].pop(), lambda r: r["acceptance"][0].update(owner=""), lambda r: r["predecessor"]["deferred"].pop(), lambda r: r["acceptance"][0].update(state="passed", evidence=["fabricated"]), lambda r: r.update(bh06_eligible=True)]:
            self.json_mutation(AREA + "entry-ledger-v0.1.0.json", mutate, "entry/acceptance/owner/deferral mismatch")

    def test_stale_predecessor_and_rewritten_historical_inputs(self):
        self.json_mutation("docs/research/assets/bh-04-correction/decision.json", lambda r: r.update(bh05_eligible=False), "stale inherited input")
        self.json_mutation("docs/research/assets/bh-04-baseline/blazex-bh-04-phase-10-review-v0.1.0.json", lambda r: r.update(deferred=[]), "altered inherited input")

    def test_forbidden_dependency_and_private_import(self):
        self.json_mutation("packages/blazex_core/blazex.project.json", lambda r: r["dependencies"].append("phoenix"), "dependency")
        self.mutation("packages/blazex_core/mix.exs", lambda s: s.replace("deps: []", 'deps: [{:phoenix, path: "../phoenix"}]'), "Mix dependency")
        for token in ["Phoenix.LiveView", "BlazeX.Runtime.Private", "BlazeX.Renderer.DOM", "Popcorn", "Qt", "Microsoft.Razor"]:
            with self.subTest(token=token):
                self.mutation("packages/blazex_core/lib/blazex/core.ex", lambda s: s.replace("defmodule BlazeX.Core do", "defmodule BlazeX.Core do\n  alias " + token), "host/framework/private import")

    def test_callbacks_processes_dynamic_dispatch_and_emissions(self):
        for statement in ["defmacro facade(), do: nil", "def process(), do: spawn(fn -> :ok end)", "def dispatch(m, f, a), do: apply(m, f, a)", "@callback emit() :: [term()]"]:
            self.mutation("packages/blazex_core/lib/blazex/core.ex", lambda s: s.replace("\nend", "\n  " + statement + "\nend"), "altered inherited input")
        self.mutation("packages/blazex_effects/lib/new_process.ex", lambda _: "defmodule NewProcess do end", "new implementation surface")
        self.mutation("hidden_callback.ex", lambda _: "defmodule Hidden do end", "executable outside Phase 1")

    def test_closed_empty_evidence_all_groups(self):
        for group in ["facade", "schemas", "composition", "state", "roots", "scheduling", "effects", "context", "registry", "failure", "runtime", "measurement", "review", "acceptance"]:
            with self.subTest(group=group):
                self.json_mutation("integration/bh-05/index-v0.1.0.json", lambda r: r["groups"][group].append({"result": "passed", "parity": True}), "empty evidence")
        self.json_mutation("integration/bh-05/index.schema.json", lambda r: r.update(additionalProperties=True), "empty evidence mismatch")
        self.mutation("integration/bh-05/hidden.json", lambda _: '{"result":"passed"}', "unindexed")
        self.mutation(AREA + "parity.json", lambda _: '{"ERTS":"passed","AtomVM":"passed"}', "unindexed")

    def test_ownership_plan_links_and_later_completion(self):
        self.json_mutation(AREA + "ownership-v0.1.0.json", lambda r: r["roles"]["nested-stateful"].update(own_process=True), "ownership")
        self.mutation(PLAN + "README.md", lambda s: s.replace("phase-02-component-roles-authoring-facade-and-callback-algebra.md", "missing.md"), "unindexed phase")
        self.mutation(PLAN + "phase-02-component-roles-authoring-facade-and-callback-algebra.md", lambda s: s.replace("[ ]", "[x]", 1), "premature later phase")

    def test_post_execution_source_drift(self):
        before = execution_sources(self.root)
        self.assertEqual(execution_source_errors({"source_hashes": before, "final_source_hashes": before}, before), [])
        changed = {**before, "packages/blazex_core/mix.exs": "forged"}
        self.assertTrue(execution_source_errors({"source_hashes": before, "final_source_hashes": before}, changed))


if __name__ == "__main__":
    unittest.main()
