---
title: "Phase 3 - Artifact Acquisition, Runtime Startup, and Readiness"
kind: note
created: "2026-09-06"
maturity: developing
tags:
  - artifact-integrity
  - bh-03
  - browser-host
  - runtime-startup
aliases:
  - "BH-03 phase 3"
---

# Phase 3 - Artifact Acquisition, Runtime Startup, and Readiness

Back to milestone: [README](README.md)

- [ ] 3 Phase - Artifact Acquisition, Runtime Startup, and Readiness.

  Acquire only the artifacts accepted by the Phase 2 pre-acquisition gate,
  start the pinned Popcorn runtime through an isolated transport, load the
  declared application bundle, and resolve only after a bounded, correlated
  readiness event. This phase does not share runtimes or register roots.

  - [x] 3.1 Section - Authorize Phase 3 and freeze the executable contract.

    - [x] 3.1.1 Task - Bind authority and predecessor truth.

      - [x] 3.1.1.1 Subtask - Record synchronized `main`, exact base, working branch, four-section delivery, one PR, merge, synchronized-main return, and local/remote branch deletion.
      - [x] 3.1.1.2 Subtask - Bind the Phase 2 completion, executable contract, integration index, profile manifest, and implementation evidence by SHA-256.
      - [x] 3.1.1.3 Subtask - Exclude shared-runtime registry, root lifecycle, shutdown/recovery, profile browser composition, measurements, support, and public stability.

    - [x] 3.1.2 Task - Freeze acquisition, startup, and readiness behavior.

      - [x] 3.1.2.1 Subtask - Define exact artifact order, per-role and aggregate byte limits, response constraints, digest verification, and all-or-nothing publication.
      - [x] 3.1.2.2 Subtask - Define the immutable Popcorn startup descriptor, isolated transport handoff, application-bundle load, and generation correlation.
      - [x] 3.1.2.3 Subtask - Define bounded readiness, cancellation, failure classification, cleanup ownership, and the Phase 4 boundary.

  - [x] 3.2 Section - Implement verified all-or-nothing artifact acquisition.

    - [x] 3.2.1 Task - Acquire only accepted manifest artifacts.

      - [x] 3.2.1.1 Subtask - Require a successful Phase 2 gate result and preserve the declared runtime-module, runtime-wasm, and application-bundle order.
      - [x] 3.2.1.2 Subtask - Fetch same-origin, no-store, identity-encoded responses with bounded cancellation and no redirects.
      - [x] 3.2.1.3 Subtask - Enforce declaration, per-role, aggregate, MIME, exact-size, SHA-256, and WebAssembly structural checks before publishing any bytes.

    - [x] 3.2.2 Task - Prove integrity and availability failures are atomic.

      - [x] 3.2.2.1 Subtask - Cover valid acquisition, corruption, truncation, oversize streams, MIME/encoding/redirect errors, cancellation, and unavailable artifacts.
      - [x] 3.2.2.2 Subtask - Normalize failures to the Phase 1 artifact-integrity or artifact-unavailable vocabulary.
      - [x] 3.2.2.3 Subtask - Keep runtime starts and all later evidence at zero.

  - [x] 3.3 Section - Implement isolated runtime startup, bundle load, and readiness.

    - [x] 3.3.1 Task - Start one isolated runtime attempt.

      - [x] 3.3.1.1 Subtask - Publish the adapter-owned startup descriptor and transfer verified artifact bytes through the runtime transport.
      - [x] 3.3.1.2 Subtask - Load the application bundle at the fixed virtual path and correlate startup events by attempt and manifest generation.
      - [x] 3.3.1.3 Subtask - Resolve only for the exact readiness event; reject stale, duplicate, failed, cancelled, and timed-out attempts.

    - [x] 3.3.2 Task - Prove cleanup and ownership limits.

      - [x] 3.3.2.1 Subtask - Release transports, listeners, abort controllers, timers, and unpublished artifact bytes on every terminal failure.
      - [x] 3.3.2.2 Subtask - Add versioned success and negative fixtures plus deterministic unit/conformance tests.
      - [x] 3.3.2.3 Subtask - Return an attempt-scoped ready handle without implementing runtime sharing, roots, recovery, or browser-profile composition.

  - [ ] 3.4 Section - Run the inherited gate and publish completion evidence.

    - [ ] 3.4.1 Task - Execute the active Phase 3 checks.

      - [ ] 3.4.1.1 Subtask - Run project-local Mix/Node tests and builds, runtime verification, Phase 1 through Phase 3 validators/tests, inherited validators/generators, JSON, archive, tracked-file, and patch hygiene.
      - [ ] 3.4.1.2 Subtask - Confirm the three profile artifacts still match their Phase 2 declarations and no completion-bound predecessor artifact changed.
      - [ ] 3.4.1.3 Subtask - Record exact commands, counts, negative outcomes, environment, limitations, and zero browser/root/measurement/acceptance results.

    - [ ] 3.4.2 Task - Publish the Phase 3 decision.

      - [ ] 3.4.2.1 Subtask - Emit a versioned validation log, implementation-evidence note, validator, tests, and completion decision bound to tracked artifacts.
      - [ ] 3.4.2.2 Subtask - Mark Phase 3 complete only if every active gate passes without overclaim.
      - [ ] 3.4.2.3 Subtask - Leave Phase 4 eligible but unauthorized.

## Section delivery rule

Complete and verify each section before its commit. Open and merge one pull
request only after Section 3.4 passes. Phase 3 may create one isolated runtime
attempt and return an attempt-scoped ready handle; it must not share that
runtime, register a root, or claim browser conformance.

## Connections

- [BH-03 plan](README.md)
- [Phase 2 implementation evidence](phase-02-implementation-evidence.md)
- [Development environment and deferred qualification policy](../../development-environment-and-deferred-qualification-policy.md)
- [BH-03 Phase 3 executable contract](../../../assets/bh-03-baseline/blazex-bh-03-phase-03-contract-v0.1.0.json)
