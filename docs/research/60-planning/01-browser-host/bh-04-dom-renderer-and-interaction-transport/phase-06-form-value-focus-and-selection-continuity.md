---
title: "Phase 6 - Form Value, Focus, and Selection Continuity"
kind: note
created: "2026-09-06"
maturity: developing
tags:
  - accessibility
  - bh-04
  - focus
  - forms
  - implementation-planning
aliases:
  - "BH-04 phase 6"
---

# Phase 6 - Form Value, Focus, and Selection Continuity

Back to milestone: [README](README.md)

- [ ] 6 Phase - Form Value, Focus, and Selection Continuity.

  Make incremental rendering safe for real user input. Preserve controlled
  values, active focus, text selection, composition, and semantic focus intent
  across compatible updates while defining deterministic behavior when the
  focused or edited node moves, changes kind, disappears, or is replaced.

  - [ ] 6.1 Section - Authorize and freeze continuity semantics.

    Bind accepted form, focus, selection, event, and renderer contracts and
    separate portable intent from browser-specific observation.

    - [ ] 6.1.1 Task - Record bounded Phase 6 authority.

      Establish exact inputs and defer product-level form APIs and advanced
      browser capabilities.

      - [ ] 6.1.1.1 Subtask - Record synchronized base, branch, section commits, one PR, cleanup, Phase 5 completion identity, and explicit Phase 6 authorization.
      - [ ] 6.1.1.2 Subtask - Bind semantic field/selection nodes, binding values, focus/selection intent, accessibility state, patch operations, interaction payloads, and root lifecycle by version and hash.
      - [ ] 6.1.1.3 Subtask - Exclude BH-10 validation/form components, BH-13 rich browser controls, BH-14 uploads, arbitrary file paths/bytes, visual styling, and support claims.

    - [ ] 6.1.2 Task - Freeze controlled-state and continuity rules.

      Decide which source owns each value and how browser state is captured and
      restored without overriding newer semantic state.

      - [ ] 6.1.2.1 Subtask - Define controlled value, checked state, selected value, text selection, composition state, and file-choice metadata ownership plus browser-to-semantic transport rules.
      - [ ] 6.1.2.2 Subtask - Define focus retention for unchanged/keyed-moved nodes, explicit focus requests, replacement/removal restoration, fallback target, order, wrapping, and root boundary behavior.
      - [ ] 6.1.2.3 Subtask - Define selection capture/apply timing, clamping, direction, incompatible input types, stale intent, user changes during pending render, and no-visible-jump expectations.

  - [ ] 6.2 Section - Implement form property and composition handling.

    Treat mutable browser form properties distinctly from HTML attributes and
    avoid destructive writes when semantic values have not changed.

    - [ ] 6.2.1 Task - Implement controlled form mutation rules.

      Apply value-bearing properties only through validated operations and
      retain user input until the accepted semantic update resolves it.

      - [ ] 6.2.1.1 Subtask - Implement value, checked, selected, indeterminate, disabled, readonly, required, and invalid mappings with explicit property/attribute ownership.
      - [ ] 6.2.1.2 Subtask - Avoid redundant value writes that reset caret/selection and define accepted-state behavior for conflicting pending user and semantic values.
      - [ ] 6.2.1.3 Subtask - Carry file-choice opaque metadata only where already authorized, never serialize local paths or bytes, and clear browser-owned file state only through explicit policy.

    - [ ] 6.2.2 Task - Implement text composition and input sequencing.

      Preserve IME/composition correctness while maintaining semantic event
      ordering and bounded payloads.

      - [ ] 6.2.2.1 Subtask - Track composition start/update/end as browser-local control state and define when change events are emitted or deferred.
      - [ ] 6.2.2.2 Subtask - Reconcile transactions arriving during composition through explicit retain, defer, commit, cancel, or replace outcomes.
      - [ ] 6.2.2.3 Subtask - Release composition state on blur, replacement, disposal, runtime loss, or rejected transaction without dispatching fabricated input.

  - [ ] 6.3 Section - Implement focus and selection preservation.

    Coordinate pre-commit observation with post-commit semantic intent so
    stable keyed nodes keep browser interaction state and explicit new intent
    wins deterministically.

    - [ ] 6.3.1 Task - Implement focus capture, mapping, and restoration.

      Preserve active ownership through incremental moves and provide bounded
      recovery when the active node is removed or replaced.

      - [ ] 6.3.1.1 Subtask - Capture active element as an owned semantic identity before commit and map it through no-op, update, move, replacement, removal, and root disposal outcomes.
      - [ ] 6.3.1.2 Subtask - Apply explicit autofocus/request-focus only after successful commit using declared priority, generation, fallback, and visibility/disabled checks.
      - [ ] 6.3.1.3 Subtask - Restore to prior, next, parent scope, root fallback, or nowhere according to portable intent without crossing roots or trapping focus accidentally.

    - [ ] 6.3.2 Task - Implement text and semantic selection continuity.

      Preserve valid selection ranges and selected semantic values independently
      of child order changes.

      - [ ] 6.3.2.1 Subtask - Capture and restore text anchor/focus/direction for compatible editable nodes, clamping only according to the accepted contract.
      - [ ] 6.3.2.2 Subtask - Apply semantic single/multiple selection by stable value identity and reject values no longer present rather than selecting by stale indexes.
      - [ ] 6.3.2.3 Subtask - Order value, selection, focus, scroll-neutral restoration, and post-commit effects to avoid flicker, caret jumps, or stale intent application.

  - [ ] 6.4 Section - Phase 6 Integration Tests and Completion Evidence.

    Exercise form, focus, selection, and composition scenarios through complete
    interaction-to-render cycles in active browsers.

    - [ ] 6.4.1 Task - Run continuity integration tests.

      Cover keyboard, pointer, programmatic intent, and concurrent transaction
      cases with observable DOM and semantic traces.

      - [ ] 6.4.1.1 Subtask - Test typed value, checkbox, selection, submit, validation state, keyed input reorder, nested update, focused removal/replacement, autofocus, restoration, and root disposal.
      - [ ] 6.4.1.2 Subtask - Test caret direction/range, redundant and conflicting value writes, IME composition with pending updates, stale focus/selection intent, disabled/hidden targets, and rapid input.
      - [ ] 6.4.1.3 Subtask - Prove no cross-root focus restoration, leaked listener/composition state, local path/byte disclosure, duplicate event, or stale DOM mutation.

    - [ ] 6.4.2 Task - Publish Phase 6 completion evidence.

      Retain browser-observable traces and explicitly separate automation from
      deferred manual assistive-technology qualification.

      - [ ] 6.4.2.1 Subtask - Run Mix/Node and Linux Chrome/Firefox suites, keyboard/form/accessibility automation, conformance fixtures, validators, dependency audits, archive/generated checks, JSON validation, and patch hygiene.
      - [ ] 6.4.2.2 Subtask - Publish browser fingerprints, value/focus/selection traces, fixture hashes, commands/counts, failures, limitations, and privacy/accessibility review.
      - [ ] 6.4.2.3 Subtask - Record unavailable manual assistive-technology and external-platform pairing as `[DEFERRED]` to BH-22; make Phase 7 eligible but unauthorized only after active gates pass.

## Section delivery rule

Complete and verify each section before its commit. Open one pull request only
after Section 6.4 passes or records a stop decision. Loss of accepted user
input, cross-root focus, stale selection, or file-path/byte disclosure is a
blocking result in the active environment.

## Connections

- [BH-04 plan](README.md)
- [Phase 5](phase-05-semantic-event-normalization-and-interaction-transport.md)
- [Host-neutral effects, capabilities, and resources](../../../20-notes/architecture-decisions/adr-0003-host-neutral-effects-capabilities-and-resources.md)
- [Development environment and deferred qualification policy](../../development-environment-and-deferred-qualification-policy.md)

## Sources

- [BH-02 presentation-intent fixtures](../../../../../integration/conformance/presentation-intent-fixtures-v0.1.0.json)
- [BH-02 DOM browser matrix](../../../../../integration/conformance/dom-browser-matrix-v0.1.0.json)
