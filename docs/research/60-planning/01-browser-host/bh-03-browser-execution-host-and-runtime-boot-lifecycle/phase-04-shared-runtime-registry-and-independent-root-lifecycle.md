---
title: "Phase 4 - Shared Runtime Registry and Independent Root Lifecycle"
kind: note
created: "2026-09-06"
maturity: developing
tags:
  - bh-03
  - browser-host
  - root-lifecycle
  - runtime-registry
aliases:
  - "BH-03 phase 4"
---

# Phase 4 - Shared Runtime Registry and Independent Root Lifecycle

Back to milestone: [README](README.md)

- [ ] 4 Phase - Shared Runtime Registry and Independent Root Lifecycle.

  Reuse one compatible runtime per host scope while independent roots register,
  mount, update, move, dispose, and remount through isolated queues. Roots never
  receive runtime ownership, and this phase does not implement shutdown,
  runtime-loss recovery, retry, fallback, or browser-profile composition.

  - [x] 4.1 Section - Authorize Phase 4 and freeze the executable contract.

    - [x] 4.1.1 Task - Bind authority and predecessor truth.

      - [x] 4.1.1.1 Subtask - Record synchronized `main`, exact base, working branch, four-section delivery, one PR, merge, synchronized-main return, and local/remote branch deletion.
      - [x] 4.1.1.2 Subtask - Bind Phase 3 completion, contract, integration index, implementation evidence, and the BH-03 lifecycle vocabulary by SHA-256.
      - [x] 4.1.1.3 Subtask - Exclude shutdown, runtime loss, retry, fallback, browser-profile composition, measurements, support, and public stability.

    - [x] 4.1.2 Task - Freeze shared-runtime and root-lifecycle behavior.

      - [x] 4.1.2.1 Subtask - Define exact-compatible host scopes, coalesced startup, one sticky runtime result per scope, and mismatch rejection before reuse.
      - [x] 4.1.2.2 Subtask - Define root identities, limits, states, transitions, independent queues, generation acknowledgements, and duplicate/stale/ownership failures.
      - [x] 4.1.2.3 Subtask - Define runtime-versus-root ownership, bounded bridge operations, remount semantics, evidence boundaries, and the Phase 5 handoff.

  - [x] 4.2 Section - Implement the exact-compatible shared runtime registry.

    - [x] 4.2.1 Task - Coalesce startup per host scope.

      - [x] 4.2.1.1 Subtask - Validate the complete compatibility identity table and normalized scope identifier before creating registry state.
      - [x] 4.2.1.2 Subtask - Share one in-flight and ready startup result for equivalent callers without exposing runtime release ownership.
      - [x] 4.2.1.3 Subtask - Start different scopes independently and reject incompatible reuse before a second startup occurs.

    - [x] 4.2.2 Task - Make registry outcomes deterministic.

      - [x] 4.2.2.1 Subtask - Retain failed scope tombstones without retry or fallback and report bounded state snapshots and counters.
      - [x] 4.2.2.2 Subtask - Prove concurrent coalescing, ready reuse, scope isolation, mismatch, and sticky failure behavior.
      - [x] 4.2.2.3 Subtask - Keep root operations and all browser/measurement/acceptance evidence empty.

  - [x] 4.3 Section - Implement independent root registration and lifecycle.

    - [x] 4.3.1 Task - Execute the closed root operation set.

      - [x] 4.3.1.1 Subtask - Reserve unique bounded root identifiers and acknowledge registration before returning handles.
      - [x] 4.3.1.2 Subtask - Serialize mount, update, move, dispose, and remount per root while different roots progress independently.
      - [x] 4.3.1.3 Subtask - Require matching root identifier and generation acknowledgements before committing each state transition.

    - [x] 4.3.2 Task - Enforce independence and ownership.

      - [x] 4.3.2.1 Subtask - Reject duplicate roots, illegal transitions, stale generations, and foreign-root acknowledgements atomically.
      - [x] 4.3.2.2 Subtask - Prove one root's failure or disposal cannot mutate, block, or dispose another root.
      - [x] 4.3.2.3 Subtask - Add versioned conformance fixtures and expose root/registry snapshots without renderer or runtime ownership.

  - [ ] 4.4 Section - Run the inherited gate and publish completion evidence.

    - [ ] 4.4.1 Task - Execute the active Phase 4 checks.

      - [ ] 4.4.1.1 Subtask - Run project-local Mix/Node tests and builds, runtime verification, Phase 1 through Phase 4 validators/tests, inherited validators/generators, JSON, archive, tracked-file, and patch hygiene.
      - [ ] 4.4.1.2 Subtask - Confirm predecessor completion-bound artifacts remain unchanged and later browser/shutdown/recovery/measurement/acceptance results remain empty.
      - [ ] 4.4.1.3 Subtask - Record exact commands, counts, negative outcomes, environment, and limitations.

    - [ ] 4.4.2 Task - Publish the Phase 4 decision.

      - [ ] 4.4.2.1 Subtask - Emit a versioned validation log, implementation-evidence note, validator, tests, and completion decision bound to tracked artifacts.
      - [ ] 4.4.2.2 Subtask - Mark Phase 4 complete only if every active gate passes without overclaim.
      - [ ] 4.4.2.3 Subtask - Leave Phase 5 eligible but unauthorized.

## Section delivery rule

Complete and verify each section before its commit. Open and merge one pull
request only after Section 4.4 passes. Phase 4 may reuse one compatible runtime
and exercise root lifecycle through injected transport conformance; it must not
implement shutdown, recovery, fallback, or claim browser conformance.

## Connections

- [BH-03 plan](README.md)
- [Phase 3 implementation evidence](phase-03-implementation-evidence.md)
- [Development environment and deferred qualification policy](../../development-environment-and-deferred-qualification-policy.md)
- [BH-03 Phase 4 executable contract](../../../assets/bh-03-baseline/blazex-bh-03-phase-04-contract-v0.1.0.json)
