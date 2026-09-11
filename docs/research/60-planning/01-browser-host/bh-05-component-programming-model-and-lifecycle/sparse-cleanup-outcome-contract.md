---
title: "BH-05 Sparse Cleanup Outcome Contract"
kind: note
created: "2026-09-11"
maturity: developing
tags: [bh-05, cleanup, contract, reliability]
aliases: []
---

# BH-05 Sparse Cleanup Outcome Contract

Back to the [Phase 16 plan](phase-16-factorized-distribution-shape-and-sparse-cleanup-outcomes.md).

## Representation

A lease outcome page retains ordered lease identifiers for every attempted
release. Status, forced status, and unresolved vectors keep their existing
compact scalar-or-vector form. Full owner identities are retained only in a
bounded sparse list for unresolved positions. A successful page therefore has
no retained owner graph, regardless of owner depth or distribution.

Sparse positions are unique, ordered, in page bounds, and correspond exactly
to true unresolved values. Readers validate the whole page before folding,
counting, reconstructing identities, or updating the ledger. Compatibility
row expansion reconstructs owners for unresolved leases and may use the
caller-supplied ordered lease set for successful rows; it cannot invent an
owner or turn a malformed page into success.

## Factorized diagnosis

The Phase 15 combined maximum shape is split into independently selectable
payload size, identifier size, owner depth, owner distribution, inventory
count, and outcome-retention axes at counts 256 and 512. Evidence must include
every axis and the unchanged canonical and combined-maximum controls. A
combined-only pass or a measurement that changes the deadline, page size,
browser set, or retained count is not causal evidence.

## Compatibility and authority

The representation is private Core cleanup evidence. It changes no component
facade, semantic tree, provider callback, public manifest, support state, or
host boundary. The authoritative root ledger remains available through final
reconciliation and forced recovery. LiveView and LocalLiveView remain
**[DEFERRED]**.
