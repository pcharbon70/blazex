---
title: "BlazeX component catalog schema and governance"
kind: note
created: "2026-09-03"
maturity: stable
tags:
  - bh-00
  - component-catalog
  - governance
  - schema
aliases:
  - "BlazeX catalog schema policy"
  - "BH-00 catalog identity contract"
---

# BlazeX component catalog schema and governance

## Status and purpose

This note defines stable identities and the authored metadata contract for the
BlazeX component catalog. The machine authority is the [catalog JSON
Schema](../assets/component-catalog/blazex-component-catalog.schema.json).
Together they let plans, tests, generated views, and releases cite the same
family without coupling BlazeX API names to MudBlazor source names or confusing
inventory completion with delivery evidence.

Schema version `1.0.0` reserves the complete BH-00 classification surface.
Phase 3 may leave product decisions explicitly unresolved; Phase 4 owns their
assignment.

## Identity layers

| Identity | Purpose | Stability rule |
| --- | --- | --- |
| Schema version | Meaning and shape of fields. | Semantic version; incompatible validation/meaning changes require a major version. |
| Catalog ID | Stable catalog lineage independent of a file/version. | Uppercase `BX-CATALOG-*`; never reused. |
| Catalog version | Immutable authored snapshot within a lineage. | Semantic version; changed whenever canonical data changes. |
| Reference ID | Exact upstream evidence lock. | `mudblazor-v9.9.0` for this catalog version; evidence only. |
| Family ID | Permanent BlazeX planning/product identity. | Uppercase `BX-FAM-*`; never derived into a runtime atom and never recycled. |
| Exception ID | Permanent source-closure/reconciliation identity. | Uppercase `BX-EXC-*`; retained even after resolution. |
| Capability/evidence ID | Cross-record references added by later phases. | Namespaced `BX-CAP-*` and `BX-EVID-*`; existence is validated against their future registries. |

The canonical authored format is JSON. Its path, generated-view path, owner
roles, deterministic sort order, exact source reference, and catalog status
are part of each catalog artifact.

## Family identity and naming rules

- Assign one stable family ID from the normalized product family, not from a
  C# namespace, Razor type, source path, ordinal, display label, or generated
  slug at runtime.
- IDs use ASCII uppercase words separated by one hyphen. Display names preserve
  human typography and may change without changing the ID.
- Records are Unicode-codepoint sorted by family ID. IDs, source-family names,
  and source identities are unique; aliases are unique within a record and may
  not collide ambiguously across active records.
- Source names, paths, and type identifiers remain evidence links. They create
  no BlazeX module, function, attribute, event, package, or compatibility name.
- Catalog strings are data. Implementations must use an allowlisted static
  registry when mapping IDs to modules or existing atoms; arbitrary catalog
  data must never call `String.to_atom/1` or equivalent interning.

## Rename, split, merge, deprecation, and removal

- A BlazeX display-name change keeps the family ID and records the prior name
  as an alias when useful.
- An upstream rename keeps both exact source identities in the appropriate
  versioned catalogs; it does not rewrite historical reference evidence.
- A true BlazeX split allocates new IDs with `split-from` relationships. The old
  ID becomes superseded and remains resolvable.
- A true merge allocates a new ID with `merged-from` relationships unless one
  existing identity remains semantically continuous by explicit review.
- Deprecation/obsolescence records lifecycle and `replaced-by` information. A
  removed or omitted family is retained in historical catalogs.
- IDs are never reassigned after rename, merge, split, deprecation, removal,
  omission, or catalog supersession.

Relationships are directed and use stable IDs. Validators must reject missing
targets, self-relationships where meaningless, duplicate edges, and cycles in
relationship types that require an acyclic ownership/replacement graph.

## Source-facing metadata

Every family carries:

- stable ID, display name, and one governed category;
- exact reference ID, source-family name, source paths, and any reviewed source
  identifiers;
- aliases and explicit parent/part/rename/split/merge/dependency relationships;
- upstream lifecycle status; and
- a nonempty inclusion reason.

The seven categories are organizational views: foundation/provider,
layout/content, actions/feedback, navigation/disclosure, forms/input,
data/visualization, and browser interaction. They do not assign packages,
delivery order, implementation strategy, or renderer support.

Exception records close evidence outside the normalized 83-family list. They
classify excluded, obsolete, experimental, service-only, infrastructure-only,
duplicate, and unresolved entries, including explicit zero-entry findings so a
category cannot disappear from review silently.

## Product classification fields reserved for Phase 4

Each family reserves:

- disposition and rationale;
- delivery tier, target package, prerequisites, optional-package status,
  payload class, and intended public identity;
- required/optional capability IDs and fallback;
- rendering-mode and runtime-eligibility assessments;
- backend portability and native-rendering strategy;
- accessibility alternative and renderer-specific extensions; and
- delivery state plus implementation-evidence IDs.

For the Phase 3 inventory, disposition is `unresolved`, tier/payload values are
`unassigned`, nullable decisions are `null`, lists are empty, portability and
native strategy are `unknown`, assessment states are `unknown`, and delivery
state is `unknown`. These are deliberate nonclaims, not defaults to copy into
Phase 4.

## State semantics

| State | Meaning | Minimum evidence |
| --- | --- | --- |
| `unknown` | No governed conclusion yet. | None; must not imply a plan or delivery. |
| `planned` | Proposed in an approved plan. | Named owner, scope, dependencies, and acceptance target. |
| `accepted` | Product/classification decision approved. | Review record and rationale; no implementation implication. |
| `implemented` | Code exists for the scoped contract. | Repository revision and implementation checks; no support implication. |
| `evidenced` | Required acceptance evidence passes in the stated matrix. | Stable evidence IDs and reproducible results. |
| `supported` | Product commits to the bounded configuration and maintenance policy. | Evidence plus release/support approval. |
| `deferred` | Intentionally postponed with trigger/owner. | Approved rationale and review trigger. |
| `omitted` | Intentionally outside scope. | Approved rationale, alternatives/fallback where applicable. |
| `superseded` | Replaced by another governed identity/decision. | Relationship and preserved history. |

States are not necessarily a monotonic pipeline: defer/omit/supersede are
governed outcomes. `implemented` cannot be inferred from planned or accepted;
`supported` cannot be inferred from implementation or evidence in a different
host/runtime/renderer matrix.

Catalog status (`draft`, `reviewed`, `locked`, `superseded`) concerns the
integrity of the authored inventory version, never component delivery state.
Upstream lifecycle concerns upstream source, never BlazeX support.

## Canonical and generated ownership

- The authored JSON is the only catalog data source. The JSON Schema is the
  shape/meaning authority. A generated Markdown view is review convenience.
- Product/catalog owners approve identity, classification, and lifecycle
  changes. Architecture owners approve capability, backend, renderer, runtime,
  and public-identity consequences. Package owners approve package placement.
  Accessibility/security owners approve affected obligations.
- Every canonical change requires rationale, schema/catalog version review,
  regenerated output, validation, source reconciliation, and affected-plan or
  decision updates.
- Schema migration transforms must preserve stable IDs and historical input;
  lossy or semantic migrations require explicit review and a new major schema
  version.
- Generated conflicts are resolved by reconciling canonical JSON, not by hand
  editing generated Markdown. A clean regeneration must reproduce committed
  output byte for byte without network access.

## Validation obligations

Validation must reject schema errors, unknown fields, duplicate IDs/names,
unstable casing, nondeterministic ordering, missing relationship targets,
source families absent from the locked snapshot, unexpected source families,
missing exception classes, stale generated output, or Phase 3 rows claiming a
post-inventory state.

Queries must be able to report counts by category, upstream lifecycle,
exception/inclusion reason, unresolved state, source coverage, disposition,
delivery tier, package, capability, runtime/mode eligibility, portability,
native strategy, delivery state, and evidence completeness.

## Explicit nonclaims

- Stable identity does not mean the family will ship.
- A source path/name does not define an Elixir API or runtime atom.
- Schema validity does not establish implementation, accessibility, behavior,
  browser support, native support, portability, or compatibility.
- MudBlazor remains evidence for catalog/UX semantics, not a .NET, Razor,
  NuGet, binary, source, or public-API compatibility target.
- The schema does not make the WebAssembly Component Model the UI component
  abstraction.

## Connections

- [Reference and inventory policy](blazex-mudblazor-reference-and-inventory-policy.md)
- [MudBlazor-inspired component system](mudblazor-inspired-component-system-for-blazex.md)
- [BH-00 Phase 3 plan](../60-planning/01-browser-host/bh-00-product-boundary-catalog-and-acceptance-contract/phase-03-catalog-schema-and-locked-inventory.md)

## Sources

- [MudBlazor v9.9.0 source architecture](../30-sources/mudblazor-project-2026-v9-9-source-architecture.md)
- [MudBlazor component catalog and documentation](../30-sources/mudblazor-project-2026-component-documentation.md)
