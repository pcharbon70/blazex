---
title: "Phase 10 - Failure Containment, Retry, Replacement, and Disposal"
kind: note
created: "2026-09-06"
maturity: developing
tags: [bh-05, failures, retry, disposal, implementation-planning]
aliases: ["BH-05 phase 10"]
---

# Phase 10 - Failure Containment, Retry, Replacement, and Disposal

Back to milestone: [README](README.md)

- [ ] 10 Phase - Failure Containment, Retry, Replacement, and Disposal.

  Contain application failures at declared boundaries, prevent retry storms,
  replace failed subtrees safely, and make terminal cleanup deterministic even
  when cleanup itself fails.

  - [ ] 10.1 Section - Define failure classification and containment policy.

    Turn every callback, scheduler, effect, resource, renderer, and invariant
    failure into a bounded record with an explicit containment scope.

    - [ ] 10.1.1 Task - Specify failure records and disclosure rules.

      Preserve actionable provenance while excluding secrets, oversized values,
      host objects, and unstable exception formatting.

      - [ ] 10.1.1.1 Subtask - Define class, phase, root/component identity, generation, source path, correlation, retryability, and cause fields.
      - [ ] 10.1.1.2 Subtask - Normalize exceptions, exits, throws, timeouts, invalid results, executor faults, and invariant violations.
      - [ ] 10.1.1.3 Subtask - Bound stack/context capture and redact component props, state, messages, and command data by policy.

    - [ ] 10.1.2 Task - Specify containment boundaries and fallback outcomes.

      Decide whether a failure preserves last-good output, replaces a subtree,
      stops a root, or escalates host/runtime loss.

      - [ ] 10.1.2.1 Subtask - Define component-local, subtree, root, renderer, and runtime failure scopes.
      - [ ] 10.1.2.2 Subtask - Define optional declared error boundaries as ordinary components with restricted failure input.
      - [ ] 10.1.2.3 Subtask - Prohibit one failed root from disposing siblings or the shared compatible runtime.

  - [ ] 10.2 Section - Implement bounded retry and replacement.

    Make recovery an explicit policy decision with deterministic budgets rather
    than implicit supervisor or callback loops.

    - [ ] 10.2.1 Task - Implement retry accounting and scheduling.

      Cap root/component recovery at three attempts in any rolling five-second
      window and preserve the failure chain across attempts.

      - [ ] 10.2.1.1 Subtask - Define retry keys, monotonic timing, attempt counting, backoff, cancellation, and success reset.
      - [ ] 10.2.1.2 Subtask - Route authorized retries through the root scheduler without overtaking accepted earlier work.
      - [ ] 10.2.1.3 Subtask - Stop or surface fallback deterministically when the three-per-five-second budget is exhausted.

    - [ ] 10.2.2 Task - Implement failed-subtree replacement.

      Dispose the failed generation completely before a fresh instance can own
      identity, state, effects, resources, or renderer output.

      - [ ] 10.2.2.1 Subtask - Preserve last-good output or publish declared error output according to boundary policy.
      - [ ] 10.2.2.2 Subtask - Allocate a fresh generation and prohibit failed local state/resource inheritance.
      - [ ] 10.2.2.3 Subtask - Correlate replacement success/failure with the original failure and retry ledger.

  - [ ] 10.3 Section - Implement deterministic disposal under failure.

    Guarantee bounded child-first cleanup and a terminal report even when
    callbacks, cancellation, release, or renderer disposal fail.

    - [ ] 10.3.1 Task - Define and implement the disposal ledger.

      Snapshot all owned children, timers, effects, resources, and registrations
      before cleanup begins and terminally account for each one.

      - [ ] 10.3.1.1 Subtask - Execute child-first component cleanup followed by timers, effects, resources, renderer registration, and root teardown.
      - [ ] 10.3.1.2 Subtask - Continue independent cleanup after individual failures while preventing duplicate successful release.
      - [ ] 10.3.1.3 Subtask - Emit one bounded aggregate report containing every failed and unresolved cleanup item.

    - [ ] 10.3.2 Task - Enforce cleanup deadlines and terminal invariants.

      Target a cleanup p95 no greater than 1000 ms in active measurement while
      making timeout behavior explicit and leak detection mandatory.

      - [ ] 10.3.2.1 Subtask - Define per-item and aggregate deadlines, cancellation escalation, and forced-detach policy.
      - [ ] 10.3.2.2 Subtask - Ensure disposed identities reject all late events, messages, timers, effects, replies, and renderer acknowledgements.
      - [ ] 10.3.2.3 Subtask - Verify final ledgers expose zero live owned items or explicit unresolved leak findings.

  - [ ] 10.4 Section - Integration Tests and Completion Evidence.

    Exercise declared component-failure and resource-cleanup-failure scenarios,
    retry exhaustion, replacement, sibling isolation, and terminal disposal.

    - [ ] 10.4.1 Task - Run failure and recovery integration scenarios.

      Inject failure at every lifecycle stage and compare containment, retry,
      output, ownership, and terminal traces.

      - [ ] 10.4.1.1 Subtask - Execute the component-failure acceptance scenario from callback failure through bounded replacement or root stop.
      - [ ] 10.4.1.2 Subtask - Execute the resource-cleanup-failure acceptance scenario and verify aggregate reporting plus continued cleanup.
      - [ ] 10.4.1.3 Subtask - Drive four attempts inside five seconds and verify the fourth recovery is rejected without a restart storm.

    - [ ] 10.4.2 Task - Publish completion evidence.

      Record exact recovery and cleanup outcomes before cross-runtime
      conformance can award equivalence credit.

      - [ ] 10.4.2.1 Subtask - Publish traces, retry windows, cleanup timings, final ledgers, commands, digests, and injected failures.
      - [ ] 10.4.2.2 Subtask - Record any unresolved leak or non-determinism as a blocking finding for active targets.
      - [ ] 10.4.2.3 Subtask - Mark Phase 11 eligible but unauthorized only after the complete gate passes.

## Section delivery rule

Complete and verify each section before its commit. Open one pull request only
after Section 10.4 passes or records a truthful stop decision.

## Connections

- [BH-05 plan](README.md)
- [Phase 8 — Effects, Resources, and Typed Command Intent](phase-08-effects-resources-and-typed-command-intent.md)
