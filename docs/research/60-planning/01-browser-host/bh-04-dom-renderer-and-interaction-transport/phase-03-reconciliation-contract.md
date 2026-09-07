---
title: "BH-04 Phase 3 Reconciliation Contract"
kind: note
created: "2026-09-07"
maturity: developing
tags:
  - bh-04
  - reconciliation
  - renderer
aliases: []
---

# BH-04 Phase 3 Reconciliation Contract

## Authority and compatibility

[Authorization](../../../assets/bh-04-baseline/blazex-bh-04-phase-03-authorization-v0.1.0.json)
binds the synchronized Phase 2 merge and inherited interfaces. Delivery has
four section commits and one merged PR, followed by synchronized main and
feature-branch deletion. The user expressly approved the protocol correction.

The v1 protocol and its fixtures remain immutable. The v2 candidate extends
the attribute vocabulary to every existing Lowerer attribute, including ARIA
relationships and logical layout. A bounded intent operation preserves complete
focus, selection and listener descriptions as canonical data, not host actions.
Its nullable old/new cells contain base64 of the unchanged canonical codec;
portable integer values use decimal strings, reversibly, to retain signed and
large semantic keys without changing the codec. Decoders validate the closed
intent grammar, including owner/source identities. This is an explicit major
wire version: v1 consumers cannot accept v2 transactions.

The neutral Session contract and historical DOM backend stay unchanged. The
new incremental backend implements the same callbacks. An acknowledgement-aware
facade holds provisional neutral sessions separately from the accepted session.
Existing full-root fixtures remain the migration oracle, not incremental credit.

## Identity and normalization

Continuity requires the same semantic root, complete path (including portable
key type), generation, node kind, compatible materialized tag and parent.
Missing explicit keys are allowed: identity path remains mandatory and stable.
Duplicate identities/keys, invalid portable keys, inconsistent parents and
invalid semantic trees reject atomically. No positional identity is invented.
Changing a parent requires a new semantic path: remove and insert, never an
implicit cross-parent move retaining an invalid identity.

Retained projection v1 contains immutable plain data, root identity, node
index, ordered children, listener/focus/selection intent, attributes, property
slots and canonical fingerprints. No host object or external mutable reference
is retained. Attribute maps become sorted name/value cells for canonical hashing.
Relationship targets must exist in the same final projection. Semantic input,
normalized state, codec and operation bounds are checked before publication.

## Diff and replacement policy

Compare IDs, then kind/tag/parent compatibility. Remove vanished or incompatible
subtrees postorder; recreate incompatible nodes and all descendants preorder.
Compatible nodes retain identity and get only changed text, attribute, property
or intent operations. Insertions and reorders are resolved right-to-left with
already attached next-sibling anchors. Relationships and intents follow final
topology; removals release listeners by explicit intent removal before deletion.
There are no executable resources in this phase; the terminal empty effect
barrier is only ordering data. Disposal releases the entire retained root.

A kind/tag change explicitly rematerializes that subtree. An authorized next
generation explicitly replaces the root. Invalid input, impossible ordering,
stale state and capacity overflow reject; no full-root fallback hides a defect.
No-op updates contain only the empty barrier. All operations depend on their
immediate predecessor, giving one canonical, dependency-safe order.

Limits inherit 128 nodes, depth 32, 512 operations, 256 listeners, 32 attributes
per node, 4096 text bytes, 2048 attribute/property value bytes and 131072 message
bytes. Work is bounded quadratic in nodes (ordered list comparison and topology
preflight), memory bounded by old/new projections and one transaction. Limits
may reject a valid but oversized semantic output; they never truncate it.

## Acknowledgement lifecycle

One proposal may be pending per root; supersession is explicitly rejected.
Accepted projection and neutral revision advance only on an exactly correlated
committed acknowledgement (disposed for disposal). Preflight/accepted progress
does not commit. Reject/rollback releases pending data and preserves accepted
state. Retry recomputes from accepted state with a new bounded attempt identity,
so a delayed acknowledgement cannot commit a later retry. Duplicate, wrong
generation, wrong digest, stale revision and post-disposal acknowledgements
reject without mutation. Terminal disposal is idempotent at the facade.

Protocol revision increases for every committed transaction, including mount
and disposal; the neutral Session retains its historical mount/replacement
revision convention. These are distinct counters, explicitly bridged by the
facade. Failure diagnostics are stable closed classes, not exception text.

## Evidence and exclusions

Section 3.4 must reconstruct every candidate projection through a pure data
model, compare the unchanged full-root lowering and headless semantic oracle,
exercise adversarial and generated traces, and compare Elixir/Node canonical
bytes. Browser DOM mutation, event handling, form/focus restoration, resource
execution, LiveView, browser qualification and support are excluded. Existing
external-platform deferrals remain owned by qualification owners for BH-22.
Phase 4 becomes eligible only after completion; it is not authorized here.

## Connections

- [Phase 3 plan](phase-03-keyed-incremental-reconciliation-and-deterministic-diffing.md)
- [Phase 2 design](phase-02-protocol-design.md)
- [Development policy](../../development-environment-and-deferred-qualification-policy.md)
