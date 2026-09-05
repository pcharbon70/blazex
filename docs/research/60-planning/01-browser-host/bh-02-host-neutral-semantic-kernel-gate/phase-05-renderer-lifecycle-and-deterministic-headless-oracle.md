---
title: "Phase 5 - Renderer Lifecycle and Deterministic Headless Oracle"
kind: note
created: "2026-09-05"
maturity: developing
tags:
  - bh-02
  - capabilities
  - conformance
  - headless
  - implementation-planning
  - renderer
aliases:
  - "BH-02 phase 5"
---

# Phase 5 - Renderer Lifecycle and Deterministic Headless Oracle

Back to milestone: [README](README.md)

- [ ] 5 Phase - Renderer Lifecycle and Deterministic Headless Oracle.

  Implement the first renderer contract and deterministic nonvisual oracle over
  the completed portable semantic intent. Keep concrete visual backends,
  geometry, platform accessibility mapping, and support claims outside this
  phase. All APIs remain experimental.

  - [x] 5.1 Section - Authorize and freeze the renderer/oracle envelope.

    Bind the completed Phase 4 gate and accepted renderer-separation decisions
    before activating renderer behavior.

    - [x] 5.1.1 Task - Record bounded Phase 5 authorization.

      - [x] 5.1.1.1 Subtask - Record the owner request, synchronized base, branch, four-section delivery, single-PR rule, and final local/remote branch cleanup.
      - [x] 5.1.1.2 Subtask - Keep Phases 6–8, visual backends, geometry, platform mapping, product components, stable APIs, and support claims unauthorized.

    - [x] 5.1.2 Task - Define renderer lifecycle and deterministic-oracle contracts.

      - [x] 5.1.2.1 Subtask - Bind ADR-0002, ADR-0004, ADR-0007, and the Phase 4 completion decision by path and SHA-256.
      - [x] 5.1.2.2 Subtask - Freeze exact renderer capability/requirement fields, current semantic vocabularies, deny-by-default compatibility, and missing-feature diagnostics.
      - [x] 5.1.2.3 Subtask - Freeze mount/update/replace/dispose context, identity/generation/revision rules, backend callback results, atomic rejection, and idempotent disposal.
      - [x] 5.1.2.4 Subtask - Freeze deterministic snapshot sections, canonical ordering, digest encoding, ordered lifecycle traces, and the nonvisual evidence boundary.

  - [x] 5.2 Section - Implement renderer negotiation and lifecycle contracts.

    Provide a backend-neutral session boundary that owns lifecycle sequencing
    and rejects incompatible or stale semantic output before invoking a backend.

    - [x] 5.2.1 Task - Implement capability discovery and compatibility checks.

      - [x] 5.2.1.1 Subtask - Add exact capability and derived-requirement data for tree version, node kinds, layout modes, accessibility roles, and five current semantic features.
      - [x] 5.2.1.2 Subtask - Reject malformed declarations, unknown or duplicate values, missing required features, and backend capability expansion outside the frozen vocabulary.

    - [x] 5.2.2 Task - Implement backend behavior and lifecycle session.

      - [x] 5.2.2.1 Subtask - Add stable diagnostic and context data plus mount/update/replace/dispose callbacks with opaque backend-owned state.
      - [x] 5.2.2.2 Subtask - Enforce exact root ownership, monotonic revisions, next-generation replacement, compatibility before callbacks, callback result shape, and idempotent disposal.
      - [x] 5.2.2.3 Subtask - Test happy paths, missing capabilities, stale/wrong output, callback rejection/failure, invalid artifacts, and prior-session retention.

  - [x] 5.3 Section - Implement deterministic headless snapshots and traces.

    Materialize semantic meaning into a canonical nonvisual oracle without
    calculating layout or accessing a host.

    - [x] 5.3.1 Task - Implement canonical normalization and snapshots.

      - [x] 5.3.1.1 Subtask - Normalize node identity/content/children, bindings, logical layout, token references, accessibility, focus, and selection into fixed tagged tuple/list sections.
      - [x] 5.3.1.2 Subtask - Sort unordered declarations and maps, preserve meaningful child/list order, use deterministic term encoding, and publish SHA-256 digests.

    - [x] 5.3.2 Task - Implement the headless backend and reusable trace support.

      - [x] 5.3.2.1 Subtask - Implement full current renderer capability declaration and deterministic mount/update/replace/dispose artifacts with ordered trace entries.
      - [x] 5.3.2.2 Subtask - Add reusable script execution and equality assertions in `blazex_test` without browser, server, runtime, or native dependencies.
      - [x] 5.3.2.3 Subtask - Test repeatability, meaningful-order sensitivity, unordered-map normalization, lifecycle ordering, generation replacement, disposal, and unsupported intent.

  - [ ] 5.4 Section - Run the Phase 5 integration gate and publish evidence.

    Exercise the representative portable interaction slice through the
    deterministic headless lifecycle without treating it as visual or native
    conformance.

    - [ ] 5.4.1 Task - Add conformance and governance evidence.

      - [ ] 5.4.1.1 Subtask - Publish versioned renderer lifecycle and headless scenarios covering negotiation, mount/update/replace/dispose, normalization, repeatability, event/effect/resource coordination, focus, selection, and rejection paths.
      - [ ] 5.4.1.2 Subtask - Add fail-closed validation for authorization, hashes, exact vocabularies, lifecycle surface, fixture coverage, forbidden leakage, and premature Phase 6–8 claims.
      - [ ] 5.4.1.3 Subtask - Add negative tests for stale authority, expanded capabilities, concrete-backend leakage, missing trace coverage, stable APIs, visual/backend results, and support overclaims.

    - [ ] 5.4.2 Task - Execute and record the complete Phase 5 gate.

      - [ ] 5.4.2.1 Subtask - Run all seven Mix project tests/format checks, Phase 1–5 validators, archive validation, inherited validators, and patch hygiene.
      - [ ] 5.4.2.2 Subtask - Record tools, commands, hashes, section commits, limitations, and a truthful pass or stop decision.
      - [ ] 5.4.2.3 Subtask - Leave Phase 6 unauthorized and make no geometry, DOM, browser, native, pixel, platform-accessibility, performance, or support claim.

## Section delivery rule

Complete and verify each section before its commit. Open one pull request only
after Section 5.4 passes or records a stop decision. Phase 5 adds no external
dependency, visual backend, geometry engine, platform bridge, or stable API.

## Connections

- [BH-02 plan](README.md)
- [ADR-0002 — Versioned semantic UI tree](../../../20-notes/architecture-decisions/adr-0002-versioned-semantic-ui-tree.md)
- [ADR-0004 — Renderer backend separation](../../../20-notes/architecture-decisions/adr-0004-renderer-backend-separation.md)
- [ADR-0007 — Native-control portability gate](../../../20-notes/architecture-decisions/adr-0007-native-control-portability-gate.md)
- [Host-neutral architecture](../../../20-notes/host-neutral-blazex-architecture-and-native-control-backends.md)

## Sources

- [Phase 4 implementation evidence](phase-04-implementation-evidence.md)
- [Cross-renderer component-model inquiry](../../../40-inquiries/can-one-blazex-component-model-target-dom-and-native-controls.md)
