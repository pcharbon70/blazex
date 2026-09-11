---
title: "BH-05 Runtime-Owned Resource Inventory Contract"
kind: note
created: "2026-09-11"
maturity: developing
tags:
  - atomvm
  - bh-05
  - cleanup
  - reliability
  - resource-ownership
aliases: []
---

# BH-05 Runtime-Owned Resource Inventory Contract

## Authority and problem

Phase 14 closes the canonical cleanup deadline but records
`BH05-P14-MAXIMUM-PAYLOAD-TRANSFER`: Firefox copies the complete 512-item,
maximum-portable acquisition inventory from the root ledger into a newly
created cleanup worker after disposal begins. That transfer consumes the same
1000 ms budget as adapter release and leaves exact unresolved identities.

Phase 15 changes internal ownership, not the public component or adapter API.
It does not move cleanup work outside the deadline. Acquisition and transfer
already are lifecycle transitions; they now also commit the complete release
descriptor to the runtime owner that will invoke the adapter. Disposal still
starts its unchanged deadline before inventory selection, compact dispatch,
callbacks, forced recovery, reconciliation, renderer disposal, and finalization.

## Ownership and bounds

Each configured action runtime owns exactly one monitored cleanup session. The
session stores at most 512 release descriptors, keyed by the same stable lease
identity as the authoritative root ledger. A completed acquisition registers
the descriptor before its result work can be observed. An accepted transfer
atomically replaces that descriptor. An explicitly terminal release drops it.
Missing, duplicate, malformed, stale, oversized, and mismatched operations
fail without partial inventory mutation.

The root ledger remains the authoritative portable lifecycle record and holds
the exact descriptor required for validation and forced recovery. The session
handle and process identifiers are private runtime state and never enter
component results, snapshots, semantic output, conformance traces, or public
manifests. The provider port and its release callbacks remain unchanged.

## Disposal protocol

Normal disposal reuses the already-live session, resets cleanup counters but
not inventory, and sends ordered pages of at most 64 compact identities. The
session resolves each identity locally, invokes the existing provider page
release, and returns one ordered terminal result per identity. A successful
reply removes exactly the terminal entries. Acquisition metadata, selection
records, source stamps, transfer history, and full lease maps never cross the
normal disposal request boundary.

An absent, dead, divergent, timed-out, or malformed session cannot be treated
as success. Recovery retains the exact unresolved identities and may open at
most one sequential forced-cleanup session using only the corresponding
root-ledger descriptors. It must not resend descriptors for acknowledged
normal releases. Repeated cleanup remains idempotent and stale replies cannot
mutate the ledger or adapter.

## Observability and decision

Lifecycle registration reports messages, bytes, inventory count, and explicit
unavailable byte instrumentation separately from timed cleanup. Disposal
reports compact request bytes, pages, callbacks, results, workers, stage
timings, terminal identities, and inventory convergence. For a configured
runtime, normal disposal starts no new normal cleanup worker; its request byte
growth follows identity size rather than acquisition payload size.

The maximum-payload fixture, all boundary counts, repetitions, browsers,
deadline, page bounds, and failed evidence are immutable. Phase 15 can pass
only when ERTS, Linux Chrome, and Linux Firefox converge to zero live and zero
unresolved leases under 1000 ms for every retained sample, including the
unchanged 512 maximum-payload case. LiveView and LocalLiveView remain
**[DEFERRED]** and no support claim follows from this correction.

## Connections

- [Phase 15 plan](phase-15-runtime-owned-resource-inventory-and-maximum-payload-requalification.md)
- [Phase 14 review](phase-14-review-and-reconciliation.md)
- [Action contract](action-contract.md)
- [Recovery contract](recovery-contract.md)
- [Cleanup scaling contract](cleanup-scaling-contract.md)

