---
title: "Phase 8 - Effects, Resources, and Typed Command Intent"
kind: note
created: "2026-09-06"
maturity: developing
tags: [bh-05, effects, resources, commands, implementation-planning]
aliases: ["BH-05 phase 8"]
---

# Phase 8 - Effects, Resources, and Typed Command Intent

Back to milestone: [README](README.md)

- [ ] 8 Phase - Effects, Resources, and Typed Command Intent.

  Turn callback intent into capability-checked asynchronous effects and owned
  resources while keeping protected server authority outside the browser.

  - [ ] 8.1 Section - Define effect intent and execution contracts.

    Specify a closed, versioned effect vocabulary and the boundary between pure
    transition evaluation and host execution.

    - [ ] 8.1.1 Task - Specify effect descriptors and capabilities.

      Define effect type, portable arguments, owner, generation, correlation,
      timeout, cancellation, and expected result schema.

      - [ ] 8.1.1.1 Subtask - Permit only registered effect types declared by the active capability manifest.
      - [ ] 8.1.1.2 Subtask - Validate and bound arguments/results without carrying executable functions or host objects.
      - [ ] 8.1.1.3 Subtask - Reject unknown, unavailable, stale, malformed, or unauthorized effect intent before execution.

    - [ ] 8.1.2 Task - Specify result delivery and transition ordering.

      Return success, failure, timeout, cancellation, and host-loss results as
      ordinary scheduler stimuli.

      - [ ] 8.1.2.1 Subtask - Define correlation and at-most-one terminal result per accepted effect generation.
      - [ ] 8.1.2.2 Subtask - Define when pending effects may be superseded or cancelled.
      - [ ] 8.1.2.3 Subtask - Keep effect completion unable to bypass prop/state validation or atomic commit.

  - [ ] 8.2 Section - Implement effect scheduling and bounded concurrency.

    Bridge validated intent to injected executors while preserving root
    isolation, deterministic accounting, and explicit overload behavior.

    - [ ] 8.2.1 Task - Implement the executor boundary.

      Dispatch descriptors to host-supplied adapters and normalize all adapter
      outcomes into portable result records.

      - [ ] 8.2.1.1 Subtask - Define executor registration, version negotiation, capability lookup, and fail-closed defaults.
      - [ ] 8.2.1.2 Subtask - Isolate executor crashes, malformed results, duplicate completion, and late completion.
      - [ ] 8.2.1.3 Subtask - Trace accepted, started, completed, failed, timed-out, cancelled, and discarded outcomes.

    - [ ] 8.2.2 Task - Enforce pending-effect limits and cleanup.

      Cap pending effects at 128 per root and make overload/release behavior
      observable and deterministic.

      - [ ] 8.2.2.1 Subtask - Account pending slots from acceptance through one terminal outcome.
      - [ ] 8.2.2.2 Subtask - Reject excess effects explicitly without executing partial batches.
      - [ ] 8.2.2.3 Subtask - Cancel or drain owned effects during replacement, root stop, and runtime loss.

  - [ ] 8.3 Section - Implement resource ownership and typed commands.

    Represent longer-lived host facilities and remote operation requests as
    separate explicit contracts.

    - [ ] 8.3.1 Task - Implement generation-scoped resource ownership.

      Track acquisition, use, replacement, release, and failure without exposing
      native handles to application components.

      - [ ] 8.3.1.1 Subtask - Allocate opaque resource identities under component/root ownership and declared capability type.
      - [ ] 8.3.1.2 Subtask - Cap active resources at 512 per root with explicit acquisition rejection.
      - [ ] 8.3.1.3 Subtask - Release child-owned resources before parents and make repeated release idempotent.

    - [ ] 8.3.2 Task - Define typed remote-command intent.

      Allow a component to request a declared server operation without treating
      browser state, command construction, or local validation as authorization.

      - [ ] 8.3.2.1 Subtask - Define versioned command name, public arguments, correlation, reply schema, timeout, and cancellation intent.
      - [ ] 8.3.2.2 Subtask - Keep sessions, credentials, authorization decisions, protected data, and transport details outside the component contract.
      - [ ] 8.3.2.3 Subtask - Route command replies through ordinary effect-result scheduling while leaving BH-07 transport unimplemented.

  - [ ] 8.4 Section - Integration Tests and Completion Evidence.

    Exercise effect, resource, and command-intent lifecycle through injected
    executors without requiring Phoenix command transport.

    - [ ] 8.4.1 Task - Run effect/resource conformance scenarios.

      Cover success, failure, timeout, cancellation, overload, replacement,
      stop, host loss, malformed adapters, and stale completion.

      - [ ] 8.4.1.1 Subtask - Compare scheduler and ownership traces across ERTS and browser-compatible paths.
      - [ ] 8.4.1.2 Subtask - Exercise exactly 128 pending effects and 512 resources, then verify explicit rejection above each bound.
      - [ ] 8.4.1.3 Subtask - Prove terminal disposal leaves zero pending effects and zero owned resources.

    - [ ] 8.4.2 Task - Publish completion evidence.

      Record capability coverage, limits, cleanup outcomes, and the unimplemented
      trusted-command transport boundary.

      - [ ] 8.4.2.1 Subtask - Publish fixtures, traces, peak counts, timings, commands, and injected-failure outcomes.
      - [ ] 8.4.2.2 Subtask - Confirm no secret, server authority, raw host handle, or transport dependency enters public component code.
      - [ ] 8.4.2.3 Subtask - Mark Phase 9 eligible but unauthorized only after the complete gate passes.

## Section delivery rule

Complete and verify each section before its commit. Open one pull request only
after Section 8.4 passes or records a truthful stop decision.

## Connections

- [BH-05 plan](README.md)
- [Phase 7 — Event, Message, Timer, and Transition Scheduling](phase-07-event-message-timer-and-transition-scheduling.md)
- [Browser-host milestone roadmap](../../../20-notes/browser-host-implementation-milestones.md)
