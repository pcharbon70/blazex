---
title: "Phase 16 - Factorized Distribution Shape and Sparse Cleanup Outcomes"
kind: note
created: "2026-09-11"
maturity: developing
tags: [atomvm, bh-05, cleanup, implementation-planning, reliability]
aliases: ["BH-05 phase 16", "BH-05 sparse cleanup outcomes"]
---

# Phase 16 - Factorized Distribution Shape and Sparse Cleanup Outcomes

Back to milestone: [README](README.md)

- [x] 16 Phase - Factorized Distribution Shape and Sparse Cleanup Outcomes.

  Correct `BH05-P15-MAXIMUM-DISTRIBUTION-SHAPE` by varying payload size,
  lease-identifier size, owner-path depth/distribution, inventory size, and
  outcome retention independently. Replace successful lease outcomes that
  retain full owner graphs with ordered identifiers plus sparse owner records
  for unresolved entries. Preserve the 1000 ms deadline, count and repetition
  matrices, page size 64, maximum page size 128, exact unresolved identities,
  forced recovery, and append-only failed evidence.

  The repository owner authorized this work on 2026-09-11. It starts from
  synchronized `main` at `0bb08528660aad2b7d0ccbb5dd5c70d8b55a08b7` on
  `codex/bh05-phase16-sparse-cleanup-outcomes`. Delivery requires one commit
  per section, one pull request, its authorized merge, synchronization of
  `main` with `origin/main`, and deletion of the local and remote feature
  branch. BH-06 remains ineligible and unauthorized until the frozen gate
  passes. LiveView and LocalLiveView remain **[DEFERRED]**.

  - [x] 16.1 Section - Freeze factorization, representation, and authority.
    - [x] 16.1.1 Task - Bind Phase 15 evidence and immutable constraints.
      - [x] 16.1.1.1 Subtask - Record source, branch, section commits, single-PR delivery, merge authority, and cleanup sequence.
      - [x] 16.1.1.2 Subtask - Bind the Phase 15 review, completion, attempt ledger, and affected sources by path and SHA-256.
      - [x] 16.1.1.3 Subtask - Prohibit deadline increases, fixture reductions, browser exclusions, failed-sample deletion, support promotion, and LiveView scope expansion.
    - [x] 16.1.2 Task - Freeze factorized diagnosis and sparse-outcome rules.
      - [x] 16.1.2.1 Subtask - Measure each maximum-shape axis independently at 256 and 512 before accepting a causal correction.
      - [x] 16.1.2.2 Subtask - Retain ordered lease IDs for all outcomes and full owners only for unresolved entries.
      - [x] 16.1.2.3 Subtask - Require exact reconstruction, bounded sparse records, portable reports, and unchanged provider callbacks.

  - [x] 16.2 Section - Add factorized fixtures and causal instrumentation.
    - [x] 16.2.1 Task - Separate the combined maximum workload axes.
      - [x] 16.2.1.1 Subtask - Add payload-only, identifier-only, owner-depth-only, distribution-only, inventory-only, and outcome-retention probes.
      - [x] 16.2.1.2 Subtask - Record stage timing, retained outcome bytes, unresolved counts, and structural amplification at 256 and 512.
      - [x] 16.2.1.3 Subtask - Keep canonical, minimal, and combined-maximum fixtures byte-for-byte semantically unchanged.
    - [x] 16.2.2 Task - Make factor evidence reproducible and fail closed.
      - [x] 16.2.2.1 Subtask - Add exact operation routing and a machine-readable factor schema.
      - [x] 16.2.2.2 Subtask - Reject missing axes, combined-only claims, altered bounds, and unavailable mandatory structural fields.
      - [x] 16.2.2.3 Subtask - Preserve source, runtime, bundle, browser, and clean-context identities.

  - [x] 16.3 Section - Implement sparse terminal cleanup outcomes.
    - [x] 16.3.1 Task - Remove completed owner graphs from retained pages.
      - [x] 16.3.1.1 Subtask - Encode ordered lease IDs and sparse unresolved owner entries per page.
      - [x] 16.3.1.2 Subtask - Reconstruct exact unresolved identities and validate sparse indexes atomically.
      - [x] 16.3.1.3 Subtask - Preserve terminal ledger summaries, forced updates, counts, and compatibility expansion.
    - [x] 16.3.2 Task - Bound outcome storage independently of owner depth.
      - [x] 16.3.2.1 Subtask - Report retained outcome bytes and sparse owner counts.
      - [x] 16.3.2.2 Subtask - Prove completed deep/distributed owners do not survive in terminal pages.
      - [x] 16.3.2.3 Subtask - Keep unresolved owners exact and portable through repeated reporting.

  - [x] 16.4 Section - Extend structural, lifecycle, and anti-concealment gates.
    - [x] 16.4.1 Task - Verify sparse representation invariants.
      - [x] 16.4.1.1 Subtask - Test uniform, mixed, forced, malformed-index, maximum-ID, and deep-owner pages.
      - [x] 16.4.1.2 Subtask - Test counts, folds, exact matching, terminal summaries, and history bounds.
      - [x] 16.4.1.3 Subtask - Test cleanup-session convergence, portable snapshots, and zero normal worker starts.
    - [x] 16.4.2 Task - Detect hidden scaling regressions.
      - [x] 16.4.2.1 Subtask - Mutation-test owner retention, factor omission, deadline drift, count reduction, and masked unresolved rows.
      - [x] 16.4.2.2 Subtask - Bound successful outcome size by identifiers rather than owner depth or acquisition payload.
      - [x] 16.4.2.3 Subtask - Retain Phase 13-15 process, message, inventory, outcome, and timing-shape checks.

  - [x] 16.5 Section - Requalify active runtimes and reconcile BH-05.
    - [x] 16.5.1 Task - Execute the source-frozen factor and correction matrices.
      - [x] 16.5.1.1 Subtask - Run ERTS and Linux Chrome/Firefox factor probes, canonical counts, maximum counts, adverse cases, and growth cases.
      - [x] 16.5.1.2 Subtask - Require every retained active correction sample within 1000 ms with zero unresolved identities and exact inventory convergence.
      - [x] 16.5.1.3 Subtask - Preserve all raw failures, timings, variance, counters, unavailable metrics, and artifact hashes.
    - [x] 16.5.2 Task - Review and reconcile the successor decision.
      - [x] 16.5.2.1 Subtask - Review correctness, portability, performance, malformed input, evidence, security, and compatibility.
      - [x] 16.5.2.2 Subtask - Map every Phase 15 re-entry condition and new finding to evidence.
      - [x] 16.5.2.3 Subtask - Accept only when all frozen gates pass; otherwise record revise or block.

  - [x] 16.6 Section - Run the full integration gate and publish completion.
    - [x] 16.6.1 Task - Rebuild and verify the complete candidate.
      - [x] 16.6.1.1 Subtask - Run package, conformance, browser, formatting, archive, provenance, dependency, and hygiene gates.
      - [x] 16.6.1.2 Subtask - Repeat maximum 512 and canonical `64, 65, 256, 512` from a second clean context.
      - [x] 16.6.1.3 Subtask - Verify indexing, source binding, public API stability, and historical immutability.
    - [x] 16.6.2 Task - Publish and deliver one successor pull request.
      - [x] 16.6.2.1 Subtask - Publish commands, environments, hashes, samples, timings, factor findings, limitations, and decision.
      - [x] 16.6.2.2 Subtask - Open and merge one PR only after recording a truthful decision.
      - [x] 16.6.2.3 Subtask - After merge, sync `main`, then delete local and remote feature branches.

## Exit gate

Phase 16 passes only when the factor matrix isolates the nonlinear structure,
successful outcomes retain no owner graphs, unresolved owners reconstruct
exactly, every retained ERTS/Chrome/Firefox correction sample has zero
unresolved identities within 1000 ms, and the complete BH-05 gate reproduces.

## Bound inputs

| Input | SHA-256 |
| --- | --- |
| `phase-15-review-and-reconciliation.md` | `1f26b51cf6e6c0729808066898031c5d5ff8caa261ca39dbee33c2c094777a3e` |
| `phase-15-completion.md` | `425ab7de7564ff9f4b49541b6d94b57f85279f2f1b040bb8eca44cf82e78f79f` |
| `integration/bh-05/runtime-owned-inventory-attempts-v0.1.0.json` | `ff697289da5effe7418541cfcb2ba3f994781c87530be9ef138cbaab7e79474d` |
| `cleanup_outcome.ex` | `c2f4e2c905cb583be91adf6a80818835244807c7d5eb093cac9e00319858f623` |
| `recovery_cleanup.ex` | `8a1c5598c9306c52323f166e8f8ea1212b8201eca340026106d2df3193289fad` |
| `cleanup_scaling.ex` | `58118d476e91ed59e20b62c5e76c13053ef347ea10b1cadd740d71756988b3c2` |

## Connections

- [Sparse cleanup outcome contract](sparse-cleanup-outcome-contract.md)
- [Phase 16 review and reconciliation](phase-16-review-and-reconciliation.md)
- [Phase 16 completion evidence](phase-16-completion.md)
- [Phase 15 review](phase-15-review-and-reconciliation.md)
- [Phase 15 completion](phase-15-completion.md)
- [Runtime-owned resource inventory contract](runtime-owned-resource-inventory-contract.md)
- [Cleanup scaling contract](cleanup-scaling-contract.md)
- [Development and deferred qualification policy](../../development-environment-and-deferred-qualification-policy.md)
