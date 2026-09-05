---
title: "Phase 6 - Standalone DOM Lowering and Browser Conformance"
kind: note
created: "2026-09-05"
maturity: developing
tags:
  - bh-02
  - browser
  - conformance
  - dom
  - implementation-planning
  - renderer
aliases:
  - "BH-02 phase 6"
---

# Phase 6 - Standalone DOM Lowering and Browser Conformance

Back to milestone: [README](README.md)

- [ ] 6 Phase - Standalone DOM Lowering and Browser Conformance.

  Replace the disposable BH-01 fixture adapter with the first bounded
  Phase 5-conforming standalone DOM backend and execute it in the active Linux
  Chrome and Firefox development matrix. Keep incremental reconciliation,
  server transport, visual qualification, and stable APIs outside this phase.

  - [x] 6.1 Section - Authorize and freeze the standalone DOM envelope.

    - [x] 6.1.1 Task - Record bounded Phase 6 authorization.

      - [x] 6.1.1.1 Subtask - Record the owner request, synchronized base, branch, four-section delivery, single-PR rule, and final local/remote branch cleanup.
      - [x] 6.1.1.2 Subtask - Keep Phases 7–8, product components, production hosting, stable APIs, external dependencies, and support claims unauthorized.

    - [x] 6.1.2 Task - Freeze package, projection, driver, and evidence contracts.

      - [x] 6.1.2.1 Subtask - Bind Phase 5 completion, ADR-0002, ADR-0004, ADR-0007, and the browser-rendering profile note by path and SHA-256.
      - [x] 6.1.2.2 Subtask - Freeze the exact inward dependency graph, full current renderer capabilities, DOM batch/node/listener fields, bounded tags, event mappings, and fail-closed rules.
      - [x] 6.1.2.3 Subtask - Freeze full-root atomic projection, accessibility/layout/focus/selection lowering, deterministic IDs/digests, stale rejection, and idempotent disposal.
      - [x] 6.1.2.4 Subtask - Require automated local Chrome and Firefox execution while excluding pixels, visual equivalence, manual accessibility conformance, and support credit.

  - [x] 6.2 Section - Implement standalone DOM lowering.

    - [x] 6.2.1 Task - Activate the Elixir DOM backend over neutral contracts.

      - [x] 6.2.1.1 Subtask - Replace the BH-01 package skeleton dependency graph and implement full current renderer capability declaration.
      - [x] 6.2.1.2 Subtask - Add versioned DOM batch, node, listener, focus, selection, portable-wire, and deterministic identity/digest data.

    - [x] 6.2.2 Task - Lower complete semantic output without host access.

      - [x] 6.2.2.1 Subtask - Lower all seven node kinds, bindings, logical layout/token references, accessibility roles/states/relationships/live intent, focus, and selection.
      - [x] 6.2.2.2 Subtask - Produce atomic mount/update/replace projections and disposal batches through the Phase 5 renderer session.
      - [x] 6.2.2.3 Subtask - Test exact mappings, ordering, deterministic IDs/digests, lifecycle generations/revisions, invalid output, and absence of server/framework leakage.

  - [x] 6.3 Section - Implement the dependency-free browser driver and matrix tests.

    - [x] 6.3.1 Task - Implement strict wire validation and DOM application.

      - [x] 6.3.1.1 Subtask - Replace the disposable fixture protocol with exact versioned batch/node/listener validation, closed tags/fields/attributes, and bounded depth/count/text/value limits.
      - [x] 6.3.1.2 Subtask - Build projections detached, replace one owned root atomically, reject stale generation/revision before mutation, and dispose roots/listeners idempotently.

    - [x] 6.3.2 Task - Implement and execute browser behavior.

      - [x] 6.3.2.1 Subtask - Normalize semantic events to plain bounded records without retaining browser event objects.
      - [x] 6.3.2.2 Subtask - Apply autofocus, same-ID update restoration, controlled value/text selection, accessibility relationships, and semantic child order.
      - [x] 6.3.2.3 Subtask - Pass dependency-free fake-DOM tests and automated real-page runs in local Linux Google Chrome and Firefox.

  - [ ] 6.4 Section - Run the Phase 6 integration gate and publish evidence.

    - [ ] 6.4.1 Task - Add cross-renderer conformance and governance evidence.

      - [ ] 6.4.1.1 Subtask - Publish versioned DOM scenarios covering lowering, headless semantic parity, lifecycle, browser events, accessibility, focus, selection, ordering, rejection, and cleanup.
      - [ ] 6.4.1.2 Subtask - Add fail-closed validation for authorization, hashes, dependency direction, exact surfaces, browser evidence, leakage, and premature Phase 7–8 claims.
      - [ ] 6.4.1.3 Subtask - Add negative tests for stale authority, expanded tags/fields/events, framework leakage, missing browser rows, visual overclaims, stable APIs, and support claims.

    - [ ] 6.4.2 Task - Execute and record the complete Phase 6 gate.

      - [ ] 6.4.2.1 Subtask - Run all activated Mix and JavaScript tests/format or syntax checks, Chrome/Firefox conformance, Phase 1–6 validators, archive validation, inherited validators, and patch hygiene.
      - [ ] 6.4.2.2 Subtask - Record tools, commands, browser versions, hashes, section commits, limitations, and a truthful pass or stop decision.
      - [ ] 6.4.2.3 Subtask - Leave Phase 7 unauthorized and make no native, visual/pixel, manual-accessibility, performance, stable-API, product, or support claim.

## Section delivery rule

Complete and verify each section before its commit. Open one pull request only
after Section 6.4 passes or records a stop decision. Phase 6 adds no external
dependency, server coupling, incremental reconciler, hydration path, or stable
API.

## Connections

- [BH-02 plan](README.md)
- [ADR-0002 — Versioned semantic UI tree](../../../20-notes/architecture-decisions/adr-0002-versioned-semantic-ui-tree.md)
- [ADR-0004 — Renderer backend separation](../../../20-notes/architecture-decisions/adr-0004-renderer-backend-separation.md)
- [Browser rendering and profile modes](../../../20-notes/blazex-browser-rendering-and-profile-modes.md)

## Sources

- [Phase 5 implementation evidence](phase-05-implementation-evidence.md)
- [Cross-renderer component-model inquiry](../../../40-inquiries/can-one-blazex-component-model-target-dom-and-native-controls.md)
