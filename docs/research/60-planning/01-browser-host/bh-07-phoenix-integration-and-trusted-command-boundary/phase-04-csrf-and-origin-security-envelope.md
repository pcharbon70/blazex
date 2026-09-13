---
title: "BH-07 Phase 4 - CSRF and Origin Security Envelope"
kind: note
created: "2026-09-12"
maturity: developing
tags: [bh-07, csrf, origin, phoenix]
aliases: ["BH-07 phase 4"]
---

# BH-07 Phase 4 - CSRF and Origin Security Envelope

Back to the [milestone](README.md).

- [ ] 4 Phase - CSRF and Origin Security Envelope.
  - Need: Phase 3 established authenticated sessions but deliberately exposed no
    anti-CSRF material. A future state-changing command boundary needs one
    reusable, session-bound proof and one exact origin policy first.
  - Outcome: every authenticated session owns a rotating anti-CSRF proof whose
    digest remains server-side, while Phoenix exposes only the raw browser proof
    and enforces canonical same-origin checks on state-changing BH-07 routes.
  - Boundary: no credentials/login provider, production identity integration,
    roles, permissions, commands, effects, pushes, reconnect, deployment
    coordination, production support, LiveView, LocalLiveView, or BH-08.

  - [x] 4.1 Section - Authorize and freeze the security envelope.
    - [x] Bind Phase 3 completion, exact base, workflow, and deferrals.
    - [x] Freeze token entropy, digest ownership, comparison, rotation, origin,
      cookie, response, redaction, and failure semantics.
    - [x] Activate Phase 4 planning, baseline, integration, and evidence indexes.

  - [x] 4.2 Section - Implement reusable CSRF and origin primitives.
    - [x] Bind one 32-byte random anti-CSRF token to each opaque session while
      retaining only its digest in server authority.
    - [x] Verify proofs in constant time and rotate atomically without extending
      session expiry or reviving an invalid session.
    - [x] Canonicalize exact HTTP/HTTPS origins and reject absent, duplicate,
      malformed, user-info, path, query, fragment, or cross-origin input.

  - [ ] 4.3 Section - Integrate the Phoenix security transport.
    - [ ] Return the session proof only in authenticated no-store projections and
      retain it in the encrypted, signed, HTTP-only session cookie.
    - [ ] Add same-origin, proof-authenticated rotation and require the proof for
      authenticated logout before any server-owned state changes.
    - [ ] Preserve gated test issuance/reset, bounded responses, explicit method
      handling, capability truth, and zero command/effect authority.

  - [ ] 4.4 Section - Reproduce, review, and publish completion.
    - [ ] Run package/profile tests, mutation validator, archive, dependency,
      JSON, formatting, and patch-hygiene gates.
    - [ ] Publish source-bound evidence, limitations, inherited status, and the
      acceptance decision.
    - [ ] Accept only with session-bound CSRF proofs, exact origin policy, no
      command execution, and unchanged LiveView/LocalLiveView deferral.

## Exit gate

An authenticated browser can obtain, prove, and rotate one session-bound CSRF
token. Missing, stale, malformed, duplicated, or cross-origin proof attempts
cannot alter server-owned session state. Trusted commands remain later,
separately authorized work.
