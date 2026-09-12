import json,shutil,tempfile,unittest
from pathlib import Path
from research_paths import REPO_ROOT
from validate_bh07_static_delivery import *

class StaticDeliveryTests(unittest.TestCase):
 def setUp(self):
  self.temp=tempfile.TemporaryDirectory(); self.root=Path(self.temp.name)
  authority=load(REPO_ROOT,AUTHORITY); evidence=load(REPO_ROOT,EVIDENCE)
  paths=[AUTHORITY,EVIDENCE,INDEX,COMPLETION,PLAN,CONTRACT,ENGINE,ASSET_PLUG,CACHE,PROFILE_MIX,PROFILE_LOCK,BOUNDARY_TEST,*authority["bound_inputs"],*evidence["source_bindings"]]
  for rel in set(paths):
   target=self.root/rel; target.parent.mkdir(parents=True,exist_ok=True); shutil.copy2(REPO_ROOT/rel,target)
  profile_lib=self.root/"profiles/browser_phoenix/lib"
  shutil.copytree(REPO_ROOT/"profiles/browser_phoenix/lib",profile_lib,dirs_exist_ok=True)
 def tearDown(self): self.temp.cleanup()
 def write(self,rel,data): (self.root/rel).write_text(json.dumps(data))
 def test_valid_acceptance(self): self.assertEqual([],validate(self.root))
 def test_false_decision(self):
  data=load(self.root,EVIDENCE); data["decision"]="reject"; self.write(EVIDENCE,data)
  self.assertTrue(any("decision" in error for error in validate(self.root)))
 def test_source_binding_mutation(self):
  path=self.root/ENGINE; path.write_text(path.read_text().replace("artifact-content-mismatch","content-skipped"))
  self.assertTrue(any("source binding" in error or "fail-closed" in error for error in validate(self.root)))
 def test_scaling_mutation(self):
  data=load(self.root,EVIDENCE); data["scaling"]["retained_identity_results"]=2; self.write(EVIDENCE,data)
  self.assertTrue(any("scaling bound" in error for error in validate(self.root)))
 def test_active_dependency_mutation(self):
  path=self.root/PROFILE_MIX; path.write_text(path.read_text()+"\n# {:local_live_view, \"== 0.1.0\"}\n")
  self.assertTrue(any("deferred dependency" in error for error in validate(self.root)))
 def test_lock_dependency_mutation(self):
  path=self.root/PROFILE_LOCK; path.write_text(path.read_text()+"\n\"phoenix_live_view\"\n")
  self.assertTrue(any("active lock" in error for error in validate(self.root)))
 def test_incomplete_plan(self):
  path=self.root/PLAN; path.write_text(path.read_text()+"\n- [ ] hidden bypass\n")
  self.assertTrue(any("checklist" in error for error in validate(self.root)))

if __name__=="__main__": unittest.main()
