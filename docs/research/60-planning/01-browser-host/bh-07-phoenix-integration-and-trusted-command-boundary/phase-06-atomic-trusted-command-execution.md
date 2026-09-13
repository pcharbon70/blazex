---
title: "BH-07 Phase 6 - Atomic Trusted Command Execution"
kind: note
created: "2026-09-13"
maturity: developing
tags: [bh-07, commands, execution, idempotency, audit]
aliases: ["BH-07 phase 6"]
---

# BH-07 Phase 6 - Atomic Trusted Command Execution

Back to the [milestone](README.md).

- [ ] 6 Phase - Atomic Trusted Command Execution.
  - Need: Phase 5 can validate and admit a trusted command intent, but it
    deliberately cannot compare authoritative state, apply a mutation, retain
    an execution result, or audit the outcome.
  - Outcome: one disposable counter command executes atomically against
    server-owned state after the Phase 5 trust checks, with exact-once
    idempotency, optimistic revision rejection, bounded audit, and a redacted
    public result.
  - Boundary: this is one closed development fixture, not a general handler,
    effect, persistence, transaction, role, permission, or RPC system. No
    browser effect, dynamic module/function resolution, credentials/login
    provider, pushes, reconnect, deployment coordination, production support,
    LiveView, LocalLiveView, or BH-08.

  - [x] 6.1 Section - Authorize and freeze trusted execution.
    - [x] Bind Phase 5 completion, admission evidence, exact base, delivery
      workflow, action contract, and deferrals.
    - [x] Freeze the closed counter operation, validation order, authoritative
      revision, idempotency, audit, capacity, result, cleanup, and failure
      semantics.
    - [x] Activate Phase 6 planning and baseline indexes.

  - [x] 6.2 Section - Implement the reusable execution authority.
    - [x] Re-authenticate the opaque session and reuse exact Phase 5 admission
      before entering the serialized mutation boundary.
    - [x] Apply only `counter.increment`, compare the server-owned revision,
      retain the first result by session/key/fingerprint, and reject changed
      reuse or stale state without mutation.
    - [x] Bound execution records and redacted audit, revoke session-owned
      records on cleanup, and expose no credentials, tokens, command body, or
      raw idempotency key.

  - [x] 6.3 Section - Integrate the Phoenix execution transport.
    - [x] Add POST `/bh07/commands/execute` behind the Phase 4 origin, JSON,
      bounded-body, encrypted-session, and current-CSRF controls.
    - [x] Return bounded no-store results/errors with explicit status mapping
      and no browser-supplied authority, handler, effect, or resource target.
    - [x] Extend test reset/session cleanup and publish only the truthful,
      narrow trusted-execution capability.

  - [ ] 6.4 Section - Reproduce, review, and publish completion.
    - [ ] Run package/profile tests, mutation validator, archive, dependency,
      JSON, formatting, and patch-hygiene gates.
    - [ ] Publish source-bound evidence, limitations, inherited unsupported
      status, and the acceptance decision.
    - [ ] Accept only with one atomic authorized mutation, exact replay without
      duplicate mutation, bounded redacted audit, and unchanged deferrals.

## Exit gate

An authenticated operator can execute the one declared counter increment and
receive the server-owned value/revision. Exact replay returns the first result
without a second mutation. Unauthorized, malformed, stale, conflicting,
oversized, expired, or capacity-exhausted requests cannot mutate state. The
phase remains an unsupported in-memory development fixture.
