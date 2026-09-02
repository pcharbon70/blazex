---
title: "ADR-0005 — Server adapter and trust boundary"
kind: note
created: "2026-09-02"
maturity: stable
tags:
  - architecture-decision
  - bh-00
  - security
  - server-integration
aliases:
  - "ADR-0005"
---

# ADR-0005 — Server adapter and trust boundary

## Decision metadata

| Field | Value |
| --- | --- |
| Status | accepted |
| Date | 2026-09-02 |
| Owners | architecture, product, security, server-integration, and component stewards |
| Scope | `packages/blazex_phoenix`, `packages/blazex_plug`, command contracts, and browser profiles |
| Supersedes | None |
| Superseded by | None |
| Review triggers | client state is proposed as server authority; Phoenix/Plug behavior enters the kernel; or a remote command bypasses validation policy |

## Context

Phoenix and Plug can serve assets, establish sessions, receive commands, push
data, and integrate trusted application work. They do not execute every local
interaction and cannot trust state merely because it was produced by a BlazeX
component running in a browser or another remote process.

## Decision

Phoenix and Plug integrations are server or remote adapters, not execution
hosts, component kernels, or renderer contracts. Portable components may emit
typed command intent. A server adapter authenticates the peer and independently
authorizes, validates, rate-limits where appropriate, executes, and audits the
command before returning typed data or errors.

Client state, semantic trees, events, effects, resource identifiers, and
capability claims remain untrusted server input. The Plug baseline must not
acquire Phoenix, LiveView, LocalLiveView, or the LiveView DOM adapter directly
or transitively.

## Rationale

The boundary preserves local-first interaction and multiple server integrations
without confusing transport with authority. It also makes the security model
explicit enough to test independently of renderer or runtime choices.

## Consequences

### Enables

- Phoenix-rich and smaller Plug profiles over the same component contracts.
- Explicit command schemas, policy hooks, observability, and denial behavior.
- Browser-local and offline interactions that do not require server trust.

### Constrains

- Components cannot treat local authorization state as proof to a server.
- Server adapters cannot reach into component internals as their command API.
- Transport convenience must preserve replay, validation, error, and audit
  semantics defined by the server boundary.

## Alternatives considered

- **Phoenix as the execution host:** rejected because it conflates remote
  coordination with the environment executing local component code.
- **Trust framework-generated client state:** rejected because remote input is
  attacker-controlled regardless of its client-side origin.
- **Phoenix-only integration:** rejected because Plug is an explicit independent
  baseline and portability check.

## Impact review

### Compatibility

Typed command and response schemas are versioned integration contracts.
Phoenix- or Plug-specific routing and transport details are adapter concerns.

### Security and trust

Server policy is fail-closed. Authentication, authorization, validation,
anti-replay/CSRF as applicable, limits, and auditability are server-owned.

### Accessibility

Denied, delayed, disconnected, and failed commands need semantic status/error
outcomes that components can announce and render accessibly.

### Packaging and dependencies

`blazex_phoenix` and `blazex_plug` depend inward on public contracts. Core and
component-family packages do not depend on either. The Plug dependency graph is
tested for the explicit framework exclusions.

### Cross-backend portability

Command intent is renderer-neutral. A DOM, headless, or native renderer can
initiate the same command without carrying transport or server-framework types.

## Evidence basis

- [Canonical vocabulary](../blazex-canonical-vocabulary.md)
- [Repository ownership and dependency map](../../10-maps/blazex-repository-ownership-and-dependency-map.md)
- [Host-neutral architecture synthesis](../host-neutral-blazex-architecture-and-native-control-backends.md)

## Unresolved evidence

Later browser milestones must define the first command envelope, Phoenix and
Plug security hooks, replay/CSRF policy, error semantics, and adversarial tests.

## Change control

Security and server-integration stewards review changes with product, component,
runtime, host, and affected profile owners. Command schemas, threat models,
adapter contracts, dependency checks, support claims, and acceptance records
change atomically.

## Connections

- [ADR-0001 — Host-neutral semantic component kernel](adr-0001-host-neutral-semantic-component-kernel.md)
- [ADR-0003 — Host-neutral effects, capabilities, and resources](adr-0003-host-neutral-effects-capabilities-and-resources.md)
- [ADR-0006 — Profile composition](adr-0006-profile-composition.md)
- [Browser host milestones](../browser-host-implementation-milestones.md)

## Sources

- [Phoenix documentation notes](../../30-sources/phoenix-framework-2026-phoenix-1-8-documentation.md)
- [Plug documentation notes](../../30-sources/elixir-plug-team-2026-plug-1-20-documentation.md)
- [LiveView documentation and source notes](../../30-sources/phoenix-framework-2026-liveview-1-2-documentation-and-source.md)
