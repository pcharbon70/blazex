---
title: "Phase 2 - Component Roles, Authoring Facade, and Callback Algebra"
kind: note
created: "2026-09-06"
maturity: developing
tags: [bh-05, component-model, authoring, callbacks, implementation-planning]
aliases: ["BH-05 phase 2"]
---

# Phase 2 - Component Roles, Authoring Facade, and Callback Algebra

Back to milestone: [README](README.md)

- [ ] 2 Phase - Component Roles, Authoring Facade, and Callback Algebra.

  Define the smallest idiomatic Elixir surface for declaring components while
  keeping evaluation explicit, deterministic, host-neutral, and inspectable.

  - [ ] 2.1 Section - Specify the three public component roles.

    Give each role a distinct responsibility and lifecycle cost so authors do
    not accidentally introduce processes or state where composition suffices.

    - [ ] 2.1.1 Task - Define pure and nested-stateful roles.

      Specify their inputs, outputs, permitted state, identity needs, and
      callback participation.

      - [ ] 2.1.1.1 Subtask - Define pure components as deterministic composition with no owned local state or resources.
      - [ ] 2.1.1.2 Subtask - Define nested stateful components as reconciled values owned by a root scheduler rather than individual processes.
      - [ ] 2.1.1.3 Subtask - Define legal promotion, replacement, and composition relationships between the roles.

    - [ ] 2.1.2 Task - Define process-root local views.

      Establish explicit process ownership for independently supervised local
      application roots without leaking process mechanics into children.

      - [ ] 2.1.2.1 Subtask - Define root creation, initial state, identity, mailbox, supervisor ownership, and terminal disposal.
      - [ ] 2.1.2.2 Subtask - Define what roots may supervise and what nested components may never own directly.
      - [ ] 2.1.2.3 Subtask - Reject implicit process-per-component semantics.

  - [ ] 2.2 Section - Design the public Elixir authoring facade.

    Provide familiar module declarations and compile-time metadata without
    exposing runtime or renderer implementation modules.

    - [ ] 2.2.1 Task - Define declarations and generated metadata.

      Specify macros or behaviours that remain analyzable by the browser build
      pipeline and usable under both ERTS and AtomVM constraints.

      - [ ] 2.2.1.1 Subtask - Define component role declarations, prop/slot declarations, callback declarations, and stable component identifiers.
      - [ ] 2.2.1.2 Subtask - Generate deterministic metadata without evaluating application callbacks at compile time.
      - [ ] 2.2.1.3 Subtask - Keep the facade optional beneath a direct behaviour-based API for tooling and testing.

    - [ ] 2.2.2 Task - Define diagnostics and compatibility rules.

      Make invalid declarations actionable and prevent host-only features from
      entering portable modules unnoticed.

      - [ ] 2.2.2.1 Subtask - Produce source-located diagnostics for duplicate declarations, invalid roles, callback conflicts, and unsupported options.
      - [ ] 2.2.2.2 Subtask - Define metadata/schema version negotiation and unknown-version rejection.
      - [ ] 2.2.2.3 Subtask - Add static checks for forbidden private, renderer, browser, and server dependencies.

  - [ ] 2.3 Section - Define callback inputs, results, and transition algebra.

    Replace hidden mutation with a closed set of explicit results that the
    lifecycle engine can validate and schedule consistently.

    - [ ] 2.3.1 Task - Specify callback families and contexts.

      Define initialization, rendering, update, event, message, effect-result,
      error, and disposal callbacks with minimal typed contexts.

      - [ ] 2.3.1.1 Subtask - Define required and optional callbacks for each component role.
      - [ ] 2.3.1.2 Subtask - Expose only public identifiers, validated input, state, context snapshots, and capability handles.
      - [ ] 2.3.1.3 Subtask - Reject host objects, renderer nodes, raw JavaScript values, PIDs, and trusted server state at portable boundaries.

    - [ ] 2.3.2 Task - Specify the closed callback-result algebra.

      Describe no-change, state transition, semantic output, effect intent,
      command intent, stop, and failure results with deterministic ordering.

      - [ ] 2.3.2.1 Subtask - Define legal result shapes and composition rules per callback family.
      - [ ] 2.3.2.2 Subtask - Define validation order, canonical normalization, and explicit rejection behavior.
      - [ ] 2.3.2.3 Subtask - Prove that results contain data and intent only, never executable host closures or private objects.

  - [ ] 2.4 Section - Integration Tests and Completion Evidence.

    Exercise declarations, metadata, callback contracts, diagnostics, and
    forbidden edges through both direct and facade-based component fixtures.

    - [ ] 2.4.1 Task - Build the authoring-contract conformance suite.

      Cover each role and callback result with positive, boundary, and negative
      fixtures that produce canonical evidence.

      - [ ] 2.4.1.1 Subtask - Compile valid pure, stateful, and local-view examples through both APIs and compare metadata.
      - [ ] 2.4.1.2 Subtask - Reject invalid declarations, results, versions, private imports, and role/callback mismatches.
      - [ ] 2.4.1.3 Subtask - Run the same contract fixtures on available ERTS and browser-compatible compilation paths.

    - [ ] 2.4.2 Task - Publish completion evidence.

      Bind the accepted public shape and all known limitations before value
      validation and evaluation are added.

      - [ ] 2.4.2.1 Subtask - Record API inventory, fixture digests, diagnostics, commands, and environment versions.
      - [ ] 2.4.2.2 Subtask - Confirm no renderer, lifecycle engine, product catalog, or support claim was introduced.
      - [ ] 2.4.2.3 Subtask - Mark Phase 3 eligible but unauthorized only after the complete gate passes.

## Section delivery rule

Complete and verify each section before its commit. Open one pull request only
after Section 2.4 passes or records a truthful stop decision.

## Connections

- [BH-05 plan](README.md)
- [BH-02 semantic-kernel plan](../bh-02-host-neutral-semantic-kernel-gate/README.md)
