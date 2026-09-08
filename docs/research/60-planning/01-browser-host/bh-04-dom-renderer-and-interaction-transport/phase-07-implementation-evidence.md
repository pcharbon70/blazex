---
title: "BH-04 Phase 7 implementation evidence"
kind: note
created: "2026-09-08"
maturity: developing
tags:
  - bh-04
  - effects
  - implementation-evidence
  - resources
aliases: []
---

# BH-04 Phase 7 implementation evidence

## Scope and result

The bounded lifecycle implementation provides opt-in timer effect emissions,
transaction/result correlation, generation-scoped cleanup leases, subsystem
resource inventories and one root-local recovery owner. Existing callers keep
their legacy protocols and empty-emission behavior. Component callback shapes,
Effect/Result types, package dependencies and the existing Wasm demo are unchanged.

See the [contract](phase-07-lifecycle-contract.md),
[authorization](../../../assets/bh-04-baseline/blazex-bh-04-phase-07-authorization-v0.1.0.json),
[source index](../../../assets/bh-04-baseline/blazex-bh-04-phase-07-source-index-v0.1.0.json),
[validation log](../../../assets/bh-04-baseline/blazex-bh-04-phase-07-validation-log-v0.1.0.txt),
and [completion record](../../../assets/bh-04-baseline/blazex-bh-04-phase-07-completion-v0.1.0.json).

## Executable path

`ContinuitySession.mount/6` accepts explicit grants (`[:time]` for timers or `[]`
for effect-aware denial); the five-argument legacy call still rejects emissions.
The internal bridge version is `blazex.host-bridge/4`. `FormEvaluator.dispatch/3`
accepts an outward typed-emission validator without taking an effects/provider
dependency. It does not silently discard callback emissions.

`EffectBatch` validates the existing portable requests, serializes an internal
`blazex.dom-effects/1` companion and validates every terminal result before
semantic state promotion. `EffectDOMRoots` explicitly grants only `time`, binds
the unchanged continuity/DOM transaction, restores focus and selection, then
runs bounded timers. Failures with omit/component fallback produce typed results
for the session owner; no new result callback or synthetic event is introduced.
IDs are single-use per generation, with a non-evicting 256-ID replay bound.

Cleanup leases own real release functions and inspect the underlying DOM,
form/listener and interaction inventories. Failed cleanup retains a blocking
record. The coordinator bounds diagnostics to 32, fallback attempts to one and
retry attempts to zero. Required timer failure, uncertain acknowledgement and
runtime loss remove the affected DOM through bounded empty fallback, without
promoting its provisional semantic state. Fresh lifecycle establishment belongs
to the owner, never automatic recovery.

## Active evidence

[Raw browser evidence](../../../assets/bh-04-baseline/blazex-bh-04-phase-07-browser-results-v0.1.0.json)
contains Linux Chrome and Firefox fingerprints, runtime request/response pairs,
19 scenario traces and 24 complete cleanups per browser, plus a further 1000 ms
late-resource observation. Twelve repeated update/reorder/replace/fail/dispose
cycles run while an independent sibling remains usable. Tests exercise actual
Elixir callback emissions and real browser timers, not a JavaScript component.

Independent replay checks 188 proposals, 150 commits, 78 semantic deliveries
and 40 acknowledged effect results across both browsers. Failed/unacknowledged
candidates are not promoted and are discarded at explicit runtime stop.
The test-only carrier uses offline ERTS in Docker through Playwright DevTools
and stdio. Initial HTML/module GETs are separate from the local interaction path;
there is no interaction HTTP/Phoenix/Plug traffic.

The unchanged active Phase 4, 5 and 6 matrices also pass. Phase 4 covers all
50 transaction scenarios, 1204 rollback boundaries, 100 stale rejections and
queue maximum 64 in each browser. Phase 5 covers 13 event mappings and 17 negative
cases. Phase 6 covers all 16 form/focus/selection scenarios. Exact counts and
commands are retained in the validation log.

## Repairs and review

The integration pass corrected a missing array case in bridge byte-size
validation and added a real bridge-ack regression. The fixture's focus target
was corrected to include its required order. Review also added the bounded
cross-transaction effect-ID replay guard, defensive result snapshots, and
release of container/document references after DOM disposal. No failing active
case is waived. Review is by the implementation agent, not independent review.

## Limits and next step

This is renderer-local acceptance evidence for
`BX-ACC-FAILURE-BX-FAIL-RENDERER`, not BH-22 release resilience qualification.
Inventory/cleanup observations are not heap-profiler or physical-device proof.
The test-only lifecycle carrier explicitly stops the Elixir session after failed
or disposed scenarios; no new AtomVM/Wasm lifecycle endpoint is packaged.
Only timers execute: no clipboard/storage/file capability, product control,
offline recovery, activation, server authority, browser support or public API
stability is claimed. Paint observation is not a rendered-pixel guarantee.

Unavailable platforms, physical IME and manual assistive technology remain
[DEFERRED] to platform/accessibility owners at BH-22. Phase 8 is eligible after
the completed gate but remains unauthorized; BH-05 remains ineligible.
At completion of all BH-04 phases, prominently warn the owner **SCRIPTS MOVE**;
do not move scripts without a separate request.

## Connections

- [Milestone plan](README.md)
- [Phase 7 checklist](phase-07-effect-ordering-resources-disposal-and-failure-isolation.md)
