---
title: "Phase 11 - ERTS, Browser-AtomVM, and Cross-Backend Conformance"
kind: note
created: "2026-09-06"
maturity: developing
tags:
  - atomvm
  - bh-05
  - browser
  - conformance
  - implementation-planning
aliases:
  - "BH-05 phase 11"
---

# Phase 11 - ERTS, Browser-AtomVM, and Cross-Backend Conformance

Back to milestone: [README](README.md)

- [ ] 11 Phase - ERTS, Browser-AtomVM, and Cross-Backend Conformance.

  Execute one public BlazeX application corpus under local ERTS/headless and
  browser AtomVM/DOM and compare callback ordering, identity, state, output,
  actions, failures, disposal, and final state. Re-run the retained direct GTK
  portability slice for changed public semantics without claiming native-host
  or browser support.

  - [ ] 11.1 Section - Authorize and freeze the conformance matrix.

    Bind all BH-05 contracts plus accepted runtime/renderer paths and define
    exact portable observations, allowed runtime variation, active rows, and
    deferrals.

    - [ ] 11.1.1 Task - Record bounded Phase 11 authority.

      Establish candidate, environment, and delivery provenance without
      implying general build/package or platform support.

      - [ ] 11.1.1.1 Subtask - Record synchronized base, branch, section commits, one PR, cleanup, Phase 1–10 completion identities, and explicit Phase 11 authorization.
      - [ ] 11.1.1.2 Subtask - Bind public facade/schemas/lifecycle/scheduler/effects/context/registry/failure contracts, BH-03 runtime, accepted BH-04 renderer, headless oracle, native spike, and runtime compatibility baseline by version and hash.
      - [ ] 11.1.1.3 Subtask - Declare local ERTS/headless and Linux Chrome/Firefox browser AtomVM/DOM active; mark unavailable operating systems, Safari, physical devices, and manual assistive-technology pairings `[DEFERRED]` to BH-22.

    - [ ] 11.1.2 Task - Freeze trace and equivalence rules.

      Compare public semantic behavior while excluding runtime-specific noise
      that is not part of the component contract.

      - [ ] 11.1.2.1 Subtask - Define canonical declaration/schema, callback enter/exit, identity, accepted/candidate state, semantic output, event/message/timer, action/result, context/registry, commit, failure/retry, disposal, and final-state observations.
      - [ ] 11.1.2.2 Subtask - Exclude PIDs, references, monotonic clock origins, scheduler reductions, stack traces, adapter-internal transactions, browser-generated IDs, and private module names from equality while retaining their bounded diagnostic evidence separately.
      - [ ] 11.1.2.3 Subtask - Define exact-match, allowed-runtime-variation, fail, blocked, not-applicable, and deferred states and prohibit manual normalization that hides semantic divergence.

  - [ ] 11.2 Section - Build the public conformance application corpus.

    Create representative applications that import only documented public
    BlazeX contracts and exercise every supported BH-05 semantic dimension.

    - [ ] 11.2.1 Task - Implement canonical application scenarios.

      Cover simple and composed behavior with deterministic input scripts and
      expected public traces.

      - [ ] 11.2.1.1 Subtask - Add pure/nested-stateful/process-root components using required/default/local/host props, default/named/contextual slots, controlled props, local state, keyed insert/move/remove/replace, and semantic accessibility output.
      - [ ] 11.2.1.2 Subtask - Add event, self/child/parent message, timer, delayed/denied effect, resource lease/transfer/release, command intent, tracked/fixed context, dynamic registry, and multi-root scenarios.
      - [ ] 11.2.1.3 Subtask - Add callback/schema/output failure, renderer reject, persistent retry, stale work/result, root crash, removal/replacement, fallback, disposal, and remount scenarios.

    - [ ] 11.2.2 Task - Implement deterministic runners and trace normalization.

      Use one scenario description and expected outcome model across ERTS,
      browser AtomVM, headless, DOM, and the bounded portability check.

      - [ ] 11.2.2.1 Subtask - Define setup, bootstrap, root registration, input/effect/result/failure injection, checkpoints, final-state capture, disposal, and cleanup independent of concrete runtime and renderer internals.
      - [ ] 11.2.2.2 Subtask - Implement stable trace encoding/digests and exact mismatch reports linked to scenario, step, root/component identity, generation/revision, and public contract version.
      - [ ] 11.2.2.3 Subtask - Audit fixtures for private runtime/renderer/host/server imports, direct process manipulation, framework structs, DOM/JavaScript values, and runtime-conditional semantic branches.

  - [ ] 11.3 Section - Execute local ERTS and headless/backend conformance.

    Establish the deterministic reference traces under the supported local
    ERTS environment before comparing browser AtomVM.

    - [ ] 11.3.1 Task - Run ERTS component and headless scenarios.

      Execute normal, adversarial, repeated, and multi-root fixtures with
      deterministic providers and renderer ports.

      - [ ] 11.3.1.1 Subtask - Run every applicable scenario under ERTS with the headless renderer and retain raw callback/state/action/failure/disposal/final-state traces.
      - [ ] 11.3.1.2 Subtask - Run the accepted standalone DOM path in the local browser harness where needed to separate runtime from renderer behavior and compare normalized semantic outcomes.
      - [ ] 11.3.1.3 Subtask - Repeat scenarios under varied legal scheduler timing and delayed acknowledgements/results to prove contract order and final state do not depend on incidental process scheduling.

    - [ ] 11.3.2 Task - Re-run cross-backend portability checks.

      Ensure BH-05 public semantics remain expressible by the existing neutral
      tree/effect contracts and retained native-control experiment.

      - [ ] 11.3.2.1 Subtask - Run the supported semantic subset through headless, standalone DOM, and direct GTK experiment using public component fixtures rather than private evaluator data.
      - [ ] 11.3.2.2 Subtask - Compare layout/action/field/selection/keyed-list/surface/focus/file-choice/disposal outcomes and identify any new component semantic that lacks a backend-neutral representation.
      - [ ] 11.3.2.3 Subtask - Treat GTK as a portability gate only and retain Windows/AppKit execution as `[DEFERRED]`; grant no native package/profile/support claim.

  - [ ] 11.4 Section - Execute browser AtomVM conformance.

    Build the fixed governed fixture bundle through the accepted runtime path
    and run the same scenarios in active Linux Chrome and Firefox.

    - [ ] 11.4.1 Task - Run browser-AtomVM application scenarios.

      Preserve exact runtime/browser/toolchain identities and every failed,
      timed-out, or divergent sample.

      - [ ] 11.4.1.1 Subtask - Compile/package the declared fixed fixture roots under the accepted pinned AtomVM/Popcorn path without claiming BH-06 general reachability or build support.
      - [ ] 11.4.1.2 Subtask - Execute every applicable scenario in Linux Chrome and Firefox, including multi-root, delayed scheduling, failure/retry, stale result, disposal, and remount behavior.
      - [ ] 11.4.1.3 Subtask - Capture raw public traces, DOM/renderer outcomes, diagnostics, browser/runtime logs, resource/process inventories, and final-state digests with exact environment fingerprints.

    - [ ] 11.4.2 Task - Compare ERTS and browser-AtomVM outcomes.

      Resolve every trace field and final state against the frozen equivalence
      policy and retain all runtime limitations.

      - [ ] 11.4.2.1 Subtask - Compare callback order, identity, props/slots, state revisions, semantic output, events/messages/timers, actions/results, context/registry, failures/retries, disposal, and final-state digests.
      - [ ] 11.4.2.2 Subtask - Classify each difference as allowed runtime variation, harness defect, component contract defect, unsupported AtomVM semantic, or blocking divergence with owner and reproduction.
      - [ ] 11.4.2.3 Subtask - Require resolution or explicit BH-05 stop/revise for every active semantic divergence and prohibit browser-specific code in public fixtures as a workaround.

  - [ ] 11.5 Section - Phase 11 Integration Tests and Completion Evidence.

    Reproduce all active runtime/backend rows and publish the canonical
    cross-runtime conformance ledger for final measurement and review.

    - [ ] 11.5.1 Task - Run the complete conformance gate.

      Execute clean builds, deterministic reports, runtime/browser scenarios,
      backend checks, and architecture guards together.

      - [ ] 11.5.1.1 Subtask - Run all activated Mix/Node tests and formats, ERTS/headless suites, Linux Chrome/Firefox AtomVM/DOM scenarios, GTK portability checks, runtime/renderer validators, dependency/API audits, archive/generated checks, JSON validation, and patch hygiene.
      - [ ] 11.5.1.2 Subtask - Regenerate normalized traces/reports twice and compare bytes/hashes, raw-evidence links, environment identities, result states, and active/deferred classification.
      - [ ] 11.5.1.3 Subtask - Confirm public fixture imports are clean, all active differences are resolved or blocking, and deferred rows remain explicit and excluded from pass rates.

    - [ ] 11.5.2 Task - Publish Phase 11 completion evidence.

      Record exact supported candidate semantics and limitations without
      converting development conformance into product support.

      - [ ] 11.5.2.1 Subtask - Publish conformance ledger, raw/normalized trace hashes, exact commands/counts, runtime/browser/tool versions, active outcomes, differences, failures, deferred rows, and reviews.
      - [ ] 11.5.2.2 Subtask - Mark Phase 11 complete only if every active supported semantic has matching ERTS/browser-AtomVM evidence and backend neutrality remains intact.
      - [ ] 11.5.2.3 Subtask - Make Phase 12 eligible but unauthorized and retain all public stability, broad platform, and release-support decisions for later milestones.

## Section delivery rule

Complete and verify each section before its commit. Open one pull request only
after Section 11.5 passes or records a stop decision. Missing external
environments remain deferred, but any unresolved active ERTS/AtomVM semantic
divergence, private application import, or browser-specific public workaround
blocks completion.

## Connections

- [BH-05 plan](README.md)
- [Phase 10](phase-10-failure-containment-retry-replacement-and-disposal.md)
- [Host-neutral component-kernel decision](../../../20-notes/architecture-decisions/adr-0001-host-neutral-semantic-component-kernel.md)
- [Development environment and deferred qualification policy](../../development-environment-and-deferred-qualification-policy.md)

## Sources

- [BH-02 semantic-kernel fixtures](../../../../../integration/conformance/semantic-kernel-fixtures-v0.1.0.json)
- [BH-01 feasibility baseline](../../../assets/bh-01-release/blazex-bh-01-feasibility-baseline-v0.1.0.json)
