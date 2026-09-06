---
title: "Phase 11 - ERTS, Browser AtomVM, and Cross-Backend Conformance"
kind: note
created: "2026-09-06"
maturity: developing
tags: [bh-05, erts, atomvm, browser, conformance, implementation-planning]
aliases: ["BH-05 phase 11"]
---

# Phase 11 - ERTS, Browser AtomVM, and Cross-Backend Conformance

Back to milestone: [README](README.md)

- [ ] 11 Phase - ERTS, Browser AtomVM, and Cross-Backend Conformance.

  Prove that the supported component semantics have matching observable
  behavior on ERTS and the active browser AtomVM profile, with the headless
  oracle as arbiter and unavailable environments retained as deferrals.

  - [ ] 11.1 Section - Freeze the conformance model and fixture corpus.

    Define exactly which inputs, traces, outputs, errors, and final states must
    agree and which host timings may differ without changing semantics.

    - [ ] 11.1.1 Task - Specify canonical scenario and observation schemas.

      Represent component declarations, stimuli, expected semantic output,
      state checkpoints, effects, resources, failures, and disposal outcomes.

      - [ ] 11.1.1.1 Subtask - Version the scenario, trace, environment, and result schemas.
      - [ ] 11.1.1.2 Subtask - Define equality for ordering, identity, updates, final state, and terminal ownership.
      - [ ] 11.1.1.3 Subtask - Define tolerated host metadata/timing differences separately from semantic equivalence.

    - [ ] 11.1.2 Task - Build representative and adversarial fixtures.

      Cover every supported role and lifecycle feature in both isolated and
      composed scenarios.

      - [ ] 11.1.2.1 Subtask - Include pure, nested-stateful, local-view, props, slots, context, dynamic selection, and controlled/local state.
      - [ ] 11.1.2.2 Subtask - Include events, messages, timers, transitions, effects, resources, commands, failures, retries, replacement, and disposal.
      - [ ] 11.1.2.3 Subtask - Include boundary, maximum, stale, malformed, overload, crash, and cleanup-failure cases.

  - [ ] 11.2 Section - Implement the ERTS reference runner and headless oracle.

    Produce canonical expected behavior under the full BEAM toolchain without
    allowing implementation-specific scheduling to define the contract.

    - [ ] 11.2.1 Task - Build isolated deterministic ERTS execution.

      Run each fixture from a clean supervised context with controlled time,
      injected executors, and complete ownership accounting.

      - [ ] 11.2.1.1 Subtask - Reset registries, clocks, manifests, roots, effects, resources, and trace collectors per scenario.
      - [ ] 11.2.1.2 Subtask - Capture normalized output, ordering, identity, states, failures, timings, and terminal ledgers.
      - [ ] 11.2.1.3 Subtask - Repeat each deterministic fixture and fail on within-target drift.

    - [ ] 11.2.2 Task - Bind results to the headless oracle.

      Compare renderer-independent semantic output and component lifecycle
      observations before browser execution is considered.

      - [ ] 11.2.2.1 Subtask - Validate every ERTS trace against the canonical schema and expected invariants.
      - [ ] 11.2.2.2 Subtask - Separate semantic failures from harness, environment, or measurement failures.
      - [ ] 11.2.2.3 Subtask - Publish immutable ERTS result digests as cross-target comparison inputs.

  - [ ] 11.3 Section - Implement browser AtomVM conformance execution.

    Run the same portable fixture bundles through the BH-03 host and BH-04 DOM
    integration on active Linux Chrome and Firefox.

    - [ ] 11.3.1 Task - Assemble and launch browser fixture profiles.

      Use versioned manifests and one compatible runtime while keeping each
      scenario/root isolated and correlated.

      - [ ] 11.3.1.1 Subtask - Build fixture bundles from public entrypoints without private/runtime imports in application code.
      - [ ] 11.3.1.2 Subtask - Run through the standard loader, root lifecycle, renderer, event, and executor boundaries.
      - [ ] 11.3.1.3 Subtask - Capture canonical lifecycle traces plus browser environment and artifact identities.

    - [ ] 11.3.2 Task - Execute the active browser matrix.

      Treat Linux Chrome and Firefox as development evidence, not broad browser
      support or release qualification.

      - [ ] 11.3.2.1 Subtask - Run every automated fixture in available Chrome and Firefox configurations.
      - [ ] 11.3.2.2 Subtask - Repeat clean-context runs and detect target-local drift, stale assets, and cross-root contamination.
      - [ ] 11.3.2.3 Subtask - Mark Safari, Windows, macOS, mobile, physical-device, and unavailable browser rows `[DEFERRED]`.

  - [ ] 11.4 Section - Reconcile cross-runtime and cross-renderer outcomes.

    Compare semantics directly, classify every difference, and prevent an
    environment-specific quirk from silently becoming framework behavior.

    - [ ] 11.4.1 Task - Compare canonical result ledgers.

      Require matching ordering, identity, state, output, callback outcomes,
      ownership, and terminal state for all active targets.

      - [ ] 11.4.1.1 Subtask - Produce field-level diffs for ERTS, Chrome AtomVM, Firefox AtomVM, and headless oracle results.
      - [ ] 11.4.1.2 Subtask - Classify differences as semantic defects, adapter defects, harness defects, tolerated host metadata, or deferred qualification.
      - [ ] 11.4.1.3 Subtask - Reject unexplained, nondeterministic, or normalized-away semantic differences.

    - [ ] 11.4.2 Task - Verify public boundary and portability constraints.

      Ensure equivalent behavior was achieved through public contracts rather
      than target conditionals in application components.

      - [ ] 11.4.2.1 Subtask - Scan application fixtures for private runtime, renderer, DOM, JavaScript, Phoenix, Plug, and platform imports.
      - [ ] 11.4.2.2 Subtask - Account for target-specific code only inside declared host/renderer/executor adapters.
      - [ ] 11.4.2.3 Subtask - Record AtomVM compatibility exceptions as explicit findings for BH-06 rather than hidden branches.

  - [ ] 11.5 Section - Integration Tests and Completion Evidence.

    Run the complete cross-backend matrix from clean artifacts and publish a
    reproducible conformance decision.

    - [ ] 11.5.1 Task - Execute the milestone-wide conformance gate.

      Combine contract, archive, package, browser, trace, failure, limit, and
      dependency checks in one versioned run.

      - [ ] 11.5.1.1 Subtask - Run all Phase 1–11 validators/tests, clean builds, Chrome/Firefox scenarios, archive checks, JSON checks, and patch hygiene.
      - [ ] 11.5.1.2 Subtask - Verify every supported semantic row has matching active-target evidence or an explicit active-target failure.
      - [ ] 11.5.1.3 Subtask - Verify unavailable environment rows remain deferred and award no support credit.

    - [ ] 11.5.2 Task - Publish completion evidence.

      Preserve inputs, artifacts, traces, comparisons, findings, and the exact
      scope of the resulting claim.

      - [ ] 11.5.2.1 Subtask - Publish release-indexed fixture/result manifests, hashes, versions, commands, and cross-target diffs.
      - [ ] 11.5.2.2 Subtask - Stop on active semantic drift, public-boundary leakage, nondeterminism, or unresolved terminal ownership.
      - [ ] 11.5.2.3 Subtask - Mark Phase 12 eligible but unauthorized only after the complete gate passes.

## Section delivery rule

Complete and verify each section before its commit. Open one pull request only
after Section 11.5 passes or records a truthful stop decision.

## Connections

- [BH-05 plan](README.md)
- [Development environment and deferred qualification policy](../../development-environment-and-deferred-qualification-policy.md)
- [BH-03 browser-host plan](../bh-03-browser-execution-host-and-runtime-boot-lifecycle/README.md)
