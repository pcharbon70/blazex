---
title: "ADR-0008 — No .NET compatibility contract"
kind: note
created: "2026-09-02"
maturity: stable
tags:
  - architecture-decision
  - bh-00
  - compatibility
  - mudblazor
aliases:
  - "ADR-0008"
---

# ADR-0008 — No .NET compatibility contract

## Decision metadata

| Field | Value |
| --- | --- |
| Status | accepted |
| Date | 2026-09-02 |
| Owners | architecture, product, API, legal, and documentation stewards |
| Scope | product language, component catalog, public APIs, package names, visual profiles, and provenance records |
| Supersedes | None |
| Superseded by | None |
| Review triggers | a public claim implies .NET/Razor compatibility; copied upstream material changes provenance obligations; or catalog mapping becomes an API equivalence promise |

## Context

MudBlazor v9.9 is the target reference for component-family breadth and mature
UX behaviors. BlazeX is an Elixir/BEAM component system for Phoenix, Plug, and
other hosts; it will not run MudBlazor assemblies or reproduce its .NET public
surface.

## Decision

MudBlazor is a catalog, interaction, accessibility, and visual-behavior
reference—not a compatibility target. BlazeX makes no .NET, Razor, C#,
Blazor-parameter, NuGet-package, binary, renderer, serialization, source, or
drop-in migration compatibility promise.

BlazeX owns its component names, Elixir APIs, semantic contracts, packaging,
renderer mappings, defaults, and visual profiles. Research and implementation
must preserve source provenance, license notices, and attribution where material
is adapted; behavior may be inspired without copying incompatible code or
branding.

## Rationale

Semantic similarity provides a useful completeness benchmark while allowing an
idiomatic Elixir architecture and host-neutral renderer contract. An explicit
non-compatibility boundary prevents accidental promises that cannot be tested or
maintained.

## Consequences

### Enables

- A comprehensive, familiar component catalog with BlazeX-native contracts.
- Deliberate improvements or omissions where host-neutrality requires them.
- Honest support and migration documentation based on semantic mappings.

### Constrains

- Catalog rows cannot claim API parity from similar names or appearance.
- Documentation must qualify MudBlazor references as inspiration/comparison.
- Any adapted asset, design token, test idea, or code requires provenance and
  license review.

## Alternatives considered

- **Drop-in MudBlazor compatibility:** rejected because it would require .NET,
  Razor, renderer, package, and behavioral contracts outside the product goal.
- **Clone names and APIs selectively:** rejected because partial parity creates
  ambiguous promises and poor Elixir ergonomics.
- **Ignore MudBlazor:** rejected because its catalog and UX maturity provide a
  valuable coverage baseline.

## Impact review

### Compatibility

Only explicit BlazeX versions, profiles, modes, components, and behaviors form
the compatibility contract. MudBlazor mappings are comparative evidence.

### Security and trust

Security assumptions from Blazor/.NET are not inherited. BlazeX threat models
must cover its own runtime, browser bridge, transports, and server adapters.

### Accessibility

MudBlazor behavior is useful evidence, but BlazeX defines and tests its own
semantic accessibility requirements across renderers.

### Packaging and dependencies

No .NET runtime, Razor compiler, NuGet package, or MudBlazor binary is required.
Dependency and license inventories identify any separately reused assets.

### Cross-backend portability

BlazeX contracts are shaped by semantic behavior and multiple backends, not by
Blazor's DOM renderer or WebAssembly hosting implementation.

## Evidence basis

- [MudBlazor-inspired component-system synthesis](../mudblazor-inspired-component-system-for-blazex.md)
- [Canonical vocabulary](../blazex-canonical-vocabulary.md)
- [Host-neutral architecture synthesis](../host-neutral-blazex-architecture-and-native-control-backends.md)

## Unresolved evidence

BH-00 later phases must complete the component-by-component catalog, provenance
rules, visual-profile boundary, and acceptance language before product claims
are published.

## Change control

Product and API stewards review claim changes with legal, documentation,
accessibility, architecture, and catalog owners. The decision register, glossary,
catalog mappings, provenance ledger, support matrix, package metadata, and
acceptance records change atomically.

## Connections

- [ADR-0001 — Host-neutral semantic component kernel](adr-0001-host-neutral-semantic-component-kernel.md)
- [MudBlazor-inspired component-system synthesis](../mudblazor-inspired-component-system-for-blazex.md)
- [Browser host milestones](../browser-host-implementation-milestones.md)
- [BH-00 Phase 1 plan](../../60-planning/01-browser-host/bh-00-product-boundary-catalog-and-acceptance-contract/phase-01-terminology-and-architecture-decision-baseline.md)

## Sources

- [MudBlazor v9.9 source architecture notes](../../30-sources/mudblazor-project-2026-v9-9-source-architecture.md)
- [MudBlazor component documentation notes](../../30-sources/mudblazor-project-2026-component-documentation.md)
- [Blazor component contracts notes](../../30-sources/microsoft-2026-blazor-component-contracts-styling-and-interop.md)
