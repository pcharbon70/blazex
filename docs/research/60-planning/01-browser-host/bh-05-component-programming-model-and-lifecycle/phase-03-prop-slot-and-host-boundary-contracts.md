---
title: "Phase 3 - Prop, Slot, and Host-Boundary Contracts"
kind: note
created: "2026-09-06"
maturity: developing
tags:
  - bh-05
  - component-model
  - implementation-planning
  - props
  - slots
aliases:
  - "BH-05 phase 3"
---

# Phase 3 - Prop, Slot, and Host-Boundary Contracts

Back to milestone: [README](README.md)

- [ ] 3 Phase - Prop, Slot, and Host-Boundary Contracts.

  Implement deterministic prop and slot declarations with compile-time
  metadata and runtime boundary validation. Distinguish values passed within
  one root from values crossing a host/runtime boundary, and reject invalid
  inputs before any component callback observes them.

  - [ ] 3.1 Section - Authorize and freeze schema semantics.

    Bind the Phase 2 facade and decide type, default, required, cardinality,
    compatibility, and boundary rules before implementing macros or codecs.

    - [ ] 3.1.1 Task - Record bounded Phase 3 authority.

      Establish provenance and keep component execution and scheduling outside
      the phase.

      - [ ] 3.1.1.1 Subtask - Record synchronized base, branch, section commits, one PR, cleanup, Phase 2 completion identity, and explicit Phase 3 authorization.
      - [ ] 3.1.1.2 Subtask - Bind authoring metadata, portable-value contracts, semantic identities, diagnostic redaction, and host-boundary security policy by version and hash.
      - [ ] 3.1.1.3 Subtask - Exclude nested evaluation, state retention, processes, events/effects, dynamic registry, forms, renderer changes, and support claims.

    - [ ] 3.1.2 Task - Freeze prop and slot schema vocabulary.

      Define a small closed type system and explicit extension points suitable
      for ERTS, AtomVM, deterministic metadata, and later build analysis.

      - [ ] 3.1.2.1 Subtask - Define scalar, enum, tuple, list, map/record, opaque-ID, semantic value, local-only callable, nullable, and versioned custom schema forms with depth/size limits.
      - [ ] 3.1.2.2 Subtask - Define prop names, required/default/deprecation rules, local versus host boundary, validation/normalization order, unknown-key policy, and semantic extension bags without HTML global attributes.
      - [ ] 3.1.2.3 Subtask - Define default/named slots, required/cardinality rules, slot entry attributes, contextual values, key requirements, evaluation ownership, and local/host crossing restrictions.

  - [ ] 3.2 Section - Implement prop declarations and validation.

    Generate deterministic schema metadata and validate complete prop maps
    atomically before mount or update callbacks.

    - [ ] 3.2.1 Task - Implement prop metadata and compile-time checks.

      Reject contradictory or nondeterministic declarations when the component
      module is compiled.

      - [ ] 3.2.1.1 Subtask - Implement ordered prop declarations with type, required/default, boundary, documentation, deprecation, and schema-version metadata.
      - [ ] 3.2.1.2 Subtask - Reject duplicate/reserved names, invalid defaults, required-with-default conflicts, unsupported types, nonportable host defaults, unstable custom validators, and metadata drift.
      - [ ] 3.2.1.3 Subtask - Emit stable introspection for tooling and BH-06 reachability/compatibility analysis without relying on unrestricted runtime reflection.

    - [ ] 3.2.2 Task - Implement mount/update and host-boundary validation.

      Produce one immutable normalized prop set or one redacted error before
      component code executes.

      - [ ] 3.2.2.1 Subtask - Apply required/unknown/type/shape/range/size/custom validation and defaults in canonical order with stable field-path diagnostics.
      - [ ] 3.2.2.2 Subtask - Enforce host-boundary serialization and reject functions, PIDs, ports, references, NIF resources, framework structs, hidden secret fields, and unsupported terms crossing from server/persistence/runtime inputs.
      - [ ] 3.2.2.3 Subtask - Allow declared local-only values only within one root execution boundary and reject their use on remotely mounted roots or in persisted/command/renderer data.

  - [ ] 3.3 Section - Implement slot declarations and invocation validation.

    Represent composition as explicit, keyed, caller-owned content and
    contextual data rather than arbitrary closures crossing runtime boundaries.

    - [ ] 3.3.1 Task - Implement slot metadata and compile-time checks.

      Make slot cardinality, entry attributes, contextual values, and keys
      inspectable and deterministic.

      - [ ] 3.3.1.1 Subtask - Implement default/named slot declarations with required/min/max cardinality, entry prop schemas, contextual schema, key policy, and documentation metadata.
      - [ ] 3.3.1.2 Subtask - Reject duplicate/reserved slots, invalid cardinality, nonportable host context, contradictory key rules, undeclared entry props, and unstable declaration order.
      - [ ] 3.3.1.3 Subtask - Define caller lexical ownership and prohibit mutable captured component instances, server-only closures, renderer handles, and cross-root slot content.

    - [ ] 3.3.2 Task - Implement invocation normalization.

      Validate props and complete slot entries together so callbacks never see
      a partially accepted invocation.

      - [ ] 3.3.2.1 Subtask - Normalize slot order, keys, entry props, contextual data bindings, defaults, and empty/optional behavior deterministically.
      - [ ] 3.3.2.2 Subtask - Reject missing/excess/unknown slots, duplicate keys, invalid entry props/context, wrong boundary, and content owned by another root.
      - [ ] 3.3.2.3 Subtask - Generate redacted field/slot paths and preserve the previously accepted invocation on invalid update.

  - [ ] 3.4 Section - Phase 3 Integration Tests and Completion Evidence.

    Exercise declarations and invocation validation across compile-time,
    in-root, and host-boundary fixtures without evaluating component bodies.

    - [ ] 3.4.1 Task - Run schema and boundary integration tests.

      Cover valid, invalid, edge, determinism, compatibility, and redaction
      cases through the public facade.

      - [ ] 3.4.1.1 Subtask - Test every prop/schema form, required/default/update behavior, local/host distinction, nested field paths, bounds, deprecations, and custom schema version.
      - [ ] 3.4.1.2 Subtask - Test default/named/contextual/multiple slots, entry props, stable keys/order, cardinality, caller ownership, and invalid cross-root or host-boundary content.
      - [ ] 3.4.1.3 Subtask - Compare deterministic metadata and normalized inputs under supported ERTS and AtomVM-compatible analysis, including negative secret/framework/host-object cases.

    - [ ] 3.4.2 Task - Publish Phase 3 completion evidence.

      Record the complete schema surface, boundary decisions, diagnostics, and
      unresolved ergonomic limits.

      - [ ] 3.4.2.1 Subtask - Run Core/UI-tree/test suites, compile fixtures, schema/codec tests, boundary and dependency audits, validators, archive/generated checks, JSON validation, and patch hygiene.
      - [ ] 3.4.2.2 Subtask - Publish schema inventories, normalized fixture hashes, exact commands/counts, diagnostics/redaction results, compatibility analysis, failures, and limitations.
      - [ ] 3.4.2.3 Subtask - Mark Phase 3 complete only if invalid boundary input cannot reach callbacks; make Phase 4 eligible but unauthorized.

## Section delivery rule

Complete and verify each section before its commit. Open one pull request only
after Section 3.4 passes or records a stop decision. Phase 3 defines schemas
and invocation normalization only; it does not authorize component execution.

## Connections

- [BH-05 plan](README.md)
- [Phase 2](phase-02-component-roles-authoring-facade-and-callback-algebra.md)
- [Host-neutral component-kernel decision](../../../20-notes/architecture-decisions/adr-0001-host-neutral-semantic-component-kernel.md)
- [Blazor framework semantics beneath BlazeX](../../../20-notes/blazor-framework-semantics-beneath-blazex.md)

## Sources

- [Foundational component-semantics inquiry](../../../40-inquiries/which-foundational-component-semantics-does-blazex-need.md)
- [Canonical acceptance registry](../../../assets/quality-acceptance/blazex-acceptance-registry-v0.1.0.json)
