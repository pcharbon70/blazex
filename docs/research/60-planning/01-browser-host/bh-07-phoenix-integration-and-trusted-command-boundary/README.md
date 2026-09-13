---
title: "BH-07 Phoenix Integration and Trusted Command Boundary"
kind: map
created: "2026-09-12"
tags: [archive-navigation, bh-07, phoenix, trusted-boundary]
aliases: ["BH-07 implementation plan"]
---

# BH-07 Phoenix Integration and Trusted Command Boundary

## Purpose

Compose the accepted browser build with Phoenix as a replaceable delivery and
trusted-command adapter. Browser-host, renderer, and component behavior remain
in their owning packages. LiveView and LocalLiveView are **[DEFERRED]** and are
not dependencies, inputs, or completion gates for current BH-07 work.

## Ordered phases

| Phase | Status | Delivery | Dependency |
| --- | --- | --- | --- |
| [1 — Attested Static Delivery Boundary](phase-01-attested-static-delivery-boundary.md) | complete | Serve the accepted BH-06 artifact set through Phoenix under exact manifest cache, integrity, and private-evidence rules while removing LiveView/LocalLiveView from the active profile. | Accepted BH-06 and explicit authorization |
| [2 — Public Bootstrap Envelope](phase-02-public-bootstrap-envelope.md) | complete | Publish a bounded, deterministic, public-only bootstrap envelope tied to the accepted delivery identity without projecting server authority. | Accepted Phase 1 and explicit authorization |
| [3 — Opaque Session and Authentication Projection](phase-03-opaque-session-and-authentication-projection.md) | complete | Add bounded server-owned opaque sessions and a minimal redacted authentication projection without commands or CSRF authority. | Accepted Phase 2 and explicit authorization |
| [4 — CSRF and Origin Security Envelope](phase-04-csrf-and-origin-security-envelope.md) | active | Bind rotating anti-CSRF proofs to opaque sessions and enforce canonical same-origin transport without command authority. | Accepted Phase 3 and explicit authorization |

Later phase decomposition remains a separate planning decision. Phase 4 does
not authorize credentials, a login provider, production identity, roles,
permissions, commands, effects, pushes, reconnect, deployment coordination, support
promotion, LiveView, LocalLiveView, or BH-08.

## Index

### Documents

- [Phase 1 — Attested Static Delivery Boundary](phase-01-attested-static-delivery-boundary.md)
- [Static-delivery contract](static-delivery-contract.md)
- [Phase 1 completion evidence](phase-01-completion.md)
- [Phase 1 review and reconciliation](phase-01-review-and-reconciliation.md)
- [Phase 2 — Public Bootstrap Envelope](phase-02-public-bootstrap-envelope.md)
- [Public-bootstrap contract](public-bootstrap-contract.md)
- [Phase 2 completion evidence](phase-02-completion.md)
- [Phase 2 review and reconciliation](phase-02-review-and-reconciliation.md)
- [Phase 3 — Opaque Session and Authentication Projection](phase-03-opaque-session-and-authentication-projection.md)
- [Opaque-session boundary contract](session-boundary-contract.md)
- [Phase 3 completion evidence](phase-03-completion.md)
- [Phase 3 review and reconciliation](phase-03-review-and-reconciliation.md)
- [Phase 4 — CSRF and Origin Security Envelope](phase-04-csrf-and-origin-security-envelope.md)
- [CSRF and origin security contract](csrf-origin-contract.md)

### Subdirectories

None.

## What belongs here

Prospective, explicitly authorized BH-07 Phoenix integration plans and their
completion reviews belong here. Implementation evidence remains under
`integration/bh-07`; immutable authorization and completion bindings remain
under `assets/bh-07-baseline`.

## Maintaining this index

Index every direct planning document and add later phases only after separate
owner authorization. Keep LiveView and LocalLiveView marked deferred unless a
future planning decision explicitly changes that boundary.
