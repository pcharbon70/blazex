---
title: "Phase 5 - Semantic Event Normalization and Interaction Transport"
kind: note
created: "2026-09-06"
maturity: developing
tags:
  - bh-04
  - browser
  - events
  - implementation-planning
  - interaction
aliases:
  - "BH-04 phase 5"
---

# Phase 5 - Semantic Event Normalization and Interaction Transport

Back to milestone: [README](README.md)

- [x] 5 Phase - Semantic Event Normalization and Interaction Transport.

  Complete the browser-to-runtime half of the renderer loop. Bound listeners
  normalize native browser events into plain semantic interaction records and
  deliver them to the correct active root with exact ordering, validation, and
  backpressure. This is a local interaction path, not a Phoenix or Plug command
  channel.

  - [x] 5.1 Section - Authorize and freeze the interaction envelope.

    Bind the semantic event and renderer transaction contracts and decide what
    browser data may cross into the runtime.

    - [x] 5.1.1 Task - Record bounded Phase 5 authority.

      Establish exact inputs and prohibit server authority and component-model
      expansion.

      - [x] 5.1.1.1 Subtask - Record synchronized base, branch, section commits, one PR, cleanup, Phase 4 completion identity, and explicit Phase 5 authorization.
      - [x] 5.1.1.2 Subtask - Bind semantic bindings/events, listener projections, root/generation/revision state, runtime bridge, diagnostic classes, and applicable limits by version and hash.
      - [x] 5.1.1.3 Subtask - Exclude Phoenix/Plug commands, authorization, arbitrary JavaScript callbacks, new public component callbacks, file bytes/paths, and support claims.

    - [x] 5.1.2 Task - Freeze event mapping, cancellation, and ordering rules.

      Define closed payloads and browser default behavior for each supported
      semantic event before attaching listeners.

      - [x] 5.1.2.1 Subtask - Define native mappings and allowed normalized fields for activate, change, submit, select, expand, dismiss, move, reorder, increment, decrement, request-open, request-close, and request-page.
      - [x] 5.1.2.2 Subtask - Define listener options, prevent-default, propagation, composition, high-frequency coalescing, privacy filtering, and unsupported-event behavior explicitly.
      - [x] 5.1.2.3 Subtask - Define owner/source/listener ID, generation/revision, interaction sequence, transaction correlation, acknowledgement, rejection, timeout, and backpressure semantics.

  - [x] 5.2 Section - Implement browser event normalization.

    Convert browser events synchronously into bounded immutable records without
    retaining event targets or other host objects.

    - [x] 5.2.1 Task - Implement generated listener registration and cleanup.

      Attach only listeners declared by the committed transaction and scope
      every callback to its root generation.

      - [x] 5.2.1.1 Subtask - Register, replace, and remove listeners through the DOM applicator's node index with stable listener identities and exact-once cleanup.
      - [x] 5.2.1.2 Subtask - Reject duplicate, unknown, cross-root, stale-generation, or post-disposal listeners and events before delivery.
      - [x] 5.2.1.3 Subtask - Ensure listener closures retain no superseded projection, root, transaction, event object, or DOM subtree after replacement/disposal.

    - [x] 5.2.2 Task - Implement closed semantic payload extraction.

      Read only event-specific values required by accepted bindings and copy
      them into plain bounded data.

      - [x] 5.2.2.1 Subtask - Normalize activation, scalar value, checked/selection state, submit intent, pointer coordinates/deltas where authorized, reorder identity, and pagination/open-close intent.
      - [x] 5.2.2.2 Subtask - Normalize timestamp/order using the declared clock model while excluding DOM nodes, event objects, functions, cyclic values, arbitrary properties, credentials, and unrequested form fields.
      - [x] 5.2.2.3 Subtask - Enforce string/list/map depth, byte, item, coordinate, and rate limits with deterministic truncation prohibition and explicit rejection.

  - [x] 5.3 Section - Implement root-scoped interaction delivery.

    Route normalized events over the BH-03 runtime bridge and return correlated
    outcomes without confusing local events with trusted server commands.

    - [x] 5.3.1 Task - Implement interaction transport and sequencing.

      Maintain one ordered stream per root while allowing independent roots to
      proceed concurrently.

      - [x] 5.3.1.1 Subtask - Encode, validate, and deliver interaction envelopes to the owning runtime root using the negotiated bridge version and bounded queue.
      - [x] 5.3.1.2 Subtask - Reject wrong root/generation/revision/listener, duplicate sequence, replay, late delivery, disposed root, incompatible bridge, and oversized payload before component dispatch.
      - [x] 5.3.1.3 Subtask - Define high-frequency event coalescing, overload/backpressure, acknowledgement, cancellation on root loss, and diagnostics without blocking sibling roots.

    - [x] 5.3.2 Task - Integrate semantic dispatch and render correlation.

      Deliver accepted records to the existing semantic owner/source binding
      while keeping component behavior outside JavaScript.

      - [x] 5.3.2.1 Subtask - Resolve only committed binding identities and dispatch the accepted semantic event to the root-local Elixir execution path.
      - [x] 5.3.2.2 Subtask - Correlate resulting renderer transactions with the interaction sequence for diagnostics and measurements without requiring one transaction per event.
      - [x] 5.3.2.3 Subtask - Record local-event provenance distinctly from future remote command, server push, navigation, and capability-result messages.

  - [x] 5.4 Section - Phase 5 Integration Tests and Completion Evidence.

    Exercise native browser events through normalization, runtime dispatch, and
    a resulting DOM commit across isolated roots.

    - [x] 5.4.1 Task - Run interaction transport integration tests.

      Use real browser dispatch where available and deterministic synthetic
      fixtures for malformed, stale, replayed, and overloaded traffic.

      - [x] 5.4.1.1 Subtask - Test every supported event mapping, payload allowlist, prevent-default/propagation policy, ordering, acknowledgement, coalescing, and resulting semantic trace.
      - [x] 5.4.1.2 Subtask - Test unbound, malformed, cyclic, oversized, stale, duplicate, replayed, cross-root, post-disposal, and bridge-mismatch events with no runtime or DOM mutation.
      - [x] 5.4.1.3 Subtask - Drive multiple roots concurrently and prove independent ordering, bounded queues, listener cleanup, and no server/Phoenix/Plug traffic for local interactions.

    - [x] 5.4.2 Task - Publish Phase 5 completion evidence.

      Preserve normalized input/output traces and privacy/security review
      boundaries without claiming a public event API.

      - [x] 5.4.2.1 Subtask - Run Mix/Node/browser suites in Linux Chrome/Firefox, conformance and failure fixtures, validators, dependency/leakage audits, archive/generated checks, JSON validation, and patch hygiene.
      - [x] 5.4.2.2 Subtask - Publish browser fingerprints, event fixture hashes, exact commands/counts, rejection and cleanup traces, security/privacy observations, failures, and limitations.
      - [x] 5.4.2.3 Subtask - Mark Phase 5 complete only if every delivered event is bounded, attributable, root-local, and semantic; make Phase 6 eligible but unauthorized.

## Section delivery rule

Complete and verify each section before its commit. Open one pull request only
after Section 5.4 passes or records a stop decision. No browser event object,
server authority, or arbitrary callback may cross the interaction boundary.

## Connections

- [BH-04 plan](README.md)
- [Phase 4](phase-04-atomic-dom-application-root-queues-and-stale-rejection.md)
- [Host-neutral effects, capabilities, and resources](../../../20-notes/architecture-decisions/adr-0003-host-neutral-effects-capabilities-and-resources.md)
- [Server adapter and trust boundary](../../../20-notes/architecture-decisions/adr-0005-server-adapter-and-trust-boundary.md)

## Sources

- [BH-02 event/effect/resource fixtures](../../../../../integration/conformance/event-effect-resource-fixtures-v0.1.0.json)
- [Canonical acceptance registry](../../../assets/quality-acceptance/blazex-acceptance-registry-v0.1.0.json)
