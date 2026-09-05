---
title: "Phase 4 - Layout, Tokens, Accessibility, Focus, and Selection Intent"
kind: note
created: "2026-09-05"
maturity: developing
tags:
  - accessibility
  - bh-02
  - focus
  - implementation-planning
  - layout
  - selection
  - tokens
aliases:
  - "BH-02 phase 4"
---

# Phase 4 - Layout, Tokens, Accessibility, Focus, and Selection Intent

Back to milestone: [README](README.md)

- [ ] 4 Phase - Layout, Tokens, Accessibility, Focus, and Selection Intent.

  Complete the portable semantic intent required by the representative BH-02
  interaction slice without implementing geometry, rendering, platform
  accessibility objects, or concrete focus/selection operations. All contracts
  remain experimental.

  - [x] 4.1 Section - Authorize and freeze the experimental intent envelope.

    Bind the completed Phase 3 gate and accepted semantic/native-portability
    architecture before extending the UI-tree contract.

    - [x] 4.1.1 Task - Record bounded Phase 4 authorization.

      - [x] 4.1.1.1 Subtask - Record the owner request, synchronized base, branch, four-section delivery, single-PR rule, and final local/remote branch cleanup.
      - [x] 4.1.1.2 Subtask - Keep Phases 5–8, renderer behavior, concrete layout/accessibility systems, product components, stable APIs, and support claims unauthorized.

    - [x] 4.1.2 Task - Define the first portable presentation-intent envelope.

      - [x] 4.1.2.1 Subtask - Bind ADR-0001, ADR-0002, ADR-0007, and the Phase 3 completion decision by path and SHA-256.
      - [x] 4.1.2.2 Subtask - Freeze token-reference categories and a bounded stack/grid/overlay layout vocabulary with logical sizing, alignment, spacing, overflow, growth, and virtualization hints.
      - [x] 4.1.2.3 Subtask - Freeze accessibility roles, states, relationships, live intent, focus participation/scope/restoration, and controlled selection forms.
      - [x] 4.1.2.4 Subtask - Freeze a versioned intent-set wrapper that preserves the Phase 3 semantic document and validates every annotation against exact tree identity and generation.

  - [x] 4.2 Section - Implement design-token references and logical layout intent.

    Represent portable constraints and relationships without computing final
    geometry or importing a renderer-owned measurement type.

    - [x] 4.2.1 Task - Implement bounded token and metric data.

      - [x] 4.2.1.1 Subtask - Add exact token categories with bounded portable names and reject literal host objects, CSS values, and toolkit resources.
      - [x] 4.2.1.2 Subtask - Add logical auto/content/fill/unit/token metrics and validate non-negative finite unit values.

    - [x] 4.2.2 Task - Implement per-node layout intent.

      - [x] 4.2.2.1 Subtask - Add exact layout modes, direction, alignment, gap, padding, size bounds, growth, overflow, and optional virtualization hints.
      - [x] 4.2.2.2 Subtask - Reject invalid modes, dimensions, min/max relations, virtualization forms, owner identities, opaque terms, and concrete renderer vocabulary.
      - [x] 4.2.2.3 Subtask - Test representative stack/grid, logical token, scrolling, sizing, and virtualization declarations without producing geometry.

  - [x] 4.3 Section - Implement accessibility, focus, selection, and intent-set validation.

    Attach nonvisual meaning and interaction state to exact semantic nodes
    while keeping platform APIs and execution in later renderer phases.

    - [x] 4.3.1 Task - Implement accessibility and focus intent.

      - [x] 4.3.1.1 Subtask - Add exact roles, bounded names/descriptions, typed states, in-tree relationships, and off/polite/assertive live intent.
      - [x] 4.3.1.2 Subtask - Add none/target/scope focus behavior, deterministic order, optional autofocus, previous-focus restoration, and scope wrapping.

    - [x] 4.3.2 Task - Implement controlled selection and composed validation.

      - [x] 4.3.2.1 Subtask - Add none, single, multiple, and directional text-range selection with portable unique values and bounded offsets.
      - [x] 4.3.2.2 Subtask - Add a version-1 intent set over a semantic document; reject unknown owners/targets, duplicate annotations, duplicate focus order, incompatible node kinds, and stale generations.
      - [x] 4.3.2.3 Subtask - Accept intent-set component output atomically across mount, update, event dispatch, and replacement while retaining prior evaluation on failure.

  - [ ] 4.4 Section - Run the Phase 4 integration gate and publish evidence.

    Exercise the representative semantic relationships through the composed
    profile without calculating layout or invoking a concrete renderer.

    - [ ] 4.4.1 Task - Add conformance and governance evidence.

      - [ ] 4.4.1.1 Subtask - Publish versioned layout/token/accessibility/focus/selection scenarios covering positive declarations, relationships, ordering, controlled updates, and rejection paths.
      - [ ] 4.4.1.2 Subtask - Add fail-closed validation for authorization, hashes, exact vocabularies, ownership, fixture coverage, forbidden leakage, and premature Phase 5–8 claims.
      - [ ] 4.4.1.3 Subtask - Add negative tests for stale authority, expanded vocabularies, concrete-system leakage, missing lifecycle coverage, stable APIs, backend results, and support overclaims.

    - [ ] 4.4.2 Task - Execute and record the complete Phase 4 gate.

      - [ ] 4.4.2.1 Subtask - Run all seven Mix project tests/format checks, Phase 1–4 validators, archive validation, inherited validators, and patch hygiene.
      - [ ] 4.4.2.2 Subtask - Record tools, commands, hashes, section commits, limitations, and a truthful pass or stop decision.
      - [ ] 4.4.2.3 Subtask - Leave Phase 5 unauthorized and make no renderer, geometry, browser, native, performance, accessibility-conformance, or support claim.

## Section delivery rule

Complete and verify each section before its commit. Open one pull request only
after Section 4.4 passes or records a stop decision. Phase 4 adds no external
dependency, layout engine, accessibility bridge, renderer behavior, or stable
API.

## Connections

- [BH-02 plan](README.md)
- [ADR-0001 — Host-neutral semantic component kernel](../../../20-notes/architecture-decisions/adr-0001-host-neutral-semantic-component-kernel.md)
- [ADR-0002 — Versioned semantic UI tree](../../../20-notes/architecture-decisions/adr-0002-versioned-semantic-ui-tree.md)
- [ADR-0007 — Native-control portability gate](../../../20-notes/architecture-decisions/adr-0007-native-control-portability-gate.md)
- [Native host and renderer architecture](../../../20-notes/cross-platform-native-host-and-renderer-architecture.md)

## Sources

- [Phase 3 implementation evidence](phase-03-implementation-evidence.md)
- [Foundational component semantics inquiry](../../../40-inquiries/which-foundational-component-semantics-does-blazex-need.md)
- [Cross-renderer component-model inquiry](../../../40-inquiries/can-one-blazex-component-model-target-dom-and-native-controls.md)
