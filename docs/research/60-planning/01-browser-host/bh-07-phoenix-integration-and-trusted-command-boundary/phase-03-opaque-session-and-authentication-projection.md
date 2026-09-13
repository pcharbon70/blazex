---
title: "BH-07 Phase 3 - Opaque Session and Authentication Projection"
kind: note
created: "2026-09-12"
maturity: developing
tags: [bh-07, sessions, authentication, phoenix]
aliases: ["BH-07 phase 3"]
---

# BH-07 Phase 3 - Opaque Session and Authentication Projection

Back to the [milestone](README.md).

- [x] 3 Phase - Opaque Session and Authentication Projection.
  - Need: Phase 2 exposes only anonymous public bootstrap data. The Phoenix
    adapter next needs a bounded server-owned session lifecycle and a minimal
    non-authoritative browser projection before command or CSRF work begins.
  - Outcome: opaque, expiring, revocable server sessions and a redacted
    `/bh07/session` projection with test-only deterministic issuance controls.
  - Boundary: no credentials/login provider, roles, permissions, CSRF tokens,
    commands, effects, pushes, reconnect, deployment coordination, production
    support, LiveView, LocalLiveView, or BH-08 is authorized.

  - [x] 3.1 Section - Authorize and freeze the session boundary.
    - [x] Bind Phase 2 completion, exact base, workflow, and deferrals.
    - [x] Freeze opaque identity, TTL, capacity, pruning, rotation, revocation,
      projection, cookie, test-control, redaction, and failure semantics.
    - [x] Activate Phase 3 planning, baseline, integration, and evidence indexes.

  - [x] 3.2 Section - Implement the reusable bounded session registry.
    - [x] Issue server-generated opaque identifiers for trusted subject inputs.
    - [x] Enforce TTL/capacity, prune expiry, rotate atomically, revoke idempotently,
      and return only minimal authentication projections.
    - [x] Prove concurrency, expiry, capacity recovery, rotation, revocation,
      invalid input, restart invalidation, and snapshot redaction.

  - [x] 3.3 Section - Integrate Phoenix session projection and test controls.
    - [x] Add GET `/bh07/session` with anonymous/authenticated redacted output.
    - [x] Add loopback, same-origin, test-only issuance/reset controls and
      same-origin logout using the encrypted, signed, strict-site host cookie.
    - [x] Update bootstrap capabilities, preserve no-store and bounded responses,
      and prove no identifiers, credentials, roles, or permissions escape.

  - [x] 3.4 Section - Reproduce, review, and publish completion.
    - [x] Run package/profile tests, mutation validator, archive, dependency,
      JSON, formatting, and patch-hygiene gates.
    - [x] Publish evidence, limitations, inherited status, and decision.
    - [x] Accept only with bounded server-owned sessions, redacted projection,
      and unchanged LiveView/LocalLiveView deferral.

## Exit gate

The Phoenix adapter can establish, inspect, expire, rotate, and revoke a
bounded opaque session without exposing its identifier or server authority.
Only a minimal authentication projection reaches the browser. CSRF and trusted
commands remain later, separately authorized work.
