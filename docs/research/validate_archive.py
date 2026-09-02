#!/usr/bin/env python3
"""Validate the BlazeX Research archive's structural invariants."""

from __future__ import annotations

import copy
import json
import re
import sys
from collections import defaultdict
from pathlib import Path
from urllib.parse import unquote, urlsplit

try:
    import jsonschema
    import yaml
except ModuleNotFoundError as error:
    print(
        f"Missing validation dependency: {error.name}. "
        "Run `python3 -m pip install -r requirements-validation.txt`.",
        file=sys.stderr,
    )
    raise SystemExit(2) from error


ROOT = Path(__file__).resolve().parent
SCHEMA_PATH = ROOT / "frontmatter.schema.json"
ARCHIVE_DIRECTORIES = {
    "00-inbox",
    "10-maps",
    "20-notes",
    "30-sources",
    "40-inquiries",
    "50-journal",
    "90-archive",
    "assets",
    "templates",
}
IGNORED_NAMES = {
    ".DS_Store",
    ".git",
    ".mypy_cache",
    ".pytest_cache",
    ".ruff_cache",
    "__pycache__",
}
REQUIRED_README_HEADINGS = {
    "Purpose",
    "What belongs here",
    "Index",
    "Maintaining this index",
}
KNOWLEDGE_FILENAME = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*\.md$")
JOURNAL_FILENAME = re.compile(
    r"^\d{4}-\d{2}-\d{2}(?:-[a-z0-9]+(?:-[a-z0-9]+)*)?\.md$"
)
PLACEHOLDER = re.compile(
    r"\{(?:title|question|YYYY-MM-DD|author|directory title|directory-name)\}"
)
MARKDOWN_LINK = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")


class StringDateLoader(yaml.SafeLoader):
    """A safe YAML loader that does not coerce ISO dates to Python dates."""


StringDateLoader.yaml_implicit_resolvers = copy.deepcopy(
    yaml.SafeLoader.yaml_implicit_resolvers
)
for initial, resolvers in list(StringDateLoader.yaml_implicit_resolvers.items()):
    StringDateLoader.yaml_implicit_resolvers[initial] = [
        (tag, expression)
        for tag, expression in resolvers
        if tag != "tag:yaml.org,2002:timestamp"
    ]


def relative(path: Path) -> str:
    """Return a stable repository-relative display path."""

    try:
        value = path.resolve().relative_to(ROOT)
    except ValueError:
        return str(path)
    return "." if value == Path(".") else value.as_posix()


def is_ignored(path: Path) -> bool:
    """Return whether a path is repository machinery rather than archive data."""

    try:
        parts = path.resolve().relative_to(ROOT).parts
    except ValueError:
        parts = path.parts
    return any(part in IGNORED_NAMES or part.startswith(".") for part in parts)


def visible_children(directory: Path) -> list[Path]:
    """Return direct archive children, excluding repository machinery."""

    return sorted(
        (
            child
            for child in directory.iterdir()
            if not is_ignored(child) and child.name != "README.md"
        ),
        key=lambda child: child.name,
    )


def archive_directories() -> list[Path]:
    """Return the root and every non-generated archive directory."""

    return [
        ROOT,
        *sorted(
            (
                path
                for path in ROOT.rglob("*")
                if path.is_dir() and not is_ignored(path)
            ),
            key=lambda path: path.as_posix(),
        ),
    ]


def completed_markdown_files() -> list[Path]:
    """Return completed knowledge documents and directory READMEs."""

    files: list[Path] = []
    for top_name in sorted(ARCHIVE_DIRECTORIES):
        top = ROOT / top_name
        if not top.is_dir():
            continue
        for path in sorted(top.rglob("*.md")):
            if is_ignored(path):
                continue
            if top_name == "templates" and path.name != "README.md":
                continue
            if top_name == "00-inbox" and path.name != "README.md":
                continue
            files.append(path)
    return files


def parse_frontmatter(path: Path) -> tuple[dict[str, object], str]:
    """Parse one completed Markdown file into metadata and body."""

    text = path.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        raise ValueError("missing opening YAML frontmatter delimiter")
    end = text.find("\n---\n", 4)
    if end < 0:
        raise ValueError("missing closing YAML frontmatter delimiter")
    metadata = yaml.load(text[4:end], Loader=StringDateLoader)
    if not isinstance(metadata, dict):
        raise ValueError("frontmatter must be a YAML mapping")
    return metadata, text[end + 5 :]


def link_destination(raw: str) -> str:
    """Remove optional Markdown angle brackets and link titles."""

    value = raw.strip()
    if value.startswith("<"):
        close = value.find(">")
        return value[1:close] if close >= 0 else value[1:]
    return value.split(maxsplit=1)[0]


def local_link_target(source: Path, raw: str) -> tuple[Path, str] | None:
    """Resolve a Markdown destination, returning None for external links."""

    destination = link_destination(raw)
    parsed = urlsplit(destination)
    if parsed.scheme or parsed.netloc:
        return None
    decoded_path = unquote(parsed.path)
    target = source if not decoded_path else source.parent / decoded_path
    return target.resolve(), unquote(parsed.fragment)


def github_heading_anchors(markdown: str) -> set[str]:
    """Approximate GitHub heading IDs, including duplicate suffixes."""

    anchors: set[str] = set()
    occurrences: defaultdict[str, int] = defaultdict(int)
    for line in markdown.splitlines():
        match = re.match(r"^#{1,6}\s+(.+?)\s*#*\s*$", line)
        if not match:
            continue
        heading = re.sub(r"<[^>]+>", "", match.group(1))
        heading = re.sub(r"[`*_~]", "", heading).strip().lower()
        slug = re.sub(r"[^\w\- ]", "", heading, flags=re.UNICODE)
        slug = re.sub(r"\s+", "-", slug)
        suffix = occurrences[slug]
        occurrences[slug] += 1
        anchors.add(slug if suffix == 0 else f"{slug}-{suffix}")
    return anchors


def validate() -> tuple[list[str], dict[str, int]]:
    """Run all checks and return errors plus summary counts."""

    errors: list[str] = []
    counts: defaultdict[str, int] = defaultdict(int)

    try:
        schema = json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))
        jsonschema.Draft202012Validator.check_schema(schema)
    except (OSError, json.JSONDecodeError, jsonschema.SchemaError) as error:
        return [f"{relative(SCHEMA_PATH)}: invalid JSON Schema: {error}"], counts

    validator = jsonschema.Draft202012Validator(
        schema, format_checker=jsonschema.FormatChecker()
    )
    records: dict[Path, tuple[dict[str, object], str]] = {}

    for top_name in sorted(ARCHIVE_DIRECTORIES):
        if not (ROOT / top_name).is_dir():
            errors.append(f"{top_name}/: missing canonical archive directory")

    for path in completed_markdown_files():
        counts["completed_documents"] += 1
        try:
            metadata, body = parse_frontmatter(path)
        except (OSError, ValueError, yaml.YAMLError) as error:
            errors.append(f"{relative(path)}: {error}")
            continue
        records[path.resolve()] = (metadata, body)
        schema_errors = validator.iter_errors(metadata)
        for schema_error in sorted(
            schema_errors, key=lambda item: list(item.absolute_path)
        ):
            location = ".".join(str(part) for part in schema_error.absolute_path)
            errors.append(
                f"{relative(path)}: frontmatter {location or '<root>'}: "
                f"{schema_error.message}"
            )

        h1 = re.search(r"^#\s+(.+?)\s*$", body, flags=re.MULTILINE)
        title = str(metadata.get("title", ""))
        if h1 is None:
            errors.append(f"{relative(path)}: missing H1")
        elif path.name == "README.md":
            if not h1.group(1).replace("`", "").startswith(title):
                errors.append(
                    f"{relative(path)}: H1 {h1.group(1)!r} does not match title "
                    f"{title!r}"
                )
        elif h1.group(1) != title:
            errors.append(
                f"{relative(path)}: H1 {h1.group(1)!r} does not match title {title!r}"
            )

        if path.name == "README.md":
            continue
        kind = metadata.get("kind")
        filename_pattern = JOURNAL_FILENAME if kind == "journal" else KNOWLEDGE_FILENAME
        if not filename_pattern.fullmatch(path.name):
            errors.append(
                f"{relative(path)}: filename does not follow the convention for {kind}"
            )
        top_name = path.relative_to(ROOT).parts[0]
        destinations = {
            "map": "10-maps",
            "note": "20-notes",
            "source": "30-sources",
            "inquiry": "40-inquiries",
            "journal": "50-journal",
        }
        expected = destinations.get(kind)
        if top_name not in {"90-archive", "assets"} and expected and top_name != expected:
            errors.append(f"{relative(path)}: kind {kind!r} belongs in {expected}/")

    for path in sorted(ROOT.rglob("*.md")):
        if is_ignored(path):
            continue
        if path.parent == ROOT / "templates" or path == ROOT / "AGENTS.md":
            continue
        if path.parent == ROOT / "00-inbox" and path.name != "README.md":
            continue
        for line_number, line in enumerate(
            path.read_text(encoding="utf-8").splitlines(), start=1
        ):
            if PLACEHOLDER.search(line):
                errors.append(
                    f"{relative(path)}:{line_number}: unresolved template placeholder"
                )

    links_by_source: defaultdict[Path, set[Path]] = defaultdict(set)
    incoming_from_conceptual: defaultdict[Path, set[Path]] = defaultdict(set)
    for path in sorted(ROOT.rglob("*.md")):
        if is_ignored(path):
            continue
        text = path.read_text(encoding="utf-8")
        for line_number, line in enumerate(text.splitlines(), start=1):
            for raw in MARKDOWN_LINK.findall(line):
                resolved = local_link_target(path, raw)
                if resolved is None:
                    continue
                target, fragment = resolved
                counts["local_links"] += 1
                if link_destination(raw).startswith("/"):
                    errors.append(
                        f"{relative(path)}:{line_number}: local link must be relative: {raw}"
                    )
                    continue
                if not target.exists():
                    errors.append(
                        f"{relative(path)}:{line_number}: missing local link target: {raw}"
                    )
                    continue
                links_by_source[path.resolve()].add(target)
                if target.suffix.lower() == ".md" and fragment:
                    anchors = github_heading_anchors(target.read_text(encoding="utf-8"))
                    if fragment not in anchors:
                        errors.append(
                            f"{relative(path)}:{line_number}: missing heading fragment "
                            f"#{fragment} in {relative(target)}"
                        )

                source_record = records.get(path.resolve())
                source_is_conceptual = path == ROOT / "README.md" or (
                    source_record is not None
                    and path.name != "README.md"
                    and source_record[0].get("kind") == "map"
                )
                if source_is_conceptual:
                    incoming_from_conceptual[target].add(path.resolve())

    for directory in archive_directories():
        counts["directories"] += 1
        readme = directory / "README.md"
        if not readme.is_file():
            errors.append(f"{relative(directory)}: missing README.md")
            continue
        text = readme.read_text(encoding="utf-8")
        headings = set(re.findall(r"^##\s+(.+?)\s*$", text, flags=re.MULTILINE))
        if directory != ROOT:
            for missing in sorted(REQUIRED_README_HEADINGS - headings):
                errors.append(f"{relative(readme)}: missing section ## {missing}")
            if not re.search(r"^###\s+Subdirectories\s*$", text, flags=re.MULTILINE):
                errors.append(f"{relative(readme)}: missing ### Subdirectories")
            if not re.search(
                r"^###\s+(?:Documents|Files|Templates)\s*$",
                text,
                flags=re.MULTILINE,
            ):
                errors.append(
                    f"{relative(readme)}: missing ### Documents, ### Files, or "
                    "### Templates"
                )

        indexed_targets = links_by_source.get(readme.resolve(), set())
        for child in visible_children(directory):
            expected = child / "README.md" if child.is_dir() else child
            if expected.resolve() not in indexed_targets:
                errors.append(
                    f"{relative(readme)}: unindexed direct child {child.name!r}"
                )

    completed_paths = set(records)
    for path, (metadata, _body) in sorted(
        records.items(), key=lambda item: relative(item[0])
    ):
        if path.name == "README.md":
            continue
        outgoing = {
            target
            for target in links_by_source.get(path, set())
            if target == ROOT / "README.md" or target in completed_paths
        }
        if not outgoing and not incoming_from_conceptual.get(path):
            errors.append(f"{relative(path)}: no conceptual body link or incoming map link")

    identifiers: dict[str, defaultdict[str, list[Path]]] = {
        key: defaultdict(list) for key in ("citation_key", "doi", "url")
    }
    for path, (metadata, _body) in records.items():
        if metadata.get("kind") != "source":
            continue
        counts["source_documents"] += 1
        for key, values in identifiers.items():
            value = metadata.get(key)
            if value:
                values[str(value).casefold()].append(path)
    for key, values in identifiers.items():
        for value, paths in sorted(values.items()):
            if len(paths) > 1:
                joined = ", ".join(relative(path) for path in sorted(paths))
                errors.append(f"duplicate {key} {value!r}: {joined}")

    return sorted(set(errors)), counts


def main() -> int:
    errors, counts = validate()
    if errors:
        print(f"Archive validation failed with {len(errors)} error(s):")
        for error in errors:
            print(f"- {error}")
        return 1

    print(
        "Archive validation passed: "
        f"{counts['completed_documents']} completed documents, "
        f"{counts['directories']} directories, "
        f"{counts['local_links']} local links, and "
        f"{counts['source_documents']} source notes checked."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
