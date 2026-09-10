---
title: "BH-05 Cleanup Session and Scaling Requalification Contract"
kind: note
created: "2026-09-10"
maturity: developing
tags: [atomvm, bh-05, cleanup, reliability, scaling]
aliases: []
---

# BH-05 Cleanup Session and Scaling Requalification Contract

Back to [milestone](README.md) and [Phase 13](phase-13-bounded-paged-cleanup-and-scaling-requalification.md).

## Authority and immutable predecessor

The repository owner authorized Phase 13 on 2026-09-10. Work starts from the
merged Phase 12 revision `3d8485ef90ed579dde5d5e425545efba7a309ccf` on branch
`codex/bh05-phase13-cleanup-scaling`. The machine-readable
[authorization](../../../assets/bh-05-baseline/cleanup-scaling-authorization-v0.1.0.json)
binds the immutable Phase 12 decision, raw observations, reports, recovery
contract, and re-entry conditions.

Phase 12 remains **revise**. Its 1000 ms deadline, 512-lease fixture, Chrome and
Firefox failures, sample histories, and support limitations cannot be edited,
relabelled, removed, or replaced. Phase 13 publishes a successor overlay.

## Frozen correction

Cleanup uses one monitored runtime-owned normal session per root for owner
discovery, cancellations, component cleanup, lease release, and renderer
disposal. Jobs and correlated result vectors use pages of 64 entries; the
protocol rejects pages larger than 128. Existing adapter callbacks remain the
unit of resource truth, so adapters require no batch API and each resource
retains an independent terminal result.

The normal session and at most one forced-cleanup session execute sequentially.
There is at most one live cleanup worker and at most two cleanup-worker starts
per disposal. A failed or timed-out page preserves prior acknowledgements,
marks every unacknowledged identity unresolved, and sends exactly that remainder
through the forced session. Late, duplicate, malformed, or stale replies cannot
mutate root, ledger, renderer, or focus state.

The monotonic deadline begins at the disposal request and remains 1000 ms. It
includes inventory, ordering, planning, session work, callbacks, result
collation, forced cleanup, renderer disposal, and ledger finalization.

## Frozen scaling matrix

Canonical counts are `0, 1, 63, 64, 65, 127, 128, 129, 255, 256, 257, 511,
512`. Canonical payloads run at every count; maximum-portable payloads run at
`64, 65, 256, 512`; minimal payload controls run at `64, 512`. Exact payload
limits belong to the versioned fixture schema and cannot change after the first
retained run.

After one discarded warmup, ERTS retains 20 samples at every count and 100 at
512. Linux Chrome and Firefox AtomVM each retain 10 samples at every count and
20 at 512. Reruns append records; no failure or outlier is discarded.

## Structural and timing gates

Every retained active-runtime sample requires zero unresolved identities.
Controlled ERTS cleanup retains the existing nearest-rank p95 maximum of 1000
ms. Successful structural observations require at most one normal worker, at
most two total worker starts, at most one live cleanup worker, exactly
`ceil(resource_count / 64)` lease pages, and page-proportional rather than
resource-proportional protocol messages.

For each runtime, retained medians at counts of at least 64 are fit with a
Theil-Sen line. A point above its prediction by more than the greater of 100 ms
or 50% is a blocking scaling alarm. A reproduced bounded runtime discontinuity
may explain the alarm only by producing a **revise** decision; it cannot waive
the gate or manufacture acceptance.

## Evidence semantics

`execution_state` records whether a harness ran. `acceptance_state` records
whether all semantic, deadline, structural, and evidence gates passed. A
completed harness may therefore be executed and failed; it cannot emit an
unqualified passing result.

Raw evidence is append-only and binds runtime/browser, source and bundle
identity, sample and payload class, stage timings, structural counters, exact
terminal identities, raw-record hash, and unavailable instrumentation. Summary
validators recompute statistics and reject missing failures, scale points,
samples, counters, hashes, or browser rows.

## Decision boundary

BH-05 becomes accepted and BH-06 becomes eligible-but-unauthorized only if the
unchanged Phase 12 fixture, the complete Phase 13 matrices, all inherited gates,
and an independent clean repeat pass without an active finding. Otherwise the
successor decision is **revise** or **block**. No result grants browser,
platform, profile, public 1.0, or release support. LiveView and LocalLiveView
remain deferred; unavailable external qualification remains deferred to BH-22.
