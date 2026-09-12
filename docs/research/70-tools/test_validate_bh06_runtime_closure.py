import shutil,tempfile,unittest
from pathlib import Path
from research_paths import REPO_ROOT
from validate_bh06_runtime_closure import *

class RuntimeClosureTests(unittest.TestCase):
 paths=[AUTHORITY,POLICY,CLOSURE,PAYLOAD_POLICY,PHASE8_POLICY,PAYLOAD,MANIFEST,BROWSER,INDEX,COMPLETION,PLAN,REDUCER,TASK,RUNNER,"integration/bh-06/runtime-closure-policy.schema.json","integration/bh-06/runtime-closure-report.schema.json","integration/bh-06/payload-policy.schema.json","integration/bh-06/payload-report.schema.json",*PRIVATE.values()]
 def setUp(self):
  self.temp=tempfile.TemporaryDirectory(); self.root=Path(self.temp.name); authority=load(REPO_ROOT,AUTHORITY)
  for rel in set(self.paths+list(authority["bound_inputs"])):
   target=self.root/rel; target.parent.mkdir(parents=True,exist_ok=True); shutil.copy2(REPO_ROOT/rel,target)
 def tearDown(self): self.temp.cleanup()
 def mutate(self,rel,old,new):
  path=self.root/rel; path.write_text(path.read_text().replace(old,new,1))
 def test_valid_acceptance(self): self.assertEqual([],validate(self.root))
 def test_removed_module_concealment(self):
  data=load(self.root,CLOSURE); data["removed_modules"].pop(); (self.root/CLOSURE).write_text(json.dumps(data)); self.assertTrue(any("removed-module" in x or "binding drift" in x for x in validate(self.root)))
 def test_opaque_mutation(self):
  data=load(self.root,CLOSURE); module=data["opaque_modules"][0]; next(x for x in data["outputs"] if x["module"]==module)["sha256"]="0"*64; (self.root/CLOSURE).write_text(json.dumps(data)); self.assertTrue(any("opaque" in x or "binding drift" in x for x in validate(self.root)))
 def test_threshold_waiver(self):
  self.mutate(PAYLOAD_POLICY,'"threshold":1638400','"threshold":2638400'); self.assertTrue(any("thresholds drifted" in x for x in validate(self.root)))
 def test_concealed_payload_failure(self):
  self.mutate(PAYLOAD,'"decision":"accept"','"decision":"reject"'); self.assertTrue(any("payload acceptance" in x for x in validate(self.root)))
 def test_browser_failure(self):
  self.mutate(BROWSER,'"result": "passed"','"result": "failed"'); self.assertTrue(any("browser proof" in x for x in validate(self.root)))
 def test_reducer_unwired(self):
  self.mutate(TASK,"RuntimeClosure.reduce!","RuntimeClosure.disabled!"); self.assertTrue(any("not wired" in x for x in validate(self.root)))

if __name__=="__main__": unittest.main()
