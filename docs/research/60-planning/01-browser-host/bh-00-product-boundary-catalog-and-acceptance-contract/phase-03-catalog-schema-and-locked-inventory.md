---
title: "Phase 3 - Catalog Schema and Locked Inventory"
kind: note
created: "2026-09-02"
maturity: developing
tags:
  - bh-00
  - browser
  - component-catalog
  - implementation-planning
aliases:
  - "BH-00 phase 3"
---

# Phase 3 - Catalog Schema and Locked Inventory

Back to milestone: [README](README.md)

- [ ] 3 Phase - Catalog Schema and Locked Inventory.

  Pin the MudBlazor catalog reference, inventory every relevant family, and
  create a stable machine-validatable BlazeX catalog structure before assigning
  final dispositions, capabilities, fallbacks, or portability claims.

  - [x] 3.1 Section - Lock the reference catalog and extraction boundary.

    Establish reproducible source identity and inclusion rules so the inventory
    cannot drift with a live documentation site or silently omit difficult
    component families.

    - [x] 3.1.1 Task - Pin and document the MudBlazor reference truth.

      The catalog input must identify an exact release and distinguish reviewed
      source evidence from generated documentation, examples, and assumptions.

      - [x] 3.1.1.1 Subtask - Record the MudBlazor v9.9.0 tag or commit, repository URL, relevant source and documentation paths, license identity, review date, and content hashes where practical.
      - [x] 3.1.1.2 Subtask - Identify authoritative inputs for public components, supporting types, services, providers, icons, examples, experimental features, obsolete features, and internal-only implementation helpers.
      - [x] 3.1.1.3 Subtask - Define a later-reference update process that creates a reviewed catalog diff and never mutates BlazeX dispositions automatically.

    - [x] 3.1.2 Task - Define inventory inclusion and normalization rules.

      Families must be counted consistently even when MudBlazor exposes nested
      parts, aliases, generic variants, service APIs, or documentation-only
      groupings.

      - [x] 3.1.2.1 Subtask - Define family, component, subcomponent, supporting type, service, provider, utility, experimental, obsolete, and internal classifications.
      - [x] 3.1.2.2 Subtask - Define normalization for generic variants, inherited bases, nested parts, aliases, renamed components, duplicate documentation entries, and one family spanning multiple source files.
      - [x] 3.1.2.3 Subtask - Record explicit inclusion and exclusion reasons for icons, localization, themes, JavaScript helpers, test components, documentation infrastructure, and non-component services.

  - [ ] 3.2 Section - Define stable catalog identity and metadata schema.

    Create a format that supports human review, deterministic validation, future
    generation, and stable references from roadmaps, phases, tests, and releases.

    - [ ] 3.2.1 Task - Define catalog and family identities.

      Stable BlazeX IDs must survive display-name changes while preserving exact
      traceability to the pinned reference family.

      - [ ] 3.2.1.1 Subtask - Define catalog version, schema version, stable family ID, display name, category, source identities, aliases, parent or part relationships, and lifecycle status.
      - [ ] 3.2.1.2 Subtask - Define uniqueness, casing, ordering, rename, split, merge, deprecation, removal, and reserved-ID rules without deriving runtime atoms from arbitrary catalog data.
      - [ ] 3.2.1.3 Subtask - Require source paths and reference identifiers to remain evidence links rather than public BlazeX API or compatibility promises.

    - [ ] 3.2.2 Task - Define delivery and ownership metadata.

      The schema must reserve every field BH-00 needs while keeping later
      implementation status and evidence separate from planned classification.

      - [ ] 3.2.2.1 Subtask - Define disposition, rationale, delivery tier, target package, prerequisites, optional-package status, payload class, and intended public identity fields.
      - [ ] 3.2.2.2 Subtask - Define required and optional capabilities, fallback, rendering modes, runtime eligibility, backend portability, native strategy, accessibility alternative, and renderer-specific extension fields.
      - [ ] 3.2.2.3 Subtask - Define planned, accepted, implemented, evidenced, supported, deferred, omitted, superseded, and unknown states so a completed row cannot imply delivered behavior.

  - [ ] 3.3 Section - Build the complete normalized inventory artifact.

    Populate the source-facing portion of the catalog and produce deterministic
    human and machine views without making Phase 4 classification decisions
    implicitly.

    - [ ] 3.3.1 Task - Enumerate and normalize every catalog family.

      The inventory must close over the pinned source and expose uncertainty or
      exceptional groupings rather than hiding them in prose.

      - [ ] 3.3.1.1 Subtask - Extract all included public families and supporting entries from the pinned source into stable IDs with categories, source identities, and relationship metadata.
      - [ ] 3.3.1.2 Subtask - Create explicit records for excluded, obsolete, experimental, service-only, infrastructure-only, duplicate, and unresolved entries with reasons.
      - [ ] 3.3.1.3 Subtask - Reconcile the normalized inventory against the existing MudBlazor research note and document every addition, omission, regrouping, or naming difference.

    - [ ] 3.3.2 Task - Establish deterministic catalog stewardship.

      Authored source, generated views, validation, and review reports must have
      clear ownership so generated output cannot become a competing truth.

      - [ ] 3.3.2.1 Subtask - Select the canonical authored format, schema location, generated human-readable view, validation command, and deterministic sort order within the approved repository structure.
      - [ ] 3.3.2.2 Subtask - Define reviewer ownership, change rationale, source-diff report, schema migration, generated-file update, and conflict-resolution procedures.
      - [ ] 3.3.2.3 Subtask - Define queries and summary counts for category, lifecycle, inclusion reason, unresolved status, source coverage, and later disposition completeness.

  - [ ] 3.4 Section - Phase 3 Integration Tests.

    Prove that the pinned source, normalization policy, schema, and inventory
    produce one complete deterministic catalog before classifications are added.

    - [ ] 3.4.1 Task - Validate source coverage and catalog determinism.

      Automated checks and independent review must reject missing source
      families, duplicate identities, stale generation, and unreviewed drift.

      - [ ] 3.4.1.1 Subtask - Validate front matter, schema, stable IDs, enums, relationships, source references, ordering, uniqueness, required fields, and generated-view freshness.
      - [ ] 3.4.1.2 Subtask - Run two clean catalog generations and require byte-identical outputs, stable counts, and no network dependency after the reference input is pinned.
      - [ ] 3.4.1.3 Subtask - Independently sample every category plus all exclusions, obsolete entries, experimental entries, services, nested parts, aliases, and unresolved rows against the pinned source.

    - [ ] 3.4.2 Task - Record completion evidence and deliver the phase.

      Phase completion requires a complete source inventory and valid schema,
      while disposition and support fields may remain deliberately unassigned.

      - [ ] 3.4.2.1 Subtask - Record source revision, extraction inputs, hashes, inventory counts, schema and generation versions, commands, reviewer findings, and unresolved normalization questions.
      - [ ] 3.4.2.2 Subtask - Confirm no catalog row is presented as implemented, supported, portable, or compatible merely because its identity and source relationship are complete.
      - [ ] 3.4.2.3 Subtask - Complete one commit per coherent section and open the Phase 3 PR without beginning Phase 4 disposition assignment.

## Section delivery rule

Complete and verify each coherent section before committing it. Open one PR for
this phase; do not merge without a later request.
