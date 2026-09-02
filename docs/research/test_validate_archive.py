#!/usr/bin/env python3
"""Focused tests for BlazeX Research archive validation."""

import json
import tempfile
import unittest
from pathlib import Path

import jsonschema

from validate_archive import (
    ROOT,
    github_heading_anchors,
    link_destination,
    local_link_target,
    parse_frontmatter,
)


class FrontmatterSchemaTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        schema = json.loads((ROOT / "frontmatter.schema.json").read_text(encoding="utf-8"))
        cls.validator = jsonschema.Draft202012Validator(
            schema, format_checker=jsonschema.FormatChecker()
        )

    def test_accepts_valid_note(self) -> None:
        metadata = {
            "title": "Example",
            "kind": "note",
            "created": "2026-08-28",
            "maturity": "seed",
            "tags": ["webassembly"],
            "aliases": [],
        }
        self.assertEqual([], list(self.validator.iter_errors(metadata)))

    def test_rejects_note_without_maturity(self) -> None:
        metadata = {
            "title": "Example",
            "kind": "note",
            "created": "2026-08-28",
            "tags": [],
            "aliases": [],
        }
        self.assertNotEqual([], list(self.validator.iter_errors(metadata)))

    def test_rejects_uncontrolled_tag_spelling(self) -> None:
        metadata = {
            "title": "Example",
            "kind": "map",
            "created": "2026-08-28",
            "tags": ["Not Kebab Case"],
            "aliases": [],
        }
        self.assertNotEqual([], list(self.validator.iter_errors(metadata)))


class MarkdownTests(unittest.TestCase):
    def test_heading_anchors_include_duplicate_suffixes(self) -> None:
        anchors = github_heading_anchors("# A Title\n\n## Repeat\n\n## Repeat\n")
        self.assertEqual({"a-title", "repeat", "repeat-1"}, anchors)

    def test_link_destination_removes_title_and_angle_brackets(self) -> None:
        self.assertEqual("notes/a.md", link_destination('notes/a.md "title"'))
        self.assertEqual("notes/a file.md", link_destination("<notes/a file.md>"))

    def test_external_link_has_no_local_target(self) -> None:
        self.assertIsNone(local_link_target(ROOT / "README.md", "https://example.com"))


class FrontmatterParsingTests(unittest.TestCase):
    def test_dates_remain_strings(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "example.md"
            path.write_text(
                "---\ntitle: Example\nkind: map\ncreated: 2026-08-28\n"
                "tags: []\naliases: []\n---\n# Example\n",
                encoding="utf-8",
            )
            metadata, body = parse_frontmatter(path)
        self.assertEqual("2026-08-28", metadata["created"])
        self.assertIn("# Example", body)


if __name__ == "__main__":
    unittest.main()
