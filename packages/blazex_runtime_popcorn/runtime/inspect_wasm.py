#!/usr/bin/env python3
"""Inspect the subset of a Wasm binary contract required by BH-01."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Any


SECTION_NAMES = {0: "custom", 1: "type", 2: "import", 3: "function", 4: "table", 5: "memory", 6: "global", 7: "export", 8: "start", 9: "element", 10: "code", 11: "data", 12: "data_count", 13: "tag"}
KIND_NAMES = {0: "function", 1: "table", 2: "memory", 3: "global", 4: "tag"}


class Reader:
    def __init__(self, data: bytes):
        self.data = data
        self.position = 0

    def byte(self) -> int:
        value = self.data[self.position]
        self.position += 1
        return value

    def uleb(self) -> int:
        value = 0
        shift = 0
        while True:
            current = self.byte()
            value |= (current & 0x7F) << shift
            if current & 0x80 == 0:
                return value
            shift += 7
            if shift > 35:
                raise ValueError("oversized unsigned LEB128")

    def name(self) -> str:
        size = self.uleb()
        value = self.data[self.position:self.position + size].decode("utf-8")
        self.position += size
        return value

    def limits(self) -> dict[str, Any]:
        flags = self.uleb()
        minimum = self.uleb()
        maximum = self.uleb() if flags & 0x01 else None
        return {"minimum": minimum, "maximum": maximum, "shared": bool(flags & 0x02), "memory64": bool(flags & 0x04)}


def parse_imports(payload: bytes) -> list[dict[str, Any]]:
    reader = Reader(payload)
    imports = []
    for _ in range(reader.uleb()):
        item: dict[str, Any] = {"module": reader.name(), "name": reader.name()}
        kind = reader.byte()
        item["kind"] = KIND_NAMES.get(kind, f"unknown-{kind}")
        if kind == 0:
            item["type_index"] = reader.uleb()
        elif kind == 1:
            item["element_type"] = reader.byte()
            item["limits"] = reader.limits()
        elif kind == 2:
            item["limits"] = reader.limits()
        elif kind == 3:
            item["value_type"] = reader.byte()
            item["mutable"] = bool(reader.byte())
        elif kind == 4:
            item["attribute"] = reader.byte()
            item["type_index"] = reader.uleb()
        else:
            raise ValueError(f"unsupported import kind {kind}")
        imports.append(item)
    return imports


def parse_exports(payload: bytes) -> list[dict[str, Any]]:
    reader = Reader(payload)
    return [
        {"name": reader.name(), "kind": KIND_NAMES.get(reader.byte(), "unknown"), "index": reader.uleb()}
        for _ in range(reader.uleb())
    ]


def inspect(path: Path) -> dict[str, Any]:
    data = path.read_bytes()
    if data[:4] != b"\0asm" or data[4:8] != b"\x01\0\0\0":
        raise ValueError("not a WebAssembly 1.0 module")
    reader = Reader(data[8:])
    sections = []
    imports: list[dict[str, Any]] = []
    exports: list[dict[str, Any]] = []
    custom_sections = []
    start_index = None
    while reader.position < len(reader.data):
        section_id = reader.byte()
        size = reader.uleb()
        payload = reader.data[reader.position:reader.position + size]
        reader.position += size
        entry: dict[str, Any] = {"id": section_id, "name": SECTION_NAMES.get(section_id, "unknown"), "bytes": size}
        if section_id == 0:
            custom = Reader(payload).name()
            entry["custom_name"] = custom
            custom_sections.append(custom)
        elif section_id == 2:
            imports = parse_imports(payload)
            entry["count"] = len(imports)
        elif section_id == 7:
            exports = parse_exports(payload)
            entry["count"] = len(exports)
        elif section_id == 8:
            start_index = Reader(payload).uleb()
            entry["function_index"] = start_index
        sections.append(entry)
    memory_imports = [item for item in imports if item["kind"] == "memory"]
    raw_strings = [b"/home/", b"/tmp/", b"/inputs/", b"/outputs/", b"BEGIN PRIVATE KEY", b"AWS_SECRET_ACCESS_KEY"]
    forbidden_hits = [needle.decode() for needle in raw_strings if needle in data]
    return {
        "format": "WebAssembly",
        "version": 1,
        "sha256": hashlib.sha256(data).hexdigest(),
        "bytes": len(data),
        "sections": sections,
        "custom_sections": custom_sections,
        "imports": imports,
        "exports": exports,
        "start_function_index": start_index,
        "memory_imports": memory_imports,
        "import_modules": sorted({item["module"] for item in imports}),
        "atomic_opcode_prefix_observed": b"\xfe" in data,
        "forbidden_embedded_strings": forbidden_hits,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("wasm", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    result = inspect(args.wasm)
    rendered = json.dumps(result, indent=2, sort_keys=True) + "\n"
    if args.output:
        args.output.write_text(rendered, encoding="utf-8")
    else:
        print(rendered, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
