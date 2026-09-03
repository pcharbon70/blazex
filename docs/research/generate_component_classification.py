#!/usr/bin/env python3
"""Generate the deterministic joined view of the BlazeX component classification."""

from __future__ import annotations

import argparse
import json
import sys
from collections import Counter
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parent
CLASSIFICATION_PATH = ROOT / "assets" / "component-catalog" / "blazex-component-classification-v0.1.0.json"
SOURCE_CATALOG_PATH = ROOT / "assets" / "component-catalog" / "blazex-component-catalog-v0.1.0.json"
OUTPUT_PATH = ROOT / "assets" / "component-catalog" / "blazex-component-classification-v0-1-0-generated.md"


def _escape(value: Any) -> str:
    return str(value).replace("|", "\\|").replace("\n", " ")


def render_classification(classification: dict[str, Any], source_catalog: dict[str, Any]) -> str:
    source_by_id = {record["id"]: record for record in source_catalog["families"]}
    disposition_counts = Counter(record["product"]["disposition"] for record in classification["families"])
    tier_counts = Counter(record["product"]["delivery_tier"] for record in classification["families"])
    package_counts = Counter(record["product"]["target_package"] for record in classification["families"])
    remote_counts = Counter(record["remote"]["authority"] for record in classification["families"])
    fallback_counts = Counter(record["fallback"]["primary"] for record in classification["families"])
    portability_counts = Counter(record["portability"]["status"] for record in classification["families"])
    native_counts = Counter(record["portability"]["native_strategy"] for record in classification["families"])

    lines = [
        "---",
        'title: "BlazeX component classification v0.1.0"',
        "kind: note",
        'created: "2026-09-03"',
        "maturity: stable",
        "tags:",
        "  - bh-00",
        "  - component-catalog",
        "  - generated",
        "  - product-classification",
        "aliases:",
        '  - "BlazeX generated component classification"',
        "---",
        "",
        "# BlazeX component classification v0.1.0",
        "",
        "> Generated deterministically from the locked Phase 3 source catalog and canonical Phase 4 classification. Do not edit by hand.",
        "",
        "## Classification identity",
        "",
        "| Field | Value |",
        "| --- | --- |",
        f"| Classification ID | `{_escape(classification['classification_id'])}` |",
        f"| Classification/schema version | `{classification['classification_version']}` / `{classification['schema_version']}` |",
        f"| Stage / status | `{classification['stage']}` / `{classification['status']}` |",
        f"| Source catalog | `{classification['source_catalog']}` |",
        f"| Source catalog SHA-256 | `{classification['source_catalog_sha256']}` |",
        f"| Families / exceptions | {len(classification['families'])} / {len(classification['exceptions'])} |",
        "",
        "## Summary",
        "",
        "| Dimension | Counts |",
        "| --- | --- |",
        f"| Disposition | {', '.join(f'`{key}` {value}' for key, value in sorted(disposition_counts.items()))} |",
        f"| Delivery tier | {', '.join(f'`{key}` {value}' for key, value in sorted(tier_counts.items()))} |",
        f"| Package | {', '.join(f'`{key}` {value}' for key, value in sorted(package_counts.items()))} |",
        f"| Remote authority | {', '.join(f'`{key}` {value}' for key, value in sorted(remote_counts.items()))} |",
        f"| Primary fallback | {', '.join(f'`{key}` {value}' for key, value in sorted(fallback_counts.items()))} |",
        f"| Portability | {', '.join(f'`{key}` {value}' for key, value in sorted(portability_counts.items()))} |",
        f"| Native strategy | {', '.join(f'`{key}` {value}' for key, value in sorted(native_counts.items()))} |",
        "",
        "## Families",
        "",
        "| Stable ID | Source family | Disposition | Tier | Package | Prerequisites | Remote | Fallback | Portability | Native strategy | Classification / implementation |",
        "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |",
    ]
    for record in classification["families"]:
        source = source_by_id[record["family_id"]]
        prerequisites = ", ".join(f"`{value}`" for value in record["product"]["prerequisites"]) or "—"
        lines.append(
            "| `{family_id}` | `{source}` | `{disposition}` | `{tier}` | `{package}` | {prerequisites} | `{remote}` | `{fallback}` | `{portability}` | `{native}` | `{classification_state}` / `{implementation_state}` |".format(
                family_id=_escape(record["family_id"]),
                source=_escape(source["source"]["source_family"]),
                disposition=_escape(record["product"]["disposition"]),
                tier=_escape(record["product"]["delivery_tier"]),
                package=_escape(record["product"]["target_package"]),
                prerequisites=prerequisites,
                remote=_escape(record["remote"]["authority"]),
                fallback=_escape(record["fallback"]["primary"]),
                portability=_escape(record["portability"]["status"]),
                native=_escape(record["portability"]["native_strategy"]),
                classification_state=record["classification_state"],
                implementation_state=record["implementation_state"],
            )
        )
    lines.extend([
        "",
        "## Source-closure exception outcomes",
        "",
        "| Exception ID | Product disposition | Classification / implementation | Rationale |",
        "| --- | --- | --- | --- |",
    ])
    for record in classification["exceptions"]:
        lines.append(
            f"| `{record['exception_id']}` | `{record['product_disposition']}` | `{record['classification_state']}` / `{record['implementation_state']}` | {_escape(record['rationale'])} |"
        )
    lines.extend([
        "",
        "## Evidence boundary",
        "",
        "Every row is an accepted product classification layered over locked source evidence.",
        "No row is implemented, evidenced, supported, native-compatible, renderer-compatible,",
        "or API-compatible. Public identities are provisional BlazeX planning names and are not",
        "runtime atoms or a MudBlazor/.NET compatibility surface.",
        "",
        "## Connections",
        "",
        "- [Disposition, tier, and package policy](../../20-notes/blazex-component-disposition-tier-and-package-policy.md)",
        "- [Phase 4 implementation evidence](../../60-planning/01-browser-host/bh-00-product-boundary-catalog-and-acceptance-contract/phase-04-implementation-evidence.md)",
        "",
        "## Sources",
        "",
        "- [Locked Phase 3 source catalog](blazex-component-catalog-v0.1.0.json)",
        "- [Canonical Phase 4 classification](blazex-component-classification-v0.1.0.json)",
        "",
    ])
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--classification", type=Path, default=CLASSIFICATION_PATH)
    parser.add_argument("--source-catalog", type=Path, default=SOURCE_CATALOG_PATH)
    parser.add_argument("--output", type=Path, default=OUTPUT_PATH)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    try:
        classification = json.loads(args.classification.read_text(encoding="utf-8"))
        source_catalog = json.loads(args.source_catalog.read_text(encoding="utf-8"))
        rendered = render_classification(classification, source_catalog)
        if args.check:
            if args.output.read_text(encoding="utf-8") != rendered:
                print(f"Generated component classification is stale: {args.output}", file=sys.stderr)
                return 1
        else:
            args.output.write_text(rendered, encoding="utf-8", newline="\n")
    except (OSError, UnicodeError, json.JSONDecodeError, ValueError, KeyError) as error:
        print(f"Component classification generation failed: {error}", file=sys.stderr)
        return 1
    action = "matches" if args.check else "wrote"
    print(f"Component classification generation {action} {args.output}: {len(classification['families'])} families, {len(classification['exceptions'])} exceptions, stage {classification['stage']}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
