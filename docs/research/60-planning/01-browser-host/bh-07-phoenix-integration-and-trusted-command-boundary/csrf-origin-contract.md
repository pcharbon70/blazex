---
title: "BH-07 CSRF and Origin Security Contract"
kind: note
created: "2026-09-12"
maturity: developing
tags: [bh-07, csrf, origin, security, contract]
aliases: []
---

# BH-07 CSRF and Origin Security Contract

Back to the [milestone](README.md) and [Phase 4](phase-04-csrf-and-origin-security-envelope.md).

Each newly issued opaque session receives an independent token generated from
32 cryptographically random bytes. The raw token exists only in the trusted
issuance result, the encrypted and signed host cookie, and authenticated public
projection. Server authority retains a SHA-256 digest and compares supplied
proofs in constant time. Rotation requires the current proof, replaces the
digest atomically, preserves expiry, and immediately rejects the old proof.
Expiry, revocation, reset, or process restart invalidates the proof with its
session.

Origin enforcement accepts exactly one syntactically valid HTTP or HTTPS
origin whose canonical scheme, case-insensitive host, and effective port equal
the request endpoint. User-info, path, query, fragment, opaque/null, missing,
duplicated, and cross-origin values fail closed. Production proxy and allowed-
origin configuration are not inferred from untrusted forwarding headers.

Authenticated session projection may add only `csrf_token` to the Phase 3
fields and remains `no-store`. The token is proof of browser-session possession,
not identity, authorization, or command authority. It must never appear in
snapshots, logs, errors, evidence, URLs, or public bootstrap data. Authenticated
logout and token rotation require exact origin and proof validation. Anonymous
same-origin logout remains an idempotent no-op.

No trusted command or effect is implemented in this phase. Credentials, roles,
permissions, LiveView, and LocalLiveView remain **[DEFERRED]**.
