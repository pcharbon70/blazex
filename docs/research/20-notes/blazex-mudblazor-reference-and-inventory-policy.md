---
title: "BlazeX MudBlazor reference and inventory policy"
kind: note
created: "2026-09-03"
maturity: stable
tags:
  - bh-00
  - component-catalog
  - mudblazor
  - normalization
  - provenance
aliases:
  - "BlazeX catalog extraction policy"
  - "BH-00 MudBlazor reference lock"
---

# BlazeX MudBlazor reference and inventory policy

## Status and scope

This policy fixes the source truth, extraction boundary, inclusion rules, and
normalization vocabulary for the initial BlazeX component catalog. It prevents
the inventory from drifting with MudBlazor's moving branches or live site and
prevents convenient leaf controls from hiding difficult compound families,
providers, services, obsolete entries, or infrastructure.

The exact machine source is the [MudBlazor v9.9.0 reference
lock](../assets/component-catalog/mudblazor-v9.9.0-reference-lock.json). The
locked raw family input is the [83-name source-family
snapshot](../assets/component-catalog/mudblazor-v9.9.0-source-families.txt).

## Locked reference identity

| Field | Locked value |
| --- | --- |
| Repository | `https://github.com/MudBlazor/MudBlazor.git` |
| Release/tag | `v9.9.0` |
| Commit | `3d85eed63a2c886d0a2e37f9f0cad78be655ad1c` |
| Commit date | 2026-08-23T10:09:30-05:00 |
| Release date | 2026-08-24 |
| Research review | 2026-09-02 |
| License | MIT, upstream `LICENSE` blob `b42f9e95acc46da742dc5da1ca1a8864d2dbfae0` |
| Root tree | `9d22822949515751b9c011e588238dcf5787686a` |
| Component tree | `d3f33e5039ea0974f648f32365242714831f757a` |
| Documentation component tree | `90c6b7127c5e3e24681306effb38604bbf631ff2` |
| Project file blob | `c9d8509eaf4c135fd4b7728914faff2f5f23dacb` |
| Raw family snapshot | 83 sorted names; SHA-256 `c6021b2b52b81a3beafb642ac5c114a5cb753c7dfa7561200aaaf988b394b041` |

Git object IDs bind the reviewed source even if a mutable web page changes.
The SHA-256 binds the local extraction input used by the catalog tooling.

## Evidence precedence

When inputs disagree, inventory decisions use this order:

1. source and project metadata at the locked commit;
2. license, public declarations, attributes, inheritance, and registration at
   the locked commit;
3. tagged documentation source and examples in the same commit;
4. tagged tests as behavioral/relationship evidence;
5. live first-party documentation only as a lead that must be reconciled to
   tagged source; and
6. BlazeX synthesis/assumption, explicitly labeled and never treated as
   upstream fact.

The moving `dev` branch, nightlies, search snippets, third-party component
lists, and a live/generated documentation count are not catalog authority.

## Authoritative extraction paths

| Input | Role |
| --- | --- |
| `src/MudBlazor/Components/` | Primary public/compound component-family closure; every first-level directory must map to an included or explicitly excluded source record. |
| `src/MudBlazor/Base/`, `State/` | Inheritance, parameter/form state, supporting types, and cross-family semantics. |
| `src/MudBlazor/Services/`, `Extensions/ServiceCollectionExtensions.cs` | Service/provider registrations and host capabilities that may require explicit infrastructure records. |
| `Themes/`, `Icons/`, `Styles/`, `TScripts/` | Shared visual/asset/browser infrastructure; not automatically component families. |
| `src/MudBlazor.Docs/Pages/Components/` | Public intent, naming, aliases, examples, and documentation groupings; corroborating rather than source-count authority. |
| `src/MudBlazor.UnitTests/` | Behavior and relationship evidence; never public catalog identity by test-file count. |

## Inventory classifications

| Classification | Meaning | Default inventory treatment |
| --- | --- | --- |
| `family` | Stable product/problem grouping represented by one or more components, parts, services, or helpers. | One primary normalized family record. |
| `component` | Public renderable unit that applications may compose directly. | Child/source identity under a family unless independently product-significant. |
| `subcomponent` | Public or semipublic compound part meaningful only with a parent/context. | Relationship entry under the owning family; separate record only when stable cross-references require it. |
| `supporting-type` | Public option/model/converter/definition/context type used by components. | Relationship/source identity, not a family count by default. |
| `service` | Nonvisual API managing operations, state, or host coordination. | Explicit service-only/infrastructure entry when it affects product capability. |
| `provider` | Root/subtree owner that supplies theme, surface, queue, context, or capability behavior. | Explicit provider relationship; may be a family when publicly installed/composed. |
| `utility` | Reusable helper, builder, observer, layout primitive, or non-product helper. | Include only when it creates a BlazeX public/infrastructure obligation; otherwise explicit exclusion class. |
| `experimental` | Upstream entry explicitly marked unstable/experimental or lacking stable inclusion evidence. | Preserve with experimental lifecycle and no automatic BlazeX commitment. |
| `obsolete` | Upstream entry marked obsolete/deprecated/replaced at the lock. | Preserve as historical source/exclusion record with replacement relationship. |
| `internal` | Implementation-only helper not intended for upstream application use. | Exclude from public family inventory but preserve reason/coverage when encountered in extraction. |

`service-only`, `infrastructure-only`, `documentation-only`, `duplicate`, and
`unresolved` are inventory outcomes used to close the source boundary; they do
not imply BlazeX delivery dispositions.

## Normalization rules

### Families and source files

- One first-level source directory normally yields one source family and one
  stable normalized record, even when it contains many `.razor`, code-behind,
  model, and helper files.
- Multiple source files for a compound system remain one family when they share
  product purpose, parent context, state ownership, and documentation grouping.
- A source file may be cited by multiple relationship entries, but one source
  identity has one primary family owner.

### Generic variants and inheritance

- Closed generic uses and type-parameter variants do not create new families.
- A generic component with materially distinct public product variants records
  those variants as parts/aliases under the same family unless source and docs
  establish separate product identity.
- Inherited bases and shared input/picker/form primitives are supporting or
  infrastructure relationships, not duplicate families for every descendant.

### Nested and compound parts

- Child items, columns, panels, rows, cells, headers, providers, and containers
  are parts of the parent family when they require its context/lifecycle.
- A nested part gets a stable part identity only when plans/tests/docs need to
  reference independent behavior; parts do not inflate the 83-family closure.
- Cross-family primitives such as focus, overlay, field chrome, and picker
  infrastructure retain their own source family when the locked tree does.

### Aliases, renames, duplicates, splits, and merges

- Documentation labels, C# type names, source-directory names, and eventual
  BlazeX display names are separate fields.
- An alias points to one stable record and never creates a second family count.
- A renamed upstream entry preserves old names and source reference; a BlazeX
  rename never rewrites the locked source name.
- Duplicate documentation pages/groupings map to one primary record plus
  explicit duplicate relationships.
- A later split creates new BlazeX IDs with `split-from`; a merge creates a new
  ID with `merged-from`. Existing IDs are never silently recycled.

## Inclusion and exclusion policy

| Area | Treatment | Reason |
| --- | --- | --- |
| 83 component directories | Include in source closure. | This is the reproducible first-level source boundary already audited. |
| Public nested/compound parts | Include as relationships or explicit part records. | Required to understand product semantics without changing family count. |
| Root providers and registered services | Include as provider/service/infrastructure relationships. | They own required state/capabilities even when nonvisual. |
| Material icon constants | Exclude from family count; include icon infrastructure/provenance record. | Thousands of generated glyph names are assets, not UI families. |
| Themes/tokens | Include ThemeProvider family plus shared infrastructure relationship. | Runtime visual policy is a catalog prerequisite, not thousands of families. |
| Localization | Include as cross-cutting infrastructure/capability metadata. | It affects components but is not one visual family per resource/type. |
| JavaScript helpers | Exclude as public family; include host-capability/source relationships. | Browser implementations do not define portable component identity. |
| Tests and test components | Exclude from public inventory; use as evidence links. | Test shape is not public product shape. |
| Documentation infrastructure/examples | Exclude as catalog entries; use for names, aliases, intent, and behavior evidence. | Generated/grouped docs are not one-to-one with source families. |
| Non-component services | Include explicit service/infrastructure records only when they create a BlazeX obligation. | Completeness requires visibility without pretending services are controls. |
| Internal helpers | Exclude with reason when extraction surfaces them. | No public identity or compatibility promise. |
| Experimental/obsolete entries | Preserve explicitly with lifecycle/reason. | Difficult or historical rows must not disappear silently. |

## Reference update process

A future MudBlazor reference requires a new immutable lock and catalog version;
it never edits the old release in place.

1. Fetch an exact signed/tagged source reference and record commit, tree/blob,
   release, license, and review identities.
2. Extract a new sorted raw source snapshot and verify its count/hash offline.
3. Produce a source-tree/path diff and classify every add/remove/rename/change.
4. Normalize the new source-facing catalog using the then-current schema.
5. Produce a catalog diff covering IDs, names, aliases, relationships,
   lifecycle, source coverage, and unresolved entries.
6. Review license/provenance and every exceptional normalization.
7. Accept/reject each BlazeX consequence explicitly. Never copy upstream
   grouping, tier, disposition, fallback, or support status automatically.
8. Preserve the old lock, source snapshot, catalog, reports, and decisions.

An upstream addition is evidence to review, not an automatic BlazeX component
commitment. An upstream removal does not automatically remove a BlazeX family.

## Explicit non-claims

- The 83-directory closure is not 83 implemented or supported BlazeX controls.
- Source paths and names are evidence identifiers, not BlazeX API names.
- MudBlazor nested parts, C# generics, parameters, services, and providers do not
  dictate Elixir modules or runtime atoms.
- Tagged documentation/source identity does not establish accessibility,
  behavior, visual, renderer, package, or .NET compatibility.
- Phase 3 inventory completeness does not assign Phase 4 dispositions.

## Change control

Reference changes require catalog, product, provenance/license, architecture,
and documentation owners. Normalization exceptions additionally require the
owner of the affected family area. Update the lock, snapshot, source-diff,
schema/catalog version, generated view, review report, maps, and acceptance
evidence atomically.

## Connections

- [MudBlazor-inspired component system](mudblazor-inspired-component-system-for-blazex.md)
- [MudBlazor component-system map](../10-maps/mudblazor-inspired-component-system.md)
- [ADR-0008 — No .NET compatibility contract](architecture-decisions/adr-0008-no-dotnet-compatibility-contract.md)
- [BH-00 Phase 3 plan](../60-planning/01-browser-host/bh-00-product-boundary-catalog-and-acceptance-contract/phase-03-catalog-schema-and-locked-inventory.md)

## Sources

- [MudBlazor v9.9.0 source architecture](../30-sources/mudblazor-project-2026-v9-9-source-architecture.md)
- [MudBlazor v9.9 component catalog and documentation](../30-sources/mudblazor-project-2026-component-documentation.md)
- [MudBlazor source-audit journal](../50-journal/2026-09-02-mudblazor-component-system-deep-dive.md)
