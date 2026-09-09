---
title: "Phase 4 - Pure Composition and Atomic Semantic Evaluation"
kind: note
created: "2026-09-06"
maturity: developing
tags:
  - bh-05
  - component-model
  - composition
  - implementation-planning
  - semantic-ui
aliases:
  - "BH-05 phase 4"
---

# Phase 4 - Pure Composition and Atomic Semantic Evaluation

Back to milestone: [README](README.md)

- [x] 4 Phase - Pure Composition and Atomic Semantic Evaluation.

  Implement deterministic nested pure-component composition over validated
  props and slots. Derive stable structural identity, evaluate children in a
  canonical order, and accept one complete semantic output atomically without
  retaining state, invoking host effects, or accessing a renderer.

  - [x] 4.1 Section - Authorize and freeze pure composition semantics.

    Bind schema and semantic-tree inputs and define invocation, identity,
    recursion, error, and output-acceptance rules before execution.

    - [x] 4.1.1 Task - Record bounded Phase 4 authority.

      Establish exact provenance and keep retained state and process lifecycle
      outside the phase.

      - [x] 4.1.1.1 Subtask - Record synchronized base, branch, section commits, one PR, cleanup, Phase 3 completion identity, and explicit Phase 4 authorization.
      - [x] 4.1.1.2 Subtask - Bind pure role, prop/slot schemas, structural identity, semantic tree/document/intent-set validation, limits, and diagnostics by version and hash.
      - [x] 4.1.1.3 Subtask - Exclude nested retained state, local-view processes, events/messages/effects, dynamic registry, renderer execution, HEEx/DOM output, and support claims.

    - [x] 4.1.2 Task - Freeze composition and atomicity rules.

      Define how call sites, explicit keys, slot entries, contextual values,
      and child results form one deterministic semantic tree.

      - [x] 4.1.2.1 Subtask - Define child identity from root, parent path, component public identity, call-site identity, explicit sibling key, slot name, and generation without runtime-assigned randomness.
      - [x] 4.1.2.2 Subtask - Define canonical parent/slot/child evaluation order, duplicate identity rejection, recursion/depth/node/invocation bounds, and cycle diagnostics.
      - [x] 4.1.2.3 Subtask - Define candidate-output validation and require all-or-nothing acceptance so a failed descendant leaves no partial semantic output or state.

  - [x] 4.2 Section - Implement pure component invocation and composition.

    Extend the evaluator from one opaque component output to an explicit tree
    of validated pure invocations and semantic nodes.

    - [x] 4.2.1 Task - Implement invocation planning and identity derivation.

      Normalize the full invocation graph before executing child callbacks.

      - [x] 4.2.1.1 Subtask - Build immutable invocation records from public facade calls with normalized props, slots, call-site/key identity, parent ownership, and declared output contract.
      - [x] 4.2.1.2 Subtask - Validate role, schema version, identity uniqueness, ownership, recursion, graph bounds, and prohibited local/host crossings before callback invocation.
      - [x] 4.2.1.3 Subtask - Produce deterministic traversal and diagnostic paths independent of map order, scheduler timing, module load order, or renderer behavior.

    - [x] 4.2.2 Task - Implement pure evaluation and slot expansion.

      Evaluate pure callbacks and caller-owned contextual slots into semantic
      output without ambient mutation or side effects.

      - [x] 4.2.2.1 Subtask - Invoke pure render callbacks with normalized props/slots/context and reject attempts to retain state, emit effects/commands, send messages, or access process/host/renderer handles.
      - [x] 4.2.2.2 Subtask - Expand default/named/contextual slots in caller scope with stable entry keys and semantic ancestry while preserving component diagnostic ownership.
      - [x] 4.2.2.3 Subtask - Memoize or skip nothing by implicit policy; any later optimization must preserve exact callbacks, diagnostics, output, and ordering or be separately governed.

  - [x] 4.3 Section - Implement atomic semantic output acceptance.

    Validate the composed tree, bindings, layout, accessibility, focus,
    selection, effects references, and root identity before returning success.

    - [x] 4.3.1 Task - Compose and validate complete semantic output.

      Merge child outputs through UI-tree-owned constructors rather than direct
      struct manipulation in application code.

      - [x] 4.3.1.1 Subtask - Compose semantic nodes/documents/intent sets while preserving derived identity, binding ownership, relationship targets, child order, and declared capabilities.
      - [x] 4.3.1.2 Subtask - Validate the entire output for identity, bounds, semantics, accessibility relationships, focus/selection targets, and opaque resource references before acceptance.
      - [x] 4.3.1.3 Subtask - Return one accepted output or one redacted deterministic diagnostic and discard every candidate-only invocation/output record on failure.

    - [x] 4.3.2 Task - Add deterministic pure-composition traces.

      Record enough public observations to compare runtimes and backends later
      without exposing private evaluator internals.

      - [x] 4.3.2.1 Subtask - Emit normalized invocation-enter/exit, slot expansion, semantic-node acceptance, callback rejection/failure, and final-output digest trace events.
      - [x] 4.3.2.2 Subtask - Exclude wall-clock/process IDs, stack traces, raw props/state, module-private names, and host/renderer data from canonical traces.
      - [x] 4.3.2.3 Subtask - Ensure identical validated inputs produce identical output and trace digests across repeated ERTS executions.

  - [x] 4.4 Section - Phase 4 Integration Tests and Completion Evidence.

    Exercise representative and adversarial pure trees through the public
    facade and compare accepted output with the headless semantic oracle.

    - [x] 4.4.1 Task - Run pure-composition integration tests.

      Cover nested props/slots, keys, semantic intent, failures, limits, and
      deterministic replay.

      - [x] 4.4.1.1 Subtask - Test nested pure layout/action/field/selection/list/surface composition, default/named/contextual slots, explicit keys, repeated calls, and complete semantic intent.
      - [x] 4.4.1.2 Subtask - Test missing/invalid props/slots, duplicate keys, recursive cycles, depth/node/invocation overflow, wrong root/relationship, callback exception/rejection, and prohibited emissions.
      - [x] 4.4.1.3 Subtask - Replay all fixtures repeatedly and compare output/trace digests plus headless normalized semantics with no private package imports in application code.

    - [x] 4.4.2 Task - Publish Phase 4 completion evidence.

      Record the pure composition contract, fixture coverage, determinism, and
      all unresolved stateful/runtime questions.

      - [x] 4.4.2.1 Subtask - Run Core/UI-tree/headless/test suites, composition fixtures, boundary audits, validators, archive/generated checks, JSON validation, and patch hygiene.
      - [x] 4.4.2.2 Subtask - Publish public example sources, normalized output/trace hashes, commands/counts, negative diagnostics, dependency audit, failures, and limitations.
      - [x] 4.4.2.3 Subtask - Mark Phase 4 complete only if complete pure trees accept atomically and deterministically; make Phase 5 eligible but unauthorized.

## Section delivery rule

Complete and verify each section before its commit. Open one pull request only
after Section 4.4 passes or records a stop decision. Pure composition may not
retain state, emit work, access a host/renderer, or claim independent failure
isolation.

## Connections

- [BH-05 plan](README.md)
- [Phase 3](phase-03-prop-slot-and-host-boundary-contracts.md)
- [Versioned semantic UI tree](../../../20-notes/architecture-decisions/adr-0002-versioned-semantic-ui-tree.md)
- [Host-neutral component-kernel decision](../../../20-notes/architecture-decisions/adr-0001-host-neutral-semantic-component-kernel.md)

## Sources

- [BH-02 semantic-kernel fixtures](../../../../../integration/conformance/semantic-kernel-fixtures-v0.1.0.json)
- [BH-02 headless fixtures](../../../../../integration/conformance/renderer-headless-fixtures-v0.1.0.json)
