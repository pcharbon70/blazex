---
title: "BH-07 Phase 4 Completion Evidence"
kind: note
created: "2026-09-12"
maturity: developing
tags: [bh-07, csrf, origin, completion]
aliases: []
---

# BH-07 Phase 4 Completion Evidence

Back to the [plan](phase-04-csrf-and-origin-security-envelope.md) and
[review](phase-04-review-and-reconciliation.md).

## Decision

Phase 4 is **complete — accept** for unsupported development evidence.

Each opaque session now owns an independent 32-byte anti-CSRF proof. The raw
proof is returned only to the trusted adapter and authenticated browser
projection, while the server registry retains its SHA-256 digest. Verification
uses constant-time comparison. Rotation is atomic, preserves session expiry,
and immediately invalidates the old proof.

The Phoenix adapter enforces one canonical same-origin value and the current
proof on rotation and authenticated logout. Missing, duplicate, malformed,
decorated, or cross-origin values fail closed. Session responses remain bounded
and `no-store`; the encrypted, signed, HTTP-only, strict-site cookie retains the
opaque identifier and proof. The machine-readable result is in
[`phase-04-csrf-origin-evidence-v0.1.0.json`](../../../../../integration/bh-07/phase-04-csrf-origin-evidence-v0.1.0.json).

Credentials, production identity, roles, permissions, trusted commands,
effects, pushes, reconnect, deployment coordination, production support,
LiveView, LocalLiveView, and BH-08 remain deferred. A later phase requires
separate authorization.
