import json,shutil,tempfile,unittest
from pathlib import Path
from research_paths import REPO_ROOT
from validate_bh07_public_bootstrap import *

class PublicBootstrapTests(unittest.TestCase):
 def setUp(self):
  self.temp=tempfile.TemporaryDirectory(); self.root=Path(self.temp.name); authority=load(REPO_ROOT,AUTHORITY); evidence=load(REPO_ROOT,EVIDENCE)
  paths=[AUTHORITY,EVIDENCE,INDEX,COMPLETION,PLAN,CONTRACT,ENGINE,STATIC,PLUG,CONFIG,ENDPOINT,PROFILE_MIX,PROFILE_LOCK,*authority["bound_inputs"],*evidence["source_bindings"]]
  for rel in set(paths):
   target=self.root/rel; target.parent.mkdir(parents=True,exist_ok=True); shutil.copy2(REPO_ROOT/rel,target)
  shutil.copytree(REPO_ROOT/"profiles/browser_phoenix/lib",self.root/"profiles/browser_phoenix/lib",dirs_exist_ok=True)
 def tearDown(self): self.temp.cleanup()
 def write(self,rel,data): (self.root/rel).write_text(json.dumps(data))
 def test_valid_acceptance(self): self.assertEqual([],validate(self.root))
 def test_false_decision(self):
  data=load(self.root,EVIDENCE); data["decision"]="reject"; self.write(EVIDENCE,data); self.assertTrue(any("decision" in x for x in validate(self.root)))
 def test_source_mutation(self):
  path=self.root/ENGINE; path.write_text(path.read_text().replace("@forbidden_key","@ignored_key")); self.assertTrue(any("source binding" in x or "trust or limit" in x for x in validate(self.root)))
 def test_limit_mutation(self):
  data=load(self.root,EVIDENCE); data["bootstrap"]["max_nodes"]=257; self.write(EVIDENCE,data); self.assertTrue(any("contract or bound" in x for x in validate(self.root)))
 def test_capability_mutation(self):
  data=load(self.root,EVIDENCE); data["capabilities"]["server_mutation"]=True; self.write(EVIDENCE,data); self.assertTrue(any("capability authority" in x for x in validate(self.root)))
 def test_route_removal(self):
  path=self.root/PLUG; path.write_text(path.read_text().replace('/bh07/bootstrap.json','/removed')); self.assertTrue(any("transport" in x for x in validate(self.root)))
 def test_deferred_dependency(self):
  path=self.root/PROFILE_MIX; path.write_text(path.read_text()+'\n# {:local_live_view, "== 0.1.0"}\n'); self.assertTrue(any("deferred dependency" in x for x in validate(self.root)))
 def test_incomplete_plan(self):
  path=self.root/PLAN; path.write_text(path.read_text()+"\n- [ ] bypass\n"); self.assertTrue(any("checklist" in x for x in validate(self.root)))

if __name__=="__main__": unittest.main()
