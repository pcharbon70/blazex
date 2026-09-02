---
title: "ADR-0001 — Host-neutral semantic component kernel"
kind: note
created: "2026-09-02"
maturity: stable
tags:
  - architecture-decision
  - bh-00
  - component-model
  - host-neutrality
aliases:
  - "ADR-0001"
---

# ADR-0001 — Host-neutral semantic component kernel

## Decision metadata

| Field | Value |
| --- | --- |
| Status | accepted |
| Date | 2026-09-02 |
| Owners | architecture, product, and component-kernel stewards |
| Scope | `packages/blazex_core` and every component-family package |
| Supersedes | None |
| Superseded by | None |
| Review triggers | a portable lifecycle cannot be expressed without a host type; a new runtime or host requires kernel changes; or executable conformance evidence contradicts host neutrality |

## Context

BlazeX begins with a browser/Phoenix product profile, but its intended component
semantics must remain reusable with Plug, headless tests, WebViews, non-browser
runtimes, and future native-control renderers. Treating Phoenix, Popcorn, the
DOM, JavaScript, or a native toolkit as the component model would make that
portability impossible to test or preserve.

## Decision

BlazeX will define one host-neutral semantic component kernel. The kernel owns
component identity, lifecycle, local state transitions, semantic events, local
messages, and typed command intent. It will not expose Phoenix, Plug, LiveView,
DOM, JavaScript, Popcorn, WebView, operating-system, or native-toolkit types.

Runtime substrates execute the kernel; execution hosts supply lifecycle and
capabilities; renderers lower semantic output; server adapters validate remote
commands; and profiles compose those independent selections. None of them is
the definition of a BlazeX component.

## Rationale

A small semantic kernel gives every backend the same behavior to execute and
lets conformance tests distinguish portable component defects from adapter
defects. It also keeps the first browser profile from becoming an accidental
framework root.

## Consequences

### Enables

- The same component contract can be tested headlessly and rendered through
  DOM or future native-control backends.
- Runtime, host, renderer, server adapter, and shell can evolve independently.
- Component-family packages can publish semantics without taking browser or
  Phoenix dependencies.

### Constrains

- Host services must be represented through portable effects and capabilities.
- Renderer details must be represented through semantic UI rather than
  component-owned DOM or toolkit operations.
- Convenience APIs that leak a concrete adapter into the kernel are forbidden,
  even when only the first browser profile needs them.

## Alternatives considered

- **Phoenix or LiveView as the component root:** rejected because server
  integration would define local component semantics and exclude Plug/headless
  composition.
- **Popcorn as the component model:** rejected because Popcorn is one runtime
  adapter, not the portable contract.
- **One abstraction per backend:** rejected because behavior would diverge and
  no common conformance target would exist.

## Impact review

### Compatibility

Public compatibility is defined against BlazeX contracts, not Razor, .NET,
Phoenix components, DOM APIs, or a native widget API.

### Security and trust

Local component state is untrusted at a server boundary. Typed command intent
does not grant authority; server adapters authenticate, authorize, validate,
and audit remote effects.

### Accessibility

Components express semantic roles, state, relationships, and interaction intent
without assuming ARIA or a native accessibility API. Renderers must preserve
that intent in their platform mapping.

### Packaging and dependencies

`blazex_core` is an inward dependency. Concrete runtimes, hosts, renderers,
server frameworks, and profiles may depend on it; it may not depend on them.

### Cross-backend portability

Portable components must execute against the headless contract and remain
lowerable by both DOM and native-control proofs before their API is stabilized.

## Evidence basis

- [Canonical vocabulary](../blazex-canonical-vocabulary.md)
- [Repository ownership and dependency map](../../10-maps/blazex-repository-ownership-and-dependency-map.md)
- [Host-neutral architecture synthesis](../host-neutral-blazex-architecture-and-native-control-backends.md)

## Unresolved evidence

BH-02 must demonstrate an executable vertical slice across headless, DOM, and
an actual native toolkit without adding backend types to the kernel.

## Change control

Architecture and component-kernel stewards review changes with affected runtime,
host, renderer, security, accessibility, and product owners. A material change
requires a superseding ADR plus atomic updates to the vocabulary, ownership map,
roadmap, package boundaries, compatibility claims, and acceptance evidence.

## Connections

- [ADR-0002 — Versioned semantic UI tree](adr-0002-versioned-semantic-ui-tree.md)
- [ADR-0003 — Host-neutral effects, capabilities, and resources](adr-0003-host-neutral-effects-capabilities-and-resources.md)
- [ADR-0006 — Profile composition](adr-0006-profile-composition.md)
- [BH-00 Phase 1 plan](../../60-planning/01-browser-host/bh-00-product-boundary-catalog-and-acceptance-contract/phase-01-terminology-and-architecture-decision-baseline.md)

## Sources

- [Popcorn documentation and source notes](../../30-sources/software-mansion-2026-popcorn-documentation-and-source.md)
- [Phoenix documentation notes](../../30-sources/phoenix-framework-2026-phoenix-1-8-documentation.md)
- [Blazor component contracts notes](../../30-sources/microsoft-2026-blazor-component-contracts-styling-and-interop.md)
