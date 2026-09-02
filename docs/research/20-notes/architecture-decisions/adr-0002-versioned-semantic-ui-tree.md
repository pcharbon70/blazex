---
title: "ADR-0002 — Versioned semantic UI tree"
kind: note
created: "2026-09-02"
maturity: stable
tags:
  - architecture-decision
  - bh-00
  - renderer-contract
  - semantic-ui
aliases:
  - "ADR-0002"
---

# ADR-0002 — Versioned semantic UI tree

## Decision metadata

| Field | Value |
| --- | --- |
| Status | accepted |
| Date | 2026-09-02 |
| Owners | architecture, product, UI-tree, and renderer-contract stewards |
| Scope | `packages/blazex_ui_tree`, `packages/blazex_renderer`, component families, and renderer backends |
| Supersedes | None |
| Superseded by | None |
| Review triggers | a supported renderer cannot lower the tree; a semantic requirement can only be stored in renderer output; or the tree schema needs a breaking revision |

## Context

A portable component cannot emit HTML/HEEx for a native renderer or native
widget calls for a browser renderer. BlazeX needs one inspectable output that
preserves meaning while allowing each backend to choose concrete controls,
layout mechanisms, resources, and accessibility APIs.

## Decision

Portable render output will be a typed, versioned semantic UI tree. The tree
owns stable node identity, component relationships, semantic roles and states,
layout intent, design-token references, event bindings, accessibility intent,
and opaque resource identifiers. It is neither HTML/HEEx nor any native-toolkit
object graph.

Renderer contracts consume a declared tree version and lower it to concrete
backend operations. Unsupported semantics are surfaced through capability
negotiation and diagnostics rather than silently discarded.

## Rationale

A semantic intermediate representation separates product meaning from platform
mechanics, supplies a deterministic headless oracle, and creates one contract
against which DOM and native mappings can be compared.

## Consequences

### Enables

- Deterministic tree snapshots, diffs, event traces, and accessibility checks.
- Backend-specific optimization without changing component behavior.
- Versioned compatibility and explicit renderer capability negotiation.

### Constrains

- CSS selectors, DOM nodes, HEEx fragments, native handles, and toolkit layout
  objects cannot become portable component state.
- Semantic additions require schema evolution and cross-backend impact review.
- Renderers must diagnose unsupported intent and define degradation behavior.

## Alternatives considered

- **HTML/HEEx as canonical output:** rejected because it privileges the browser
  and embeds server-renderer assumptions.
- **Lowest-common-denominator widget API:** rejected because it would erase
  important accessibility and interaction semantics.
- **Independent model per renderer:** rejected because cross-backend semantic
  equivalence could not be tested.

## Impact review

### Compatibility

Tree versions and negotiated features are BlazeX compatibility surfaces. A
renderer declares the versions and semantics it supports.

### Security and trust

Tree content is data, not trusted markup or executable script. Concrete
renderers must escape or validate materialized content and resource use.

### Accessibility

Accessibility intent is first-class tree data. DOM renderers map it to semantic
elements/ARIA where appropriate; native renderers map it to toolkit and OS
accessibility APIs.

### Packaging and dependencies

`blazex_ui_tree` depends only on inward semantic contracts. Renderers and
component families may depend on it, while it may not depend on renderer code.

### Cross-backend portability

Every public semantic node must define expected DOM, headless, fallback, and
eventual native-control behavior or carry an explicit backend limitation.

## Evidence basis

- [Canonical vocabulary](../blazex-canonical-vocabulary.md)
- [Host-neutral architecture synthesis](../host-neutral-blazex-architecture-and-native-control-backends.md)
- [Repository ownership and dependency map](../../10-maps/blazex-repository-ownership-and-dependency-map.md)

## Unresolved evidence

BH-02 must select the first schema representation, diff semantics, versioning
rules, and prove equivalent traces through the headless, DOM, and native spike.

## Change control

UI-tree and renderer-contract stewards review changes with component,
accessibility, security, and each affected backend owner. Breaking changes need
a superseding ADR or version decision and atomic updates to schemas, capability
matrices, renderer contracts, fixtures, catalogs, and acceptance records.

## Connections

- [ADR-0001 — Host-neutral semantic component kernel](adr-0001-host-neutral-semantic-component-kernel.md)
- [ADR-0004 — Renderer backend separation](adr-0004-renderer-backend-separation.md)
- [ADR-0007 — Native-control portability gate](adr-0007-native-control-portability-gate.md)
- [Browser host milestones](../browser-host-implementation-milestones.md)

## Sources

- [ASP.NET Core component renderer source notes](../../30-sources/dotnet-project-2025-aspnetcore-component-renderer-source.md)
- [Blazor component contracts notes](../../30-sources/microsoft-2026-blazor-component-contracts-styling-and-interop.md)
- [MudBlazor source architecture notes](../../30-sources/mudblazor-project-2026-v9-9-source-architecture.md)
