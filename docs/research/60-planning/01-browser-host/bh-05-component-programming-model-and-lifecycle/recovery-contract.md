---
title: "BH-05 Root Recovery and Disposal Contract"
kind: note
created: "2026-09-09"
maturity: developing
tags:
  - bh-05
  - failure-recovery
  - disposal
aliases: []
---

# BH-05 Root Recovery and Disposal Contract

## Authority

Version `0.1.0-bh05-recovery` follows Phase 9 PR #60 at
`77bf199bebb680b24efef0130b19d93ef181f4d5`. The owner authorized Phase 10,
four verified section commits, one PR and merge, then main synchronization
before branch deletion. Phase 1–9 default roots and accepted evidence remain
unchanged; explicit recovery roots activate the successor lifecycle.

Core owns recovery policy, the guardian, cancellation and portable diagnostics.
The outward UI-tree recovery evaluator supplies semantic fallback and per-owner
cleanup. The runtime-owned renderer/provider ports implement bounded, idempotent
release and forced cleanup; no renderer or server implementation enters Core.

## Failure taxonomy and containment

Malformed declarations/schema/host ingress, stale correlation and scheduling
overload are handled rejection before callbacks. Admitted callback, state/result,
semantic/context/registry, renderer/commit, timeout, crash and cleanup failures
fail the owning process root. Rejected renderer candidates are canceled before
fallback; no partial state or action batch is published. Nested components are
not independent failure boundaries. Sibling roots remain operational.

One recovery guardian owns retry admission. Its worker owns one transition at a
time, invalidates ordinary ingress on failure, cancels queued work and pending
transactions, and releases owned work. Diagnostics contain only safe code/stage,
public root/component identity, generation/revision/sequence, a digest of those
safe classification fields, retry counters and cleanup status. Raw exceptions,
module names, props/state/messages, provider objects and server data are excluded.
Repeated equivalent failures share a fingerprint; changing secret payloads cannot
change a diagnostic. Failure notification is emitted once per failed generation.

## Fallback and retry

Fallback never invokes the failed application. A dedicated `failure` correlation
submits minimal semantic alert/status text and a focus target through the ordinary
renderer submit/commit path. Retry is a declared runtime action, not an arbitrary
application event. The host retains static fallback and reload presentation if
the renderer cannot commit; no browser support credit is implied.
Recovery roots require an explicit static fallback ID in the root specification;
diagnostics carry that ID and the committed fallback digest when available.

Retry sources are declared user, host, changed-input/build and automatic policy.
Requests bind the failed generation and fingerprint. Every admitted retry starts
fresh state and a new generation, without reusing accepted output, pending events,
timers, effects, commands or context subscriptions. Automatic retry is opt-in,
has backoff, permits at most three attempts in a rolling five-second monotonic
window, and latches terminal fallback on exhaustion. No render-loop retry or
effect/command replay occurs. Explicit user/host retry does not erase the automatic
budget. Runtime loss requires host escalation, not whole-VM automatic recovery.

## Cleanup

Invalidate ingress and cancel queued/candidate work and timers first. Cancel
pending provider requests, dispose component owners deepest-first, release leases,
dispose renderer ownership and end the worker. Replacement/retry uses a new
generation only after this cleanup. Context/candidate state is discarded, not
replayed. Repeated disposal returns the same terminal result without callbacks.

All recovery ports run with bounded execution. One root cleanup deadline is
1000 ms, not 1000 ms per lease. Each owner records requested and completed,
failed or timed-out release, with elapsed monotonic time. Failed/timed-out adapter
release may use the declared idempotent forced-cleanup port, never revive component
callbacks. Unconfirmed release remains an observable unresolved leak and blocks
the active gate. Public records are paged to respect portable collection bounds.
Focus redirects to semantic fallback or the host's retained static target;
successful disposal uses the adapter's accepted restoration policy.

## Qualification and exclusions

ERTS/headless failure injection executes `BX-ACC-FAILURE-BX-FAIL-COMPONENT` and
`BX-ACC-FAILURE-BX-FAIL-RESOURCE-CLEANUP`, restart stress, sibling isolation,
generation rejection and bounded cleanup. Raw attempts, timings, leaks, forced
cleanup and trace hashes remain visible. Phase 11 owns browser AtomVM/Wasm and
cross-backend execution; profile owners retain deferred qualification there.
BH-15 offline recovery, whole-VM automatic policy, production reporting,
subtree isolation without processes, command replay and support claims are excluded.
LiveView and LocalLiveView remain explicitly deferred. Phase 11 becomes eligible
only after passing Phase 10 evidence, and still needs authorization.

## Connections

- [Milestone](README.md)
- [Phase 10](phase-10-failure-containment-retry-replacement-and-disposal.md)
- [Scope contract](scope-contract.md)
- [Action contract](action-contract.md)
- [Qualification policy](../../development-environment-and-deferred-qualification-policy.md)
