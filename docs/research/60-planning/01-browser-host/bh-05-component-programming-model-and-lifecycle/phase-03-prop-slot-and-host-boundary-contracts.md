---
title: "Phase 3 - Prop, Slot, and Host-Boundary Contracts"
kind: note
created: "2026-09-06"
maturity: developing
tags: [bh-05, props, slots, trust-boundary, implementation-planning]
aliases: ["BH-05 phase 3"]
---

# Phase 3 - Prop, Slot, and Host-Boundary Contracts

Back to milestone: [README](README.md)

- [ ] 3 Phase - Prop, Slot, and Host-Boundary Contracts.

  Make every component input explicit, bounded, validated, and portable while
  preserving a hard distinction between public browser data and trusted server
  state.

  - [ ] 3.1 Section - Define prop schemas and deterministic validation.

    Establish a closed validation vocabulary that gives authors useful Elixir
    ergonomics without relying on runtime-specific reflection.

    - [ ] 3.1.1 Task - Specify prop declarations and value constraints.

      Define required/defaulted inputs, portable types, enums, collections,
      nested schemas, and custom validation boundaries.

      - [ ] 3.1.1.1 Subtask - Define presence, default, nullable, scalar, collection, shape, range, and size semantics.
      - [ ] 3.1.1.2 Subtask - Define deterministic default evaluation and prohibit ambient host/server reads.
      - [ ] 3.1.1.3 Subtask - Define canonical path-aware error records with redacted values.

    - [ ] 3.1.2 Task - Implement bounded prop normalization.

      Normalize accepted values once and reject malformed, oversized, cyclic,
      or host-specific inputs before component callbacks run.

      - [ ] 3.1.2.1 Subtask - Enforce depth, item-count, byte-size, key, atom, and text limits.
      - [ ] 3.1.2.2 Subtask - Preserve deterministic map/list ordering and canonical scalar representation.
      - [ ] 3.1.2.3 Subtask - Add focused property and negative tests for all schema forms.

  - [ ] 3.2 Section - Define named slots and child-content contracts.

    Treat composition as typed data with explicit cardinality and scope rather
    than unconstrained callback execution.

    - [ ] 3.2.1 Task - Specify slot declarations and invocation.

      Define default/named slots, required/optional cardinality, arguments,
      fallback behavior, and stable invocation identity.

      - [ ] 3.2.1.1 Subtask - Define zero/one/many slot cardinality and duplicate handling.
      - [ ] 3.2.1.2 Subtask - Validate slot arguments and returned semantic/component values through closed contracts.
      - [ ] 3.2.1.3 Subtask - Define lexical ownership and forbid slots from capturing private host resources.

    - [ ] 3.2.2 Task - Implement slot normalization and diagnostics.

      Produce canonical slot collections and actionable source/runtime errors.

      - [ ] 3.2.2.1 Subtask - Normalize declaration order, explicit keys, fallback content, and slot argument schemas.
      - [ ] 3.2.2.2 Subtask - Reject missing required slots, unknown names, invalid cardinality, invalid returns, and excessive expansion.
      - [ ] 3.2.2.3 Subtask - Test nested slot composition without renderer or DOM coupling.

  - [ ] 3.3 Section - Enforce serialization and trust boundaries.

    Define exactly what may cross into a local browser runtime and ensure typed
    commands cannot masquerade as trusted decisions.

    - [ ] 3.3.1 Task - Classify portable, public, opaque, and forbidden values.

      Give build tooling and runtime validation one shared host-boundary policy.

      - [ ] 3.3.1.1 Subtask - Define portable public values and versioned opaque identifiers with bounded encoding.
      - [ ] 3.3.1.2 Subtask - Exclude secrets, credentials, server sessions, authorization decisions, PIDs, ports, references, functions, and host objects.
      - [ ] 3.3.1.3 Subtask - Define redaction and diagnostics that reveal paths and types without sensitive payloads.

    - [ ] 3.3.2 Task - Implement round-trip and leakage validation.

      Ensure accepted values retain meaning across BEAM/browser encodings and
      fail closed when an unsupported representation appears.

      - [ ] 3.3.2.1 Subtask - Add deterministic encode/decode fixtures and canonical digests for every accepted value class.
      - [ ] 3.3.2.2 Subtask - Scan component metadata, defaults, props, slots, and callback results for forbidden values.
      - [ ] 3.3.2.3 Subtask - Test malicious nesting, oversized values, unknown tags, stale schema versions, and accidental secret-shaped input.

  - [ ] 3.4 Section - Integration Tests and Completion Evidence.

    Verify props, slots, serialization, and trust classification together before
    any component evaluator can execute application code.

    - [ ] 3.4.1 Task - Run boundary conformance scenarios.

      Exercise valid and invalid inputs across direct declarations, authoring
      facade metadata, and the browser-compatible codec.

      - [ ] 3.4.1.1 Subtask - Compare normalized values, slot expansions, errors, and digests across ERTS and browser-compatible paths.
      - [ ] 3.4.1.2 Subtask - Prove callbacks are not invoked after input validation failure.
      - [ ] 3.4.1.3 Subtask - Prove trusted/server-only and private host values cannot cross the boundary.

    - [ ] 3.4.2 Task - Publish completion evidence.

      Record the accepted schema envelope and unresolved compatibility limits.

      - [ ] 3.4.2.1 Subtask - Publish fixtures, command logs, test counts, digests, and negative outcomes.
      - [ ] 3.4.2.2 Subtask - Record active Linux evidence and mark unavailable environment qualification `[DEFERRED]`.
      - [ ] 3.4.2.3 Subtask - Mark Phase 4 eligible but unauthorized only after the complete gate passes.

## Section delivery rule

Complete and verify each section before its commit. Open one pull request only
after Section 3.4 passes or records a truthful stop decision.

## Connections

- [BH-05 plan](README.md)
- [Development environment and deferred qualification policy](../../development-environment-and-deferred-qualification-policy.md)
