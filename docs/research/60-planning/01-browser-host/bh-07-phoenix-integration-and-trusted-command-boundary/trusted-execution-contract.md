---
title: "BH-07 Trusted Execution Contract"
kind: note
created: "2026-09-13"
maturity: developing
tags: [bh-07, commands, execution, security]
aliases: []
---

# BH-07 Trusted Execution Contract

Back to the [milestone](README.md) and [Phase 6](phase-06-atomic-trusted-command-execution.md).

## Closed operation

The sole executable command is `counter.increment` with schema
`counter.increment`, payload `{ "amount": 1..10 }`, and the Phase 5 envelope.
The server owns the resource identity, current integer value, current revision,
subject grant, operation, and result construction. No client field can select a
resource, handler, module, function, process, URL, transport, or effect.

## Ordered authority

Execution repeats current session/CSRF authentication and exact Phase 5
admission. Inside one serialized authority it then checks execution replay,
changed-key conflict, global/per-session capacity, the authoritative revision,
and the closed operation before applying one mutation. Exact replay precedes
capacity and revision checks and returns the retained first result. Successful
and stale post-admission outcomes are retained, so a future-revision request
cannot become executable merely because authoritative state later advances.

The key is the opaque session plus idempotency key; the retained fingerprint is
one-way. A changed request using the same key is an idempotency conflict. A new
request with a stale `expected_revision` is rejected without mutation. No
request rejected before admission or for exhausted execution capacity consumes
execution-record capacity.

## Bounds and redaction

At most 256 execution records, 32 per session, and 64 audit entries are kept in
memory. Audit contains sequence, command, correlation identity, outcome,
mutation flag, resulting revision, and a truncated one-way idempotency digest.
Snapshots and responses omit opaque session IDs, CSRF proofs, raw idempotency
keys, command bodies, subject grants, and internal records.

Logout, session replacement, and invalid-session cleanup revoke that session's
execution records. Explicit test reset restores counter value/revision to zero
and advances a generation. Process or application restart loses all in-memory
state; persistence and distributed exact-once behavior are not claimed.

## **[DEFERRED]** scope

General handlers, dynamic resolution, arbitrary effects, external resources,
transactions/databases, credentials/login providers, generalized roles and
permissions, pushes/reconnect, production deployment/support, LiveView,
LocalLiveView, and BH-08 remain deferred.
