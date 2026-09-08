---
title: "BH-04 Phase 5 Implementation Evidence"
kind: note
created: "2026-09-08"
maturity: developing
tags:
  - bh-04
  - interaction
  - implementation-evidence
aliases: []
---

# BH-04 Phase 5 Implementation Evidence

## Decision and provenance

Phase 5 completes the bounded local interaction development gate on Linux.
Phase 6 is eligible but unauthorized; BH-05 remains ineligible. The API remains
experimental and every browser remains unsupported. Authority binds accepted
base `f00a9352beb4bc103e8c5ca4e7fc12099f9223fe` and branch
`codex/bh04-phase5-interactions`. Section 5.1 froze the contract, 5.2 implemented
listeners, 5.3 implemented ordered dispatch, and 5.4 supplies integrated evidence.
The completion record binds the first three commits and the introducing fourth
commit without an impossible self-referential commit hash. Delivery is one PR,
merge, main checkout and origin synchronization before feature-branch deletion.
Unrelated README, BH-05 planning and demo work is excluded and preserved.

## Executed behavior

All 13 semantic mappings pass in Chrome and Firefox. Each browser exercises
three independent roots, 18 event-induced DOM commits, two accepted no-render
events, 17 named negative/overflow cases, a maximum queue of 64, and cleanup of
all three roots. The pressure run accepts its active event and rejects the
remaining 63 old-revision events as stale; no events are coalesced. A sibling
progresses while that queue is full. Runtime loss and disposal clear listeners
and queues; delayed input cannot dispatch.

The raw evidence contains 75 carrier request/response pairs per browser. An
independent JavaScript replay validates 40 accepted deliveries, 24 runtime
rejections and 42 renderer commits across both browsers (including six initial
mounts). Unit tests additionally cover timeout cancellation, late completion,
immutable copying, accessor/cycle rejection, listener leases, cross-target
ownership and bridge identity mismatch. No DOM/Event object crosses the wire.

One activation per browser uses trusted mouse input; the other mappings use
programmatic native browser events. Existing Elixir semantic callbacks execute
through `ComponentEvaluator` and `ReconciledSession`; component behavior is not
duplicated in JavaScript. Renderer state is promoted only after its matching
commit acknowledgement. Unchanged output advances semantic state without a
renderer transaction.

## Security, privacy and compatibility review

The v1 lifecycle bridge is immutable. The additive v2 companion is explicitly
negotiated and rejects v1 semantic requests. Plain envelopes bind root,
lifecycle/semantic generation, owner, source/listener, committed revision,
transaction digest/ID and increasing sequence. Only committed bindings resolve
to existing Elixir event atoms; no atom is created from wire input. There are no
new component callbacks, effect execution, server commands or dependencies.

Native fields are read from a closed allowlist; file data, credential-designated
controls, composing input, oversize data and arbitrary properties are rejected.
Logs contain controlled fixture values only. Designation filtering cannot detect
arbitrary secrets entered in an ordinary field. The same-origin application is
not a security sandbox. Network evidence contains only 15 initial HTML/module
GETs per browser; local interactions use no HTTP, Phoenix or Plug traffic.

Native scalar edits initially failed strict Phase 4 DOM preflight. The fix admits
only successfully normalized value/checked observations into the accepted journal;
foreign attributes/tree changes remain rejected. Rendering reapplies declared
scalar values or defaults. Phase 6 owns user-value, composition and selection
continuity. Both unchanged Phase 4 browser matrices pass after this integration.

## Runtime and qualification limits

The harness uses real Elixir 1.17.3 / OTP 26 in offline Docker with a test-only
Playwright DevTools/stdio carrier. This is **not** execution of a newly packaged
AtomVM/Wasm semantic endpoint: the existing browser Popcorn fixture still exposes
v1. Adapters must explicitly implement the new endpoint and root-state ownership;
this evidence does not silently claim that integration is shipped in the demo.
Existing pinned Jason 1.4.5 is used only by the test carrier. Its harmless
already-consolidated Enumerable warning does not affect plain-map JSON.

No performance, heap-profiling, public API, manual accessibility or physical
gesture qualification is claimed. Review is implementation-agent review, not
independent review. [DEFERRED] Unavailable OS/browser/device/manual-AT work stays
with the inherited platform, device and accessibility qualification owners,
reactivating no later than BH-22 under the development policy; no pass credit.

## Reproduction and artifacts

- [Interaction contract](phase-05-interaction-contract.md)
- [Integration usage](../../../../../integration/bh-04/interaction-usage.md)
- [Authorization](../../../assets/bh-04-baseline/blazex-bh-04-phase-05-authorization-v0.1.0.json)
- [Source index](../../../assets/bh-04-baseline/blazex-bh-04-phase-05-source-index-v0.1.0.json)
- [Raw browser and runtime traces](../../../assets/bh-04-baseline/blazex-bh-04-phase-05-browser-results-v0.1.0.json)
- [Exact commands, counts, repairs and limitations](../../../assets/bh-04-baseline/blazex-bh-04-phase-05-validation-log-v0.1.0.txt)
- [Bounded completion record](../../../assets/bh-04-baseline/blazex-bh-04-phase-05-completion-v0.1.0.json)
- [Development and deferred qualification policy](../../development-environment-and-deferred-qualification-policy.md)
