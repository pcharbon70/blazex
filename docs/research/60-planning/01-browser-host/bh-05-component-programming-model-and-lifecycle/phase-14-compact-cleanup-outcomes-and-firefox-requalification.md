---
title: "Phase 14 - Compact Cleanup Outcomes and Firefox Requalification"
kind: note
created: "2026-09-11"
maturity: developing
tags:
  - atomvm
  - bh-05
  - cleanup
  - implementation-planning
  - reliability
  - scaling
aliases:
  - "BH-05 phase 14"
  - "BH-05 compact cleanup correction"
---

# Phase 14 - Compact Cleanup Outcomes and Firefox Requalification

Back to milestone: [README](README.md)

- [x] 14 Phase - Compact Cleanup Outcomes and Firefox Requalification.

  Correct the Phase 13 Firefox deadline failure by removing per-resource
  public-map materialization and duplicate ledger collation from the cleanup
  hot path. Preserve the 1000 ms deadline, 512-lease fixture, page size 64,
  maximum page size 128, exact outcomes, and append-only failed evidence.

  The repository owner authorized this work on 2026-09-11. It starts from
  synchronized `main` at `7798903bf74250ead754955502fe33ccb5e4a974` on
  `codex/bh05-phase14-compact-cleanup-reporting`. Delivery requires one commit
  per section, one pull request, its authorized merge, synchronization of
  `main` with `origin/main`, and deletion of the local and remote feature
  branch. BH-06 remains ineligible and unauthorized until this phase passes.
  LiveView and LocalLiveView remain **[DEFERRED]**.

  - [x] 14.1 Section - Freeze compact reporting and corrective authority.
    - [x] 14.1.1 Task - Bind Phase 13 inputs and immutable constraints.
      - [x] 14.1.1.1 Subtask - Record source, branch, section commits, one PR, merge authority, and cleanup workflow.
      - [x] 14.1.1.2 Subtask - Bind the Phase 13 decision and cleanup sources by path and SHA-256.
      - [x] 14.1.1.3 Subtask - Prohibit deadline increases, fixture or repetition reductions, browser exclusions, timer movement, failed-sample deletion, and support promotion.
    - [x] 14.1.2 Task - Freeze the compact exact outcome contract.
      - [x] 14.1.2.1 Subtask - Store at most 64 ordered identities per versioned page with scalar-or-vector outcomes and no duplicated acquisition payload.
      - [x] 14.1.2.2 Subtask - Preserve exact owner, lease ID, normal status, forced status, unresolved flag, and page elapsed time per item.
      - [x] 14.1.2.3 Subtask - Provide bounded validation, folding, extraction, and diagnostic expansion outside the timed path.

  - [x] 14.2 Section - Implement compact exact cleanup outcomes.
    - [x] 14.2.1 Task - Add the internal versioned outcome-page codec.
      - [x] 14.2.1.1 Subtask - Encode homogeneous values once and heterogeneous values as bounded vectors.
      - [x] 14.2.1.2 Subtask - Reject malformed versions, lengths, identities, statuses, and oversized pages.
      - [x] 14.2.1.3 Subtask - Test success, partial failure, forced recovery, extraction, expansion, and malformed pages.
    - [x] 14.2.2 Task - Replace lease-row construction in recovery cleanup.
      - [x] 14.2.2.1 Subtask - Retain normal results as compact pages without acquisition metadata.
      - [x] 14.2.2.2 Subtask - Apply forced results by stable page/item position and retain exact failures.
      - [x] 14.2.2.3 Subtask - Keep non-lease rows bounded and preserve historical unresolved inventories.

  - [x] 14.3 Section - Reconcile the ledger atomically from outcome vectors.
    - [x] 14.3.1 Task - Add ordered bounded terminal reconciliation.
      - [x] 14.3.1.1 Subtask - Consume one terminal status per ordered lease without constructing `{lease, status}` pairs.
      - [x] 14.3.1.2 Subtask - Clear exact leases, update totals, and retain the bounded history tail.
      - [x] 14.3.1.3 Subtask - Reject count or identity mismatch without manufacturing success.
    - [x] 14.3.2 Task - Integrate recovery totals and deadline accounting.
      - [x] 14.3.2.1 Subtask - Derive all counts by bounded page folds.
      - [x] 14.3.2.2 Subtask - Keep encoding and reconciliation inside the original deadline interval.
      - [x] 14.3.2.3 Subtask - Prove idempotency, stale rejection, callback order, and unresolved retention.

  - [x] 14.4 Section - Extend structural and anti-concealment gates.
    - [x] 14.4.1 Task - Measure outcome representation scaling.
      - [x] 14.4.1.1 Subtask - Record page count, encoded bytes, identities, vectors, and expanded rows.
      - [x] 14.4.1.2 Subtask - Require page-proportional maps and zero timed-path row expansion.
      - [x] 14.4.1.3 Subtask - Retain Phase 13 callback, worker, message, payload, shape, and availability counters.
    - [x] 14.4.2 Task - Make compact evidence fail closed.
      - [x] 14.4.2.1 Subtask - Mutation-test missing/reordered identities, vector length, scalar substitution, and masked failure.
      - [x] 14.4.2.2 Subtask - Recompute terminal inventories and summaries from compact pages.
      - [x] 14.4.2.3 Subtask - Preserve Phase 12 and 13 failures in the append-only ledger.

  - [x] 14.5 Section - Requalify active runtimes and reconcile BH-05.
    - [x] 14.5.1 Task - Execute the source-frozen correction matrix.
      - [x] 14.5.1.1 Subtask - Run ERTS/headless and Linux Chrome/Firefox AtomVM/DOM matrices and growth cases.
      - [x] 14.5.1.2 Subtask - Require every retained active sample within 1000 ms with zero live and unresolved leases.
      - [x] 14.5.1.3 Subtask - Preserve identities, hashes, raw failures, variance, counters, and unavailable metrics.
    - [x] 14.5.2 Task - Review and reconcile the successor decision.
      - [x] 14.5.2.1 Subtask - Review correctness, portability, performance, malformed input, evidence, and compatibility.
      - [x] 14.5.2.2 Subtask - Publish findings and map every Phase 13 re-entry condition to evidence.
      - [x] 14.5.2.3 Subtask - Accept only when all frozen gates pass; otherwise record revise or block.

  - [x] 14.6 Section - Run the full integration gate and publish completion.
    - [x] 14.6.1 Task - Rebuild and verify the complete candidate.
      - [x] 14.6.1.1 Subtask - Run package, conformance, browser, formatting, archive, provenance, dependency, and hygiene gates.
      - [x] 14.6.1.2 Subtask - Repeat 512 and `64, 65, 256, 512` from a second clean context.
      - [x] 14.6.1.3 Subtask - Verify indexing and source binding without historical rewrites.
    - [x] 14.6.2 Task - Publish and deliver one successor pull request.
      - [x] 14.6.2.1 Subtask - Publish commands, environments, hashes, samples, timings, inventories, findings, limitations, and outcomes.
      - [x] 14.6.2.2 Subtask - Open one PR only after recording a truthful decision.
      - [x] 14.6.2.3 Subtask - After merge, sync `main`, then delete local and remote feature branches.

## Exit gate

Phase 14 passes only when exact compact pages validate, summaries recompute,
the timed path expands zero diagnostic rows, every retained ERTS/Chrome/Firefox
sample has zero unresolved identities and stays within the unchanged deadline,
structural and shape gates pass, and the source-frozen BH-05 gate reproduces.

## Connections

- [Compact cleanup outcome contract](compact-cleanup-outcome-contract.md)
- [Phase 13 plan](phase-13-bounded-paged-cleanup-and-scaling-requalification.md)
- [Phase 13 completion](phase-13-completion.md)
- [Phase 13 review and reconciliation](phase-13-review-and-reconciliation.md)
- [Development environment policy](../../development-environment-and-deferred-qualification-policy.md)
