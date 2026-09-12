import shutil,tempfile,unittest
from pathlib import Path
from research_paths import REPO_ROOT
from validate_bh06_feature_bundles import *

class FeatureBundleTests(unittest.TestCase):
    paths=[AUTHORITY,POLICY,PLAN,AUDIT,LICENSES,MANIFEST,BROWSER,INDEX,COMPLETION,PHASE_PLAN,CLOSURE,TASK,BRIDGE,HOST,"integration/bh-06/bundle-policy.schema.json","integration/bh-06/bundle-plan.schema.json"]
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory(); self.root=Path(self.temp.name); authority=load(REPO_ROOT,AUTHORITY)
        for rel in set(self.paths+list(authority["bound_inputs"])):
            target=self.root/rel; target.parent.mkdir(parents=True,exist_ok=True); shutil.copy2(REPO_ROOT/rel,target)
    def tearDown(self): self.temp.cleanup()
    def mutate(self,rel,old,new):
        path=self.root/rel; path.write_text(path.read_text().replace(old,new))
    def test_valid(self): self.assertEqual([],validate(self.root))
    def test_policy_mutation(self):
        self.mutate(POLICY,'"counter"]','"other"]'); self.assertTrue(any("normalized policy" in x for x in validate(self.root)))
    def test_feature_membership(self):
        self.mutate(PLAN,'"bundle_id":"counter"','"bundle_id":"base"'); self.assertTrue(any("input ownership" in x for x in validate(self.root)))
    def test_audit_omission(self):
        self.mutate(AUDIT,'"bytes":7592','"bytes":7593'); self.assertTrue(any("audited BEAM" in x for x in validate(self.root)))
    def test_manifest_substitution(self):
        self.mutate(MANIFEST,'9ea6df54','0ea6df54'); self.assertTrue(any("canonical bundle plan" in x for x in validate(self.root)))
    def test_browser_load_removed(self):
        self.mutate(BROWSER,'"feature-dynamic-load",',''); self.assertTrue(any("dynamic-load proof" in x for x in validate(self.root)))
    def test_gate_bypass(self):
        self.mutate(CLOSURE,"BundlePlan.plan!","BundlePlan.bypass!"); self.assertTrue(any("precedes assembly" in x for x in validate(self.root)))
    def test_runtime_loader_removed(self):
        self.mutate(BRIDGE,":atomvm.add_avm_pack_binary",":atomvm.skip_avm_pack_binary"); self.assertTrue(any("dynamic feature load" in x for x in validate(self.root)))

if __name__=="__main__": unittest.main()
