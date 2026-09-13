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
| [4 — CSRF and Origin Security Envelope](phase-04-csrf-and-origin-security-envelope.md) | complete | Bind rotating anti-CSRF proofs to opaque sessions and enforce canonical same-origin transport without command authority. | Accepted Phase 3 and explicit authorization |
| [5 — Typed Command Admission and Authorization](phase-05-typed-command-admission-and-authorization.md) | complete | Admit bounded typed command intents against static declarations and private subject grants without executing handlers or effects. | Accepted Phase 4, BH-05 action contract, and explicit authorization |
| [6 — Atomic Trusted Command Execution](phase-06-atomic-trusted-command-execution.md) | complete | Execute one closed counter mutation against server-owned revision state with exact replay and bounded redacted audit. | Accepted Phase 5 and explicit authorization |
| [7 — Authenticated Server Push and Resynchronization](phase-07-authenticated-server-push-and-resynchronization.md) | active | Push redacted counter updates to authenticated Phoenix Channels with bounded replay-or-snapshot cursor recovery and no socket command authority. | Accepted Phase 6 and explicit authorization |

Later phase decomposition remains a separate planning decision. Phase 7
authorizes only one authenticated counter-update topic and server-side cursor
resynchronization; it does not authorize socket commands, arbitrary topics,
durable history, browser-managed reconnect, routing/deployment coordination,
effects, production support, LiveView, LocalLiveView, or BH-08.

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
- [Phase 4 completion evidence](phase-04-completion.md)
- [Phase 4 review and reconciliation](phase-04-review-and-reconciliation.md)
- [Phase 5 — Typed Command Admission and Authorization](phase-05-typed-command-admission-and-authorization.md)
- [Typed command admission contract](command-admission-contract.md)
- [Phase 5 completion evidence](phase-05-completion.md)
- [Phase 5 review and reconciliation](phase-05-review-and-reconciliation.md)
- [Phase 6 — Atomic Trusted Command Execution](phase-06-atomic-trusted-command-execution.md)
- [Trusted execution contract](trusted-execution-contract.md)
- [Phase 6 completion evidence](phase-06-completion.md)
- [Phase 6 review and reconciliation](phase-06-review-and-reconciliation.md)
- [Phase 7 — Authenticated Server Push and Resynchronization](phase-07-authenticated-server-push-and-resynchronization.md)
- [Authenticated server push contract](server-push-contract.md)

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
