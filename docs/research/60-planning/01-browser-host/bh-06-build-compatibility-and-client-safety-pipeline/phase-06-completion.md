---
title: "BH-06 Phase 6 Completion Evidence"
kind: note
created: "2026-09-12"
maturity: developing
tags: [bh-06, build, completion, evidence, licensing, provenance]
aliases: []
---

# BH-06 Phase 6 Completion Evidence

Back to the [plan](phase-06-license-and-provenance-inventory.md) and [review](phase-06-review-and-reconciliation.md).

## Outcome

Phase 6 is complete with decision **accept**. All 698 Phase 5-audited inputs
resolve to one of seven shipped components and non-empty license-record sets
before assembly. Two notice files verify by digest, and Ninja plus GNU gperf
remain visible as build-only lineage.

This is an inventory acceptance, not legal advice or redistribution approval.
The repository has no BlazeX public-license grant at this revision, so all 85
project-owned inputs are explicitly `NOASSERTION` and
`private-development-only`.

## Evidence

Two builds were byte-identical. The ten-artifact manifest totals 8,741,846
bytes and has SHA-256 `75bb1e707702660950eda147bcf6870c4322a62bf7c4ecf9ac97a57b7dc8d992`.
The inventory accounts for 20,712,482 source bytes; its canonical SHA-256 is
`0a2cbd6dfb370f11fdeb31587331498763d3df668867fe65c6afdf4f3866eb4f`.

Chrome 140 and Firefox 153 passed byte-identical AtomVM/Wasm lifecycle replays
with zero page errors. The report SHA-256 is
`023d7560c20ad9696185cbd24a667c5b4b22a71d07dd7aa9ee040ab2a5afabdd`.

## Bound evidence

- Policy evidence: `2be11a8f5183a1cbb42e8ecf9494c109e830dc5214dbb16aac929e83befa080f`.
- Normalized policy: `2becee961e75e51853277827e85fcaa7a155b977bde4b276c6e24a896b7b08c3`.
- Inventory implementation: `d57e3857316c1a98a671ecb5ad1c3539b2d4f38bdbbce8024c0760d5838f8a0d`.
- Section 6.3 revision: `664fe06d65c20532ed5bfffb6ca2809f1088f297`.

Further BH-06 decomposition requires separate authorization. LiveView and
LocalLiveView remain deferred; no production support or BH-07 authority is implied.

