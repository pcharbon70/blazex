---
title: "BH-04 Phase 10 frozen acceptance contract"
kind: note
created: "2026-09-08"
maturity: developing
tags: [bh-04, acceptance, benchmarks]
aliases: []
---

# BH-04 Phase 10 frozen acceptance contract

The owner's Phase 10 request authorizes five section commits and one PR, merge,
main synchronization, then branch deletion. The synchronized base is
`23176db2ff608084e9f779943eadcd0eed1926af`. Unrelated README, BH-05 and demo
edits are preserved separately. No script move is authorized.

The [authorization](../../../assets/bh-04-baseline/blazex-bh-04-phase-10-authorization-v0.1.0.json)
freezes predecessor hashes, sample counts, thresholds, review lenses and rules
before measurement. Historical evidence and the canonical planned acceptance
registry remain immutable. New results form a candidate overlay, not release
qualification. [LiveView/LocalLiveView remain deferred](../../liveview-integration-deferral.md).

## Measurement boundary and honesty

Use the unchanged renderer's scheduling, acknowledgement and fault-observation
hooks. Record receipt, scheduled pump start, accepted preflight, first operation,
commit and two subsequent animation frames. The second frame is a conservative
frame-opportunity proxy, **not proof of compositor paint**. This distinction
must remain visible in the decision: missing required paint evidence cannot be
reported as a measured paint-budget pass. A measurement-method gap is a revise
finding, not an external-platform deferral.

Per Linux browser retain one setup sample plus 100 keyed-reorder samples,
20 overload bursts of 65 transactions, and 1,000 randomized prior-generation
messages each for renderer and effect paths. Record every failure without
dropping it. Nearest-rank statistics and population coefficient of variation
are computed independently from raw rows. Investigate CV above 10 percent.
Fresh failure corpora retain immediate cleanup and observations through 1000 ms.

## Review and decision

Accountable owners are architecture-owner, renderer-owner, security-owner,
accessibility-owner, performance-owner, packaging-owner and quality-owner.
These are ownership roles, not invented approvals. The implementing agent may
perform all lenses but cannot claim independence. Independent reviewers require
separate agent authorization or external review; absent that evidence acceptance
is blocked. A separate clean build is execution independence, not review independence.

The five acceptance rows are update latency, queue bound, stale rejection,
renderer failure, and the roadmap outcome. Each requires source-bound evidence.
Any active missing evidence, incorrect result or budget breach prevents acceptance.
Only explicitly owned external qualification and independent clean-environment
repeat obligations can be bounded conditions. BH-05 is eligible only on an
accepted decision and always needs a separate implementation request.

## Connections

- [Phase 10 plan](phase-10-measurement-review-and-bh-04-acceptance.md)
- [Milestone index](README.md)
- [Quality contract](../../../assets/quality-acceptance/blazex-quality-contract-v0.1.0.json)
