---
title: "BH-07 Opaque Session Boundary Contract"
kind: note
created: "2026-09-12"
maturity: developing
tags: [bh-07, session, security, contract]
aliases: []
---

# BH-07 Opaque Session Boundary Contract

Back to the [milestone](README.md) and [Phase 3](phase-03-opaque-session-and-authentication-projection.md).

The registry accepts only a trusted server-side subject identifier and a fixed
public display label. It generates an opaque random session identifier, stores
session records only on the server, applies a one-hour maximum TTL, and retains
at most 256 live sessions. Expired records are pruned before capacity decisions.
Rotation atomically invalidates the prior identifier; revocation is idempotent;
process restart invalidates every identifier.

The public projection contains only protocol, authentication state, display
label, and expiry. It never contains the session identifier, credentials,
roles, permissions, allowed actions, CSRF material, or mutation authority.
Anonymous, unknown, expired, revoked, malformed, or post-restart identifiers
cannot be upgraded by client claims.

The Phoenix cookie is encrypted, signed, HTTP-only, strict-site, and scoped to
the host adapter. Test issuance/reset is loopback, same-origin, explicitly
header-gated, and unavailable outside test mode. Logout is same-origin and
idempotent. All responses are bounded and `no-store`.

CSRF tokens and trusted commands are not implemented in this phase. LiveView
and LocalLiveView remain **[DEFERRED]**.
