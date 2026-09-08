---
title: "Phase 1 - Authorization, BH-04 Handoff Reconciliation, and Boundary Activation"
kind: note
created: "2026-09-06"
maturity: developing
tags:
  - authorization
  - bh-05
  - component-model
  - implementation-planning
  - lifecycle
aliases:
  - "BH-05 phase 1"
---

# Phase 1 - Authorization, BH-04 Handoff Reconciliation, and Boundary Activation

Back to milestone: [README](README.md)

- [ ] 1 Phase - Authorization, BH-04 Handoff Reconciliation, and Boundary Activation.

  Establish exact BH-05 implementation authority, bind the accepted BH-04
  renderer handoff and inherited neutral contracts, activate only component
  model evidence boundaries, and prove fail-closed ownership. This phase does
  not implement a new callback, macro, state machine, or process.

  - [x] 1.1 Section - Authorize Phase 1 and reconcile milestone entry.

    Convert BH-04 acceptance into a versioned BH-05 ledger without inferring
    authority from existing experimental Core modules.

    - [x] 1.1.1 Task - Bind authority and delivery provenance.

      Record the exact base, authorizing request, immutable inputs, and
      section-by-section delivery rules.

      - [x] 1.1.1.1 Subtask - Record synchronized `main`, feature branch, planned section commits, one-PR rule, merge policy, synchronized-main return, and branch cleanup.
      - [x] 1.1.1.2 Subtask - Bind BH-04 acceptance/completion/release/entry artifacts, BH-02 kernel baseline, roadmap, accepted ADRs, acceptance registry, quality contract, and deferral policy by path and SHA-256.
      - [x] 1.1.1.3 Subtask - Limit authority to Phase 1 reconciliation, activation, validation, and evidence; prohibit Phase 2 API work and all support/public-stability claims.

    - [x] 1.1.2 Task - Publish the BH-05 entry and acceptance ledger.

      Preserve inherited conditions and assign all nine BH-05 obligations to
      phases, suites, owners, and stop rules.

      - [x] 1.1.2.1 Subtask - Import BH-04 conditions, renderer compatibility requirements, unresolved findings, private-coupling limits, deferred qualifications, and downstream restrictions unchanged.
      - [x] 1.1.2.2 Subtask - Register the roadmap outcome, six first-measurement budgets, and two failure conditions with exact evidence owners and closure phases.
      - [x] 1.1.2.3 Subtask - Record entry, stop, revise, defer, and acceptance outcomes and leave BH-06 implementation ineligible.

  - [ ] 1.2 Section - Freeze unit ownership and activate repository boundaries.

    Make public facade, core lifecycle, semantic output, effects, test harness,
    runtime consumption, and integration evidence independently auditable.

    - [ ] 1.2.1 Task - Freeze package and unit boundaries.

      Define exact ownership for pure, nested-stateful, and process-root units
      and prohibit outward implementation dependencies in the kernel.

      - [ ] 1.2.1.1 Subtask - Record `blazex_core` ownership of facade metadata, schemas, lifecycle, state, scheduling, context, registry, command intent, diagnostics, and root-process contracts.
      - [ ] 1.2.1.2 Subtask - Record `blazex_ui_tree`, `blazex_effects`, and `blazex_test` ownership and the allowed inward dependency graph among them.
      - [ ] 1.2.1.3 Subtask - Prohibit Phoenix, Plug, HEEx/HTML, DOM/JavaScript, Popcorn internals, concrete renderer/host, server authority, and native-toolkit dependencies from portable component code.

    - [ ] 1.2.2 Task - Activate BH-05 evidence locations.

      Create empty schema-bound locations for future contracts, traces,
      failures, measurements, reviews, and acceptance without claiming results.

      - [ ] 1.2.2.1 Subtask - Activate `integration/bh-05` with an empty versioned index covering facade, schemas, composition, state, roots, scheduling, effects, context, registry, failure, runtime, measurement, and review evidence.
      - [ ] 1.2.2.2 Subtask - Update package, profile, integration, and corpus indexes with truthful Phase 1 activation and no implemented BH-05 behavior.
      - [ ] 1.2.2.3 Subtask - Inventory existing BH-02 Core APIs as inherited experimental inputs and identify every surface requiring preservation, supersession, migration, or rejection.

  - [ ] 1.3 Section - Implement fail-closed activation governance.

    Reject stale handoff, ownership leakage, premature behavior, fabricated
    evidence, and ungoverned public API expansion before implementation starts.

    - [ ] 1.3.1 Task - Implement the Phase 1 activation validator.

      Validate machine-readable identities, hashes, package graph, empty
      evidence, and status rather than trusting prose labels.

      - [ ] 1.3.1.1 Subtask - Verify authorization, BH-04 handoff hashes, all nine acceptance IDs, twelve-phase plan, evidence schemas, owners, stop rules, and synchronized-base ancestry.
      - [ ] 1.3.1.2 Subtask - Audit direct/transitive dependencies and source tokens for renderer, host, server-framework, browser-object, runtime-private, .NET/Razor, and native-toolkit leakage.
      - [ ] 1.3.1.3 Subtask - Reject new callbacks/macros/processes, nonempty results, passing measurements, public stability, support claims, or Phase 2 authorization.

    - [ ] 1.3.2 Task - Add focused negative governance tests.

      Exercise every material activation failure and require actionable,
      deterministic diagnostics.

      - [ ] 1.3.2.1 Subtask - Reject missing authority, stale/missing BH-04 input, altered acceptance set, absent owner, broken plan link, forbidden dependency, or unindexed evidence path.
      - [ ] 1.3.2.2 Subtask - Reject rewritten historical evidence, hidden deferral, fabricated ERTS/AtomVM parity, arbitrary dynamic dispatch, generic unbounded emissions, or unsupported compatibility claims.
      - [ ] 1.3.2.3 Subtask - Prove the unimplemented Phase 1 candidate passes deterministically from a clean checkout.

  - [ ] 1.4 Section - Phase 1 Integration Tests and Completion Evidence.

    Execute the inherited activation gate and publish a bounded decision before
    authoring-facade design becomes eligible.

    - [ ] 1.4.1 Task - Run the active Phase 1 integration gate.

      Reproduce all inherited and activated checks with exact commands,
      versions, counts, and negative cases.

      - [ ] 1.4.1.1 Subtask - Run package-local tests/formats, BH-04 release checks, BH-05 activation validator/tests, inherited validators/generators, archive/JSON/dependency checks, and patch hygiene.
      - [ ] 1.4.1.2 Subtask - Confirm facade, schema, lifecycle, scheduling, effects, registry, runtime, failure, measurement, and acceptance result sets remain empty and later phases unauthorized.
      - [ ] 1.4.1.3 Subtask - Record environment, tools, exact commands/counts, expected negative failures, input hashes, limitations, and deferred qualifications.

    - [ ] 1.4.2 Task - Publish Phase 1 completion evidence.

      Bind the activation result to immutable inputs and make no component
      implementation claim.

      - [ ] 1.4.2.1 Subtask - Publish the validation log, implementation-evidence note, and completion decision with exact artifact hashes.
      - [ ] 1.4.2.2 Subtask - Mark Phase 1 complete only if every active gate passes and no stop condition remains open.
      - [ ] 1.4.2.3 Subtask - Make Phase 2 eligible but unauthorized and keep BH-06 ineligible.

## Section delivery rule

Complete and verify each section before its commit. Open one pull request only
after Section 1.4 passes or records a truthful stop decision. Phase 1 activates
governance and evidence only; it may not implement component behavior.

## Connections

- [BH-05 plan](README.md)
- [Browser-host milestone roadmap](../../../20-notes/browser-host-implementation-milestones.md)
- [Host-neutral component-kernel decision](../../../20-notes/architecture-decisions/adr-0001-host-neutral-semantic-component-kernel.md)
- [Development environment and deferred qualification policy](../../development-environment-and-deferred-qualification-policy.md)

## Sources

- [BH-02 internal contract baseline](../../../assets/bh-02-baseline/blazex-bh-02-contract-baseline-v0.1.0.json)
- [Canonical acceptance registry](../../../assets/quality-acceptance/blazex-acceptance-registry-v0.1.0.json)
