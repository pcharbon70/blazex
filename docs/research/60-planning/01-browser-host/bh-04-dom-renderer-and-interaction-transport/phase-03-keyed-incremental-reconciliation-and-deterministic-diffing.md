---
title: "Phase 3 - Keyed Incremental Reconciliation and Deterministic Diffing"
kind: note
created: "2026-09-06"
maturity: developing
tags:
  - bh-04
  - dom
  - implementation-planning
  - reconciliation
  - renderer
aliases:
  - "BH-04 phase 3"
---

# Phase 3 - Keyed Incremental Reconciliation and Deterministic Diffing

Back to milestone: [README](README.md)

- [ ] 3 Phase - Keyed Incremental Reconciliation and Deterministic Diffing.

  Replace the standalone DOM backend's full-root-only update path with a
  deterministic reconciler that preserves semantic identity and emits bounded
  Phase 2 transactions. Reconciliation remains pure Elixir data processing;
  this phase does not mutate a browser DOM.

  - [ ] 3.1 Section - Authorize and freeze reconciliation semantics.

    Bind the protocol candidate and define when identity is retained, moved,
    replaced, or removed before selecting a diff algorithm.

    - [ ] 3.1.1 Task - Record bounded Phase 3 authority.

      Establish provenance and keep browser, interaction, and framework work
      outside the authorized change.

      - [ ] 3.1.1.1 Subtask - Record synchronized base, branch, section commits, one PR, cleanup, Phase 2 completion identity, and explicit Phase 3 authorization.
      - [ ] 3.1.1.2 Subtask - Bind semantic identity, renderer session state, DOM projection, transaction protocol, limits, and diagnostic classes by version and hash.
      - [ ] 3.1.1.3 Subtask - Exclude live DOM application, browser events, form/focus restoration, effect execution, LiveView translation, support, and public stability.

    - [ ] 3.1.2 Task - Freeze identity and replacement rules.

      Make keyed behavior deterministic for nested trees, collections, and
      generation transitions.

      - [ ] 3.1.2.1 Subtask - Define identity continuity by root, semantic path/key, generation, node kind, materialization compatibility, and parent ownership.
      - [ ] 3.1.2.2 Subtask - Define duplicate-key, missing-key, key-type, parent-change, incompatible-kind, generation-change, and invalid-tree rejection or replacement outcomes.
      - [ ] 3.1.2.3 Subtask - Define when a reorder emits moves, when replacement is mandatory, and how descendants/listeners/resources inherit removal or replacement.

  - [ ] 3.2 Section - Implement projection state and keyed reconciliation.

    Retain the minimum immutable prior state required to compare one accepted
    semantic output with the next without retaining host objects.

    - [ ] 3.2.1 Task - Implement normalized retained projection state.

      Build deterministic indexes and fingerprints that remain scoped to one
      root and one accepted revision.

      - [ ] 3.2.1.1 Subtask - Extend DOM renderer state with accepted projection, root/generation/revision identity, node indexes, parent/child order, listeners, and canonical fingerprints.
      - [ ] 3.2.1.2 Subtask - Validate unique identities, tree shape, bounds, relationship targets, and state/version compatibility before diffing.
      - [ ] 3.2.1.3 Subtask - Ensure retained state contains no DOM node, browser event, LiveView struct, server session, process reference, or mutable external object.

    - [ ] 3.2.2 Task - Implement deterministic keyed tree comparison.

      Compare previous and next projections using stable traversal and
      operation-order rules.

      - [ ] 3.2.2.1 Subtask - Detect unchanged nodes, text/attribute/property/listener changes, compatible insertions/removals, keyed moves, replacements, and subtree disposal.
      - [ ] 3.2.2.2 Subtask - Emit dependency-safe canonical operations so removals, creations, insertions, moves, relationships, and post-commit intents resolve deterministically.
      - [ ] 3.2.2.3 Subtask - Bound algorithm work and memory by governed node/operation limits and fail before emitting partial transactions on overflow or invalid input.

  - [ ] 3.3 Section - Integrate transactions with renderer lifecycle.

    Connect mount, update, replace, and dispose callbacks to the reconciler
    while advancing state only after a correlated commit acknowledgement.

    - [ ] 3.3.1 Task - Implement lifecycle transaction production.

      Preserve the neutral backend contract and explicit generation/revision
      transitions.

      - [ ] 3.3.1.1 Subtask - Emit initial transactions for mount, incremental transactions for compatible updates, explicit replacement transactions for incompatible state, and disposal transactions for terminal cleanup.
      - [ ] 3.3.1.2 Subtask - Separate pending from accepted projection state and define commit, reject, rollback, retry, supersession, and disposal transitions.
      - [ ] 3.3.1.3 Subtask - Reject wrong-generation, stale-base, duplicate, out-of-order, or post-disposal acknowledgements without advancing renderer state.

    - [ ] 3.3.2 Task - Add reconciler diagnostics and deterministic fallbacks.

      Distinguish programmer-invalid semantic output from protocol, capacity,
      and renderer-state failures.

      - [ ] 3.3.2.1 Subtask - Emit stable diagnostics for invalid identity, incompatible state, limit overflow, impossible operation ordering, acknowledgement mismatch, and replacement decisions.
      - [ ] 3.3.2.2 Subtask - Define bounded full replacement as an explicit fallback only where the accepted policy permits it; never silently replace to hide a diff defect.
      - [ ] 3.3.2.3 Subtask - Preserve the last accepted projection after rejection and release pending-only data deterministically.

  - [ ] 3.4 Section - Phase 3 Integration Tests and Completion Evidence.

    Prove canonical incremental output against governed semantic traces without
    requiring a browser.

    - [ ] 3.4.1 Task - Execute reconciler conformance and property tests.

      Cover representative and adversarial tree changes through real renderer
      callbacks and the shared protocol codecs.

      - [ ] 3.4.1.1 Subtask - Test no-op, leaf change, nested insert/remove, keyed reorder, cross-parent rejection/replacement, listener change, accessibility relationship, root replace, generation replace, and disposal fixtures.
      - [ ] 3.4.1.2 Subtask - Add generated/property tests for deterministic replay, unique identities, operation dependency safety, old-to-new projection equivalence, bounded output, and invalid-tree atomic rejection.
      - [ ] 3.4.1.3 Subtask - Compare reconciled semantic outcomes with the headless oracle and retained BH-02 full-root projection without requiring transaction-byte equivalence across backends.

    - [ ] 3.4.2 Task - Publish Phase 3 completion evidence.

      Record algorithm scope, fixture coverage, complexity bounds, negative
      outcomes, and unresolved browser risks.

      - [ ] 3.4.2.1 Subtask - Run Mix/Node codec tests, conformance suites, dependency and leakage audits, validators, archive/generated checks, JSON validation, and patch hygiene.
      - [ ] 3.4.2.2 Subtask - Publish exact commands, counts, fixture/digest hashes, replacement cases, complexity observations, failures, and limitations.
      - [ ] 3.4.2.3 Subtask - Mark Phase 3 complete only if canonical transactions reconstruct every accepted next projection; make Phase 4 eligible but unauthorized.

## Section delivery rule

Complete and verify each section before its commit. Open one pull request only
after Section 3.4 passes or records a stop decision. Phase 3 may emit internal
transactions but may not access or mutate a browser DOM.

## Connections

- [BH-04 plan](README.md)
- [Phase 2](phase-02-versioned-render-transaction-and-patch-protocol.md)
- [Versioned semantic UI tree](../../../20-notes/architecture-decisions/adr-0002-versioned-semantic-ui-tree.md)
- [Renderer backend separation](../../../20-notes/architecture-decisions/adr-0004-renderer-backend-separation.md)

## Sources

- [BH-02 DOM renderer fixtures](../../../../../integration/conformance/dom-renderer-fixtures-v0.1.0.json)
- [BH-02 headless fixtures](../../../../../integration/conformance/renderer-headless-fixtures-v0.1.0.json)
