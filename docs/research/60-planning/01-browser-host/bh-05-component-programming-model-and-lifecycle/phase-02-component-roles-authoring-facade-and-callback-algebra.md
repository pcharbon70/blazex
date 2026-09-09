---
title: "Phase 2 - Component Roles, Authoring Facade, and Callback Algebra"
kind: note
created: "2026-09-06"
maturity: developing
tags:
  - authoring
  - bh-05
  - component-model
  - elixir
  - implementation-planning
aliases:
  - "BH-05 phase 2"
---

# Phase 2 - Component Roles, Authoring Facade, and Callback Algebra

Back to milestone: [README](README.md)

- [x] 2 Phase - Component Roles, Authoring Facade, and Callback Algebra.

  Define the public-facing Elixir module shape for pure components, nested
  stateful components, and process-root local views. Freeze callback inputs,
  transition names, return forms, diagnostics, and metadata introspection
  before implementing prop/slot schemas or runtime scheduling.

  - [x] 2.1 Section - Authorize and freeze the authoring envelope.

    Bind Phase 1 and accepted kernel inputs, then state what Phoenix familiarity
    means without importing Phoenix or HEEx semantics.

    - [x] 2.1.1 Task - Record bounded Phase 2 authority.

      Establish provenance, allowed modules, and explicit exclusions.

      - [x] 2.1.1.1 Subtask - Record synchronized base, branch, section commits, one PR, cleanup, Phase 1 completion identity, and explicit Phase 2 authorization.
      - [x] 2.1.1.2 Subtask - Bind inherited Component/Evaluator/Context/Evaluation/Diagnostic contracts, semantic output versions, ADR-0001, and AtomVM compatibility conditions by hash.
      - [x] 2.1.1.3 Subtask - Exclude prop/slot validation implementation, nested state retention, process startup, event/effect execution, renderer changes, forms, and support claims.

    - [x] 2.1.2 Task - Freeze authoring principles and compatibility policy.

      Preserve idiomatic modules, pattern matching, explicit data, and familiar
      lifecycle vocabulary without copying Blazor classes or Phoenix sockets.

      - [x] 2.1.2.1 Subtask - Define documented public namespaces, `use`/behaviour responsibilities, compile metadata, reflection limits, version identities, and deprecation/change-control rules.
      - [x] 2.1.2.2 Subtask - Define Phoenix-familiar naming where semantics match and explicitly document divergences for mutable assigns, component references, arbitrary callbacks, `StateHasChanged`, DI, Razor, and render modes.
      - [x] 2.1.2.3 Subtask - Require public application code to depend only on facade contracts while keeping implementation modules private and renderer/runtime adapters replaceable.

  - [x] 2.2 Section - Define component roles and lifecycle vocabulary.

    Give each unit an honest state, scheduling, identity, failure, and ownership
    model that cannot be confused with another unit.

    - [x] 2.2.1 Task - Define pure and nested-stateful roles.

      Specify caller-owned pure evaluation and root-owned retained nested state
      without implying independent processes.

      - [x] 2.2.1.1 Subtask - Define pure component declaration, inputs, deterministic render callback, semantic output, no retained state, no mailbox, and owning-root failure behavior.
      - [x] 2.2.1.2 Subtask - Define nested-stateful declaration, initialization, prop update, local event/message transition, render, replacement, and disposal callbacks within the owning root scheduler.
      - [x] 2.2.1.3 Subtask - Define stable module/instance identity and document that nested components share process, transition, failure, effect, and renderer commit boundaries with their root.

    - [x] 2.2.2 Task - Define process-root local-view role.

      Specify the only BH-05 unit with an independent process, mailbox,
      generation, renderer root, fallback, and supervised retry boundary.

      - [x] 2.2.2.1 Subtask - Define mount, host-prop update, local event, local message/info, render, commit acknowledgement, effect result, failure, retry, replace, and terminate/dispose transitions.
      - [x] 2.2.2.2 Subtask - Define root identity, generation, revision, sequence, scheduler, mailbox, renderer ownership, effect/resource ownership, and host lifecycle correlation.
      - [x] 2.2.2.3 Subtask - Prohibit arbitrary nested render-mode switching, server process/PID transfer, mutable component instance handles, and direct renderer or browser access.

  - [x] 2.3 Section - Define and implement closed callback contracts.

    Replace generic callback values and emissions with explicit candidate
    transition results that can be validated before state is committed.

    - [x] 2.3.1 Task - Define callback arguments and immutable contexts.

      Supply only the component's declared inputs and portable transition
      metadata at each lifecycle stage.

      - [x] 2.3.1.1 Subtask - Define props, slots, prior state, semantic event/message, root/component identity, generation/revision/sequence, transition, capability summary, and context access for each callback.
      - [x] 2.3.1.2 Subtask - Define which arguments are available to pure, nested-stateful, and process-root roles and reject context fields that expose host, renderer, server, process internals, secrets, or mutable objects.
      - [x] 2.3.1.3 Subtask - Define portable diagnostic redaction so raw exceptions, props, state, messages, command payloads, and opaque resources do not leak by default.

    - [x] 2.3.2 Task - Define callback result algebra and facade metadata.

      Make candidate state, semantic output, typed actions, no-op/stop intent,
      and handled failure distinguishable and bounded.

      - [x] 2.3.2.1 Subtask - Define closed success, no-change, state/output candidate, action-emitting, stop, retry-request, and rejected result forms per callback.
      - [x] 2.3.2.2 Subtask - Reject malformed tuples, unsupported actions, nonportable boundary values, excessive action counts, direct DOM/host values, and ambiguous state/output ownership.
      - [x] 2.3.2.3 Subtask - Implement deterministic facade metadata exposing role, callback set, contract version, declared schemas/capabilities/registry entries, and public/private status for later phases and BH-06.

  - [x] 2.4 Section - Phase 2 Integration Tests and Completion Evidence.

    Prove compile-time and runtime authoring contracts without starting a root
    process or executing later lifecycle behavior.

    - [x] 2.4.1 Task - Run facade and callback-contract integration tests.

      Compile representative valid and invalid modules and inspect exact
      metadata, callbacks, warnings, and diagnostics.

      - [x] 2.4.1.1 Subtask - Test pure, nested-stateful, and local-view declarations, required callback presence, optional callbacks, role separation, metadata determinism, and documented examples.
      - [x] 2.4.1.2 Subtask - Reject conflicting roles, missing callbacks, invalid arity/result, unsupported metadata, private-module exposure, host/renderer/server imports, Blazor/Razor compatibility surfaces, and mutable references.
      - [x] 2.4.1.3 Subtask - Verify facade modules compile under the supported ERTS toolchain and their runtime subset remains compatible with the pinned AtomVM compiler/analyzer without claiming execution parity.

    - [x] 2.4.2 Task - Publish Phase 2 completion evidence.

      Record the exact candidate surface and unresolved ergonomics/runtime
      questions while retaining pre-1.0 change control.

      - [x] 2.4.2.1 Subtask - Run Core/UI-tree/effects/test package suites, facade compile fixtures, boundary audits, validators, archive/generated checks, JSON validation, and patch hygiene.
      - [x] 2.4.2.2 Subtask - Publish API/metadata inventory, valid/invalid fixture hashes, exact commands/counts, warnings/diagnostics, dependency audit, failures, and limitations.
      - [x] 2.4.2.3 Subtask - Mark Phase 2 complete only if all three roles and callback results are unambiguous and host-neutral; make Phase 3 eligible but unauthorized.

## Section delivery rule

Complete and verify each section before its commit. Open one pull request only
after Section 2.4 passes or records a stop decision. Phase 2 defines candidate
authoring contracts only; it does not authorize full lifecycle execution or
public stability.

## Connections

- [BH-05 plan](README.md)
- [Phase 1](phase-01-authorization-bh-04-handoff-reconciliation-and-boundary-activation.md)
- [Host-neutral component-kernel decision](../../../20-notes/architecture-decisions/adr-0001-host-neutral-semantic-component-kernel.md)
- [Blazor framework semantics beneath BlazeX](../../../20-notes/blazor-framework-semantics-beneath-blazex.md)

## Sources

- [BH-02 internal contract baseline](../../../assets/bh-02-baseline/blazex-bh-02-contract-baseline-v0.1.0.json)
- [Foundational component-semantics inquiry](../../../40-inquiries/which-foundational-component-semantics-does-blazex-need.md)
