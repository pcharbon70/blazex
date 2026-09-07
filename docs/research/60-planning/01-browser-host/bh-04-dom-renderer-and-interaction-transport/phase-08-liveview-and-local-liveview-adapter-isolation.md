---
title: "Phase 8 - LiveView and LocalLiveView Adapter Isolation"
kind: note
created: "2026-09-06"
maturity: developing
tags:
  - bh-04
  - implementation-planning
  - liveview
  - local-live-view
  - renderer
aliases:
  - "BH-04 phase 8"
---

# Phase 8 - LiveView and LocalLiveView Adapter Isolation

Back to milestone: [README](README.md)

- [ ] 8 Phase - LiveView and LocalLiveView Adapter Isolation.

  Replace the disposable BH-01 compatibility fixture with an optional,
  version-pinned adapter that translates only the selected LiveView and
  LocalLiveView render-data, patching, lifecycle, and transport surfaces. The
  standalone DOM path remains complete and framework-independent.

  - [ ] 8.1 Section - Authorize and qualify the framework compatibility envelope.

    Bind the exact compatible framework/runtime inputs and decide whether the
    optional adapter remains technically and operationally bounded.

    - [ ] 8.1.1 Task - Record bounded Phase 8 authority.

      Establish provenance and prevent optional framework work from becoming a
      prerequisite of standalone DOM or the Plug profile.

      - [ ] 8.1.1.1 Subtask - Record synchronized base, branch, section commits, one PR, cleanup, Phase 7 completion identity, exact dependency locks, and explicit Phase 8 authorization.
      - [ ] 8.1.1.2 Subtask - Bind standalone transaction/interaction contracts, pinned LiveView/LocalLiveView/Popcorn compatibility identities, profile composition, and BH-01 private-coupling findings by version and hash.
      - [ ] 8.1.1.3 Subtask - Exclude Phoenix command authority, Plug adapter behavior, prerender/activation, uploads, navigation, public compatibility promises, and support claims.

    - [ ] 8.1.2 Task - Inspect and freeze the exact adapter surface.

      Use source-bound inspection to name every public or private framework
      structure and callback the adapter must understand.

      - [ ] 8.1.2.1 Subtask - Inventory render-data construction, component/root identity, static/dynamic fragments, keyed collections, patch operations, client lifecycle, hook points, and transport envelopes actually used by the pinned pair.
      - [ ] 8.1.2.2 Subtask - Classify each dependency as public, version-sensitive, or private; isolate private access behind one compatibility module and define a replacement/upstream path.
      - [ ] 8.1.2.3 Subtask - Define exact-match enablement, mismatch disablement before partial activation, diagnostics, fallback to standalone DOM where valid, and unsupported combinations.

  - [ ] 8.2 Section - Implement render-data and patch translation.

    Translate framework-specific inputs into the same validated DOM transaction
    outcomes without leaking framework terms into portable components or the
    standalone renderer.

    - [ ] 8.2.1 Task - Implement adapter compatibility and lifecycle modules.

      Keep framework imports, structs, callbacks, and feature probes physically
      inside `blazex_renderer_dom_liveview`.

      - [ ] 8.2.1.1 Subtask - Add exact version/feature descriptors and fail-closed startup negotiation for the pinned LiveView and LocalLiveView pair.
      - [ ] 8.2.1.2 Subtask - Map framework root/component identity and lifecycle into BlazeX root, generation, revision, transaction, acknowledgement, and disposal records.
      - [ ] 8.2.1.3 Subtask - Disable the adapter atomically on unknown fields/shapes, missing features, version mismatch, malformed data, or incompatible lifecycle ordering.

    - [ ] 8.2.2 Task - Implement deterministic framework translation.

      Normalize initial render data and subsequent patches into closed internal
      transactions or a documented equivalent application path.

      - [ ] 8.2.2.1 Subtask - Translate static/dynamic fragments, attributes, text, keyed collection operations, listener/event metadata, and removals without evaluating arbitrary HTML or JavaScript.
      - [ ] 8.2.2.2 Subtask - Preserve identity, accessibility, forms, focus/selection, transaction barriers, stale rejection, and root ownership through initial and incremental framework updates.
      - [ ] 8.2.2.3 Subtask - Canonicalize adapter output and diagnostics so equivalent pinned inputs produce deterministic semantic DOM outcomes.

  - [ ] 8.3 Section - Integrate optional patching and prove dependency isolation.

    Compose the adapter only in an explicitly selected browser/Phoenix mode and
    ensure it cannot enter the standalone or future Plug dependency closure.

    - [ ] 8.3.1 Task - Implement optional profile composition.

      Select standalone or compatible LiveView lowering before root activation
      and keep the choice observable for diagnostics.

      - [ ] 8.3.1.1 Subtask - Add explicit profile configuration, compatibility decision, asset/module inclusion, lifecycle wiring, and fallback behavior for the optional adapter.
      - [ ] 8.3.1.2 Subtask - Reuse the BH-03 shared runtime/root lifecycle and BH-04 transaction/interaction contracts without giving the adapter server authorization or portable state ownership.
      - [ ] 8.3.1.3 Subtask - Prevent mixed ownership in one root, duplicate patchers/listeners, partial adapter activation, and runtime switching after root commit except through declared replacement.

    - [ ] 8.3.2 Task - Enforce package and profile closure.

      Prove framework coupling has one owner at source, compile, lock, asset,
      and runtime levels.

      - [ ] 8.3.2.1 Subtask - Audit `blazex_renderer_dom`, neutral packages, JavaScript standalone entry points, headless profile, and future Plug closure for Phoenix, Plug, LiveView, LocalLiveView, and adapter references.
      - [ ] 8.3.2.2 Subtask - Audit the adapter for undeclared framework surface access and verify every private/version-sensitive use maps to the compatibility inventory and tests.
      - [ ] 8.3.2.3 Subtask - Build and test the standalone path with the adapter and framework dependencies absent from the resolved dependency and asset graphs.

  - [ ] 8.4 Section - Phase 8 Integration Tests and Completion Evidence.

    Compare standalone and compatible adapter outcomes, then exercise mismatch
    and malformed framework traffic before declaring the adapter bounded.

    - [ ] 8.4.1 Task - Run adapter conformance and compatibility tests.

      Use pinned real framework inputs where available and immutable fixtures
      for every accepted or rejected shape.

      - [ ] 8.4.1.1 Subtask - Test initial render, incremental text/attribute/property updates, keyed insert/move/remove, events, form state, focus/selection, accessibility, failure, and disposal through both paths.
      - [ ] 8.4.1.2 Subtask - Test unknown/mismatched versions, changed/private shapes, missing features, malformed/oversized patches, stale generations/revisions, duplicate patchers, and adapter removal before activation.
      - [ ] 8.4.1.3 Subtask - Assert equivalent documented DOM/semantic outcomes, not byte-identical framework transactions, and prove standalone behavior succeeds with all framework dependencies absent.

    - [ ] 8.4.2 Task - Publish Phase 8 completion evidence.

      Record the precise compatibility burden, private coupling, fallback, and
      unsupported combinations without making a framework support promise.

      - [ ] 8.4.2.1 Subtask - Run adapter and standalone Mix/Node/Linux Chrome/Firefox suites, source/lock/asset dependency audits, compatibility negatives, validators, archive/generated checks, JSON validation, and patch hygiene.
      - [ ] 8.4.2.2 Subtask - Publish exact dependency/framework/browser versions, surface inventory, fixture hashes, commands/counts, private-coupling findings, failures, fallbacks, and limitations.
      - [ ] 8.4.2.3 Subtask - Mark Phase 8 complete only if all coupling is isolated and mismatch fails before partial activation; make Phase 9 eligible but unauthorized.

## Section delivery rule

Complete and verify each section before its commit. Open one pull request only
after Section 8.4 passes or records a stop decision. If the adapter requires a
reverse dependency, leaks framework structures into portable contracts, or
cannot fail closed on mismatch, record a stop/revise result rather than
weakening the standalone architecture.

## Connections

- [BH-04 plan](README.md)
- [Phase 7](phase-07-effect-ordering-resources-disposal-and-failure-isolation.md)
- [Renderer backend separation](../../../20-notes/architecture-decisions/adr-0004-renderer-backend-separation.md)
- [Profile composition](../../../20-notes/architecture-decisions/adr-0006-profile-composition.md)

## Sources

- [LiveView and LocalLiveView source note](../../../30-sources/phoenix-framework-2026-liveview-1-2-documentation-and-source.md)
- [LocalLiveView source note](../../../30-sources/software-mansion-2026-local-live-view-first-release.md)
