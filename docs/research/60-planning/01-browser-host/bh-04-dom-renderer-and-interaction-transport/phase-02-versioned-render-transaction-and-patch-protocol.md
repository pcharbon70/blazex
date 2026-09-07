---
title: "Phase 2 - Versioned Render Transaction and Patch Protocol"
kind: note
created: "2026-09-06"
maturity: developing
tags:
  - bh-04
  - dom
  - implementation-planning
  - protocol
  - renderer
aliases:
  - "BH-04 phase 2"
---

# Phase 2 - Versioned Render Transaction and Patch Protocol

Back to milestone: [README](README.md)

- [ ] 2 Phase - Versioned Render Transaction and Patch Protocol.

  Define the internal, versioned language between the renderer backend and the
  browser applicator. The protocol must describe incremental transactions,
  acknowledgements, diagnostics, limits, compatibility, and failure semantics
  without becoming a public component API or exposing browser objects.

  - [ ] 2.1 Section - Authorize and freeze the Phase 2 protocol envelope.

    Bind Phase 1 completion and decide the exact protocol questions Phase 2 may
    answer before implementing either reconciliation or DOM mutation.

    - [ ] 2.1.1 Task - Record bounded Phase 2 authority.

      Establish provenance, dependencies, and exclusions for protocol work.

      - [ ] 2.1.1.1 Subtask - Record synchronized base, feature branch, section commits, single PR, cleanup, Phase 1 completion identity, and explicit Phase 2 authorization.
      - [ ] 2.1.1.2 Subtask - Bind renderer lifecycle, semantic identity, event/effect/resource, presentation-intent, BH-03 root/generation, and BH-02 DOM projection contracts by version and hash.
      - [ ] 2.1.1.3 Subtask - Exclude reconciliation algorithms, live DOM mutation, framework adapter behavior, product components, public stability, and support qualification.

    - [ ] 2.1.2 Task - Freeze protocol design invariants.

      Make compatibility, ownership, ordering, bounds, and atomicity explicit
      before selecting operation encodings.

      - [ ] 2.1.2.1 Subtask - Define protocol and schema identities, version negotiation, feature/capability declaration, compatibility outcomes, and upgrade/rejection rules.
      - [ ] 2.1.2.2 Subtask - Define root owner, generation, base revision, target revision, transaction ID, digest, operation ordering, acknowledgement, and diagnostic correlation invariants.
      - [ ] 2.1.2.3 Subtask - Define bounded depth, nodes, operations, listeners, attributes, values, text, queue, and message size limits plus fail-closed overflow behavior.

  - [ ] 2.2 Section - Define the closed render-transaction vocabulary.

    Replace implicit full-root semantics with a canonical transaction model
    that can represent initial materialization, incremental change, replacement,
    and disposal while retaining exact root ownership.

    - [ ] 2.2.1 Task - Define transaction and patch operation records.

      Give each mutation enough information for preflight validation,
      deterministic execution, diagnostics, and replay testing.

      - [ ] 2.2.1.1 Subtask - Define initial, patch, replace, and dispose transaction kinds and a closed set of create, insert, move, remove, replace, text, attribute, property, listener, focus, selection, and effect-barrier operations.
      - [ ] 2.2.1.2 Subtask - Define canonical node/listener identities, parent/anchor references, old/new assertions, operation dependencies, and normalized serialization order.
      - [ ] 2.2.1.3 Subtask - Define transaction digests and deterministic encoding independent of map iteration, process timing, or browser implementation details.

    - [ ] 2.2.2 Task - Define acknowledgement and failure records.

      Make every accepted, rejected, committed, rolled-back, replaced, and
      disposed outcome observable to the owning root.

      - [ ] 2.2.2.1 Subtask - Define preflight, accepted, committed, rejected, rolled-back, fallback, and disposed acknowledgement states with root/generation/revision correlation.
      - [ ] 2.2.2.2 Subtask - Define malformed, incompatible, stale, duplicate, missing-target, ownership, limit, apply, rollback, and disposed-root diagnostic classes.
      - [ ] 2.2.2.3 Subtask - Prohibit silent coercion, partial-success acknowledgement, arbitrary exception serialization, and cross-root diagnostic disclosure.

  - [ ] 2.3 Section - Implement schemas, codecs, and contract validation.

    Publish equivalent Elixir and JavaScript representations and prove they
    agree before either side executes transactions.

    - [ ] 2.3.1 Task - Implement owner-specific protocol modules.

      Keep host-neutral lifecycle additions in `blazex_renderer`, DOM records
      in `blazex_renderer_dom`, and browser validation in `js/blazex_runtime`.

      - [ ] 2.3.1.1 Subtask - Implement immutable Elixir transaction, operation, acknowledgement, limit, compatibility, and diagnostic data with strict constructors.
      - [ ] 2.3.1.2 Subtask - Implement JavaScript schema constants and pure validators with exact fields, types, bounds, identity formats, and error codes.
      - [ ] 2.3.1.3 Subtask - Retain the BH-02 full-root batch as an explicitly versioned migration input or superseded fixture rather than silently changing its meaning.

    - [ ] 2.3.2 Task - Add cross-language protocol fixtures.

      Prove valid records normalize identically and invalid records fail before
      DOM access or runtime dispatch.

      - [ ] 2.3.2.1 Subtask - Publish versioned positive fixtures for every transaction kind, operation, acknowledgement, diagnostic, and declared limit boundary.
      - [ ] 2.3.2.2 Subtask - Publish malformed, unknown-version, extra-field, wrong-owner, stale-base, duplicate-ID, impossible-order, oversized, and digest-mismatch fixtures.
      - [ ] 2.3.2.3 Subtask - Round-trip canonical fixtures through Elixir and JavaScript and compare normalized bytes, digests, and error classes.

  - [ ] 2.4 Section - Phase 2 Integration Tests and Completion Evidence.

    Execute the protocol gate with no live DOM mutations and publish evidence
    that later behavior remains outside the phase.

    - [ ] 2.4.1 Task - Run deterministic protocol integration tests.

      Exercise the schemas and codecs through their real package boundaries.

      - [ ] 2.4.1.1 Subtask - Run Mix and Node contract suites over all positive, negative, boundary, determinism, version-negotiation, and cross-language fixtures.
      - [ ] 2.4.1.2 Subtask - Run dependency, forbidden-token, archive, inherited-governance, JSON/schema, generated-freshness, and patch-hygiene checks.
      - [ ] 2.4.1.3 Subtask - Confirm no reconciler, DOM applicator, event transport, LiveView adapter, browser result, or measurement is implemented or claimed.

    - [ ] 2.4.2 Task - Publish Phase 2 completion evidence.

      Record the exact internal protocol candidate and its unresolved
      implementation risks without promoting it publicly.

      - [ ] 2.4.2.1 Subtask - Publish protocol inventory, fixture hashes, command log, negative outcomes, dependency audit, limitations, and implementation-evidence note.
      - [ ] 2.4.2.2 Subtask - Mark Phase 2 complete only if Elixir/JavaScript agreement is exact and all malformed traffic fails before mutation.
      - [ ] 2.4.2.3 Subtask - Make Phase 3 eligible but unauthorized and retain protocol change control through BH-04 acceptance.

## Section delivery rule

Complete and verify each section before its commit. Open one pull request only
after Section 2.4 passes or records a stop decision. Phase 2 defines an
internal renderer protocol; it does not authorize reconciliation or DOM
mutation.

## Connections

- [BH-04 plan](README.md)
- [Phase 1](phase-01-authorization-handoff-reconciliation-and-renderer-boundary-activation.md)
- [Versioned semantic UI tree](../../../20-notes/architecture-decisions/adr-0002-versioned-semantic-ui-tree.md)
- [Renderer backend separation](../../../20-notes/architecture-decisions/adr-0004-renderer-backend-separation.md)

## Sources

- [BH-02 renderer lifecycle fixtures](../../../../../integration/conformance/renderer-headless-fixtures-v0.1.0.json)
- [BH-02 DOM renderer fixtures](../../../../../integration/conformance/dom-renderer-fixtures-v0.1.0.json)
