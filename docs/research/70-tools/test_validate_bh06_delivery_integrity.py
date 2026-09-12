import json,shutil,tempfile,unittest
from pathlib import Path
from research_paths import REPO_ROOT
from validate_bh06_delivery_integrity import *

class DeliveryIntegrityTests(unittest.TestCase):
 paths=[AUTHORITY,POLICY,MANIFEST,BROWSER,PAYLOAD,INDEX,COMPLETION,PLAN,ENGINE,TASK,HOST,RUNNER,"integration/bh-06/delivery-integrity-policy.schema.json",*PRIVATE.values()]
 def setUp(self):
  self.temp=tempfile.TemporaryDirectory(); self.root=Path(self.temp.name); authority=load(REPO_ROOT,AUTHORITY)
  for rel in set(self.paths+list(authority["bound_inputs"])):
   target=self.root/rel; target.parent.mkdir(parents=True,exist_ok=True); shutil.copy2(REPO_ROOT/rel,target)
 def tearDown(self): self.temp.cleanup()
 def write(self,rel,data): (self.root/rel).write_text(json.dumps(data))
 def test_valid_acceptance(self): self.assertEqual([],validate(self.root))
 def test_policy_binding_mutation(self):
  data=load(self.root,MANIFEST); data["delivery_integrity"]["policy_sha256"]="0"*64; self.write(MANIFEST,data); self.assertTrue(any("policy binding" in x for x in validate(self.root)))
 def test_sri_mutation(self):
  data=load(self.root,MANIFEST); data["artifacts"][0]["integrity"]="sha384-"+"A"*64; self.write(MANIFEST,data); self.assertTrue(any("integrity drift" in x or "identities" in x for x in validate(self.root)))
 def test_cache_mutation(self):
  data=load(self.root,MANIFEST); data["artifacts"][0]["cache_control"]="no-store" if data["artifacts"][0]["cache_control"]!="no-store" else "public, max-age=31536000, immutable"; self.write(MANIFEST,data); self.assertTrue(any("cache metadata" in x for x in validate(self.root)))
 def test_browser_failure(self):
  data=load(self.root,BROWSER); data["results"][0]["result"]="failed"; self.write(BROWSER,data); self.assertTrue(any("browser proof" in x for x in validate(self.root)))
 def test_negative_concealment(self):
  data=load(self.root,BROWSER); data["negative_sri"]["result"]="passed"; self.write(BROWSER,data); self.assertTrue(any("negative_sri" in x for x in validate(self.root)))
 def test_engine_bypass(self):
  path=self.root/TASK; path.write_text(path.read_text().replace("delivery_integrity:","delivery_disabled:")); self.assertTrue(any("not wired" in x for x in validate(self.root)))

if __name__=="__main__": unittest.main()
