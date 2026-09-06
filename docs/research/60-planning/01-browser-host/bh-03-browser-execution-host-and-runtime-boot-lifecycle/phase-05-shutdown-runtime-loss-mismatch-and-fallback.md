---
title: "Phase 5 - Shutdown, Runtime Loss, Mismatch, and Fallback"
kind: note
created: "2026-09-06"
maturity: developing
tags:
  - bh-03
  - browser-host
  - fallback
  - runtime-lifecycle
aliases:
  - "BH-03 phase 5"
---

# Phase 5 - Shutdown, Runtime Loss, Mismatch, and Fallback

Back to milestone: [README](README.md)

- [x] 5 Phase - Shutdown, Runtime Loss, Mismatch, and Fallback.

  Make page-level runtime ownership converge intentionally after shutdown,
  post-readiness runtime loss, incompatibility, and unavailable prerequisites.
  One retryable loss may replace the runtime and replay existing roots through
  the same handles. Fallback is a bounded decision record only; Phase 6 owns
  browser-profile composition and visible presentation.

  - [x] 5.1 Section - Authorize Phase 5 and freeze the lifecycle contract.

    - [x] 5.1.1 Task - Bind authority and predecessor truth.

      - [x] 5.1.1.1 Subtask - Record synchronized `main`, exact base, working branch, four-section delivery, one PR, merge, synchronized-main return, and local/remote branch deletion.
      - [x] 5.1.1.2 Subtask - Bind Phase 4 completion, contract, integration index, implementation evidence, and the BH-03 lifecycle vocabulary by SHA-256.
      - [x] 5.1.1.3 Subtask - Exclude Phase 6 browser composition, visible DOM fallback, measurements, acceptance, support, publication, and public stability.

    - [x] 5.1.2 Task - Freeze shutdown, loss, recovery, and fallback behavior.

      - [x] 5.1.2.1 Subtask - Define registry-owned shutdown ordering, timeout bounds, acknowledgements, unconditional release, tombstones, and idempotence.
      - [x] 5.1.2.2 Subtask - Define generation-bound loss reports, root quiescence, one replacement, same-handle atomic replay, and failure convergence.
      - [x] 5.1.2.3 Subtask - Define bounded non-DOM fallback decisions for mismatch, unsupported prerequisites, startup failure, runtime loss, and recovery exhaustion.

  - [x] 5.2 Section - Implement deterministic shutdown and terminal ownership.

    - [x] 5.2.1 Task - Quiesce roots and stop one shared runtime.

      - [x] 5.2.1.1 Subtask - Reject new roots, drain per-root queues, dispose registrations independently, and stop every root bridge.
      - [x] 5.2.1.2 Subtask - Require matching scope and runtime-generation shutdown acknowledgement before success.
      - [x] 5.2.1.3 Subtask - Release the registry-owned runtime exactly once on success, rejection, or timeout and retain a stopped tombstone.

    - [x] 5.2.2 Task - Make shutdown bounded and idempotent.

      - [x] 5.2.2.1 Subtask - Coalesce concurrent close requests and return the stopped snapshot on later close calls.
      - [x] 5.2.2.2 Subtask - Force-stop root bridges and classify timeout, stale acknowledgement, foreign acknowledgement, and remote rejection deterministically.
      - [x] 5.2.2.3 Subtask - Prove roots and scope handles cannot release or revive the runtime after registry shutdown.

  - [x] 5.3 Section - Implement runtime-loss recovery and bounded fallback decisions.

    - [x] 5.3.1 Task - Recover one exact active generation without partial roots.

      - [x] 5.3.1.1 Subtask - Reject stale loss reports without mutation; quiesce active roots and release the failed runtime once.
      - [x] 5.3.1.2 Subtask - Attempt one delayed replacement, preserve scope and root handle identities, and replay registered, ready, and disposed roots.
      - [x] 5.3.1.3 Subtask - Publish ready only after every retained root replay succeeds; otherwise release the replacement and retain fallback state.

    - [x] 5.3.2 Task - Classify intentional fallback without rendering it.

      - [x] 5.3.2.1 Subtask - Map compatibility mismatch, unsupported prerequisites, startup failure, non-retryable loss, replay failure, and replacement exhaustion to closed fallback actions.
      - [x] 5.3.2.2 Subtask - Redact and bound fallback diagnostics, forbid partial activation, and keep all DOM/HTML/browser-profile behavior absent.
      - [x] 5.3.2.3 Subtask - Add versioned injected-transport fixtures and prove retry, replay, isolation, exhaustion, and fallback behavior.

  - [x] 5.4 Section - Run the inherited gate and publish completion evidence.

    - [x] 5.4.1 Task - Execute the active Phase 5 checks.

      - [x] 5.4.1.1 Subtask - Run project-local Mix/Node tests and builds, runtime verification, Phase 1 through Phase 5 validators/tests, inherited validators/generators, JSON, archive, tracked-file, and patch hygiene.
      - [x] 5.4.1.2 Subtask - Confirm predecessor completion-bound artifacts remain unchanged and browser/profile/measurement/acceptance results remain empty.
      - [x] 5.4.1.3 Subtask - Record exact commands, counts, negative outcomes, environment, and limitations.

    - [x] 5.4.2 Task - Publish the Phase 5 decision.

      - [x] 5.4.2.1 Subtask - Emit a versioned validation log, implementation-evidence note, validator, tests, and completion decision bound to tracked artifacts.
      - [x] 5.4.2.2 Subtask - Mark Phase 5 complete only if every active gate passes without overclaim.
      - [x] 5.4.2.3 Subtask - Leave Phase 6 eligible but unauthorized.

## Section delivery rule

Complete and verify each section before its commit. Open and merge one pull
request only after Section 5.4 passes. Phase 5 may exercise shutdown, recovery,
root replay, and fallback decisions through injected transport conformance; it
must not compose a browser profile, render fallback UI, or claim browser
conformance.

## Connections

- [BH-03 plan](README.md)
- [Phase 4 implementation evidence](phase-04-implementation-evidence.md)
- [Development environment and deferred qualification policy](../../development-environment-and-deferred-qualification-policy.md)
- [BH-03 Phase 5 executable contract](../../../assets/bh-03-baseline/blazex-bh-03-phase-05-contract-v0.1.0.json)
