---
title: "BH-07 Phase 4 Review and Reconciliation"
kind: note
created: "2026-09-12"
maturity: developing
tags: [bh-07, csrf, origin, reconciliation, security]
aliases: []
---

# BH-07 Phase 4 Review and Reconciliation

Back to the [plan](phase-04-csrf-and-origin-security-envelope.md) and
[completion evidence](phase-04-completion.md).

## Decision

The Phase 4 candidate is **complete — accept** inside the unsupported
development boundary.

## Review

CSRF generation and digest replacement occur inside the same serialized
registry that owns session validity. Expiry, revocation, reset, or supervised
restart therefore invalidates both pieces of authority together. Neither
snapshots nor authentication projections from the reusable package expose raw
proofs; the adapter adds the proof only after validating the encrypted cookie
against current server state.

Origin parsing admits only HTTP/HTTPS origins without user-info, path, query,
or fragment and compares canonical scheme, case-insensitive host, and effective
port against the direct endpoint. Authenticated mutation attempts require one
origin and one exact proof. The legacy BH-01 test cleanup was narrowed to its
own cookie key so it cannot clear active BH-07 security state.

## Reconciliation

Thirty-six package tests, twenty-nine profile tests, eight validator mutation
tests, archive validation, dependency inspection, JSON parsing, scoped
formatting, and patch hygiene pass. Active manifests remain free of LiveView
and LocalLiveView dependencies.

The direct request endpoint is not yet a production proxy/allowed-origin
configuration. The localhost development cookie does not set `Secure`. The raw
CSRF token is browser-visible proof, not authorization; XSS defense, production
TLS/proxy policy, credential authentication, roles, permissions, commands,
effects, traffic qualification, production support, LiveView, and LocalLiveView
are not claimed.
