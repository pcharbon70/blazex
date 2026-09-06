---
title: "Phase 1 - Authorization, BH-04 Handoff Reconciliation, and Boundary Activation"
kind: note
created: "2026-09-06"
maturity: developing
tags: [bh-05, authorization, component-model, implementation-planning]
aliases: ["BH-05 phase 1"]
---

# Phase 1 - Authorization, BH-04 Handoff Reconciliation, and Boundary Activation

Back to milestone: [README](README.md)

- [ ] 1 Phase - Authorization, BH-04 Handoff Reconciliation, and Boundary Activation.

  Establish the exact authority, immutable inputs, ownership boundaries,
  vocabulary, and evidence rules for BH-05. This phase activates component-model
  work but implements no component behavior.

  - [ ] 1.1 Section - Authorize entry and reconcile the BH-04 handoff.

    Bind BH-05 to an accepted renderer/interaction baseline and preserve every
    inherited condition, finding, and deferral without silently resolving it.

    - [ ] 1.1.1 Task - Record authority and delivery provenance.

      Define the authorized scope and reproducible branch-to-PR workflow.

      - [ ] 1.1.1.1 Subtask - Record synchronized base, feature branch, section commits, one PR, merge, synchronized-main return, and branch cleanup expectations.
      - [ ] 1.1.1.2 Subtask - Bind the accepted BH-04 release index, decision, roadmap, acceptance registry, and environment policy by path and digest.
      - [ ] 1.1.1.3 Subtask - Prohibit Phase 2 behavior, stable API claims, catalog work, and support promotion.

    - [ ] 1.1.2 Task - Publish the milestone entry ledger.

      Translate the BH-04 exit state into explicit BH-05 inputs and unresolved
      obligations.

      - [ ] 1.1.2.1 Subtask - Inventory accepted renderer, interaction, focus, event, patch, and disposal contracts.
      - [ ] 1.1.2.2 Subtask - Carry forward open findings, retained failures, deferred environments, and compatibility caveats unchanged.
      - [ ] 1.1.2.3 Subtask - Map all BH-05 outputs and acceptance conditions to first-responsible phases.

  - [ ] 1.2 Section - Freeze terminology, roles, and ownership boundaries.

    Establish one vocabulary and dependency direction before public component
    behavior can emerge in competing packages.

    - [ ] 1.2.1 Task - Freeze the planned component lifecycle vocabulary.

      Name component roles, identities, generations, transitions, effects,
      resources, failures, replacement, and disposal precisely.

      - [ ] 1.2.1.1 Subtask - Distinguish pure components, nested stateful components, and process-root local views.
      - [ ] 1.2.1.2 Subtask - Distinguish props, slots, controlled state, local state, context, messages, events, effects, resources, and commands.
      - [ ] 1.2.1.3 Subtask - Define planned lifecycle states and terminal outcomes without implementation claims.

    - [ ] 1.2.2 Task - Freeze repository ownership and forbidden edges.

      Assign each contract to one package and prevent profiles or renderers from
      defining the programming model.

      - [ ] 1.2.2.1 Subtask - Assign authoring and lifecycle contracts to `blazex_core`, semantic output to `blazex_ui_tree`, effects/resources to `blazex_effects`, and shared harnesses to `blazex_test`.
      - [ ] 1.2.2.2 Subtask - Prohibit public application dependencies on private runtime, renderer, Phoenix, LiveView, DOM, JavaScript, or platform modules.
      - [ ] 1.2.2.3 Subtask - Keep host adapters as consumers of versioned neutral contracts.

  - [ ] 1.3 Section - Activate fail-closed planning and evidence boundaries.

    Create only the minimum versioned locations needed for later work and make
    premature implementation or overclaiming mechanically visible.

    - [ ] 1.3.1 Task - Activate package and integration evidence locations.

      Prepare truthful indexes and empty fixture/result boundaries.

      - [ ] 1.3.1.1 Subtask - Update package manifests with a BH-05 Phase 1 activation state that does not imply behavior.
      - [ ] 1.3.1.2 Subtask - Create an indexed `integration/bh-05` boundary with no passing scenarios or results.
      - [ ] 1.3.1.3 Subtask - Update planning and repository indexes with exact ownership and status.

    - [ ] 1.3.2 Task - Implement activation validation and negative cases.

      Reject stale inputs, forbidden dependencies, missing acceptance mappings,
      and claims that exceed the authorized phase.

      - [ ] 1.3.2.1 Subtask - Validate authority, hashes, phase count, dependency order, package ownership, and evidence emptiness.
      - [ ] 1.3.2.2 Subtask - Scan activated boundaries for renderer, host, server-authority, and private-runtime leakage.
      - [ ] 1.3.2.3 Subtask - Prove deterministic rejection of missing authority, mutated inputs, implementation artifacts, or support claims.

  - [ ] 1.4 Section - Integration Tests and Completion Evidence.

    Run the complete inherited and Phase 1 gate and publish a reproducible
    decision before any component API is authorized.

    - [ ] 1.4.1 Task - Execute the activation integration gate.

      Verify the archive, packages, planning map, validators, and negative
      fixtures as one coherent repository state.

      - [ ] 1.4.1.1 Subtask - Run active Mix/Node checks, inherited validators, archive validation, generated-file checks, JSON checks, and patch hygiene.
      - [ ] 1.4.1.2 Subtask - Confirm no component runtime behavior or passing support evidence exists.
      - [ ] 1.4.1.3 Subtask - Record commands, versions, counts, hashes, and expected negative outcomes.

    - [ ] 1.4.2 Task - Publish the Phase 1 decision.

      Close the phase only from immutable evidence and leave later work visibly
      unauthorized.

      - [ ] 1.4.2.1 Subtask - Publish a versioned validation log and implementation-evidence note.
      - [ ] 1.4.2.2 Subtask - Mark Phase 1 complete only when every active gate passes without overclaim.
      - [ ] 1.4.2.3 Subtask - Leave Phase 2 eligible but unauthorized.

## Section delivery rule

Complete and verify each section before its commit. Open one pull request only
after Section 1.4 passes or records a truthful stop decision.

## Connections

- [BH-05 plan](README.md)
- [Browser-host milestone roadmap](../../../20-notes/browser-host-implementation-milestones.md)
- [Development environment and deferred qualification policy](../../development-environment-and-deferred-qualification-policy.md)
