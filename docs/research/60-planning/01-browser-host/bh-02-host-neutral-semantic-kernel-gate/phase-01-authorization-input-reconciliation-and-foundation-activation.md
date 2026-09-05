---
title: "Phase 1 - Authorization, Input Reconciliation, and Foundation Activation"
kind: note
created: "2026-09-05"
maturity: developing
tags:
  - bh-02
  - host-neutral
  - implementation-planning
  - repository-structure
aliases:
  - "BH-02 phase 1"
---

# Phase 1 - Authorization, Input Reconciliation, and Foundation Activation

Back to milestone: [README](README.md)

- [x] 1 Phase - Authorization, Input Reconciliation, and Foundation Activation.

  Convert the conditional BH-02 handoff into an auditable start, activate only
  the host-neutral foundation needed by later contract work, and prove that
  browser, server, runtime, and native implementation objects cannot enter it.

  - [x] 1.1 Section - Record authority and reconcile the governing inputs.

    Start from explicit owner authorization and the exact completed BH-01
    handoff while preserving prior evidence as immutable history.

    - [x] 1.1.1 Task - Record bounded Phase 1 authorization.

      - [x] 1.1.1.1 Subtask - Record the owner request, date, synchronized base revision, feature branch, phase scope, section-commit rule, single-PR rule, and final branch-cleanup instruction.
      - [x] 1.1.1.2 Subtask - State that Phases 2–8, stable APIs, support, product components, dependency upgrades, and production claims remain unauthorized.

    - [x] 1.1.2 Task - Reconcile the BH-01 entry package and architecture.

      - [x] 1.1.2.1 Subtask - Bind the immutable BH-01 feasibility baseline, conditional BH-02 entry manifest, milestone roadmap, and development-environment policy by path and SHA-256.
      - [x] 1.1.2.2 Subtask - Import all nine required outputs, nine inherited conditions, repository boundaries, forbidden leakage, limitations, and repeat obligations into the BH-02 entry ledger without rewriting their evidence state.
      - [x] 1.1.2.3 Subtask - Reconcile the native proof with the direct Win32/AppKit/GTK decision and exclude Qt/wxWidgets from active or transitive use.

  - [x] 1.2 Section - Activate the host-neutral project boundaries.

    Initialize only the packages and profile required for later portable
    contracts, with experimental module roots and explicit inward dependency
    direction.

    - [x] 1.2.1 Task - Activate the contract-owning packages.

      - [x] 1.2.1.1 Subtask - Initialize independent Mix projects for `blazex_core`, `blazex_effects`, `blazex_ui_tree`, and `blazex_renderer` with ownership metadata and boundary tests.
      - [x] 1.2.1.2 Subtask - Give each project only its architecture-approved inward path dependencies and no external dependency or lockfile.
      - [x] 1.2.1.3 Subtask - Mark all module roots experimental and prohibit semantic implementation before its later authorized phase.

    - [x] 1.2.2 Task - Activate the oracle, test support, and headless composition.

      - [x] 1.2.2.1 Subtask - Initialize `blazex_renderer_headless` and `blazex_test` as independent Mix projects with inward-only development dependencies.
      - [x] 1.2.2.2 Subtask - Initialize `profiles/headless` as an executable test composition without browser, server, runtime-adapter, or native dependencies.
      - [x] 1.2.2.3 Subtask - Compile and test every activated project independently without claiming renderer or component behavior.

  - [x] 1.3 Section - Establish repository and evidence governance.

    Make the approved activation boundary machine-checkable before semantic
    implementation begins.

    - [x] 1.3.1 Task - Activate conformance and native-spike evidence locations.

      - [x] 1.3.1.1 Subtask - Add versioned indexes for shared semantic fixtures, renderer traces, and backend outcomes under `integration/conformance`.
      - [x] 1.3.1.2 Subtask - Define the bounded direct Win32/AppKit/GTK experiment inventory and `[DEFERRED]` unavailable-target states without implementing controls.

    - [x] 1.3.2 Task - Add fail-closed validation.

      - [x] 1.3.2.1 Subtask - Validate authorization, inherited hashes, exact project inventory, ownership metadata, allowed path dependencies, and absence of external locks.
      - [x] 1.3.2.2 Subtask - Scan portable manifests and sources for forbidden browser, server, runtime, DOM, JavaScript, Qt, wxWidgets, and platform-object leakage.
      - [x] 1.3.2.3 Subtask - Add negative tests for unauthorized branches, stale inputs, extra projects, forbidden dependencies/tokens, and false implementation/support claims.

  - [x] 1.4 Section - Run the Phase 1 integration gate and publish evidence.

    Demonstrate that authorization, activation, and enforcement work together
    before any semantic contract is implemented.

    - [x] 1.4.1 Task - Execute the complete Phase 1 gate.

      - [x] 1.4.1.1 Subtask - Run all package/profile tests, formatting checks, BH-02 validator tests, archive validation, relevant inherited validators, and patch hygiene checks.
      - [x] 1.4.1.2 Subtask - Confirm no external dependency, lockfile, semantic component implementation, renderer output, native control, browser result, support state, or quality-budget pass was introduced.

    - [x] 1.4.2 Task - Publish reproducible completion evidence.

      - [x] 1.4.2.1 Subtask - Record tool identities, commands, project inventory, hashes, negative cases, limitations, deferred evidence, and section commits.
      - [x] 1.4.2.2 Subtask - Record a truthful pass or stop decision and leave Phase 2 unauthorized.

## Section delivery rule

Complete and verify each section before its commit. Open one pull request only
after Section 1.4 passes or records a stop decision. Phase 1 acquires no
external dependency and implements no stable semantic or renderer API.

## Connections

- [BH-02 plan](README.md)
- [BH-02 entry manifest](../../../assets/bh-01-release/blazex-bh-02-entry-manifest-v0-1-0.md)
- [BH-02 authorization](../../../assets/bh-02-baseline/blazex-bh-02-authorization-v0.1.0.json)
- [Repository ownership map](../../../10-maps/blazex-repository-ownership-and-dependency-map.md)
- [Phase 1 implementation evidence](phase-01-implementation-evidence.md)

## Sources

- [BH-01 feasibility baseline](../../../assets/bh-01-release/blazex-bh-01-feasibility-baseline-v0.1.0.json)
- [Development environment policy](../../development-environment-and-deferred-qualification-policy.md)
