import shutil,tempfile,unittest
from pathlib import Path
from research_paths import REPO_ROOT
from validate_bh06_license_provenance import *

class LicenseProvenanceTests(unittest.TestCase):
    paths=[AUTHORITY,POLICY,REPORT,AUDIT,MANIFEST,BROWSER,INDEX,COMPLETION,PLAN,CLOSURE,TASK,"integration/bh-06/license-policy.schema.json","integration/bh-06/license-inventory.schema.json","integration/bh-06/THIRD_PARTY_NOTICES.md","packages/blazex_runtime_popcorn/runtime/THIRD_PARTY_NOTICES.md"]
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory(); self.root=Path(self.temp.name); authority=load(REPO_ROOT,AUTHORITY)
        for rel in set(self.paths+list(authority["bound_inputs"])):
            target=self.root/rel; target.parent.mkdir(parents=True,exist_ok=True); shutil.copy2(REPO_ROOT/rel,target)
    def tearDown(self): self.temp.cleanup()
    def mutate(self,rel,old,new):
        path=self.root/rel; path.write_text(path.read_text().replace(old,new))
    def test_valid(self): self.assertEqual([],validate(self.root))
    def test_policy_mutation(self):
        self.mutate(POLICY,'"version": "1.18.4"','"version": "1.18.5"'); self.assertTrue(any("normalized policy" in x for x in validate(self.root)))
    def test_notice_drift(self):
        self.mutate("integration/bh-06/THIRD_PARTY_NOTICES.md","candidate third-party","changed third-party"); self.assertTrue(any("notice drift" in x for x in validate(self.root)))
    def test_component_removal(self):
        self.mutate(REPORT,'"component_id":"blazex"','"component_id":"missing"'); self.assertTrue(any("lacks component" in x for x in validate(self.root)))
    def test_audit_divergence(self):
        self.mutate(AUDIT,'"bytes":5729','"bytes":5730'); self.assertTrue(any("exactly match" in x for x in validate(self.root)))
    def test_manifest_substitution(self):
        self.mutate(MANIFEST,'0a2cbd6d','1a2cbd6d'); self.assertTrue(any("canonical Phase 6" in x for x in validate(self.root)))
    def test_gate_bypass(self):
        self.mutate(CLOSURE,"LicenseInventory.analyze!","LicenseInventory.bypass!"); self.assertTrue(any("precedes assembly" in x for x in validate(self.root)))

if __name__=="__main__": unittest.main()
