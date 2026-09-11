---
title: "Phase 18 - Compact Ticket Acknowledgements and Deadline-Safe Reconciliation"
kind: note
created: "2026-09-11"
maturity: developing
tags: [atomvm, bh-05, cleanup, implementation-planning, reliability]
aliases: ["BH-05 phase 18", "BH-05 compact ticket acknowledgements"]
---

# Phase 18 - Compact Ticket Acknowledgements and Deadline-Safe Reconciliation

Back to milestone: [README](README.md)

- [ ] 18 Phase - Compact Ticket Acknowledgements and Deadline-Safe Reconciliation.

  Correct `BH05-P17-FIREFOX-TICKET-SESSION-DEADLINE` without weakening the
  provider-issued ticket authority established by Phase 17. A provider may
  acknowledge an entire validated ticket page with one bounded uniform-success
  result; mixed or failed pages retain exact positional results. Core must carry
  that compact result through RecoveryPort and construct the already-compact
  terminal outcome without materializing per-ticket success vectors.

  The repository owner authorized this work on 2026-09-11. It starts from
  synchronized `main` at `ae88d905ea9c904ecf065752ae3a01f257df24d8` on
  `codex/bh05-phase18-compact-ticket-acknowledgements`. Delivery requires one
  commit per section, one pull request, its authorized merge, synchronization
  of `main` with `origin/main`, and deletion of the local and remote feature
  branch. BH-06 remains ineligible until the frozen gate passes. LiveView and
  LocalLiveView remain **[DEFERRED]**.

  - [x] 18.1 Section - Freeze compact acknowledgement authority and scope.
    - [x] 18.1.1 Task - Bind Phase 17 evidence and immutable limits.
      - [x] 18.1.1.1 Subtask - Bind the merged source, review, completion, attempt ledger, RecoveryPort, RootPort, and CleanupOutcome by revision and hash.
      - [x] 18.1.1.2 Subtask - Preserve the 1000 ms deadline, 64-ticket pages, 512 count, active browser set, ordered callbacks, and exact failure recovery.
      - [x] 18.1.1.3 Subtask - Prohibit warm-up exclusion, count reduction, deadline relaxation, browser exclusion, and scalar acknowledgement without provider page authority.
    - [x] 18.1.2 Task - Freeze the compact result algebra.
      - [x] 18.1.2.1 Subtask - Permit one scalar success only for an entire validated ordered page.
      - [x] 18.1.2.2 Subtask - Require exact positional vectors for every mixed, failed, malformed, or partial result.
      - [x] 18.1.2.3 Subtask - Preserve public ticket envelopes and provider isolation.

  - [x] 18.2 Section - Add provider-authorized compact page acknowledgements.
    - [x] 18.2.1 Task - Extend RootPort and the Effects bridge.
      - [x] 18.2.1.1 Subtask - Normalize scalar page success without expanding it into one result per ticket.
      - [x] 18.2.1.2 Subtask - Keep public action ports on validated ticket envelopes and compact internal callbacks on validated tuples.
      - [x] 18.2.1.3 Subtask - Reject scalar failure, partial vectors, invalid values, and wrong-provider routing.
    - [x] 18.2.2 Task - Preserve provider compatibility.
      - [x] 18.2.2.1 Subtask - Retain individual release callbacks and positional page vectors.
      - [x] 18.2.2.2 Subtask - Permit the built-in bridge to collapse only unanimous released results.
      - [x] 18.2.2.3 Subtask - Document provider migration and fail-closed fallback.

  - [x] 18.3 Section - Carry compact success through disposal and outcomes.
    - [x] 18.3.1 Task - Update RecoveryPort inventory release.
      - [x] 18.3.1.1 Subtask - Reconcile scalar success by the requested page count without ticket/result zips.
      - [x] 18.3.1.2 Subtask - Retain exact tickets and positions for vector failures.
      - [x] 18.3.1.3 Subtask - Preserve counts, page telemetry, timeouts, teardown, and bounded messages.
    - [x] 18.3.2 Task - Update cleanup outcome construction.
      - [x] 18.3.2.1 Subtask - Construct uniform completed pages directly from authoritative ordered identities.
      - [x] 18.3.2.2 Subtask - Avoid success status, unresolved, owner, and candidate vectors.
      - [x] 18.3.2.3 Subtask - Preserve exact forced recovery and public version 2 outcome shape.

  - [x] 18.4 Section - Add correctness and anti-concealment gates.
    - [x] 18.4.1 Task - Test the compact result algebra.
      - [x] 18.4.1.1 Subtask - Cover scalar success, vector success, mixed failure, malformed scalar, partial vector, timeout, and provider denial.
      - [x] 18.4.1.2 Subtask - Prove scalar success cannot hide a failed ticket or manufacture inventory convergence.
      - [x] 18.4.1.3 Subtask - Prove public callbacks retain map envelopes and compatibility.
    - [x] 18.4.2 Task - Extend scaling observability.
      - [x] 18.4.2.1 Subtask - Record compact acknowledgement pages/items and positional result items.
      - [x] 18.4.2.2 Subtask - Mutation-test expansion, omitted callbacks, masked failure, deadline drift, and count reduction.
      - [x] 18.4.2.3 Subtask - Retain Phase 13-17 process, ticket, inventory, factor, outcome, and growth gates.

  - [x] 18.5 Section - Requalify active runtimes and reconcile BH-05.
    - [x] 18.5.1 Task - Execute the source-frozen correction matrix.
      - [x] 18.5.1.1 Subtask - Run ERTS and Linux Chrome/Firefox factor, canonical, maximum, adverse, and growth cases.
      - [x] 18.5.1.2 Subtask - Require every retained sample within 1000 ms with zero unresolved identities and exact inventory convergence.
      - [x] 18.5.1.3 Subtask - Preserve source, runtime, bundle, browser, raw failure, timing, acknowledgement, and unavailable-metric evidence.
    - [x] 18.5.2 Task - Review and reconcile the successor decision.
      - [x] 18.5.2.1 Subtask - Review correctness, authority, portability, performance, migration, security, and compatibility.
      - [x] 18.5.2.2 Subtask - Map the Phase 17 re-entry condition and every new finding to evidence.
      - [x] 18.5.2.3 Subtask - Accept only when all frozen gates pass; otherwise record revise or block.

  - [ ] 18.6 Section - Run the full integration gate and publish completion.
    - [ ] 18.6.1 Task - Rebuild and verify the complete candidate.
      - [ ] 18.6.1.1 Subtask - Run package, conformance, browser, formatting, archive, provenance, dependency, and hygiene gates.
      - [ ] 18.6.1.2 Subtask - Repeat maximum 512 and canonical `64, 65, 256, 512` from a second clean context.
      - [ ] 18.6.1.3 Subtask - Verify indexing, source binding, public facade stability, and historical immutability.
    - [ ] 18.6.2 Task - Publish and deliver one successor pull request.
      - [ ] 18.6.2.1 Subtask - Publish commands, hashes, samples, timings, counters, findings, limitations, and decision.
      - [ ] 18.6.2.2 Subtask - Open and merge one PR only after recording a truthful decision.
      - [ ] 18.6.2.3 Subtask - After merge, sync `main`, then delete local and remote feature branches.

## Exit gate

Phase 18 passes only when scalar success is provider-authorized and page-wide,
mixed results remain positional and fail closed, no owner path or expanded
success vector enters normal disposal, every retained ERTS/Chrome/Firefox
sample converges within 1000 ms, and a second clean build reproduces the result.

## Bound inputs

| Input | SHA-256 |
| --- | --- |
| `phase-17-review-and-reconciliation.md` | `ff23b8f46cbc029c43b23f249545f65b939fff91b25a9afa12e4dece06c0385c` |
| `phase-17-completion.md` | `9c40e1c8b5434a0f0f167624b24cfbdb2dd38c592d399f1711a9508817bda9bf` |
| `integration/bh-05/provider-release-ticket-attempts-v0.1.0.json` | `34564236d573659dd5d0aeed76abd99f19b8f3934ec5936e982601db797b8dd9` |
| `recovery_port.ex` | `cbda4de5b14e9c98b51846b207d1ea10270f858e272f9c24912ec0f8f8191c6f` |
| `root_port.ex` | `2955fc236feea594b5b41a85bd86eb147e24f6b5db1e72efb0e7c5482c00ad02` |
| `cleanup_outcome.ex` | `67e980aeb5ec9aeccad5523e87133d89b063ecbe2b267e5ed7f373e4347e6a42` |

## Connections

- [Phase 17 review](phase-17-review-and-reconciliation.md)
- [Phase 17 completion](phase-17-completion.md)
- [Provider release-ticket contract](provider-release-ticket-contract.md)
- [Sparse cleanup outcome contract](sparse-cleanup-outcome-contract.md)
