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

- [BH-04 protocol validator](validate_bh04_protocol.py) — current Phase 2 bindings, scope and schema agreement.
- [BH-04 protocol tests](test_validate_bh04_protocol.py) — isolated negative governance checks.

- [BH-04 history](bh04_history.py) — exact authorized Phase 1 snapshot reproduction, never current protocol validation.

- [BH-04 activation validator](validate_bh04_activation.py) — immutable handoff, dependency and empty-evidence gate.
- [BH-04 activation tests](test_validate_bh04_activation.py) — mutation tests for fail-closed governance.

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
python3 validate_bh02_activation.py
python3 -m unittest test_validate_bh02_activation.py
python3 validate_bh02_semantics.py
python3 -m unittest test_validate_bh02_semantics.py
python3 validate_bh02_effects.py
python3 -m unittest test_validate_bh02_effects.py
python3 validate_bh02_intent.py
python3 -m unittest test_validate_bh02_intent.py
python3 validate_bh02_renderer.py
python3 -m unittest test_validate_bh02_renderer.py
python3 validate_bh02_dom.py
python3 -m unittest test_validate_bh02_dom.py
python3 validate_bh02_native.py
python3 -m unittest test_validate_bh02_native.py
python3 validate_bh02_acceptance.py
python3 -m unittest test_validate_bh02_acceptance.py
python3 validate_bh03_activation.py
python3 -m unittest test_validate_bh03_activation.py
python3 validate_bh03_compatibility.py
python3 -m unittest test_validate_bh03_compatibility.py
python3 validate_bh03_startup.py
python3 -m unittest test_validate_bh03_startup.py
python3 validate_bh03_roots.py
python3 -m unittest test_validate_bh03_roots.py
python3 validate_bh03_resilience.py
python3 -m unittest test_validate_bh03_resilience.py
python3 validate_bh03_profile.py
python3 -m unittest test_validate_bh03_profile.py
python3 validate_bh03_measurements.py
python3 -m unittest test_validate_bh03_measurements.py
python3 validate_bh03_acceptance.py
python3 -m unittest test_validate_bh03_acceptance.py
python3 validate_bh03_correction.py
python3 -m unittest test_validate_bh03_correction.py

# Phase 8 remains a historical revise record. Its source exceptions are
# restricted by Phase 9 authorization; renewed acceptance uses Phase 9.
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
- [`planning_policy.py`](planning_policy.py) — shared fail-closed validation for explicitly bound research-planning amendments
- [`test_validate_browser_product_envelope.py`](test_validate_browser_product_envelope.py) — focused browser-envelope validator tests
- [`test_validate_component_catalog.py`](test_validate_component_catalog.py) — focused component-catalog validator tests
- [`test_validate_component_classification.py`](test_validate_component_classification.py) — focused Phase 4 classification validator tests
- [`test_validate_bh00_governance.py`](test_validate_bh00_governance.py) — focused Phase 6 reconciliation, review, release, and BH-01 entry validator tests
- [`test_validate_bh01_activation.py`](test_validate_bh01_activation.py) — focused BH-01 approval, evidence-governance, boundary-graph, inactive-slice, and no-dependency fail-closed tests
- [`test_validate_bh02_activation.py`](test_validate_bh02_activation.py) — focused BH-02 authorization, handoff-equivalence, project-graph, forbidden-leakage, and evidence-boundary fail-closed tests
- [`test_validate_bh02_semantics.py`](test_validate_bh02_semantics.py) — focused BH-02 Phase 2 authorization, semantic vocabulary, identity, evaluation, fixture, leakage, and overclaim tests
- [`test_validate_bh02_effects.py`](test_validate_bh02_effects.py) — focused BH-02 Phase 3 event, capability, effect, resource, fixture, leakage, and overclaim tests
- [`test_validate_bh02_intent.py`](test_validate_bh02_intent.py) — focused BH-02 Phase 4 token, layout, accessibility, focus, selection, fixture, leakage, and overclaim tests
- [`test_validate_bh02_renderer.py`](test_validate_bh02_renderer.py) — focused BH-02 Phase 5 renderer capability, lifecycle, headless snapshot, trace, fixture, leakage, and overclaim tests
- [`test_validate_bh02_dom.py`](test_validate_bh02_dom.py) — focused BH-02 Phase 6 DOM surface, browser evidence, dependency, fixture, leakage, and overclaim tests
- [`test_validate_bh02_native.py`](test_validate_bh02_native.py) — focused BH-02 Phase 7 native surface, direct-platform evidence, dependency, fixture, deferral, leakage, and overclaim tests
- [`test_validate_bh02_acceptance.py`](test_validate_bh02_acceptance.py) — focused BH-02 Phase 8 reconciliation, review, overlay, stability, deferral, and downstream-authorization fail-closed tests
- [`test_validate_bh03_activation.py`](test_validate_bh03_activation.py) — focused BH-03 Phase 1 authority, handoff, lifecycle vocabulary, boundary, dependency, empty-evidence, completion-binding, and overclaim tests
- [`test_validate_bh03_compatibility.py`](test_validate_bh03_compatibility.py) — focused BH-03 Phase 2 identity, discovery, prerequisite, manifest, fixture, declaration, evidence-boundary, and overclaim tests
- [`test_validate_bh03_startup.py`](test_validate_bh03_startup.py) — focused BH-03 Phase 3 authorization, artifact-limit, integrity, startup, readiness, fixture, completion-binding, and later-phase overclaim tests
- [`test_validate_bh03_roots.py`](test_validate_bh03_roots.py) — focused BH-03 Phase 4 authorization, exact runtime sharing, independent roots, acknowledgement, fixture, completion-binding, and later-phase overclaim tests
- [`test_validate_bh03_resilience.py`](test_validate_bh03_resilience.py) — focused BH-03 Phase 5 shutdown, loss-generation, bounded recovery, atomic replay, fallback, completion-binding, and overclaim tests
- [`test_validate_bh03_profile.py`](test_validate_bh03_profile.py) — focused BH-03 Phase 6 profile separation, active Chrome/Firefox rows, actual runtime acknowledgements, fallback, shutdown, deferral, and overclaim tests
- [`test_validate_bh03_measurements.py`](test_validate_bh03_measurements.py) — focused BH-03 Phase 7 authorization, repetition, root cleanup, timing, memory capability, failure convergence, budget, support, and acceptance-boundary tests
- [BH-03 Phase 8 acceptance validator](validate_bh03_acceptance.py) — validates review records; use `--require-accepted` to gate downstream work (currently fails with revise).
- [BH-03 historical binding helper](bh03_history.py) — exact authorized Phase 9 source exceptions; not current implementation acceptance.
- [Historical binding tests](test_bh03_history.py) — reject widened, missing, stale, or unauthorized source exceptions.
- [BH-03 Phase 9 current acceptance gate](validate_bh03_correction.py) — superseding acceptance with strict current source, recovery and regression evidence.
- [BH-03 Phase 9 gate tests](test_validate_bh03_correction.py) — reject stale sources, missing replay, false cleanup, hidden obligations and premature support.
- [BH-03 Phase 8 acceptance tests](test_validate_bh03_acceptance.py) — rejects missing evidence, hidden blockers, false deferral passes, and premature acceptance.
- [`test_validate_quality_acceptance.py`](test_validate_quality_acceptance.py) — focused Phase 5 quality-budget and acceptance-traceability validator tests
- [`test_validate_archive.py`](test_validate_archive.py) — focused validator tests
- [`validate_browser_product_envelope.py`](validate_browser_product_envelope.py) — deterministic BH-00 browser-envelope checks
- [`validate_component_catalog.py`](validate_component_catalog.py) — deterministic BH-00 reference and component-catalog checks
- [`validate_component_classification.py`](validate_component_classification.py) — deterministic BH-00 product/package/capability/portability classification checks
- [`validate_bh00_governance.py`](validate_bh00_governance.py) — deterministic BH-00 source-binding, reconciliation, review, release, and readiness checks
- [`validate_bh01_activation.py`](validate_bh01_activation.py) — fail-closed BH-01 approval, inherited-baseline, milestone-ledger, evidence-governance, and repository-activation checks
- [`validate_bh02_activation.py`](validate_bh02_activation.py) — fail-closed BH-02 Phase 1 authorization, inherited-entry, foundation-activation, dependency, leakage, and evidence-state checks
- [`validate_bh02_semantics.py`](validate_bh02_semantics.py) — fail-closed BH-02 Phase 2 semantic-tree, identity, component-evaluation, fixture, and support-limit checks
- [`validate_bh02_effects.py`](validate_bh02_effects.py) — fail-closed BH-02 Phase 3 semantic-event, capability, effect, resource-lifecycle, fixture, and support-limit checks
- [`validate_bh02_intent.py`](validate_bh02_intent.py) — fail-closed BH-02 Phase 4 presentation-intent, ownership, fixture, and support-limit checks
- [`validate_bh02_renderer.py`](validate_bh02_renderer.py) — fail-closed BH-02 Phase 5 renderer lifecycle, deterministic-headless, trace, fixture, and support-limit checks
- [`validate_bh02_dom.py`](validate_bh02_dom.py) — fail-closed BH-02 Phase 6 standalone-DOM lowering, browser-driver, browser-matrix, fixture, and support-limit checks
- [`validate_bh02_native.py`](validate_bh02_native.py) — fail-closed BH-02 Phase 7 portable native lowering, direct adapters, GTK execution, cross-renderer fixtures, deferrals, and support-limit checks
- [`validate_bh02_acceptance.py`](validate_bh02_acceptance.py) — fail-closed BH-02 Phase 8 phase binding, reconciliation, contract, review, acceptance-overlay, and candidate-decision checks
- [`validate_bh03_activation.py`](validate_bh03_activation.py) — fail-closed BH-03 Phase 1 authorization, accepted-handoff, lifecycle-contract, repository-activation, dependency, empty-evidence, and completion-binding checks
- [`validate_bh03_compatibility.py`](validate_bh03_compatibility.py) — fail-closed BH-03 Phase 2 compatibility identity, discovery, prerequisite, strict manifest, profile declaration, fixture, and evidence-state checks
- [`validate_bh03_startup.py`](validate_bh03_startup.py) — fail-closed BH-03 Phase 3 artifact acquisition, startup descriptor, isolated transport, bundle-load, readiness, ownership, fixture, and evidence-state checks
- [`validate_bh03_roots.py`](validate_bh03_roots.py) — fail-closed BH-03 Phase 4 exact-compatible runtime registry, independent root lifecycle, generation acknowledgement, ownership, fixture, and evidence-state checks
- [`validate_bh03_resilience.py`](validate_bh03_resilience.py) — fail-closed BH-03 Phase 5 registry-owned shutdown, exact-generation loss, one replacement, same-handle replay, non-DOM fallback, fixture, and evidence-state checks
- [`validate_bh03_profile.py`](validate_bh03_profile.py) — fail-closed BH-03 Phase 6 Phoenix profile, actual AtomVM/Elixir root lifecycle, active Chrome/Firefox matrix, fallback, shutdown, deferral, and evidence-state checks
- [`validate_bh03_measurements.py`](validate_bh03_measurements.py) — fail-closed BH-03 Phase 7 active-browser repetition, ten-root lifecycle, timing, memory capability, cleanup, declared-failure, budget, deferral, and evidence-state checks
- [`validate_quality_acceptance.py`](validate_quality_acceptance.py) — deterministic BH-00 quality-budget and acceptance-traceability checks
- [`validate_archive.py`](validate_archive.py) — deterministic archive checks
