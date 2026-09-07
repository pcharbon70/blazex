---
title: "Phase 4 - Atomic DOM Application, Root Queues, and Stale Rejection"
kind: note
created: "2026-09-06"
maturity: developing
tags:
  - bh-04
  - browser
  - dom
  - implementation-planning
  - reliability
aliases:
  - "BH-04 phase 4"
---

# Phase 4 - Atomic DOM Application, Root Queues, and Stale Rejection

Back to milestone: [README](README.md)

- [ ] 4 Phase - Atomic DOM Application, Root Queues, and Stale Rejection.

  Implement the browser-side transaction applicator over BH-03 independent
  roots. Every transaction must be validated, ordered, and applied as one
  root-scoped outcome, with bounded queues and intentional behavior for stale,
  malformed, failed, or disposed traffic.

  - [ ] 4.1 Section - Authorize and freeze DOM application semantics.

    Bind the reconciler and BH-03 root lifecycle, then define atomicity and
    queue behavior before mutating live DOM.

    - [ ] 4.1.1 Task - Record bounded Phase 4 authority.

      Establish exact inputs and prohibit interaction or framework behavior.

      - [ ] 4.1.1.1 Subtask - Record synchronized base, branch, section commits, one PR, cleanup, Phase 3 completion, accepted BH-03 root lifecycle identity, and explicit Phase 4 authorization.
      - [ ] 4.1.1.2 Subtask - Bind transaction schemas, reconciliation state, root ownership, runtime loss/shutdown behavior, diagnostics, and queue/stale acceptance budgets by version and hash.
      - [ ] 4.1.1.3 Subtask - Exclude browser-event delivery, form/focus preservation beyond existing intent, effect execution, LiveView patching, product behavior, and support claims.

    - [ ] 4.1.2 Task - Freeze preflight, commit, rollback, and fallback rules.

      Define what atomic means for live DOM and what observable state remains
      after any failure point.

      - [ ] 4.1.2.1 Subtask - Require complete schema, compatibility, ownership, generation, revision, digest, operation dependency, target, and limit preflight before first mutation.
      - [ ] 4.1.2.2 Subtask - Define bounded rollback journaling or equivalent restoration, last-valid projection retention, root isolation, and explicit full-replacement/fallback escalation.
      - [ ] 4.1.2.3 Subtask - Define per-root queue capacity at no more than 64, backpressure/coalescing eligibility, no cross-root head-of-line blocking, and terminal overflow behavior.

  - [ ] 4.2 Section - Implement strict transaction preflight and root sequencing.

    Extend the browser runtime with an owner-scoped applicator that accepts
    only compatible transactions for a currently registered root.

    - [ ] 4.2.1 Task - Implement per-root transaction state and validation.

      Track accepted generation/revision and bounded pending work without
      leaking ownership across roots.

      - [ ] 4.2.1.1 Subtask - Register applicator state through BH-03 root lifecycle and retain root handle, owner identity, generation, committed revision/digest, queue, and disposal state.
      - [ ] 4.2.1.2 Subtask - Validate complete transactions and resolve all node/anchor/parent targets under the owned root before mutation.
      - [ ] 4.2.1.3 Subtask - Reject stale generation, wrong base revision, duplicate/replayed transaction, revision gaps, unknown root, disposed root, cross-root target, and overflow without DOM mutation.

    - [ ] 4.2.2 Task - Implement queue scheduling and acknowledgements.

      Ensure each root advances serially while independent roots continue when
      another root is slow or failed.

      - [ ] 4.2.2.1 Subtask - Enqueue, schedule, coalesce only policy-approved supersedable work, and enforce deterministic queue limits and fairness.
      - [ ] 4.2.2.2 Subtask - Emit correlated accepted, committed, rejected, rollback, fallback, and disposed acknowledgements exactly once.
      - [ ] 4.2.2.3 Subtask - Cancel or reject queued work deterministically on generation replacement, root disposal, runtime shutdown, or runtime loss.

  - [ ] 4.3 Section - Implement atomic incremental DOM mutation and recovery.

    Apply the closed operation set while preserving root ownership and a
    recoverable last-valid state.

    - [ ] 4.3.1 Task - Implement operation application.

      Execute dependency-safe create, update, move, remove, and replace work
      with strict target assertions.

      - [ ] 4.3.1.1 Subtask - Materialize new nodes detached, bind attributes/properties/listeners safely, and insert or move them only under validated owned parents and anchors.
      - [ ] 4.3.1.2 Subtask - Apply text, attribute, property, listener, reorder, removal, replacement, and disposal operations in canonical order while maintaining the node index.
      - [ ] 4.3.1.3 Subtask - Reject unsafe names/values, unexpected node state, duplicate materialization, missing targets, and mutation outside the owned root.

    - [ ] 4.3.2 Task - Implement rollback, root isolation, and fallback.

      Prevent partial corruption from becoming an accepted renderer state.

      - [ ] 4.3.2.1 Subtask - Capture bounded reversible state or use an equivalent commit strategy sufficient to restore the prior accepted root after any injected operation failure.
      - [ ] 4.3.2.2 Subtask - If restoration cannot be proven, quarantine only the affected root and install the declared last-valid reconstruction or bounded fallback without touching sibling roots.
      - [ ] 4.3.2.3 Subtask - Release abandoned nodes/listeners/queued data and emit stable diagnostics with no unbounded retry loop.

  - [ ] 4.4 Section - Phase 4 Integration Tests and Completion Evidence.

    Execute root-isolation, stale-rejection, queue, and failure-injection tests
    in fake DOM plus active Linux Chrome and Firefox.

    - [ ] 4.4.1 Task - Run atomic applicator and lifecycle integration tests.

      Drive real Phase 3 transactions through the BH-03 root lifecycle and
      inspect both DOM and acknowledgement outcomes.

      - [ ] 4.4.1.1 Subtask - Test initial, incremental, move, replace, dispose, remount, multi-root interleaving, queue pressure, coalescing, runtime shutdown, and root loss scenarios.
      - [ ] 4.4.1.2 Subtask - Randomize delayed prior-generation/revision messages and prove 100% rejection without DOM mutation; inject a failure at every operation boundary and prove rollback or root-scoped fallback.
      - [ ] 4.4.1.3 Subtask - Prove queue depth never exceeds 64, acknowledgements are exactly once, sibling roots progress independently, and disposed resources converge.

    - [ ] 4.4.2 Task - Publish Phase 4 completion evidence.

      Preserve raw browser and failure results with exact identities and avoid
      converting development observations into support.

      - [ ] 4.4.2.1 Subtask - Run Node/fake-DOM suites, Linux Chrome/Firefox scenarios, activated Mix suites, validators, dependency/leakage audits, archive/generated checks, JSON validation, and patch hygiene.
      - [ ] 4.4.2.2 Subtask - Publish raw stale/queue/failure traces, browser fingerprints, commands, counts, transaction hashes, cleanup observations, failures, and limitations.
      - [ ] 4.4.2.3 Subtask - Mark Phase 4 complete only if atomicity, stale rejection, queue bounds, and root isolation pass; make Phase 5 eligible but unauthorized.

## Section delivery rule

Complete and verify each section before its commit. Open one pull request only
after Section 4.4 passes or records a stop decision. Any stale mutation,
cross-root access, unbounded queue, or unrecoverable accepted partial state is
a blocking result.

## Connections

- [BH-04 plan](README.md)
- [Phase 3](phase-03-keyed-incremental-reconciliation-and-deterministic-diffing.md)
- [BH-03 plan](../bh-03-browser-execution-host-and-runtime-boot-lifecycle/README.md)
- [Browser trust, deployment, and fallback policy](../../../20-notes/blazex-browser-trust-deployment-and-fallback-policy.md)

## Sources

- [Canonical acceptance registry](../../../assets/quality-acceptance/blazex-acceptance-registry-v0.1.0.json)
- [BH-02 DOM renderer fixtures](../../../../../integration/conformance/dom-renderer-fixtures-v0.1.0.json)
