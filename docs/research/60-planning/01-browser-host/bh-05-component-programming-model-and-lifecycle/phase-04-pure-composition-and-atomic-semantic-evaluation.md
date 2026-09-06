---
title: "Phase 4 - Pure Composition and Atomic Semantic Evaluation"
kind: note
created: "2026-09-06"
maturity: developing
tags: [bh-05, pure-components, evaluation, semantic-tree, implementation-planning]
aliases: ["BH-05 phase 4"]
---

# Phase 4 - Pure Composition and Atomic Semantic Evaluation

Back to milestone: [README](README.md)

- [ ] 4 Phase - Pure Composition and Atomic Semantic Evaluation.

  Implement deterministic pure-component expansion into validated semantic
  output and publish output atomically so partial evaluation never reaches a
  renderer.

  - [ ] 4.1 Section - Specify evaluation context and composition rules.

    Define the closed inputs, recursion model, identity path, and work limits
    for pure evaluation.

    - [ ] 4.1.1 Task - Define the pure evaluation contract.

      Establish callback ordering, child expansion, slot invocation, and the
      absence of owned mutable state, effects, resources, and processes.

      - [ ] 4.1.1.1 Subtask - Define canonical input, context snapshot, component path, and output forms.
      - [ ] 4.1.1.2 Subtask - Define deterministic depth-first expansion and source-order preservation.
      - [ ] 4.1.1.3 Subtask - Reject effects, commands, timers, messages, resources, or state transitions from pure components.

    - [ ] 4.1.2 Task - Define bounded evaluation and cycle handling.

      Ensure malformed or recursive composition cannot monopolize the root
      scheduler or produce partially committed output.

      - [ ] 4.1.2.1 Subtask - Set depth, node-count, slot-expansion, callback-step, and output-size limits.
      - [ ] 4.1.2.2 Subtask - Detect declaration and runtime composition cycles with stable paths.
      - [ ] 4.1.2.3 Subtask - Define deterministic failure precedence when multiple limits or errors occur.

  - [ ] 4.2 Section - Implement the pure evaluator and canonical output.

    Build a host-neutral evaluator over public component metadata and BH-02
    semantic nodes.

    - [ ] 4.2.1 Task - Implement validated recursive expansion.

      Resolve declared components, validate inputs, invoke callbacks, expand
      slots, and normalize semantic output without renderer knowledge.

      - [ ] 4.2.1.1 Subtask - Implement path-scoped component resolution and prop/slot validation.
      - [ ] 4.2.1.2 Subtask - Normalize fragments, empty output, keyed children, text, and semantic nodes.
      - [ ] 4.2.1.3 Subtask - Return closed success/failure records with source and component paths.

    - [ ] 4.2.2 Task - Implement deterministic evaluation traces.

      Expose testable traces without leaking sensitive values or making traces
      part of renderer behavior.

      - [ ] 4.2.2.1 Subtask - Record callback entry/exit, validation, expansion, normalization, and failure steps.
      - [ ] 4.2.2.2 Subtask - Canonicalize trace identifiers and redact disallowed payloads.
      - [ ] 4.2.2.3 Subtask - Prove equivalent inputs produce equivalent output and trace digests.

  - [ ] 4.3 Section - Implement transactional publication and failure isolation.

    Stage complete semantic output before committing it to a renderer-facing
    generation.

    - [ ] 4.3.1 Task - Add atomic evaluation generations.

      Separate working output from the last accepted generation and publish one
      complete generation only after validation.

      - [ ] 4.3.1.1 Subtask - Allocate monotonic root-scoped evaluation generations.
      - [ ] 4.3.1.2 Subtask - Commit complete normalized output and metadata as one immutable result.
      - [ ] 4.3.1.3 Subtask - Preserve the prior accepted generation after callback, validation, or limit failure.

    - [ ] 4.3.2 Task - Add deterministic failure surfaces.

      Keep application failure data neutral and ready for later containment
      policy without invoking a renderer or retry loop.

      - [ ] 4.3.2.1 Subtask - Classify validation, callback, output, cycle, and budget failures.
      - [ ] 4.3.2.2 Subtask - Normalize exceptions, throws, exits, and malformed returns into bounded failure records.
      - [ ] 4.3.2.3 Subtask - Prove failed evaluations produce no renderer batch, effects, resources, or commands.

  - [ ] 4.4 Section - Integration Tests and Completion Evidence.

    Prove deterministic pure composition and atomic publication through the
    headless oracle and available execution targets.

    - [ ] 4.4.1 Task - Execute pure-component integration scenarios.

      Cover nested composition, slots, keys, limits, failures, repeated input,
      and last-good-output preservation.

      - [ ] 4.4.1.1 Subtask - Compare semantic output and trace digests across repeated ERTS runs and browser-compatible execution.
      - [ ] 4.4.1.2 Subtask - Inject callback, cycle, malformed-output, and budget failures and verify atomic rollback.
      - [ ] 4.4.1.3 Subtask - Confirm public examples import no private runtime or renderer modules.

    - [ ] 4.4.2 Task - Publish completion evidence.

      Record the exact evaluator contract and maintain later lifecycle work as
      visibly absent.

      - [ ] 4.4.2.1 Subtask - Publish canonical fixtures, hashes, command logs, counts, and expected negative results.
      - [ ] 4.4.2.2 Subtask - Confirm no stateful reconciliation, process lifecycle, scheduling, effects, or retries were introduced.
      - [ ] 4.4.2.3 Subtask - Mark Phase 5 eligible but unauthorized only after the complete gate passes.

## Section delivery rule

Complete and verify each section before its commit. Open one pull request only
after Section 4.4 passes or records a truthful stop decision.

## Connections

- [BH-05 plan](README.md)
- [BH-02 semantic-kernel plan](../bh-02-host-neutral-semantic-kernel-gate/README.md)
