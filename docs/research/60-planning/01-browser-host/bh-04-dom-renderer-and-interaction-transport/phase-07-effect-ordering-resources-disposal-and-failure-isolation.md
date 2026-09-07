---
title: "Phase 7 - Effect Ordering, Resources, Disposal, and Failure Isolation"
kind: note
created: "2026-09-06"
maturity: developing
tags:
  - bh-04
  - effects
  - implementation-planning
  - reliability
  - resources
aliases:
  - "BH-04 phase 7"
---

# Phase 7 - Effect Ordering, Resources, Disposal, and Failure Isolation

Back to milestone: [README](README.md)

- [ ] 7 Phase - Effect Ordering, Resources, Disposal, and Failure Isolation.

  Complete the renderer lifecycle around DOM commit. Effects execute only at
  declared barriers, every browser-owned resource belongs to one root
  generation, disposal converges exactly once, and malformed or failed traffic
  cannot corrupt sibling roots or grow retries, queues, listeners, and retained
  state without bound.

  - [ ] 7.1 Section - Authorize and freeze ordering and ownership policy.

    Bind accepted effects/resources and DOM commit semantics before enabling
    browser side effects or failure recovery.

    - [ ] 7.1.1 Task - Record bounded Phase 7 authority.

      Establish exact inputs and exclude later capability and resilience
      product features.

      - [ ] 7.1.1.1 Subtask - Record synchronized base, branch, section commits, one PR, cleanup, Phase 6 completion identity, and explicit Phase 7 authorization.
      - [ ] 7.1.1.2 Subtask - Bind effect phases, resource handles, generation/revision ownership, transaction barriers, focus/selection ordering, BH-03 shutdown/runtime-loss, and renderer failure acceptance by version and hash.
      - [ ] 7.1.1.3 Subtask - Exclude BH-13 broad browser capabilities, BH-15 offline recovery, BH-18 activation, unbounded automatic retry, product components, and support claims.

    - [ ] 7.1.2 Task - Freeze commit/effect and resource lifecycle rules.

      Make execution points, cancellation, diagnostics, and cleanup deadlines
      explicit for every renderer-owned resource class.

      - [ ] 7.1.2.1 Subtask - Define preflight, pre-commit, commit, focus/selection restore, post-commit, paint-observation, acknowledgement, and disposal barriers with legal effect classes at each point.
      - [ ] 7.1.2.2 Subtask - Define ownership and replacement rules for listeners, pending transactions, queued interactions, timers used by the renderer, observers, focus/composition records, rollback journals, and diagnostics.
      - [ ] 7.1.2.3 Subtask - Define timeout, cancellation, retry eligibility, maximum attempts, failure escalation, fallback, and cleanup convergence against the 1000 ms renderer-failure observation window.

  - [ ] 7.2 Section - Implement ordered effects and resource accounting.

    Execute only negotiated renderer effects and track every acquired resource
    in a generation-scoped ledger.

    - [ ] 7.2.1 Task - Implement transaction effect barriers.

      Ensure effects cannot observe or act on an uncommitted, rolled-back,
      stale, or disposed root.

      - [ ] 7.2.1.1 Subtask - Validate effect identity, capability, owner, generation, revision, barrier, dependencies, payload bounds, timeout, and fallback before scheduling.
      - [ ] 7.2.1.2 Subtask - Execute focus/selection and permitted browser effects in deterministic barrier order and correlate results with transaction acknowledgements.
      - [ ] 7.2.1.3 Subtask - Reject or cancel stale, duplicate, unsupported, post-failure, and post-disposal effects without browser mutation or semantic state advancement.

    - [ ] 7.2.2 Task - Implement renderer resource ledger and disposal.

      Account for creation, replacement, cancellation, release, and leak checks
      independently for each root generation.

      - [ ] 7.2.2.1 Subtask - Register all renderer-owned listeners, queues, pending records, callbacks, observers, rollback state, timers, and effect handles with stable owner identities.
      - [ ] 7.2.2.2 Subtask - Release superseded resources on node removal/replacement, generation replacement, transaction rejection, root disposal, runtime loss, shutdown, and fallback.
      - [ ] 7.2.2.3 Subtask - Make disposal idempotent and observable, reject cross-root release, and report retained resources after the declared convergence bound.

  - [ ] 7.3 Section - Implement renderer failure isolation and recovery.

    Apply the canonical renderer-failure contract consistently across protocol,
    reconciliation, apply, interaction, effect, acknowledgement, and cleanup
    failures.

    - [ ] 7.3.1 Task - Implement root-scoped failure coordination.

      Select one deterministic outcome without allowing independent layers to
      retry or replace the same root concurrently.

      - [ ] 7.3.1.1 Subtask - Normalize failure origin/severity into stable root-scoped diagnostics and elect one recovery owner per failed transaction.
      - [ ] 7.3.1.2 Subtask - Reject atomically, retain/reconstruct the last valid generation where safe, otherwise install the bounded fallback and quarantine only the affected root.
      - [ ] 7.3.1.3 Subtask - Bound retry count, delay, queue retention, diagnostic volume, and fallback attempts; require explicit owner action after terminal failure.

    - [ ] 7.3.2 Task - Add adversarial lifecycle coverage.

      Exercise failures at every boundary and verify state, authority, focus,
      interaction, and cleanup outcomes.

      - [ ] 7.3.2.1 Subtask - Inject malformed transaction, diff failure, apply exception, rollback failure, lost acknowledgement, effect failure/timeout, event overload, runtime loss, and disposal race.
      - [ ] 7.3.2.2 Subtask - Verify last-valid/fallback DOM, no stale state advance, no duplicate effect/event, bounded diagnostics/retries/queues, and unaffected sibling roots.
      - [ ] 7.3.2.3 Subtask - Verify abandoned resources release within the governed observation window or produce a blocking leak record.

  - [ ] 7.4 Section - Phase 7 Integration Tests and Completion Evidence.

    Execute the renderer-failure acceptance scenario and repeated lifecycle
    tests across fake DOM and active browsers.

    - [ ] 7.4.1 Task - Run effect, resource, and failure integration tests.

      Drive complete semantic-output-to-DOM cycles under normal and injected
      failure conditions.

      - [ ] 7.4.1.1 Subtask - Test barrier ordering, focus/selection precedence, acknowledgement timing, effect result delivery, supersession, cancellation, timeout, and idempotent disposal.
      - [ ] 7.4.1.2 Subtask - Repeat mount/update/reorder/fail/replace/dispose/remount across multiple roots and measure listeners, queues, pending work, handles, retained nodes, and cleanup convergence.
      - [ ] 7.4.1.3 Subtask - Execute `BX-ACC-FAILURE-BX-FAIL-RENDERER` and prove atomic rejection, last-valid or bounded fallback, root isolation, diagnostics, and abandoned-resource release.

    - [ ] 7.4.2 Task - Publish Phase 7 completion evidence.

      Preserve all negative and resource observations and distinguish a bounded
      implementation gate from BH-15/BH-22 release resilience.

      - [ ] 7.4.2.1 Subtask - Run Mix/Node/Linux Chrome/Firefox suites, adversarial and repeated-lifecycle scenarios, validators, dependency/leakage audits, archive/generated checks, JSON validation, and patch hygiene.
      - [ ] 7.4.2.2 Subtask - Publish raw resource/failure traces, browser fingerprints, commands/counts, cleanup timings, retry/queue maxima, failures, and limitations.
      - [ ] 7.4.2.3 Subtask - Mark Phase 7 complete only if no active leak, stale effect, cross-root failure, or unbounded recovery remains; make Phase 8 eligible but unauthorized.

## Section delivery rule

Complete and verify each section before its commit. Open one pull request only
after Section 7.4 passes or records a stop decision. A swallowed renderer
failure, stale effect, unbounded recovery path, or owned resource surviving its
active cleanup bound blocks completion.

## Connections

- [BH-04 plan](README.md)
- [Phase 6](phase-06-form-value-focus-and-selection-continuity.md)
- [Host-neutral effects, capabilities, and resources](../../../20-notes/architecture-decisions/adr-0003-host-neutral-effects-capabilities-and-resources.md)
- [Browser trust, deployment, and fallback policy](../../../20-notes/blazex-browser-trust-deployment-and-fallback-policy.md)

## Sources

- [BH-02 event/effect/resource fixtures](../../../../../integration/conformance/event-effect-resource-fixtures-v0.1.0.json)
- [Canonical acceptance registry](../../../assets/quality-acceptance/blazex-acceptance-registry-v0.1.0.json)
