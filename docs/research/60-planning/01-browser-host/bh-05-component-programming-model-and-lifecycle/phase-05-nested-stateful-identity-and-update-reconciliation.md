---
title: "Phase 5 - Nested Stateful Identity and Update Reconciliation"
kind: note
created: "2026-09-06"
maturity: developing
tags:
  - bh-05
  - component-model
  - identity
  - implementation-planning
  - state
aliases:
  - "BH-05 phase 5"
---

# Phase 5 - Nested Stateful Identity and Update Reconciliation

Back to milestone: [README](README.md)

- [x] 5 Phase - Nested Stateful Identity and Update Reconciliation.

  Implement root-owned retained state for keyed nested components. Preserve
  local state across compatible parent renders and keyed moves, apply new props
  through explicit updates, initialize inserted identities, dispose removed
  identities, and replace incompatible generations without pretending nested
  components are independently supervised processes.

  - [x] 5.1 Section - Authorize and freeze nested-state semantics.

    Bind pure composition and define controlled props, local state, identity,
    transition, and reconciliation rules before retaining component instances.

    - [x] 5.1.1 Task - Record bounded Phase 5 authority.

      Establish provenance and keep process roots, mailbox scheduling, and host
      effects outside the phase.

      - [x] 5.1.1.1 Subtask - Record synchronized base, branch, section commits, one PR, cleanup, Phase 4 completion identity, and explicit Phase 5 authorization.
      - [x] 5.1.1.2 Subtask - Bind stateful role, validated invocation, structural identity, existing evaluation/event contracts, semantic output, and disposal diagnostics by version and hash.
      - [x] 5.1.1.3 Subtask - Exclude GenServer/root startup, external messages/timers, concrete effects/commands, renderer commit, context/registry, independent subtree recovery, and support claims.

    - [x] 5.1.2 Task - Freeze controlled and local state ownership.

      Define how parent input and component-retained state interact without
      mutation, hidden two-way binding, or stale overwrite.

      - [x] 5.1.2.1 Subtask - Define normalized props as parent-controlled snapshots and local state as component-owned portable data changed only by accepted stateful transitions.
      - [x] 5.1.2.2 Subtask - Define mount, compatible prop update, local event candidate, no-change, render, remove, replace, and dispose ordering plus legal callback results.
      - [x] 5.1.2.3 Subtask - Define child-to-parent notification as typed event/message intent and prohibit mutable parent props, shared state references, arbitrary closures, and direct child-instance calls.

  - [x] 5.2 Section - Implement the root-owned nested component table.

    Store immutable accepted state and invocation data by stable nested identity
    within one owning root candidate.

    - [x] 5.2.1 Task - Implement state records and identity indexes.

      Track enough data for deterministic update/reconciliation and later
      disposal without exposing runtime process or renderer objects.

      - [x] 5.2.1.1 Subtask - Define nested record identity, component module/public ID, schema/contract version, props, slots/invocation digest, state, output digest, generation, revision, event sequence, status, and owned action references.
      - [x] 5.2.1.2 Subtask - Validate unique identity, component/role compatibility, portable state, revision monotonicity, parent/root ownership, and declared bounds.
      - [x] 5.2.1.3 Subtask - Separate accepted and candidate tables so failed callbacks/output validation cannot partially mutate retained state.

    - [x] 5.2.2 Task - Implement mount and compatible update transitions.

      Initialize new identities and update existing identities in canonical tree
      order using only validated invocation input.

      - [x] 5.2.2.1 Subtask - Invoke initialization and render for new nested identities, validate state/output/actions, and add them only to the candidate table.
      - [x] 5.2.2.2 Subtask - Invoke prop update only when the accepted contract says input changed, preserve state on no-op updates, and render the resulting candidate deterministically.
      - [x] 5.2.2.3 Subtask - Reject stale schema/contract versions, invalid state/action/output, wrong role, and callback failures with the previously accepted table intact.

  - [x] 5.3 Section - Implement keyed reconciliation, replacement, and disposal planning.

    Compare accepted and next invocation graphs to retain, move, insert,
    replace, or remove nested component state deterministically.

    - [x] 5.3.1 Task - Implement nested identity reconciliation.

      Preserve logical identity independently of child position while keeping
      identity scoped to its declared parent/root boundary.

      - [x] 5.3.1.1 Subtask - Retain accepted state for unchanged compatible keys, apply prop updates, and move keyed components without reinitialization when parent-scope rules permit.
      - [x] 5.3.1.2 Subtask - Initialize insertions, plan deepest-first removals, and replace identities when module/public ID, role, schema, parent scope, or generation becomes incompatible.
      - [x] 5.3.1.3 Subtask - Reject duplicate/unstable keys, cross-root moves, impossible ancestry, unauthorized component changes, and reconciliation overflow atomically.

    - [x] 5.3.2 Task - Implement candidate commit and disposal plans.

      Couple accepted state advancement to validated complete semantic output
      while retaining deterministic cleanup work for removed candidates.

      - [x] 5.3.2.1 Subtask - Validate composed semantic output and all nested records/actions before publishing one candidate state/output transition.
      - [x] 5.3.2.2 Subtask - Emit ordered disposal plans for removed/replaced components and ensure candidate-only resources/actions are discarded after rejection.
      - [x] 5.3.2.3 Subtask - Define final-state and trace digests for accepted, rejected, replaced, and removed nested transitions without requiring a renderer commit yet.

  - [x] 5.4 Section - Phase 5 Integration Tests and Completion Evidence.

    Exercise nested state, identity, update, reorder, failure, and removal
    through deterministic in-memory transitions and semantic validation.

    - [x] 5.4.1 Task - Run nested-state reconciliation integration tests.

      Use public application fixtures with multiple levels of pure and
      stateful children and exact expected state/output traces.

      - [x] 5.4.1.1 Subtask - Test initialize/update/no-op/local candidate, keyed reorder, insertion/removal, nested removal, module/schema replacement, parent replacement, and generation replacement.
      - [x] 5.4.1.2 Subtask - Test invalid/duplicate keys, nonportable state, callback rejection/raise, malformed action/output, cross-root identity, stale event sequence, overflow, and atomic rollback.
      - [x] 5.4.1.3 Subtask - Repeat traces to prove deterministic callback order, retained state, disposal plan, final state, semantic output, diagnostics, and digests.

    - [x] 5.4.2 Task - Publish Phase 5 completion evidence.

      Record the exact nested-state contract and explicitly document its shared
      process/failure boundary.

      - [x] 5.4.2.1 Subtask - Run Core/UI-tree/headless/test suites, nested fixtures, property/determinism tests, dependency audits, validators, archive/generated checks, JSON validation, and patch hygiene.
      - [x] 5.4.2.2 Subtask - Publish state-machine/identity inventories, fixture and trace hashes, exact commands/counts, disposal plans, negative outcomes, failures, and limitations.
      - [x] 5.4.2.3 Subtask - Mark Phase 5 complete only if retained state and output reconcile atomically by stable identity; make Phase 6 eligible but unauthorized.

## Section delivery rule

Complete and verify each section before its commit. Open one pull request only
after Section 5.4 passes or records a stop decision. Nested state remains owned
by one future root process and has no independent crash/restart guarantee.

## Connections

- [BH-05 plan](README.md)
- [Phase 4](phase-04-pure-composition-and-atomic-semantic-evaluation.md)
- [Host-neutral component-kernel decision](../../../20-notes/architecture-decisions/adr-0001-host-neutral-semantic-component-kernel.md)
- [Blazor framework semantics beneath BlazeX](../../../20-notes/blazor-framework-semantics-beneath-blazex.md)

## Sources

- [BH-02 semantic-kernel fixtures](../../../../../integration/conformance/semantic-kernel-fixtures-v0.1.0.json)
- [Foundational component-semantics inquiry](../../../40-inquiries/which-foundational-component-semantics-does-blazex-need.md)
