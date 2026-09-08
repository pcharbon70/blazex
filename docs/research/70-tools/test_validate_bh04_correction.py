import unittest
import hashlib
from pathlib import Path
import tempfile
from validate_bh04_correction import gate_errors, execution_source_errors, immutable_input_errors


class CorrectiveGateTests(unittest.TestCase):
    def test_complete_successful_inventory(self):
        self.assertEqual(gate_errors([{"name": "one", "exit_code": 0, "error": None}], {"one"}), [])

    def test_failures_duplicates_and_missing_rows(self):
        for rows in [[], [{"name": "one", "exit_code": 1}], [{"name": "one", "exit_code": 0, "error": "failure"}], [{"name": "one", "exit_code": 0}] * 2]:
            self.assertTrue(gate_errors(rows, {"one"}))

    def test_post_execution_changes_cannot_be_resealed(self):
        tested = {"packages/component.ex": "old", "docs/research/70-tools/tool.py": "old"}
        record = {"source_hashes": tested, "final_source_hashes": tested}
        self.assertEqual(execution_source_errors(record, tested), [])
        for path in tested:
            changed = {**tested, path: "new"}
            self.assertTrue(execution_source_errors(record, changed))
        self.assertTrue(execution_source_errors(record, {**tested, "new-source": "new"}))
        self.assertTrue(execution_source_errors({"source_hashes": tested}, tested))

    def test_inherited_input_tampering_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            data = b'{"conditions":[1,2,3,4,5]}'
            (root / "overlay.json").write_bytes(data)
            blob = hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest()
            self.assertEqual(immutable_input_errors(root, {"overlay.json": blob}), [])
            (root / "overlay.json").write_text('{"conditions":[]}')
            self.assertTrue(immutable_input_errors(root, {"overlay.json": blob}))


if __name__ == "__main__":
    unittest.main()
