# BlazeX Research Archive

This archive researches an Elixir-authored, host-neutral component framework
that can run through WebAssembly and integrates first with Phoenix and, where
useful, plain Plug. Browser execution through Popcorn/AtomVM is the first
implementation path, not an architectural limit. Fully native desktop
controls are the long-term renderer goal; a desktop webview is an optional
middle profile. The archive separates source evidence, synthesis, active
questions, and time-bound observations so the architecture can evolve without
losing provenance.

MudBlazor v9.9.0 is the current target catalog and interaction/design
reference for the user-facing component library. BlazeX remains a native
Elixir/Phoenix system: it does not seek .NET, Razor, binary, package, API, or
renderer compatibility.

Start at the [home map](10-maps/home.md). Archive-wide authoring and
maintenance conventions are defined in [`AGENTS.md`](AGENTS.md).

## Structure

- [`00-inbox/`](00-inbox/README.md) — unprocessed captures
- [`10-maps/`](10-maps/README.md) — curated paths through subjects and questions
- [`20-notes/`](20-notes/README.md) — ideas and syntheses in the author's own words
- [`30-sources/`](30-sources/README.md) — reading notes and bibliographic records
- [`40-inquiries/`](40-inquiries/README.md) — active research questions
- [`50-journal/`](50-journal/README.md) — dated observations and experiments
- [`60-planning/`](60-planning/README.md) — numbered implementation roadmaps
  and completion evidence
- [`90-archive/`](90-archive/README.md) — inactive or superseded material
- [`assets/`](assets/README.md) — durable research attachments
- [`templates/`](templates/README.md) — document and directory scaffolds

Folders describe what a document is doing. Links, maps, and tags describe what
it is about. Directory READMEs are complete local inventories; maps are
selective conceptual paths.

## Research boundary

The central question is how much of Elixir's programming model can run
usefully across browser and non-browser hosts without confusing
runtime-in-Wasm execution with native application AOT compilation. The
archive covers Blazor, Plug, Phoenix, HEEx, LiveView, browser and non-web
WebAssembly constraints, AtomVM, Popcorn, LocalLiveView, standalone and
embedded runtimes, semantic render trees, DOM and native-control backends,
MudBlazor's catalog and architecture, packaging, state, interop, server
integration, security, testing, and productization.

Research must distinguish:

- facts supported by primary documentation or inspected source;
- measurements made during this research;
- interpretation across sources;
- proposed BlazeX architecture; and
- behavior that remains unverified.

## Frontmatter

Every completed knowledge document begins with YAML frontmatter:

```yaml
---
title: "A human-readable title"
kind: note
created: "2026-09-02"
maturity: seed
tags:
  - webassembly
aliases: []
---
```

[`frontmatter.schema.json`](frontmatter.schema.json) is the authoritative
metadata contract. Document kinds are `note`, `source`, `inquiry`, `map`, and
`journal`. Notes require `maturity: seed | developing | stable`; inquiries
require `status: open | paused | resolved`.

## Working rhythm

1. Capture temporary material in `00-inbox/`.
2. Promote useful material with the closest template.
3. Connect every durable document to another document or map.
4. Preserve a source note for every primary work used substantively.
5. Record local measurements and repository inspections in the journal.
6. Update affected indexes and validate in the same change.

## Validation

From this directory:

```bash
python3 -m pip install -r requirements-validation.txt
python3 validate_archive.py
python3 -m unittest test_validate_archive.py
python3 validate_browser_product_envelope.py
python3 -m unittest test_validate_browser_product_envelope.py
python3 validate_component_catalog.py
python3 -m unittest test_validate_component_catalog.py
python3 generate_component_catalog.py --check
python3 validate_component_classification.py
python3 -m unittest test_validate_component_classification.py
python3 generate_component_classification.py --check
python3 validate_quality_acceptance.py
python3 -m unittest test_validate_quality_acceptance.py
python3 generate_acceptance_registry.py --check
python3 validate_bh00_governance.py
python3 -m unittest test_validate_bh00_governance.py
python3 generate_bh00_release.py --check
python3 validate_bh01_activation.py
python3 -m unittest test_validate_bh01_activation.py
```

The validator checks metadata, placeholders, filenames, local links,
directory inventories, conceptual connections, and duplicate source
identifiers.

## Archive files

- [`AGENTS.md`](AGENTS.md) — research, authoring, and maintenance instructions
- [`frontmatter.schema.json`](frontmatter.schema.json) — metadata schema
- [`generate_component_catalog.py`](generate_component_catalog.py) — deterministic Markdown view generation from the canonical component catalog
- [`generate_component_classification.py`](generate_component_classification.py) — deterministic joined view generation from the locked catalog and Phase 4 classification
- [`generate_bh00_release.py`](generate_bh00_release.py) — deterministic BH-00 baseline index and conditional BH-01 entry-manifest generator
- [`requirements-validation.txt`](requirements-validation.txt) — validator dependencies
- [`generate_acceptance_registry.py`](generate_acceptance_registry.py) — deterministic Phase 5 acceptance registry and coverage-report generator
- [`test_validate_browser_product_envelope.py`](test_validate_browser_product_envelope.py) — focused browser-envelope validator tests
- [`test_validate_component_catalog.py`](test_validate_component_catalog.py) — focused component-catalog validator tests
- [`test_validate_component_classification.py`](test_validate_component_classification.py) — focused Phase 4 classification validator tests
- [`test_validate_bh00_governance.py`](test_validate_bh00_governance.py) — focused Phase 6 reconciliation, review, release, and BH-01 entry validator tests
- [`test_validate_bh01_activation.py`](test_validate_bh01_activation.py) — focused BH-01 approval, evidence-governance, boundary-graph, inactive-slice, and no-dependency fail-closed tests
- [`test_validate_quality_acceptance.py`](test_validate_quality_acceptance.py) — focused Phase 5 quality-budget and acceptance-traceability validator tests
- [`test_validate_archive.py`](test_validate_archive.py) — focused validator tests
- [`validate_browser_product_envelope.py`](validate_browser_product_envelope.py) — deterministic BH-00 browser-envelope checks
- [`validate_component_catalog.py`](validate_component_catalog.py) — deterministic BH-00 reference and component-catalog checks
- [`validate_component_classification.py`](validate_component_classification.py) — deterministic BH-00 product/package/capability/portability classification checks
- [`validate_bh00_governance.py`](validate_bh00_governance.py) — deterministic BH-00 source-binding, reconciliation, review, release, and readiness checks
- [`validate_bh01_activation.py`](validate_bh01_activation.py) — fail-closed BH-01 approval, inherited-baseline, milestone-ledger, evidence-governance, and repository-activation checks
- [`validate_quality_acceptance.py`](validate_quality_acceptance.py) — deterministic BH-00 quality-budget and acceptance-traceability checks
- [`validate_archive.py`](validate_archive.py) — deterministic archive checks
