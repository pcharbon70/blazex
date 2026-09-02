---
title: "ADR-0006 — Profile composition"
kind: note
created: "2026-09-02"
maturity: stable
tags:
  - architecture-decision
  - bh-00
  - monorepo
  - profiles
aliases:
  - "ADR-0006"
---

# ADR-0006 — Profile composition

## Decision metadata

| Field | Value |
| --- | --- |
| Status | accepted |
| Date | 2026-09-02 |
| Owners | architecture, product, release, and profile stewards |
| Scope | `profiles/browser_phoenix`, `profiles/browser_plug`, `profiles/headless`, and all reusable packages |
| Supersedes | None |
| Superseded by | None |
| Review triggers | reusable logic appears in a profile; an architecture axis can no longer be selected independently; or a new supported product composition is proposed |

## Context

BlazeX needs executable products without allowing the first Phoenix application
to own the framework. Runtime, execution host, renderer, capability provider,
server adapter, packaging shell, and component families vary independently and
need reproducible dependency graphs.

## Decision

Executable profiles are composition roots. They select independent packages,
configuration, lockfiles, assets, release/deployment examples, galleries, and
profile-level tests. Reusable framework semantics remain in their owning
packages.

`browser_phoenix` is the first canonical delivery profile. `browser_plug`
proves the server adapter and LiveView stack are replaceable. `headless` proves
the browser host, DOM, JavaScript, Phoenix, and Plug are unnecessary for
portable contract execution.

## Rationale

Explicit composition roots make dependency claims executable, keep releases
reproducible, and allow support to be stated per profile without multiplying
component implementations.

## Consequences

### Enables

- Independent lockfiles and end-to-end evidence for each supported graph.
- Replacement tests for server and renderer adapters.
- Future desktop, WebView, native-process, or standalone-Wasm profiles without
  moving core ownership.

### Constrains

- Profiles may not become hidden package roots or duplicate reusable behavior.
- Every profile must declare its complete axis selection and capability set.
- Cross-profile behavior differences must be explicit support/capability data.

## Alternatives considered

- **One umbrella application for all products:** rejected because optional
  dependencies and support boundaries would be difficult to verify.
- **Phoenix project as the repository root:** rejected because Phoenix would
  become the implicit owner of portable packages.
- **Separate repository per host:** rejected for the initial architecture
  because shared contracts and conformance changes need atomic review.

## Impact review

### Compatibility

Support is claimed for named profiles and modes. Package compatibility does not
imply that every arbitrary composition is supported.

### Security and trust

Each profile declares capability grants, server trust boundary, transport,
content/security policy, and deployment assumptions independently.

### Accessibility

Profile acceptance includes the selected renderer's accessibility mapping and
all mode-specific fallbacks; accessibility cannot be inferred from component
support alone.

### Packaging and dependencies

Profiles depend outward on selected reusable packages. Packages never depend on
profiles. Browser/Plug excludes Phoenix, LiveView, LocalLiveView, and the
LiveView DOM adapter directly and transitively.

### Cross-backend portability

Headless is the minimum semantic execution proof. New renderer/host profiles
reuse contracts and add conformance evidence rather than forking components.

## Evidence basis

- [Repository ownership and dependency map](../../10-maps/blazex-repository-ownership-and-dependency-map.md)
- [Canonical vocabulary](../blazex-canonical-vocabulary.md)
- [Browser host milestones](../browser-host-implementation-milestones.md)

## Unresolved evidence

BH-01 and later phases must initialize projects, pin dependencies, prove graph
exclusions, and define which profile/mode combinations receive support status.

## Change control

Architecture and release stewards review profile changes with package,
security, accessibility, build, and product owners. Profile manifests,
dependency maps, support matrices, release evidence, and acceptance records
change together.

## Connections

- [ADR-0001 — Host-neutral semantic component kernel](adr-0001-host-neutral-semantic-component-kernel.md)
- [ADR-0004 — Renderer backend separation](adr-0004-renderer-backend-separation.md)
- [ADR-0005 — Server adapter and trust boundary](adr-0005-server-adapter-and-trust-boundary.md)
- [BH-00 Phase 1 plan](../../60-planning/01-browser-host/bh-00-product-boundary-catalog-and-acceptance-contract/phase-01-terminology-and-architecture-decision-baseline.md)

## Sources

- [Phoenix documentation notes](../../30-sources/phoenix-framework-2026-phoenix-1-8-documentation.md)
- [Plug documentation notes](../../30-sources/elixir-plug-team-2026-plug-1-20-documentation.md)
- [Popcorn documentation and source notes](../../30-sources/software-mansion-2026-popcorn-documentation-and-source.md)
