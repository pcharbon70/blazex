import json,shutil,tempfile,unittest
from pathlib import Path
from research_paths import REPO_ROOT
from validate_bh07_session_boundary import *
class SessionBoundaryTests(unittest.TestCase):
 def setUp(self):
  self.temp=tempfile.TemporaryDirectory(); self.root=Path(self.temp.name); a=load(REPO_ROOT,AUTHORITY); e=load(REPO_ROOT,EVIDENCE)
  for rel in set([AUTHORITY,EVIDENCE,INDEX,COMPLETION,PLAN,CONTRACT,REGISTRY,BOOTSTRAP,PLUG,ENDPOINT,PROFILE_MIX,PROFILE_LOCK,*a["bound_inputs"],*e["source_bindings"]]):
   target=self.root/rel; target.parent.mkdir(parents=True,exist_ok=True); shutil.copy2(REPO_ROOT/rel,target)
 def tearDown(self): self.temp.cleanup()
 def write(self,rel,data): (self.root/rel).write_text(json.dumps(data))
 def test_valid(self): self.assertEqual([],validate(self.root))
 def test_decision(self):
  d=load(self.root,EVIDENCE); d["decision"]="reject"; self.write(EVIDENCE,d); self.assertTrue(any("decision" in x for x in validate(self.root)))
 def test_capacity(self):
  d=load(self.root,EVIDENCE); d["registry"]["max_sessions"]=257; self.write(EVIDENCE,d); self.assertTrue(any("bounds" in x for x in validate(self.root)))
 def test_source(self):
  p=self.root/REGISTRY; p.write_text(p.read_text().replace("strong_rand_bytes(32)","strong_rand_bytes(8)")); self.assertTrue(any("source binding" in x or "implementation" in x for x in validate(self.root)))
 def test_projection(self):
  d=load(self.root,EVIDENCE); d["projection"]["authenticated_fields"].append("session_id"); self.write(EVIDENCE,d); self.assertTrue(any("projection contract" in x for x in validate(self.root)))
 def test_cookie(self):
  p=self.root/ENDPOINT; p.write_text(p.read_text().replace('same_site: "Strict"','same_site: "Lax"')); self.assertTrue(any("cookie composition" in x for x in validate(self.root)))
 def test_dependency(self):
  p=self.root/PROFILE_MIX; p.write_text(p.read_text()+'\n# {:local_live_view, "== 0.1.0"}\n'); self.assertTrue(any("deferred dependency" in x for x in validate(self.root)))
 def test_plan(self):
  p=self.root/PLAN; p.write_text(p.read_text()+"\n- [ ] bypass\n"); self.assertTrue(any("checklist" in x for x in validate(self.root)))
if __name__=="__main__": unittest.main()
