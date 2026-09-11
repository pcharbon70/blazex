---
title: "BH-05 Phase 16 Review and Reconciliation"
kind: note
created: "2026-09-11"
maturity: developing
tags: [atomvm, bh-05, cleanup, reconciliation, reliability, review]
aliases: []
---

# BH-05 Phase 16 Review and Reconciliation

Back to the [Phase 16 plan](phase-16-factorized-distribution-shape-and-sparse-cleanup-outcomes.md), [contract](sparse-cleanup-outcome-contract.md), and [machine review](../../../assets/bh-05-baseline/factorized-cleanup-review-v0.1.0.json).

## Decision

The decision is **revise**. Phase 16 replaces successful lease pages with
version 2 sparse outcomes: all ordered IDs remain, full owners remain only for
exact unresolved positions, and successful 256/512 ERTS factor samples retain
zero owner records. Core reports 113 tests with zero failures. Twelve Phase
13/15/16 scaling and anti-concealment tests pass.

The factor matrix closes the combined diagnosis
`BH05-P15-MAXIMUM-DISTRIBUTION-SHAPE`. Chrome passes every 256/512 profile.
Firefox passes inventory-only, payload-only, and identifier-only at 512 in
817, 918, and 931 ms. Owner-depth-only fails at 9,569 ms with 321 unresolved;
one-segment distribution fails at 2,235 ms with 65 unresolved. Deep distributed
outcome-retention and maximum profiles fail at 9,431 and 11,761 ms.

The retained candidate's fresh canonical subset passes both browsers with zero
unresolved identities: Chrome records `9, 9, 43, 145` ms and Firefox
`37, 45, 337, 973` ms. The fresh maximum-512 control passes Chrome at 324 ms
but fails Firefox at 9,105 ms with 321 unresolved identities.

## Review findings

`BH05-P16-DEEP-OWNER-RELEASE-DESCRIPTOR` is blocking. The independently varied
payload, opaque ID, and inventory-count axes are not causal. Owner path depth
inside the provider release descriptor is sufficient to reproduce the failure,
and shallow owner distribution exposes a smaller boundary. Sparse terminal
outcomes prevent successful owner retention but operate after the dominant
release stage and therefore cannot close the endpoint alone.

A second correction stored the validated owner beside an encoded provider
descriptor to avoid decoding the owner during disposal. It regressed the fresh
maximum-512 Firefox result to 13,361 ms with all 513 operations unresolved and
was reverted. Re-entry must design and verify a provider-release representation
that preserves owner authority without copying or reconstructing full owner
paths per lease inside the deadline. The adapter contract and effects resource
identity implications must be reviewed explicitly before implementation.

The 1000 ms deadline, page sizes, browser set, factor counts, canonical and
maximum controls, and failed attempts remain unchanged. This is
implementation-agent review, not independent human attestation.

LiveView and LocalLiveView remain **[DEFERRED]**. No browser, platform, profile,
public API, release, or support state is promoted. BH-06 remains ineligible and
unauthorized.

## Connections

- [Phase 16 plan](phase-16-factorized-distribution-shape-and-sparse-cleanup-outcomes.md)
- [Sparse cleanup outcome contract](sparse-cleanup-outcome-contract.md)
- [Phase 16 attempt ledger](../../../../../integration/bh-05/factorized-cleanup-attempts-v0.1.0.json)
- [Phase 15 review](phase-15-review-and-reconciliation.md)
