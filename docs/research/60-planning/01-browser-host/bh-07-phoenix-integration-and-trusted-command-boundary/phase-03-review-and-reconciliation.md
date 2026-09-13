---
title: "BH-07 Phase 3 Review and Reconciliation"
kind: note
created: "2026-09-12"
maturity: developing
tags: [bh-07, sessions, reconciliation, security]
aliases: []
---

# BH-07 Phase 3 Review and Reconciliation

Back to the [plan](phase-03-opaque-session-and-authentication-projection.md)
and [completion evidence](phase-03-completion.md).

## Decision

The Phase 3 candidate is **complete — accept** inside the unsupported
development boundary.

## Review

The reusable registry serializes issuance and rotation through one process,
caps the registry at 256 live records, limits TTL to one hour, and uses 32
cryptographically random bytes per identifier. Expiry is checked before lookup
or allocation. Rotation removes the prior identifier in the same registry
operation, while reset and supervised restart invalidate the whole in-memory
authority set.

Only a fixed public display label and expiry are projected. The profile keeps
the identifier inside Plug's encrypted and signed cookie, clears stale cookies,
and applies `no-store`, exact content length, and `nosniff` to session responses.
Deterministic identities exist only behind test-mode, loopback, same-origin,
header, type, and request-size checks.

## Reconciliation

Thirty package tests, twenty-six profile tests, seven validator mutation tests,
archive validation, dependency inspection, JSON parsing, formatting, and patch
hygiene pass. Active source and dependencies remain free of LiveView and
LocalLiveView coupling.

This is not an authentication system: there is no credential verifier,
production identity provider, authorization role, permission, CSRF token, or
trusted command. The development endpoint uses localhost HTTP, so its qualified
cookie does not set `Secure`; production TLS, proxy, cookie, deployment, and
support policy remain deferred. No browser-process, traffic, production-support,
LiveView, or LocalLiveView claim is made.
