---
title: "Phase 1 - Authorization, Handoff Reconciliation, and Renderer Boundary Activation"
kind: note
created: "2026-09-06"
maturity: developing
tags:
  - authorization
  - bh-04
  - dom
  - implementation-planning
  - renderer
aliases:
  - "BH-04 phase 1"
---

# Phase 1 - Authorization, Handoff Reconciliation, and Renderer Boundary Activation

Back to milestone: [README](README.md)

- [x] 1 Phase - Authorization, Handoff Reconciliation, and Renderer Boundary Activation.

  Establish the exact BH-04 authority, bind the accepted BH-03 handoff and
  inherited renderer contracts, activate only the named renderer evidence
  boundaries, and install fail-closed checks before implementation begins.
  This phase creates no incremental renderer behavior.

  - [x] 1.1 Section - Authorize Phase 1 and reconcile milestone entry.

    Convert the accepted BH-03 handoff into a versioned BH-04 entry ledger
    without inferring authority from existing experimental packages.

    - [x] 1.1.1 Task - Bind implementation authority and delivery provenance.

      Record who authorized the phase, what exact revision it begins from, and
      the section-by-section delivery constraints that apply.

      - [x] 1.1.1.1 Subtask - Record synchronized `main`, feature branch, planned section commits, one-PR rule, merge policy, synchronized-main return, and branch cleanup.
      - [x] 1.1.1.2 Subtask - Bind the BH-03 acceptance decision, completion evidence, release index, roadmap, acceptance registry, deferred-environment policy, and accepted ADRs by path and SHA-256.
      - [x] 1.1.1.3 Subtask - Limit authority to Phase 1 reconciliation, activation, validation, and evidence; prohibit Phase 2 protocol behavior and support/public-API promotion.

    - [x] 1.1.2 Task - Publish the BH-04 entry and acceptance ledger.

      Preserve every inherited condition and connect the five BH-04-owned
      acceptance records to future evidence owners and stop rules.

      - [x] 1.1.2.1 Subtask - Import BH-03 outputs, unresolved findings, compatibility conditions, deferred qualifications, and downstream handoff restrictions without changing their evidence state.
      - [x] 1.1.2.2 Subtask - Register `BX-ACC-ROADMAP-BH-04`, the three first-measurement budgets, and `BX-ACC-FAILURE-BX-FAIL-RENDERER` with owner, phase, suite, and closure expectations.
      - [x] 1.1.2.3 Subtask - Record entry, stop, revise, defer, and completion decision rules and leave BH-05 ineligible.

  - [x] 1.2 Section - Freeze ownership and activate repository boundaries.

    Make the neutral renderer, standalone DOM renderer, optional LiveView
    adapter, JavaScript applicator, and integration suites independently
    auditable before their behavior changes.

    - [x] 1.2.1 Task - Freeze package and dependency ownership.

      Define one accountable owner for every contract and prohibit reverse or
      framework-specific edges into reusable packages.

      - [x] 1.2.1.1 Subtask - Record the allowed inward graph from semantic contracts through `blazex_renderer` to `blazex_renderer_dom`, with the LiveView adapter depending outward on standalone DOM only.
      - [x] 1.2.1.2 Subtask - Record `js/blazex_runtime` ownership of validation, DOM application, browser normalization, and cleanup while forbidding component and server-authority behavior.
      - [x] 1.2.1.3 Subtask - Prohibit Phoenix, Plug, LiveView, LocalLiveView, Popcorn, AtomVM host-lifecycle, and native-toolkit objects from portable renderer contracts.

    - [x] 1.2.2 Task - Activate versioned BH-04 evidence locations.

      Create empty, schema-bound locations for future conformance, browser,
      failure, benchmark, and acceptance records without claiming results.

      - [x] 1.2.2.1 Subtask - Activate `integration/bh-04` with an empty versioned index and declared transaction, interaction, browser, failure, measurement, and review evidence classes.
      - [x] 1.2.2.2 Subtask - Update package and integration indexes with truthful Phase 1 activation status and no implemented or passing renderer behavior.
      - [x] 1.2.2.3 Subtask - Preserve historical BH-02 full-root fixtures and mark their reuse, supersession, and immutability boundaries explicitly.

  - [x] 1.3 Section - Implement fail-closed activation governance.

    Detect stale authority, incomplete handoff, ownership leakage, premature
    behavior, and false evidence before any renderer transaction is accepted.

    - [x] 1.3.1 Task - Implement the Phase 1 validator.

      Validate exact identities and repository boundaries rather than relying
      on prose status labels.

      - [x] 1.3.1.1 Subtask - Verify authorization, bound input hashes, all five acceptance records, phase decomposition, evidence schemas, owner assignments, and synchronized-base ancestry.
      - [x] 1.3.1.2 Subtask - Audit direct and transitive dependencies plus reusable source tokens for server-framework, host-lifecycle, browser-object, and native-toolkit leakage.
      - [x] 1.3.1.3 Subtask - Reject nonempty results, incremental protocol implementation, passing measurements, stable APIs, support claims, or Phase 2 authorization.

    - [x] 1.3.2 Task - Add focused negative governance tests.

      Prove the gate fails with actionable diagnostics for every material
      activation error.

      - [x] 1.3.2.1 Subtask - Reject missing authority, stale BH-03 handoff, changed acceptance identities, absent owners, unauthorized dependency edges, or unindexed files.
      - [x] 1.3.2.2 Subtask - Reject historical-evidence rewrites, fabricated browser rows, hidden deferrals, premature behavior, and public/support promotion.
      - [x] 1.3.2.3 Subtask - Prove the unimplemented Phase 1 candidate passes deterministically from a clean checkout.

  - [x] 1.4 Section - Phase 1 Integration Tests and Completion Evidence.

    Run the complete inherited activation gate and publish a bounded decision
    before Phase 2 can become eligible.

    - [x] 1.4.1 Task - Execute the active Phase 1 integration gate.

      Reproduce all inherited and newly activated checks with exact commands,
      versions, counts, and negative cases.

      - [x] 1.4.1.1 Subtask - Run package-local tests and formats, BH-03 release checks, the BH-04 activation validator/tests, archive and inherited governance validators/generators, JSON validation, dependency audit, and patch hygiene.
      - [x] 1.4.1.2 Subtask - Confirm transaction, reconciliation, browser, LiveView adapter, measurement, and acceptance result sets remain empty and later behavior remains unauthorized.
      - [x] 1.4.1.3 Subtask - Record exact environment, commands, output counts, expected negative failures, limitations, and deferred qualifications.

    - [x] 1.4.2 Task - Publish Phase 1 completion evidence.

      Bind the activation decision to immutable inputs and make no renderer
      implementation claim.

      - [x] 1.4.2.1 Subtask - Publish the validation log, implementation-evidence note, and completion decision with exact artifact hashes.
      - [x] 1.4.2.2 Subtask - Mark Phase 1 complete only if every active gate passes and no stop condition is open.
      - [x] 1.4.2.3 Subtask - Make Phase 2 eligible but unauthorized; keep BH-05 ineligible.

## Section delivery rule

Complete and verify each section before its commit. Open one pull request only
after Section 1.4 passes or records a truthful stop decision. Phase 1 may
activate evidence and governance only; it may not implement renderer behavior.

## Connections

- [BH-04 plan](README.md)
- [BH-03 plan](../bh-03-browser-execution-host-and-runtime-boot-lifecycle/README.md)
- [Renderer backend separation](../../../20-notes/architecture-decisions/adr-0004-renderer-backend-separation.md)
- [Development environment and deferred qualification policy](../../development-environment-and-deferred-qualification-policy.md)

## Sources

- [BH-02 contract baseline](../../../assets/bh-02-baseline/blazex-bh-02-contract-baseline-v0.1.0.json)
- [Canonical acceptance registry](../../../assets/quality-acceptance/blazex-acceptance-registry-v0.1.0.json)
