---
title: "ADR-0004 — Renderer backend separation"
kind: note
created: "2026-09-02"
maturity: stable
tags:
  - architecture-decision
  - bh-00
  - liveview
  - renderer
aliases:
  - "ADR-0004"
---

# ADR-0004 — Renderer backend separation

## Decision metadata

| Field | Value |
| --- | --- |
| Status | accepted |
| Date | 2026-09-02 |
| Owners | architecture, product, renderer, and integration stewards |
| Scope | `packages/blazex_renderer`, all `blazex_renderer_*` packages, and renderer-facing integration suites |
| Supersedes | None |
| Superseded by | None |
| Review triggers | standalone DOM requires LiveView; a renderer bypasses semantic contracts; or a new backend needs an incompatible renderer root |

## Context

The browser profile may benefit from LiveView or LocalLiveView lowering, but
BlazeX also requires a standalone DOM renderer for Plug, browser-local use, and
WebView compositions. Headless and future native-control renderers need the same
semantic input without browser or server dependencies.

## Decision

`blazex_renderer` defines the host-neutral renderer behavior, generation and
capability negotiation, diagnostics, and materialized-resource lifecycle.
Concrete backends are separate packages.

`blazex_renderer_dom` is server-framework independent and must have no Phoenix,
Plug, LiveView, or LocalLiveView dependency. Optional LiveView/LocalLiveView
render-data, patch, transport, and version coupling belongs only in
`blazex_renderer_dom_liveview`. `blazex_renderer_headless` is the deterministic
oracle. Future native backends remain separate packages after their gate.

## Rationale

Separating the renderer contract from implementations makes backend replacement
an explicit profile choice, preserves a minimal Plug graph, and confines
framework/version coupling to a named adapter.

## Consequences

### Enables

- Standalone DOM, optional LiveView lowering, headless, and future native
  backends can coexist.
- Renderer conformance can compare normalized trees, events, effects, and
  accessibility outcomes.
- Profiles can replace a renderer without redefining component semantics.

### Constrains

- DOM-specific convenience APIs cannot enter portable renderer contracts.
- LiveView optimization must not become a transitive dependency of standalone
  DOM or Plug.
- Renderer-specific capability limits and fallbacks must be explicit.

## Alternatives considered

- **One LiveView-based DOM renderer:** rejected because it prevents standalone
  DOM and violates the Plug profile boundary.
- **One package containing all backends:** rejected because dependency and
  platform coupling would become inseparable.
- **Components render directly:** rejected because backend behavior could not be
  negotiated, traced, or replaced consistently.

## Impact review

### Compatibility

The renderer contract and semantic tree versions are stable compatibility
surfaces; concrete backend internals and framework integrations are not.

### Security and trust

Renderers materialize untrusted component data safely and cannot infer server
authority. LiveView transport does not make browser state trusted.

### Accessibility

Each renderer must document and test how semantic accessibility intent maps to
its platform, including diagnostics and fallbacks for unsupported semantics.

### Packaging and dependencies

Concrete renderer packages depend inward on `blazex_renderer` and semantic
contracts. The optional LiveView adapter depends on standalone DOM, never the
reverse. Plug excludes the LiveView adapter directly and transitively.

### Cross-backend portability

Normalized headless traces are the comparison baseline. Backend-specific nodes
or effects require explicit capability markers and cannot silently redefine a
portable component family.

## Evidence basis

- [Repository ownership and dependency map](../../10-maps/blazex-repository-ownership-and-dependency-map.md)
- [Host-neutral architecture synthesis](../host-neutral-blazex-architecture-and-native-control-backends.md)
- [Canonical vocabulary](../blazex-canonical-vocabulary.md)

## Unresolved evidence

BH-02 must prove the renderer protocol and headless/DOM equivalence. The bounded
native spike must show that the contract can create real toolkit controls.

## Change control

Renderer stewards review changes with component, accessibility, security,
integration, and affected profile owners. Changes update dependency maps,
capability matrices, conformance fixtures, profile graphs, and acceptance
records in one reviewed change.

## Connections

- [ADR-0002 — Versioned semantic UI tree](adr-0002-versioned-semantic-ui-tree.md)
- [ADR-0006 — Profile composition](adr-0006-profile-composition.md)
- [ADR-0007 — Native-control portability gate](adr-0007-native-control-portability-gate.md)
- [Browser host milestones](../browser-host-implementation-milestones.md)

## Sources

- [LiveView documentation and source notes](../../30-sources/phoenix-framework-2026-liveview-1-2-documentation-and-source.md)
- [LocalLiveView release notes](../../30-sources/software-mansion-2026-local-live-view-first-release.md)
- [ASP.NET Core renderer source notes](../../30-sources/dotnet-project-2025-aspnetcore-component-renderer-source.md)
