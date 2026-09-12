import json,shutil,tempfile,unittest
from pathlib import Path
from research_paths import REPO_ROOT
from validate_bh06_entrypoint_attestation import *

class EntrypointAttestationTests(unittest.TestCase):
 paths=[AUTHORITY,POLICY,ATTESTATION,MANIFEST,BROWSER,PAYLOAD,INDEX,COMPLETION,HANDOFF,PLAN,ENGINE,TASK,RUNNER,"integration/bh-06/entrypoint-accounting-policy.schema.json","integration/bh-06/entrypoint-attestation.schema.json",*[v for k,v in REPORTS.items() if k not in {"payload","delivery_integrity"}]]
 def setUp(self):
  self.temp=tempfile.TemporaryDirectory(); self.root=Path(self.temp.name); authority=load(REPO_ROOT,AUTHORITY)
  for rel in set(self.paths+list(authority["bound_inputs"])):
   target=self.root/rel; target.parent.mkdir(parents=True,exist_ok=True); shutil.copy2(REPO_ROOT/rel,target)
 def tearDown(self): self.temp.cleanup()
 def write(self,rel,data): (self.root/rel).write_text(json.dumps(data))
 def test_valid_acceptance(self): self.assertEqual([],validate(self.root))
 def test_extra_entrypoint(self):
  data=load(self.root,POLICY); data["entrypoints"].append({"id":"extra","module":"Elixir.Extra"}); self.write(POLICY,data); self.assertTrue(any("entrypoint set" in x or "completion identities" in x for x in validate(self.root)))
 def test_manifest_binding_mutation(self):
  data=load(self.root,ATTESTATION); data["manifest"]["sha256"]="0"*64; self.write(ATTESTATION,data); self.assertTrue(any("manifest binding" in x for x in validate(self.root)))
 def test_missing_license_category(self):
  data=load(self.root,ATTESTATION); del data["evidence"]["license_inventory"]; self.write(ATTESTATION,data); self.assertTrue(any("category coverage" in x for x in validate(self.root)))
 def test_false_payload_decision(self):
  data=load(self.root,PAYLOAD); data["decision"]="reject"; self.write(PAYLOAD,data); self.assertTrue(any("payload acceptance" in x or "identity" in x for x in validate(self.root)))
 def test_browser_binding_mutation(self):
  data=load(self.root,BROWSER); data["attestation_sha256"]="0"*64; self.write(BROWSER,data); self.assertTrue(any("browser attestation" in x for x in validate(self.root)))
 def test_incomplete_set_bypass(self):
  path=self.root/ENGINE; path.write_text(path.read_text().replace("assert_complete_set!","skip_complete_set!")); self.assertTrue(any("not wired" in x for x in validate(self.root)))

if __name__=="__main__": unittest.main()
