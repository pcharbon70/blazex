---
title: "BH-05 Phase 13 Cleanup Scaling Review and Reconciliation"
kind: note
created: "2026-09-10"
maturity: developing
tags: [bh-05, cleanup, scaling, review, reconciliation]
aliases: []
---

# BH-05 Phase 13 Cleanup Scaling Review and Reconciliation

Back to the [Phase 13 plan](phase-13-bounded-paged-cleanup-and-scaling-requalification.md), the [attempt ledger](../../../../../integration/bh-05/cleanup-scaling-attempts-v0.1.0.json), and the [machine-readable review](../../../assets/bh-05-baseline/cleanup-scaling-review-v0.1.0.json).

## Decision

The Phase 13 decision is **revise**. The implementation removes the original
process-per-resource design, limits normal cleanup to one monitored session,
uses 64-resource pages, permits at most one separate forced session, keeps
protocol messages page-proportional, batches ledger finalization, and avoids
rebuilding successful result rows. Chrome's canonical 512-resource probe fell
from 68,869 ms to 286 ms with one worker, eight lease pages, eighteen protocol
messages, 513 completed callbacks, no terminal leases, and no unresolved
identity.

Firefox remains blocking. The final canonical probe consumed 3,105 ms,
completed seven lease pages before deadline exhaustion, and retained 65 exact
unresolved identities in the cleanup report. The unchanged Phase 12 repeat
also failed Firefox cleanup while both browsers reported zero unexpected
growth across 100 cycles. A zero-live ledger does not waive those unresolved
identities: resources closed as lost remain an explicit semantic failure.

## Review

The correction passes the ownership, constant-worker, mailbox-correlation,
malformed-result, bounded-history, stale-result, and process-growth lenses on
the exercised paths. Core has explicit tests for page cardinality,
out-of-order or duplicate correlation, worker death, deadline termination,
owner death, page-provider dispatch, per-result fallback, and 512-resource
batch accounting. The browser harness separates execution from acceptance and
the validator rejects missing samples, altered thresholds, relabeled terminal
state, absent counters, duplicate identities, and recomputed shape divergence.

Two findings remain open:

1. `BH05-P13-FIREFOX-DEADLINE` (blocking, runtime/performance): AtomVM on the
   active Firefox build cannot materialize the exact 512-row terminal report
   within 1,000 ms. Reproduction and every intermediate correction are retained
   in the attempt ledger.
2. `BH05-P13-ATOMVM-BYTES` (non-blocking instrumentation limitation): AtomVM's
   byte-size observation distorted or stalled cleanup. ERTS retains exact
   external sizes; AtomVM records `unavailable` while mandatory worker, page,
   callback, message, timing, terminal, and memory-page counters remain present.

This is an implementation-agent review, not an independent human attestation.
No disagreement was suppressed: the Chrome pass cannot close the Firefox
failure, and the incomplete Firefox full matrix cannot be represented as a
passing sample corpus.

## Re-entry

BH-05 remains revision-required, BH-06 remains ineligible and unauthorized,
and support remains unsupported. Re-entry requires a source-frozen Firefox
run of the unchanged Phase 12 fixture plus the complete pre-registered Phase 13
matrix with zero unresolved identities and no deadline violation. The next
correction must compact exact successful terminal reporting or move that
materialization into a bounded representation without reducing resource count,
page coverage, failure identity, or the 1,000 ms deadline. All historical
attempts must remain append-only.
