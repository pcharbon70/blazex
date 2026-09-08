---
title: "Phase 9 - Cross-Path Accessibility and Browser Conformance"
kind: note
created: "2026-09-06"
maturity: developing
tags:
  - accessibility
  - bh-04
  - browser
  - conformance
  - implementation-planning
aliases:
  - "BH-04 phase 9"
---

# Phase 9 - Cross-Path Accessibility and Browser Conformance

Current scope follows the [LiveView integration deferral](../../liveview-integration-deferral.md): LiveView and LocalLiveView
implementation, compatibility and adapter execution are **[DEFERRED]**. Active
conformance compares standalone DOM with the headless semantic oracle. Phase 8
completion is not a prerequisite; Phase 9 was explicitly authorized on 2026-09-08; implementation is in progress.


Back to milestone: [README](README.md)

- [ ] 9 Phase - Cross-Path Accessibility and Browser Conformance.

  Reconcile the headless semantic oracle and standalone DOM renderer through
  one governed scenario corpus. Execute
  active behavior in Linux Chrome and Firefox, retain unavailable platform and
  manual assistive-technology work as explicit deferrals, and make no browser
  support claim.

  - [x] 9.1 Section - Authorize and freeze the conformance matrix.

    Bind all implemented paths and define the observable outcomes that must
    agree without requiring backend-internal representation equality.

    - [x] 9.1.1 Task - Record bounded Phase 9 authority.

      Establish exact candidate identities, active environments, deferred
      environments, and exclusions.

      - [x] 9.1.1.1 Subtask - Record synchronized base, branch, section commits, one PR, cleanup, Phase 7 completion identity and the dated LiveView integration deferral, and explicit Phase 9 authorization.
      - [x] 9.1.1.2 Subtask - Bind the headless oracle, standalone DOM path, deferred-integration record, BH-03 browser host, acceptance registry, and deferred-environment policy by version and hash.
      - [x] 9.1.1.3 Subtask - Declare Linux Chrome/Firefox as active; mark unavailable Safari/macOS, Windows, mobile/physical devices, and manual assistive-technology pairings `[DEFERRED]` to BH-22 with owners and reactivation rules.

    - [x] 9.1.2 Task - Freeze scenario, oracle, and comparison rules.

      Define semantic, DOM, accessibility, interaction, focus, selection,
      lifecycle, failure, and resource observations for each applicable path.

      - [x] 9.1.2.1 Subtask - Define required scenarios for initial render, incremental update, nested/keyed change, every accepted event family, forms, accessibility relationships/state/live intent, focus/selection, effects, failure, fallback, and disposal.
      - [x] 9.1.2.2 Subtask - Define canonical semantic traces, normalized DOM observations, accessibility-tree or computed accessibility observations where available, event/effect/resource traces, and path-specific allowances.
      - [x] 9.1.2.3 Subtask - Define pass, fail, blocked, not-applicable, and deferred states and prohibit a result from one browser/path or schema validity alone from closing another row.

  - [x] 9.2 Section - Build the governed cross-path conformance corpus.

    Publish reusable fixtures and drivers that exercise the same semantic
    scenario through each applicable rendering path.

    - [x] 9.2.1 Task - Implement canonical scenario fixtures and oracles.

      Make inputs deterministic and expected outcomes explicit at each
      observable boundary.

      - [x] 9.2.1.1 Subtask - Add versioned semantic inputs, interaction sequences, expected renderer transactions, normalized DOM states, accessibility states, focus/selection states, acknowledgements, diagnostics, and resource outcomes.
      - [x] 9.2.1.2 Subtask - Add stable normalization for browser-generated details without masking meaningful tag, role, attribute, property, order, focus, selection, listener, or lifecycle differences.
      - [x] 9.2.1.3 Subtask - Include adversarial malformed, stale, replayed, oversized, queue-overload, failed-effect, runtime-loss, and disposal-race scenarios.

    - [x] 9.2.2 Task - Implement path-independent conformance drivers.

      Drive headless and standalone DOM paths through one
      scenario contract while keeping each backend's internal data private.

      - [x] 9.2.2.1 Subtask - Implement deterministic setup, root registration, input replay, transaction/event capture, observation checkpoints, disposal, and cleanup for each path.
      - [x] 9.2.2.2 Subtask - Compare semantic outcomes and declared browser observations with exact mismatch diagnostics and no golden-file auto-acceptance.
      - [x] 9.2.2.3 Subtask - Prove the standalone driver runs with LiveView/LocalLiveView absent and the headless driver runs with browser/runtime/framework dependencies absent.

  - [x] 9.3 Section - Execute active browser accessibility and behavior scenarios.

    Run the corpus in the available development matrix with exact browser and
    environment fingerprints and preserve all failures.

    - [x] 9.3.1 Task - Execute standalone browser scenarios; retain deferred adapter work.

      Cover behavior under initial, repeated, concurrent, failure, and cleanup
      conditions in both active engines.

      - [x] 9.3.1.1 Subtask - Execute the standalone path in Linux Chrome and Firefox for every applicable scenario and retain raw transactions, interactions, DOM snapshots, diagnostics, and resource traces.
      - [ ] 9.3.1.2 Subtask - [DEFERRED] LiveView/LocalLiveView adapter execution and equivalence testing; retain the owned deferral record, exclude this row from active counts, and do not probe or activate an adapter.
      - [x] 9.3.1.3 Subtask - Repeat representative multi-root, rapid-input, keyed-reorder, focus, failure, and dispose/remount scenarios to expose nondeterminism or retained state.

    - [x] 9.3.2 Task - Evaluate automated accessibility outcomes.

      Inspect programmatically observable semantics and keyboard/focus behavior
      without treating automation as manual assistive-technology validation.

      - [x] 9.3.2.1 Subtask - Verify roles, names/descriptions, states, relationships, live-region attributes, reading/DOM order, keyboard activation, focus order, restoration, and no duplicate IDs.
      - [x] 9.3.2.2 Subtask - Test accessibility continuity across keyed move, dynamic insert/remove, validation change, dialog/surface replacement, stale update, failure fallback, and root disposal.
      - [x] 9.3.2.3 Subtask - Record tooling limits and all manual screen-reader/switch/voice-control pairings as `[DEFERRED]` to BH-22 rather than passing or blocking active implementation.

  - [x] 9.4 Section - Reconcile outcomes and dependency isolation.

    Resolve every path/browser/scenario row and verify the implementation still
    obeys neutral and optional-adapter boundaries after integration.

    - [x] 9.4.1 Task - Produce the conformance reconciliation ledger.

      Connect each expected outcome to raw evidence, owner, status, and any
      blocking or deferred disposition.

      - [x] 9.4.1.1 Subtask - Reconcile DOM, accessibility, interaction, form, focus, selection, effect, stale, failure, and disposal outcomes across headless and standalone paths; retain adapter equivalence as [DEFERRED].
      - [x] 9.4.1.2 Subtask - Classify differences as allowed backend representation, defect, unsupported adapter combination, deferred qualification, or contract-change request with accountable owner.
      - [x] 9.4.1.3 Subtask - Require resolution or explicit blocking for every active mismatch and prohibit hidden exceptions or path-specific semantic redefinition.

    - [x] 9.4.2 Task - Re-run architecture and dependency gates.

      Verify integration has not introduced component, server-framework,
      runtime-host, native, or browser-object leakage.

      - [x] 9.4.2.1 Subtask - Audit compile/lock/asset/runtime dependency closures and source surfaces for forbidden standalone and headless edges.
      - [x] 9.4.2.2 Subtask - Audit application fixtures to prove they depend only on BlazeX semantic/component contracts and not DOM, JavaScript, LiveView, LocalLiveView, or adapter structures.
      - [x] 9.4.2.3 Subtask - Verify the current host path does not activate or require the deferred adapter. Adapter private-surface inventory and mismatch qualification remain [DEFERRED].

  - [ ] 9.5 Section - Phase 9 Integration Tests and Completion Evidence.

    Reproduce the complete conformance candidate and publish evidence suitable
    for the final BH-04 review without claiming release qualification.

    - [ ] 9.5.1 Task - Run the complete cross-path integration gate.

      Execute all active scenarios and deterministic generators from a clean
      build while preserving deferred and failed rows.

      - [ ] 9.5.1.1 Subtask - Run all activated Mix/Node suites, Linux Chrome/Firefox scenarios, headless/standalone DOM conformance, accessibility automation, failure/resource tests, validators, dependency audits, archive/generated checks, JSON validation, and patch hygiene.
      - [ ] 9.5.1.2 Subtask - Regenerate normalized reports twice and verify byte/hash stability, raw-evidence linkage, environment fingerprints, result-state validity, and no accidental support credit.
      - [ ] 9.5.1.3 Subtask - Confirm all active mismatches are resolved or blocking and every unavailable external/manual row remains explicit, owned, deferred, and excluded from pass rates.

    - [ ] 9.5.2 Task - Publish Phase 9 completion evidence.

      Summarize exact coverage and limits for final measurement and review.

      - [ ] 9.5.2.1 Subtask - Publish conformance ledger, raw/report hashes, exact commands/counts, browser/tool versions, active outcomes, failures, adapter limits, deferred rows, and review notes.
      - [ ] 9.5.2.2 Subtask - Mark Phase 9 complete only if every active required scenario has reproducible evidence and architecture/dependency gates remain clean.
      - [ ] 9.5.2.3 Subtask - Make Phase 10 eligible but unauthorized and retain all product support and public-stability decisions for later milestones.

## Section delivery rule

Complete and verify each section before its commit. Open one pull request only
after Section 9.5 passes or records a stop decision. Unavailable external
environments are deferred under policy; failures in active applicable Chrome,
Firefox, headless, or standalone rows remain blocking. Deferred adapter rows
are excluded from active gates and grant no pass or compatibility credit.

## Connections

- [BH-04 plan](README.md)
- [Phase 8](phase-08-liveview-and-local-liveview-adapter-isolation.md)
- [Renderer backend separation](../../../20-notes/architecture-decisions/adr-0004-renderer-backend-separation.md)
- [Development environment and deferred qualification policy](../../development-environment-and-deferred-qualification-policy.md)

## Sources

- [BH-02 cross-renderer fixtures](../../../../../integration/conformance/conformance-index-v0.8.0.json)
- [Canonical acceptance registry](../../../assets/quality-acceptance/blazex-acceptance-registry-v0.1.0.json)
