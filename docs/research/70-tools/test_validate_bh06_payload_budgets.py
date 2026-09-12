import shutil,tempfile,unittest
from pathlib import Path
from research_paths import REPO_ROOT
from validate_bh06_payload_budgets import *

class PayloadBudgetTests(unittest.TestCase):
 paths=[AUTHORITY,POLICY,REPORT,MANIFEST,BROWSER,INDEX,COMPLETION,PLAN,PIPELINE,TASK,RUNNER,HOST,"integration/bh-06/payload-policy.schema.json","integration/bh-06/payload-report.schema.json",*PRIVATE.values()]
 def setUp(self):
  self.temp=tempfile.TemporaryDirectory(); self.root=Path(self.temp.name); authority=load(REPO_ROOT,AUTHORITY)
  for rel in set(self.paths+list(authority["bound_inputs"])):
   target=self.root/rel; target.parent.mkdir(parents=True,exist_ok=True); shutil.copy2(REPO_ROOT/rel,target)
 def tearDown(self): self.temp.cleanup()
 def mutate(self,rel,old,new):
  path=self.root/rel; path.write_text(path.read_text().replace(old,new))
 def test_valid_revision_required(self): self.assertEqual([],validate(self.root))
 def test_threshold_mutation(self):
  self.mutate(POLICY,'"threshold":1638400','"threshold":3000000'); self.assertTrue(any("normalized policy" in x or "decisions" in x for x in validate(self.root)))
 def test_concealed_failure(self):
  self.mutate(REPORT,'"decision":"reject"','"decision":"accept"'); self.assertTrue(any("rejection" in x for x in validate(self.root)))
 def test_owner_total_mutation(self):
  self.mutate(REPORT,'"brotli_bytes":2689798','"brotli_bytes":1689798'); self.assertTrue(any("totals" in x for x in validate(self.root)))
 def test_private_exposure_mutation(self):
  self.mutate(MANIFEST,'"exposure":"private-build-evidence"','"exposure":"public"'); self.assertTrue(any("exposure drift" in x for x in validate(self.root)))
 def test_private_evidence_mutation(self):
  self.mutate(PRIVATE["reachability-report"],'"phase":2','"phase":8'); self.assertTrue(any("private evidence binding" in x for x in validate(self.root)))
 def test_browser_encoding_removed(self):
  self.mutate(BROWSER,'"runtime-wasm": "br"','"runtime-wasm": "identity"'); self.assertTrue(any("Brotli browser proof" in x for x in validate(self.root)))
 def test_promotion_gate_removed(self):
  self.mutate(TASK,"no output was promoted","output was promoted"); self.assertTrue(any("promotion" in x for x in validate(self.root)))

if __name__=="__main__": unittest.main()
