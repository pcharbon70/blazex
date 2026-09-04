---
title: "Phase 5 - Local Browser Behavior and DOM Vertical Slice"
kind: note
created: "2026-09-03"
maturity: developing
tags:
  - bh-01
  - browser
  - implementation-planning
  - runtime-semantics
aliases:
  - "BH-01 phase 5"
---

# Phase 5 - Local Browser Behavior and DOM Vertical Slice

Back to milestone: [README](README.md)

- [ ] 5 Phase - Local Browser Behavior and DOM Vertical Slice.

  Exercise disposable local state, nested identity, form input, timers/messages,
  DOM updates, accessibility observations, and cleanup through the real browser
  runtime without stabilizing BH-02 component or renderer contracts.

  - [x] 5.1 Section - Define fixture-only behavior and observation protocols.

    Create deterministic test contracts that are rich enough to reveal runtime
    feasibility while visibly replaceable by BH-02.

    - [x] 5.1.1 Task - Define scenario, command, event, and trace records.

      Every behavior needs stable identity and observable results without
      exposing DOM or JavaScript objects to fixture runtime code.

      - [x] 5.1.1.1 Subtask - Define test-only scenario, command, event, state-snapshot, generation, node/test identity, error, and disposal records under `integration/fixtures`.
      - [x] 5.1.1.2 Subtask - Map each scenario to proof, risk, budget, acceptance, package owner, expected evidence, positive/negative cases, and cleanup expectations.
      - [x] 5.1.1.3 Subtask - Mark schemas and names experimental/non-public and add tests that reject imports from production/profile packages.

    - [x] 5.1.2 Task - Implement deterministic observation normalization.

      Cross-run traces should remove irrelevant timing noise without masking
      order, identity, state, failure, or cleanup differences.

      - [x] 5.1.2.1 Subtask - Capture runtime messages, fixture transitions, bridge operations, DOM/accessibility observations, errors, resource counts, and owned generations.
      - [x] 5.1.2.2 Subtask - Define reviewed normalization for timestamps/opaque process IDs while preserving sequence, causality, state values, semantic identity, failures, and unexplained output.

  - [x] 5.2 Section - Implement bounded DOM fixture operations.

    Build only the closed operation set needed by BH-01 and keep all concrete
    document mutation and listener ownership in `blazex_renderer_dom`.

    - [x] 5.2.1 Task - Define the allowlisted DOM operation boundary.

      The feasibility adapter must not become a generic arbitrary-tag or script
      escape interface.

      - [x] 5.2.1.1 Subtask - Define fixture root, text/state/property, field, relationship, event-listener, focus-observation, and removal operations using opaque fixture IDs.
      - [x] 5.2.1.2 Subtask - Reject arbitrary HTML/script, CSS selector/style injection, JavaScript object/function, undeclared attribute/property/event, global mutation, and code execution.
      - [x] 5.2.1.3 Subtask - Version the operation protocol and handle mismatch, unknown operation, stale generation, malformed/oversized payload, duplicate listener, missing target, and post-disposal traffic.

    - [x] 5.2.2 Task - Implement renderer ownership and event normalization.

      Browser events should become bounded values before runtime delivery and
      all listeners/roots need explicit generations and cleanup owners.

      - [x] 5.2.2.1 Subtask - Implement document creation/mutation/listener ownership in the DOM package and browser scheduling/lifecycle ownership in the browser-host package.
      - [x] 5.2.2.2 Subtask - Normalize allowed input/change/blur/focus/action events to versioned scalar/structured payloads with size, sequence, target, and generation checks.
      - [x] 5.2.2.3 Subtask - Trace every operation/event and assert no undeclared mutation, listener, global, network request, or server round trip.

  - [x] 5.3 Section - Prove local and nested state identity.

    Nested behavior must preserve deterministic ownership and failure isolation
    across updates, reordering, removal, and restart.

    - [x] 5.3.1 Task - Implement disposable parent and child fixtures.

      The fixture needs enough composition to test identity without creating a
      public component lifecycle.

      - [x] 5.3.1.1 Subtask - Implement a parent with independent keyed children, local counters/state, parent inputs, child outputs, explicit generations, and deterministic initial/update traces.
      - [x] 5.3.1.2 Subtask - Keep process ownership, fixture data, and DOM IDs internal to the scenario harness and prohibit public module/API reuse.

    - [x] 5.3.2 Task - Exercise nested identity and isolation transitions.

      Correctness needs insertion, movement, independent updates, failures, and
      disposal—not merely rendering the initial tree.

      - [x] 5.3.2.1 Subtask - Test child insertion, keyed reorder, parent update, independent child update, removal, replacement, and full subtree teardown.
      - [x] 5.3.2.2 Subtask - Test duplicate/missing identity, parent crash, child crash, retry, late child output, stale generation, and partial DOM failure.
      - [x] 5.3.2.3 Subtask - Record process/message ownership, ordering assumptions, mailbox growth, restart behavior, orphan detection, retained identity, and `BX-BH01-PROOF-NESTED-STATE` observations.

  - [ ] 5.4 Section - Prove form input and validation behavior.

    One representative field must normalize browser input, update local state,
    expose validation and accessible relationships, and retain future server
    authority boundaries.

    - [ ] 5.4.1 Task - Implement the representative field scenario.

      The field is a feasibility fixture, not a BlazeX forms API.

      - [ ] 5.4.1.1 Subtask - Implement label/help/error relationships, normalized input/change/blur, local value state, deterministic validation, disabled/read-only state, and disposal.
      - [ ] 5.4.1.2 Subtask - Keep browser element/event objects out of runtime fixture state and keep Phoenix changesets/server validation outside the local field contract.

    - [ ] 5.4.2 Task - Exercise input, validation, and focus edge cases.

      Rapid and invalid transitions should preserve identity, bounded messages,
      and accessible observable state.

      - [ ] 5.4.2.1 Subtask - Test valid, invalid, empty, rapid, repeated, composition-like, disabled, read-only, and programmatic-reset input sequences.
      - [ ] 5.4.2.2 Subtask - Test focus/blur ordering, stale validation, disposal during input, remount, malformed event, oversized value, and generation replacement.
      - [ ] 5.4.2.3 Subtask - Correlate normalized events, runtime state, DOM value/state, label/help/error observations, diagnostics, and `BX-BH01-PROOF-FORM-EVENT` evidence.

  - [ ] 5.5 Section - Prove timers, messages, DOM updates, and preliminary resources.

    Validate asynchronous transitions and document effects together while
    collecting the first interaction/resource observations.

    - [ ] 5.5.1 Task - Exercise timer and process-message behavior.

      Async work must reject stale results and clean up across crash, retry, and
      disposal.

      - [ ] 5.5.1.1 Subtask - Implement one-shot/repeated timers and representative messages that update fixture state and visible output.
      - [ ] 5.5.1.2 Subtask - Test ordering, cancellation, timeout, rapid ticks, duplicate/late messages, stale generation, crash/restart, disposal, and pending-work bounds.
      - [ ] 5.5.1.3 Subtask - Correlate runtime scheduling, bridge traffic, DOM effect, resource counts, cleanup, and `BX-BH01-PROOF-TIMER-MESSAGE` evidence.

    - [ ] 5.5.2 Task - Verify renderer-owned DOM updates.

      A state transition must yield exactly the expected observable change
      through the isolated DOM adapter.

      - [ ] 5.5.2.1 Subtask - Correlate fixture transition, normalized operation, DOM text/state/relationship change, and next-paint observation by generation.
      - [ ] 5.5.2.2 Subtask - Test no-op, burst, detached target, duplicate event, stale update, adapter error, runtime error, retry, and disposal cases.
      - [ ] 5.5.2.3 Subtask - Record preliminary event-receipt, runtime-transition, bridge, DOM-update, and paint timings as observations without passing budgets.

    - [ ] 5.5.3 Task - Establish preliminary resource and accessibility observations.

      Later stress and matrix phases need baseline instrumentation and expected
      accessible output from the local slice.

      - [ ] 5.5.3.1 Subtask - Instrument processes, mailboxes, timers, pending messages/requests, Wasm memory/pages, listeners, workers, owned roots, and cleanup time per scenario generation.
      - [ ] 5.5.3.2 Subtask - Record accessible names, roles/states/relationships, focus order/visibility, validation announcement observations, keyboard operation, and intentional limitations without claiming compliance.

  - [ ] 5.6 Section - Phase 5 Integration Tests and Completion Evidence.

    Run the full local vertical slice through real runtime/browser/DOM
    boundaries and audit fixture leakage before server integration begins.

    - [ ] 5.6.1 Task - Execute complete local behavior scenarios.

      Integration combines boot, state, nesting, forms, async work, DOM output,
      failures, accessibility observations, and disposal.

      - [ ] 5.6.1.1 Subtask - Run boot-to-ready, state/nesting, field/validation, timer/message, DOM update, error, retry, and teardown scenarios repeatedly and compare normalized traces.
      - [ ] 5.6.1.2 Subtask - Run malformed/oversized/stale/rapid/missing-target/crash/disposal-race cases and verify bounded fail-closed outcomes and resource convergence.
      - [ ] 5.6.1.3 Subtask - Evaluate nested-state, form-event, timer-message, and DOM-update proofs provisionally; stop if behavior requires browser objects in runtime code or BH-00 redefinition.

    - [ ] 5.6.2 Task - Audit abstraction leakage and publish phase evidence.

      Passing fixtures are evidence about feasibility, not accepted framework
      design.

      - [ ] 5.6.2.1 Subtask - Scan dependencies, modules, schemas, operations, and docs for accidental semantic-tree, component, capability/effect, LiveView, Phoenix, or stable renderer commitments.
      - [ ] 5.6.2.2 Subtask - Publish Phase 5 evidence with revisions, commands, scenario/trace hashes, observations, proof outcomes, limitations, resource/accessibility findings, stop/go decision, and replaceable fixture inventory.

## Section delivery rule

Complete and verify each coherent section before committing it. Open one PR for
this phase only after the final integration section passes or records a
truthful stop decision. Do not promote fixture protocols or DOM operations into
public BlazeX contracts.

## Connections

- [BH-01 plan](README.md)
- [Phase 4](phase-04-browser-host-loader-lifecycle-and-deployment.md)
- [Host-neutral kernel decision](../../../20-notes/architecture-decisions/adr-0001-host-neutral-semantic-component-kernel.md)

## Sources

- [Acceptance registry](../../../assets/quality-acceptance/blazex-acceptance-registry-v0.1.0.json)
