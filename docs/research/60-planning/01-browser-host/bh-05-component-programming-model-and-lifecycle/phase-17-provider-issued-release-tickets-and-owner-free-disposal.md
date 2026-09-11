---
title: "Phase 17 - Provider-Issued Release Tickets and Owner-Free Disposal"
kind: note
created: "2026-09-11"
maturity: developing
tags: [atomvm, bh-05, cleanup, effects, implementation-planning, reliability]
aliases: ["BH-05 phase 17", "BH-05 provider release tickets"]
---

# Phase 17 - Provider-Issued Release Tickets and Owner-Free Disposal

Back to milestone: [README](README.md)

- [ ] 17 Phase - Provider-Issued Release Tickets and Owner-Free Disposal.

  Correct `BH05-P16-DEEP-OWNER-RELEASE-DESCRIPTOR` by having the selected
  provider prepare a bounded opaque release ticket when a lease is acquired or
  transferred. Core validates full owner authority before registration, while
  deadline-bound normal disposal sends only ordered ticket records and never
  reconstructs or transports owner paths. Preserve exact forced recovery from
  the authoritative ledger, the 1000 ms deadline, page bounds, factor and
  browser matrices, provider isolation, and append-only failed evidence.

  The repository owner authorized this work on 2026-09-11. It starts from
  synchronized `main` at `ac12b947fb84b746202fed0e79dd1a540d1e590c` on
  `codex/bh05-phase17-provider-release-tickets`. Delivery requires one commit
  per section, one pull request, its authorized merge, synchronization of
  `main` with `origin/main`, and deletion of the local and remote feature
  branch. BH-06 remains ineligible and unauthorized until the frozen gate
  passes. LiveView and LocalLiveView remain **[DEFERRED]**.

  - [x] 17.1 Section - Freeze release-ticket authority and corrective scope.
    - [x] 17.1.1 Task - Bind Phase 16 evidence and immutable limits.
      - [x] 17.1.1.1 Subtask - Record source, branch, section commits, single-PR delivery, merge authority, and cleanup sequence.
      - [x] 17.1.1.2 Subtask - Bind Phase 16 review, completion, attempt ledger, RecoveryPort, and ActionBridge by path and SHA-256.
      - [x] 17.1.1.3 Subtask - Prohibit deadline increases, count reductions, browser exclusions, owner-check removal, failure deletion, support promotion, and LiveView scope expansion.
    - [x] 17.1.2 Task - Freeze provider-issued ticket semantics.
      - [x] 17.1.2.1 Subtask - Prepare tickets only after full lease owner/generation/selection validation and before acquisition becomes observable.
      - [x] 17.1.2.2 Subtask - Limit tickets to bounded portable opaque provider data correlated to one lease ID without owner paths, capabilities, selections, or acquisition payloads.
      - [x] 17.1.2.3 Subtask - Permit normal ticket release exactly once; retain full ledger descriptors only for fail-closed forced recovery.

  - [ ] 17.2 Section - Add the provider release-ticket protocol.
    - [ ] 17.2.1 Task - Extend the internal action port and Effects bridge.
      - [ ] 17.2.1.1 Subtask - Add prepare-release and release-ticket callbacks with bounded tickets and declared-provider routing.
      - [ ] 17.2.1.2 Subtask - Make Effects providers issue opaque tokens from full validated resource packets at acquisition time.
      - [ ] 17.2.1.3 Subtask - Reject missing, malformed, oversized, nonportable, mismatched, or wrong-provider tickets.
    - [ ] 17.2.2 Task - Preserve compatibility boundaries.
      - [ ] 17.2.2.1 Subtask - Keep explicit immediate release behavior and provider resource identity unchanged.
      - [ ] 17.2.2.2 Subtask - Keep tickets private to runtime inventory and exclude them from component work, snapshots, diagnostics, and public manifests.
      - [ ] 17.2.2.3 Subtask - Document provider migration and fail closed when preparation is unavailable.

  - [ ] 17.3 Section - Integrate tickets with owned inventory and disposal.
    - [ ] 17.3.1 Task - Register and replace tickets at lifecycle boundaries.
      - [ ] 17.3.1.1 Subtask - Prepare and register tickets for completed acquisitions before result work is returned.
      - [ ] 17.3.1.2 Subtask - Replace tickets after accepted transfer and drop them after explicit terminal release.
      - [ ] 17.3.1.3 Subtask - Preserve atomic inventory counts, ordering, capacity, process ownership, and teardown.
    - [ ] 17.3.2 Task - Execute owner-free normal disposal.
      - [ ] 17.3.2.1 Subtask - Decode only bounded ticket data and invoke ticket pages inside the existing deadline.
      - [ ] 17.3.2.2 Subtask - Reconcile sparse terminal outcomes by lease order and preserve exact forced candidates from the root ledger.
      - [ ] 17.3.2.3 Subtask - Report ticket preparation separately from disposal and prove zero normal owner records.

  - [ ] 17.4 Section - Add lifecycle, security, and scaling gates.
    - [ ] 17.4.1 Task - Test ticket correctness and recovery.
      - [ ] 17.4.1.1 Subtask - Cover acquisition, transfer, explicit release, replacement, shutdown, provider denial, malformed tokens, timeout, and partial ticket failure.
      - [ ] 17.4.1.2 Subtask - Prove stale/wrong-provider tickets cannot release another lease and failed preparation cannot manufacture inventory convergence.
      - [ ] 17.4.1.3 Subtask - Preserve exact unresolved owners, forced recovery, idempotency, portable snapshots, and bounded history.
    - [ ] 17.4.2 Task - Detect ticket scaling concealment.
      - [ ] 17.4.2.1 Subtask - Record ticket bytes, pages, messages, owner fields, callback counts, inventory convergence, and stage timing.
      - [ ] 17.4.2.2 Subtask - Mutation-test owner-path reintroduction, ticket omission, oversized tokens, deadline drift, count reduction, and masked unresolved rows.
      - [ ] 17.4.2.3 Subtask - Retain Phase 13-16 process, inventory, outcome, factor, and growth gates.

  - [ ] 17.5 Section - Requalify active runtimes and reconcile BH-05.
    - [ ] 17.5.1 Task - Execute the source-frozen ticket correction matrix.
      - [ ] 17.5.1.1 Subtask - Run ERTS and Linux Chrome/Firefox factor, canonical, maximum, adverse, and growth cases.
      - [ ] 17.5.1.2 Subtask - Require every retained sample within 1000 ms with zero unresolved identities and exact inventory convergence.
      - [ ] 17.5.1.3 Subtask - Preserve source, runtime, bundle, browser, ticket, raw failure, timing, and unavailable-metric evidence.
    - [ ] 17.5.2 Task - Review and reconcile the successor decision.
      - [ ] 17.5.2.1 Subtask - Review correctness, authority, portability, performance, provider migration, evidence, security, and compatibility.
      - [ ] 17.5.2.2 Subtask - Map every Phase 16 re-entry condition and new finding to evidence.
      - [ ] 17.5.2.3 Subtask - Accept only when all frozen gates pass; otherwise record revise or block.

  - [ ] 17.6 Section - Run the full integration gate and publish completion.
    - [ ] 17.6.1 Task - Rebuild and verify the complete candidate.
      - [ ] 17.6.1.1 Subtask - Run package, conformance, browser, formatting, archive, provenance, dependency, and hygiene gates.
      - [ ] 17.6.1.2 Subtask - Repeat maximum 512 and canonical `64, 65, 256, 512` from a second clean context.
      - [ ] 17.6.1.3 Subtask - Verify indexing, source binding, public facade stability, and historical immutability.
    - [ ] 17.6.2 Task - Publish and deliver one successor pull request.
      - [ ] 17.6.2.1 Subtask - Publish commands, hashes, samples, timings, ticket counters, findings, limitations, and decision.
      - [ ] 17.6.2.2 Subtask - Open and merge one PR only after recording a truthful decision.
      - [ ] 17.6.2.3 Subtask - After merge, sync `main`, then delete local and remote feature branches.

## Exit gate

Phase 17 passes only when normal cleanup transports no owner path, ticket
authority and exact forced recovery remain intact, every retained
ERTS/Chrome/Firefox sample converges with zero unresolved identities within
1000 ms, and the complete BH-05 gate reproduces from a second clean build.

## Bound inputs

| Input | SHA-256 |
| --- | --- |
| `phase-16-review-and-reconciliation.md` | `276c22f06c66fe747904e9509374d21e948fe6d2f7acde9f123b2e05a631a2dd` |
| `phase-16-completion.md` | `44834a775c76d7e991fed92d3ece08c0e29b91f920cf3790944de33598f3428b` |
| `integration/bh-05/factorized-cleanup-attempts-v0.1.0.json` | `8ed238ce1660ba60939e11740274a3d0ed253c1c5b2c23d87bfd7c3a7fe581a8` |
| `recovery_port.ex` | `347b8422be7dddc0f633121c556971805152e5284a6fa81d9900242b4f7d00c1` |
| `action_bridge.ex` | `ea637fccb0c6b10c7e58039f79655d62c26aa16773b6171dc1ef2ceda4158957` |

## Connections

- [Provider release-ticket contract](provider-release-ticket-contract.md)
- [Phase 16 review](phase-16-review-and-reconciliation.md)
- [Phase 16 completion](phase-16-completion.md)
- [Action contract](action-contract.md)
- [Recovery contract](recovery-contract.md)
- [Development and deferred qualification policy](../../development-environment-and-deferred-qualification-policy.md)
