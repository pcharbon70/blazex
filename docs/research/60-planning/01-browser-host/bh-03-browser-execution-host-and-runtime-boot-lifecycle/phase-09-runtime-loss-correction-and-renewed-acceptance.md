---
title: "Phase 9 - Runtime-Loss Correction and Renewed Acceptance"
kind: note
created: "2026-09-07"
maturity: developing
tags:
  - bh-03
  - runtime-lifecycle
  - implementation-planning
aliases: []
---

# Phase 9 - Runtime-Loss Correction and Renewed Acceptance

This explicitly authorized corrective extension follows the original eight
phases without renumbering them. [Phase 8](phase-08-implementation-evidence.md)
remains an immutable revise decision.

- [x] 9 Phase - Correct runtime-loss propagation and repeat acceptance.
  - [x] 9.1 Section - Authorize corrective scope and freeze the handoff.
    - [x] 9.1.1 Task - Bind Phase 8 findings and synchronized main.
      - [x] 9.1.1.1 Subtask - Preserve user work and use four section commits in one PR.
      - [x] 9.1.1.2 Subtask - Freeze bounded loss/recovery, historical-source exceptions, and nonclaims.
  - [x] 9.2 Section - Implement registry-owned loss observation.
    - [x] 9.2.1 Task - Observe correlated post-readiness exit/failure without stale ready reuse.
      - [x] 9.2.1.1 Subtask - Bind observers to each ready handle; latch loss before subscription.
      - [x] 9.2.1.2 Subtask - Exclude stale callbacks and intentional shutdown, clean subscriptions and transport.
      - [x] 9.2.1.3 Subtask - Preserve one replacement, reject loss during replay, and test races.
  - [x] 9.3 Section - Integrate and exercise active browser correction.
    - [x] 9.3.1 Task - Repeat the real profile lifecycle with controlled runtime failures.
      - [x] 9.3.1.1 Subtask - Prove two-root replay, stale-event rejection, repeated-loss fallback, and shutdown in Chrome and Firefox.
      - [x] 9.3.1.2 Subtask - Preserve prior evidence with exact historical bindings and current-source validation.
  - [x] 9.4 Section - Run integration gate and publish superseding acceptance.
    - [x] 9.4.1 Task - Run JavaScript, pinned Mix/runtime, active browsers/measurements, research validators/tests/generators, JSON and archive checks.
      - [x] 9.4.1.1 Subtask - Reconcile the blocker and all inherited obligations; bind exact source, evidence, commands, and limitations.
      - [x] 9.4.1.2 Subtask - Accept with bounded conditions only if all active gates pass; otherwise revise or block.
      - [x] 9.4.1.3 Subtask - Record the post-commit protocol: merge one PR, synchronize main, delete branch, and restore user work.

## Integration gate

Controlled browser failure injection exercises the real Wasm runtime's failure
callback and real transport/registry; it does not qualify OS/browser-process
crashes, hangs, mobile suspension, or memory-pressure behavior. No root may
observe a ready scope backed by a known-dead runtime. Replay cannot publish
ready if the replacement fails. Normal shutdown must not start replacement.

All nine Phase 8 output mappings and 31 obligations remain in force.
[DEFERRED] platform/device, second-host and manual AT work remains owned by
qualification owners and reactivates by BH-22 under the
[development policy](../../development-environment-and-deferred-qualification-policy.md).
Memory observations are not leak proof or budgets; APIs remain experimental
and browsers unsupported. Acceptance makes BH-04 eligible, never authorized.

## Evidence and authority

- [Authorization](../../../assets/bh-03-baseline/blazex-bh-03-phase-09-authorization-v0.1.0.json)
- [Milestone](README.md)

Historical source exceptions are limited to the authorization's exact paths.
Historical decisions keep their hashes; the final current implementation must
be independently hash-bound by the Phase 9 completion gate.
