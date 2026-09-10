"""Mutation checks for Phase 11 source-frozen gate semantics."""
import copy,unittest
from validate_bh05_conformance import GATES,gate_errors

class TestConformance(unittest.TestCase):
    def record(self): return {"phase":11,"source_hashes":{"a":"b"},"final_source_hashes":{"a":"b"},"results":[{"name":n,"exit_code":0,"error":None,"command":[n]} for n in GATES]}
    def test_valid(self): self.assertEqual(gate_errors(self.record(),{"a":"b"}),[])
    def test_stale(self): self.assertTrue(gate_errors(self.record(),{"a":"c"}))
    def test_missing(self): value=self.record();value["results"].pop();self.assertTrue(gate_errors(value,{"a":"b"}))
    def test_failed(self): value=self.record();value["results"][0]["exit_code"]=1;self.assertTrue(gate_errors(value,{"a":"b"}))
    def test_duplicate(self): value=self.record();value["results"].append(copy.deepcopy(value["results"][0]));self.assertTrue(gate_errors(value,{"a":"b"}))
if __name__=="__main__": unittest.main()
