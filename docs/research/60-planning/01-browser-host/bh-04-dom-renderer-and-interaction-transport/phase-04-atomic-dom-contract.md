---
title: "BH-04 Phase 4 Atomic DOM Application Contract"
kind: note
created: "2026-09-07"
maturity: developing
tags:
  - bh-04
  - dom
  - reliability
aliases: []
---

# BH-04 Phase 4 Atomic DOM Application Contract

## Authority and inputs

The [authorization](../../../assets/bh-04-baseline/blazex-bh-04-phase-04-authorization-v0.1.0.json)
binds Phase 3 completion, the v2 protocol, retained lifecycle and accepted BH-03
root/runtime lifecycle sources. Delivery uses four section commits and one PR,
then merge, synchronized main and feature-branch removal. Unrelated user work
is preserved. V1/v2 wire schemas and the neutral kernel remain unchanged.

## Ownership and sequencing

An additive owner creates a real BH-03 BrowserRootRegistry and forwards its
synchronous lifecycle transitions to the applicator. Only handles registered
by that owner may attach. Containers are explicit Element capabilities, must
start empty, and cannot overlap or be shared. No document-wide selector lookup
resolves transaction targets. BH-03 operation generations and semantic renderer
generations are distinct: a lifecycle epoch invalidates pending browser work;
semantic generations change only through an authorized next-generation replace.
A disposed binding is terminal; remount requires a newly attached binding after
a fresh acknowledged BH-03 mount, never reuse of an old capability.

One FIFO per root holds at most 64 admitted records including in-flight work.
Overflow rejects the incoming request terminally without modifying admitted work.
There is no coalescing: every v2 transaction asserts a dependent base revision.
Independent roots have independent pumps, so slow digest/preflight on one root
cannot block another. Admissions copy bounded data. Complete schema, digest,
owner, generation, revision, dependency, target, topology, old-value, intent,
relationship and capacity checks precede the first live mutation.

Each admitted request settles once with one terminal correlated acknowledgement.
An accepted progress acknowledgement is emitted at most once after preflight.
Rejected/rolled-back/fallback/disposed outcomes are explicit. Uncorrelatable
malformed headers fail with a bounded local error rather than forged identity.
Observer callback exceptions cannot change committed state or duplicate outcomes.
Replacement cancels already queued prior-generation work. Lifecycle disposal,
loss, shutdown and recovery invalidate the binding and deterministically drain
pending work. No unbounded retry or automatic runtime recovery occurs here.

## Atomic mutation and recovery

The applicator derives a complete next plain projection with pure preflight.
New nodes are created detached. Whitelisted tags/attributes/properties and
closed intent data are applied in canonical order; compatible nodes retain
their actual Element identities. IDs, parents, anchors, child order, text,
attributes and controlled properties are checked against owned materialization.
External DOM edits reject before mutation. Relationship targets must exist in
the final owned projection. Event listeners are installed as inert owned
handlers: event delivery is Phase 5. Focus/selection behavior is limited to the
existing projection intent, not user-edited form continuity.

Atomicity means one synchronous commit job, one acknowledged outcome, and a
settled owned tree equal to the complete previous or next projection. It is not
a claim that MutationObserver records hide intermediate operations. Custom
elements, arbitrary markup, script, style, URL attributes and effect execution
are prohibited. No asynchronous boundary is allowed inside live mutation.

A bounded journal retains original Elements and the last-valid plain projection.
Failure at any operation boundary restores old attributes/properties/text,
child order and owned listeners using those Elements. Restoration is verified.
If restoration fails, only that root is quarantined and a single detached
last-valid reconstruction is attempted. If that fails too, an inert bounded
fallback is attempted and the root remains quarantined, never accepted as a
partial commit. Sibling roots remain untouched. Abandoned nodes, listener
handles and queued data are released; no automatic retry follows quarantine.

## Budgets, diagnostics and evidence

Inherited limits: 128 nodes, depth 32, 512 operations, 256 listeners,
32 attributes per node, 4096 text bytes, 2048 value bytes and 131072 wire bytes.
The journal and candidate are each bounded by one projection; queues contain
at most 64 bounded records. Work follows bounded pure preflight plus bounded
DOM traversal. Protocol diagnostic classes remain unchanged; malformed,
ownership, stale, duplicate, missing-target, limit, apply, rollback and
disposed-root distinguish terminal outcomes.

The integration gate must replay actual Phase 3 transactions through real
BH-03 root handles in fake DOM, Linux Chrome and Linux Firefox; exercise all
operation boundaries, stale traffic, independent roots, overflow, replacement,
disposal/remount and runtime loss/shutdown. Browser versions and raw traces
are recorded separately from support claims. Existing unavailable-platform
and manual-AT obligations remain with qualification owners, due by BH-22.

Phase 5 becomes eligible only after verified completion and is not authorized.

## Connections

- [Phase 4 plan](phase-04-atomic-dom-application-root-queues-and-stale-rejection.md)
- [Phase 3 evidence](phase-03-implementation-evidence.md)
- [Development policy](../../development-environment-and-deferred-qualification-policy.md)
