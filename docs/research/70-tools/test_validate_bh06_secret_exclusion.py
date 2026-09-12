import shutil,tempfile,unittest
from pathlib import Path
from research_paths import REPO_ROOT
from validate_bh06_secret_exclusion import *

class SecretExclusionTests(unittest.TestCase):
    paths=[AUTHORITY,POLICY,REPORT,MANIFEST,BROWSER,INDEX,COMPLETION,PLAN,CLOSURE,TASK,"integration/bh-06/secret-policy.schema.json","integration/bh-06/secret-audit.schema.json"]
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory(); self.root=Path(self.temp.name); authority=load(REPO_ROOT,AUTHORITY)
        for rel in set(self.paths+list(authority["bound_inputs"])):
            target=self.root/rel; target.parent.mkdir(parents=True,exist_ok=True); shutil.copy2(REPO_ROOT/rel,target)
    def tearDown(self): self.temp.cleanup()
    def mutate(self,rel,old,new):
        path=self.root/rel; path.write_text(path.read_text().replace(old,new))
    def test_valid(self): self.assertEqual([],validate(self.root))
    def test_policy_mutation(self):
        self.mutate(POLICY,"AWS access-key prefix","changed reason"); self.assertTrue(any("normalized policy" in x for x in validate(self.root)))
    def test_hidden_finding(self):
        self.mutate(REPORT,'"clean":true','"clean":false'); self.assertTrue(any("not a clean" in x for x in validate(self.root)))
    def test_path_leak(self):
        self.mutate(REPORT,'"label":"browser/host.js"','"label":"browser/host.js","path":"/tmp/secret"'); self.assertTrue(any("path-bearing" in x for x in validate(self.root)))
    def test_summary_drift(self):
        self.mutate(REPORT,'"findings":0','"findings":1'); self.assertTrue(any("summary" in x for x in validate(self.root)))
    def test_manifest_substitution(self):
        self.mutate(MANIFEST,'2e7bbb1c','0e7bbb1c'); self.assertTrue(any("canonical secret audit" in x for x in validate(self.root)))
    def test_gate_bypass(self):
        self.mutate(CLOSURE,"SecretAudit.analyze!","SecretAudit.bypass!"); self.assertTrue(any("precedes assembly" in x for x in validate(self.root)))

if __name__=="__main__": unittest.main()
