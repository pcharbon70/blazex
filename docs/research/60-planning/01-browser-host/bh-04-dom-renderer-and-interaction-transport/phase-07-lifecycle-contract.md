---
title: "BH-04 Phase 7 lifecycle contract"
kind: note
created: "2026-09-08"
maturity: developing
tags:
  - bh-04
  - effects
  - resources
aliases: []
---

# BH-04 Phase 7 lifecycle contract

## Authority and compatibility

The owner explicitly authorized Phase 7, including the previously rejected
effect-emission path. [Authority](../../../assets/bh-04-baseline/blazex-bh-04-phase-07-authorization-v0.1.0.json)
binds the synchronized base and exact accepted inputs. Sections 7.1–7.4 each
receive one commit, followed by one reviewed PR, merge, main synchronization,
then feature-branch deletion. No prior artifact or protocol is redefined.

An explicitly negotiated internal `blazex.dom-effects/1` companion wraps the
unchanged `blazex.dom-continuity/1` transaction. Its digest binds the continuity
envelope and complete ordered effects list. Effect-enabled sessions negotiate
`blazex.host-bridge/4`; legacy sessions still reject emissions. Existing public
component callbacks and host-neutral Effect/Result structures do not change.

## Barriers

1. Preflight: clone bounded closed data, verify digests, identity, grants,
   generation/revision, unique effect IDs, dependencies, timeouts and fallbacks.
   No browser effect may run. Unsupported/ungranted requests reject atomically.
2. Pre-commit: retain bounded rollback state; no effect execution.
3. Commit: apply and verify the existing atomic DOM transaction synchronously.
4. Restore focus/selection through the existing semantic intent rules, then
   publish controlled state. These are renderer intents, not new capabilities.
5. Post-commit: run only negotiated `time.schedule` effects in list order.
   Dependencies must name preceding IDs. Failed dependencies cancel dependents.
6. Paint observation is observational only; neither required for timer effects
   nor a promise of visible pixels. No animation-frame observer is acquired.
7. Acknowledgement: correlate every terminal result and both envelope digests.
   Promote provisional semantic state only after exact successful compound ack.
   Results remain typed data available to the session owner; there is no new
   component result callback and no fabricated semantic event.
8. Disposal: invalidate authority before cancelling work; cancel timers, release
   DOM/listener/form/interaction ownership and clear pending state idempotently.

## Bounds and ownership

Effects are limited to 16 per transaction; string IDs are 1–64 ASCII identifier
characters. Only root-owned version-1 `time.schedule` is enabled, with the closed
payload `delay_ms` (0–250 ms), timeout 1–500 ms, and fallback fail/omit/component.
The complete ordered batch has a 750 ms wall-clock deadline. A root has at most
one admitted effect-bearing transaction; overload rejects without enqueueing.
Underlying legacy DOM/event queues remain bounded at 64. No retries are allowed.

Renderer resources belong to one root generation. A ledger holds actual cleanup
leases and bounded subsystem inventories for DOM nodes, listeners, form and
composition records, rollback state, pending DOM jobs, interaction jobs and
their cancellation timers, effect timers, callbacks and diagnostics. No opaque
DOM/Event/provider object crosses the wire. Supersession cancels old work before
new-generation admission. Removing nodes releases their listeners and form state.
Rejection clears abandoned candidate state; rollback retains only the last valid
generation. Terminal failure/runtime loss/shutdown disposes all active leases.

## Failure policy

One coordinator per root owns the terminal decision; no layer independently
retries. Preflight failures retain last-valid output and do not advance state.
Successful rollback retains last-valid output. Uncertain apply/rollback,
acknowledgement loss, required effect failure/timeout, cleanup failure or runtime
loss quarantines only that root. A bounded empty fallback is permitted; a fresh
owner-established lifecycle is required. There is one fallback attempt, zero
retry attempts, and a 32-record redacted diagnostic ring. Cleanup failures remain
visible as retained resources, never falsely reported as released.

Effect failures cannot undo an already committed DOM transaction. This phase
therefore enables only cancellable bounded timers, not clipboard/storage/files
or other irreversible operations. A required effect failure invalidates the
candidate and installs fallback instead of claiming atomic external rollback.
Omit/component fallbacks report typed terminal results without automatic work.

All abandoned resources must release within the governed 1000 ms observation
window or produce a blocking leak record. Actual browser timings, including any
deadline overruns, are evidence rather than assumed passes.

## Qualification and follow-up

Linux Chrome and Firefox are active. Unavailable platforms, physical IME and
manual assistive technology are [DEFERRED] to platform/accessibility owners at
BH-22. This phase claims no support, public API stability, product components,
BH-13 broad capabilities, BH-15 recovery, BH-18 activation or new Wasm endpoint.
Phase 8 is eligible only after this gate passes and remains unauthorized.

At completion of **all BH-04 phases**, give the owner the requested prominent
**SCRIPTS MOVE** warning. This is a reminder, not authorization to move scripts.

## Connections

- [Phase 7 plan](phase-07-effect-ordering-resources-disposal-and-failure-isolation.md)
- [Milestone index](README.md)
