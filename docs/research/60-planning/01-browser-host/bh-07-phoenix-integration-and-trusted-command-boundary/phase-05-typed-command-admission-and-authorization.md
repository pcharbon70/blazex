---
title: "BH-07 Phase 5 - Typed Command Admission and Authorization"
kind: note
created: "2026-09-12"
maturity: developing
tags: [bh-07, commands, authorization, idempotency]
aliases: ["BH-07 phase 5"]
---

# BH-07 Phase 5 - Typed Command Admission and Authorization

Back to the [milestone](README.md).

- [ ] 5 Phase - Typed Command Admission and Authorization.
  - Need: Phase 4 provides authenticated, same-origin, CSRF-protected transport,
    but no closed command envelope, server registration, authorization, or
    replay boundary exists for a later executor.
  - Outcome: the server can admit a bounded typed command intent against static
    declarations and server-owned subject grants, returning a deterministic,
    idempotent receipt without invoking a handler or changing application state.
  - Boundary: no command execution, effects, resource mutation, arbitrary
    module/function resolution, credentials/login provider, generalized role or
    permission system, pushes, reconnect, deployment coordination, production
    support, LiveView, LocalLiveView, or BH-08.

  - [x] 5.1 Section - Authorize and freeze command admission.
    - [x] Bind Phase 4 completion, BH-05 command intent, exact base, workflow,
      and deferrals.
    - [x] Freeze declarations, envelope/schema, subject grants, validation order,
      idempotency, capacity, receipt, redaction, and failure semantics.
    - [x] Activate Phase 5 planning, baseline, integration, and evidence indexes.

  - [ ] 5.2 Section - Implement reusable typed admission authority.
    - [ ] Validate exact command envelopes and closed declarative payload schemas
      without atom creation or dynamic handler resolution.
    - [ ] Re-authenticate server-owned session context and apply exact subject
      grants rather than accepting client authority hints.
    - [ ] Serialize bounded per-session/global admission and exact replay/conflict
      decisions while retaining only one-way request fingerprints.

  - [ ] 5.3 Section - Integrate the Phoenix admission transport.
    - [ ] Add POST `/bh07/commands/admit` behind canonical origin, JSON, bounded
      body, encrypted session cookie, and current CSRF proof checks.
    - [ ] Return bounded no-store receipts/errors with explicit status mapping,
      method handling, and no secret or server-policy projection.
    - [ ] Preserve test-only identity/reset controls, publish truthful admission
      capability, and prove zero handler/effect/resource mutation.

  - [ ] 5.4 Section - Reproduce, review, and publish completion.
    - [ ] Run package/profile tests, mutation validator, archive, dependency,
      JSON, formatting, and patch-hygiene gates.
    - [ ] Publish source-bound evidence, limitations, inherited status, and the
      acceptance decision.
    - [ ] Accept only with deny-by-default typed admission, bounded replay state,
      zero execution, and unchanged LiveView/LocalLiveView deferral.

## Exit gate

An authenticated browser can submit one closed command intent and receive a
server-authorized admission receipt. Unknown, malformed, unauthorized, stale-
proof, replay-conflicting, oversized, or capacity-exhausted inputs cannot be
admitted. No command handler or effect executes in this phase.
