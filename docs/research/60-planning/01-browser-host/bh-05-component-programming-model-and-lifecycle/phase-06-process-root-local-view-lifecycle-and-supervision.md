---
title: "Phase 6 - Process-Root Local-View Lifecycle and Supervision"
kind: note
created: "2026-09-06"
maturity: developing
tags: [bh-05, local-view, processes, supervision, implementation-planning]
aliases: ["BH-05 phase 6"]
---

# Phase 6 - Process-Root Local-View Lifecycle and Supervision

Back to milestone: [README](README.md)

- [ ] 6 Phase - Process-Root Local-View Lifecycle and Supervision.

  Give independently mounted local views explicit BEAM/AtomVM process roots,
  supervision, and termination semantics while nested components remain values.

  - [ ] 6.1 Section - Specify root process and supervisor contracts.

    Define the smallest portable process boundary and the host responsibilities
    required to start, observe, and stop it.

    - [ ] 6.1.1 Task - Define local-view root ownership.

      Bind one root identity to one lifecycle process, one component tree, one
      serialized queue, and one renderer registration.

      - [ ] 6.1.1.1 Subtask - Define root startup arguments, validated bootstrap state, component entrypoint, and compatibility identity.
      - [ ] 6.1.1.2 Subtask - Define owner, supervisor, monitor, renderer, and host relationships without exposing raw PIDs publicly.
      - [ ] 6.1.1.3 Subtask - Prohibit a nested component from creating an implicit root or supervisor.

    - [ ] 6.1.2 Task - Define root lifecycle states and transitions.

      Specify created, initializing, mounted, updating, stopping, disposed, and
      failed behavior with generation-scoped correlation.

      - [ ] 6.1.2.1 Subtask - Define legal transitions, idempotent requests, stale request rejection, and terminal invariants.
      - [ ] 6.1.2.2 Subtask - Define mount readiness only after initial semantic publication succeeds.
      - [ ] 6.1.2.3 Subtask - Define stop precedence over queued work and renderer/runtime loss.

  - [ ] 6.2 Section - Implement root startup, mount, update, and stop.

    Build the process-root lifecycle on shared contracts without coupling the
    core package to browser host or renderer modules.

    - [ ] 6.2.1 Task - Implement supervised root startup and readiness.

      Validate entrypoint and inputs, initialize the component tree, and publish
      correlated readiness or a bounded failure.

      - [ ] 6.2.1.1 Subtask - Allocate root identity and generation before callback execution.
      - [ ] 6.2.1.2 Subtask - Stage initial state/output and register the renderer only after complete success.
      - [ ] 6.2.1.3 Subtask - Normalize startup exceptions, exits, timeouts, and invalid results without partial activation.

    - [ ] 6.2.2 Task - Implement serialized update and terminal stop.

      Route root-owned work through one deterministic transition loop and make
      stopping reject new work immediately.

      - [ ] 6.2.2.1 Subtask - Apply validated prop/context updates as monotonic root generations.
      - [ ] 6.2.2.2 Subtask - Expose bounded status and diagnostics without component state disclosure.
      - [ ] 6.2.2.3 Subtask - Dispose descendants, release renderer registration, acknowledge stop, and terminate exactly once.

  - [ ] 6.3 Section - Implement supervision and root isolation.

    Ensure one failed root cannot corrupt sibling roots, the shared runtime, or
    another root's renderer registration.

    - [ ] 6.3.1 Task - Define and implement restart policy boundaries.

      Keep automatic restart conservative until later retry and recovery policy
      is available.

      - [ ] 6.3.1.1 Subtask - Distinguish normal stop, application failure, invariant failure, host loss, and supervisor shutdown.
      - [ ] 6.3.1.2 Subtask - Default fail closed without unbounded automatic restart or state resurrection.
      - [ ] 6.3.1.3 Subtask - Preserve failure reports and cleanup obligations across process termination.

    - [ ] 6.3.2 Task - Prove sibling and runtime isolation.

      Exercise multiple roots with independent identities, queues, component
      trees, renderer registrations, and terminal outcomes.

      - [ ] 6.3.2.1 Subtask - Mount, update, stop, and remount roots independently through one compatible runtime.
      - [ ] 6.3.2.2 Subtask - Crash one root and verify sibling state, output, and queue ordering remain unchanged.
      - [ ] 6.3.2.3 Subtask - Reject cross-root messages, updates, state handles, and disposal requests.

  - [ ] 6.4 Section - Integration Tests and Completion Evidence.

    Run process lifecycle and supervision scenarios on available ERTS and the
    browser-compatible runtime path without yet adding events or effects.

    - [ ] 6.4.1 Task - Execute root-lifecycle integration scenarios.

      Cover startup, readiness, update, sibling isolation, crash, stop, repeated
      stop, renderer loss, and remount.

      - [ ] 6.4.1.1 Subtask - Compare lifecycle/state/output traces and terminal reports across execution targets.
      - [ ] 6.4.1.2 Subtask - Verify no root, monitor, registration, or descendant survives terminal disposal.
      - [ ] 6.4.1.3 Subtask - Verify nested component counts do not produce equivalent process-count growth.

    - [ ] 6.4.2 Task - Publish completion evidence.

      Record the accepted process boundary and any runtime-specific deviation.

      - [ ] 6.4.2.1 Subtask - Publish process/resource counts, traces, commands, versions, and injected-failure results.
      - [ ] 6.4.2.2 Subtask - Mark unavailable external runtime/host qualification `[DEFERRED]` rather than passing or blocking.
      - [ ] 6.4.2.3 Subtask - Mark Phase 7 eligible but unauthorized only after the complete gate passes.

## Section delivery rule

Complete and verify each section before its commit. Open one pull request only
after Section 6.4 passes or records a truthful stop decision.

## Connections

- [BH-05 plan](README.md)
- [BH-03 browser-host plan](../bh-03-browser-execution-host-and-runtime-boot-lifecycle/README.md)
