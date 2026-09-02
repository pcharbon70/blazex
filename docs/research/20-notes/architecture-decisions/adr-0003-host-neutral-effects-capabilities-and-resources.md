---
title: "ADR-0003 — Host-neutral effects, capabilities, and resources"
kind: note
created: "2026-09-02"
maturity: stable
tags:
  - architecture-decision
  - bh-00
  - capabilities
  - effects
  - host-neutrality
aliases:
  - "ADR-0003"
---

# ADR-0003 — Host-neutral effects, capabilities, and resources

## Decision metadata

| Field | Value |
| --- | --- |
| Status | accepted |
| Date | 2026-09-02 |
| Owners | architecture, product, effects, and host-adapter stewards |
| Scope | `packages/blazex_effects`, host adapters, capability providers, and component-family packages |
| Supersedes | None |
| Superseded by | None |
| Review triggers | a component requires a concrete host API; capability grants cannot express a security boundary; or resource lifetime cannot be represented portably |

## Context

Components need timers, focus, measurement, storage, networking, clipboard,
files, dialogs, and other side effects. Browser globals, Phoenix sockets, OS
objects, and toolkit handles are not portable and have different authority and
lifetime rules.

## Decision

Components request typed effects through named capabilities. Capability
providers return values or opaque resource identifiers and expose explicit
grant, denial, cancellation, timeout, fallback, ownership, transfer, and
disposal semantics. Concrete Web APIs, server transports, OS APIs, and toolkit
objects exist only behind adapters.

Capability presence is negotiated by the selected profile. Components must
handle absence or denial according to a declared fallback policy.

## Rationale

An explicit effect boundary makes side effects testable, keeps authority out of
component state, and allows browser, headless, WebView, and native hosts to
provide different implementations without changing component contracts.

## Consequences

### Enables

- Deterministic headless effect traces and fault injection.
- Least-authority capability grants per profile or component subtree.
- Resource cleanup across component termination and renderer replacement.

### Constrains

- Components may not call browser globals, server transports, OS APIs, or
  toolkit objects directly.
- Providers must implement observable cancellation and disposal behavior.
- Missing capabilities and fallbacks are part of catalog/support claims.

## Alternatives considered

- **Direct platform calls:** rejected because they couple component logic to one
  execution host and hide authority.
- **A single unrestricted host object:** rejected because it weakens typing,
  least authority, and conformance testing.
- **Server execution for every effect:** rejected because local interaction and
  offline behavior would require a remote round trip and server trust would be
  conflated with host capability.

## Impact review

### Compatibility

Effect names, payloads, results, resource identities, and lifecycle semantics
are versioned BlazeX contracts. Provider implementation details are not.

### Security and trust

Capabilities are denied by default unless a profile/provider grants them.
Opaque identifiers must not expose privileged handles, and remote commands
still require independent server authorization.

### Accessibility

Focus, announcements, modality, reduced motion, and related operations must be
represented semantically so each host can use its accessibility mechanisms.

### Packaging and dependencies

`blazex_effects` may depend on `blazex_core`; concrete providers depend on the
effect contracts. Web, server, OS, and toolkit dependencies remain outward.

### Cross-backend portability

Capabilities advertise support and fallback behavior. A component is portable
only across profiles whose declared capabilities satisfy its requirements.

## Evidence basis

- [Canonical vocabulary](../blazex-canonical-vocabulary.md)
- [Host-neutral architecture synthesis](../host-neutral-blazex-architecture-and-native-control-backends.md)
- [Repository ownership and dependency map](../../10-maps/blazex-repository-ownership-and-dependency-map.md)

## Unresolved evidence

BH-02 must prove the first effect envelope, denial/fallback path, cancellation,
and resource disposal trace. Later milestones must define the capability matrix
for each supported component family and profile.

## Change control

Effects and host-adapter stewards review changes with security, accessibility,
runtime, renderer, and product owners. Changes update the effect schema,
capability matrix, affected host adapters, fixtures, support claims, package
indexes, and acceptance evidence atomically.

## Connections

- [ADR-0001 — Host-neutral semantic component kernel](adr-0001-host-neutral-semantic-component-kernel.md)
- [ADR-0005 — Server adapter and trust boundary](adr-0005-server-adapter-and-trust-boundary.md)
- [ADR-0006 — Profile composition](adr-0006-profile-composition.md)
- [Browser host milestones](../browser-host-implementation-milestones.md)

## Sources

- [WebAssembly JavaScript and Web API notes](../../30-sources/webassembly-community-group-2026-javascript-and-web-api.md)
- [WebAssembly non-web embeddings and WASI notes](../../30-sources/webassembly-community-group-2026-non-web-embeddings-and-wasi.md)
- [Plug documentation notes](../../30-sources/elixir-plug-team-2026-plug-1-20-documentation.md)
