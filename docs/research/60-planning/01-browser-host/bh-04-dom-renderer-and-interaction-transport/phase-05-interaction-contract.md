---
title: "BH-04 Phase 5 Interaction Contract"
kind: note
created: "2026-09-08"
maturity: developing
tags:
  - bh-04
  - interaction
  - browser
aliases: []
---

# BH-04 Phase 5 Interaction Contract

## Authority and compatibility

The [authorization](../../../assets/bh-04-baseline/blazex-bh-04-phase-05-authorization-v0.1.0.json)
binds accepted Phase 4 and inherited implementation inputs. This phase adds the
local event return path, not a public component API, remote command channel,
server authorization mechanism, or browser-support decision. Sections 5.1–5.4
are delivered separately, followed by one PR, merge, synchronized main, branch
deletion and exact restoration of unrelated work.

The legacy `blazex.host-bridge/1` operation allowlist has no semantic interaction
operation. It remains immutable. A separately negotiated
`blazex.host-bridge/2` interaction extension supports only `root.interaction`
and `root.render_ack`; it does not reinterpret `fixture.event`. Legacy
root lifecycle operations continue through the BH-03 owner. A compatible
runtime must explicitly supply the v2 endpoint; unsupported negotiation rejects
before event delivery. No implicit fallback to a fixture or remote server.

## Closed mapping and browser behavior

Only committed binding projections create listeners. Native mappings retain
the existing renderer vocabulary:

| Semantic event | Native event | Semantic payload |
| --- | --- | --- |
| activate | click | empty intent |
| change | input | value and checked state of the bound control |
| submit | submit | empty intent; no form enumeration |
| select | change | value and checked state of the bound control |
| expand, dismiss | click | empty intent |
| move | pointermove | x/y, dx/dy and buttons, all finite and bounded |
| reorder | drop | bound source identity only; no DataTransfer access |
| increment, decrement | click | empty intent |
| request_open, request_close, request_page | click | empty intent |

No implicit page number, dragged foreign identity, form fields or modifier
payload is invented. Later semantic features require explicit authored intent.
Listeners use capture false and passive false. A supported, accepted event
prevents its cancelable native default and stops propagation. Rejected events
are not delivered. There is no generic event delegation: target and currentTarget
must be the declared owned Element. Descendant bubbling does not grant authority
to an ancestor binding. Browser-generated button clicks provide keyboard
activation; raw key events are not transported.

Composing scalar input is suppressed until a subsequent non-composing input
event; no composition buffer or inferred commit is created. Password, file,
hidden and credential-designated controls are rejected; file names/paths/bytes,
clipboard and DataTransfer data are never read. Scalar strings are limited to
2,048 UTF-8 bytes without truncation. Coordinates/deltas must be finite and
within ±1,000,000; buttons are integers from 0 to 31. Payload maps are closed.
Events, nodes, functions, cyclic objects, prototypes, accessors and unknown
properties cannot cross the boundary.

## Identity, clocks and resource limits

The `blazex.interaction/1` record carries local-event provenance, BH-03 root ID
and lifecycle generation, semantic owner/source/listener identities, committed
semantic generation/revision, last transaction ID/digest, sequence, normalized
timestamp and closed payload. Listener IDs derive from semantic node ID and
event name; generation/revision distinguish replacement lifetimes. The runtime
resolves identities against committed bindings, never by creating atoms from
wire data or trusting an arbitrary component name.

Sequence is a positive safe integer, strictly increasing per attached root.
It is the ordering authority. Timestamp is an owner-clock monotonic millisecond
observation, not a native Event timestamp, wall-clock claim or authorization
input. Wire records are bounded to 8,192 UTF-8 bytes, depth 6 and 64 items.
Per-root queues hold at most 64 active/pending records. No event coalescing is
authorized in this phase: overload rejects the incoming record explicitly.
There is no silent truncation, replay or retry. One root cannot hold another
root's queue. Admission and transport outcomes contain bounded diagnostic codes,
not copied payloads or exception messages.

## Dispatch, render correlation and cleanup

Only a ready BH-03 root with a committed projection may deliver. DOM application
suspends event capture; rollback restores the old binding set, commit publishes
the new set, and quarantine/disposal clears listeners and cancels pending work.
Listener closures keep only a controller and stable ID; registry entries are
removed exactly once and contain no superseded projection or transaction tree.

The owning runtime validates the complete envelope, compatibility, ownership,
committed binding, generations/revision, sequence and render correlation before
`ComponentEvaluator.dispatch` receives an existing `Core.Event`. Component
behavior remains Elixir. Event emissions are not executed by this phase.
Render results use the Phase 3 reconciler and Phase 4 atomic applicator.
Interaction acceptance and resulting DOM commit are separate correlated
outcomes; an event need not cause a render. No proposed semantic/render state
is mistaken for acknowledged DOM state. The render acknowledgement returns to
the root-local session before dependent interactions proceed.

Timeout defaults to 5,000 ms and never exceeds 10,000 ms. Loss, disposal,
replacement and uncertain timeout stop the affected stream, settle queued
requests once and reject late results. Recovery requires a fresh compatible
attachment; neither arbitrary callbacks nor retry loops repair uncertain state.

## Evidence and limits

Section 5.4 must execute every mapping, privacy rejection, queue boundary,
lifecycle cancellation, semantic dispatch and resulting atomic DOM commit in
the active Linux Chrome/Firefox matrix. Test-only transport and actual runtime
execution must be distinguished explicitly; fixture acknowledgements alone
cannot establish semantic dispatch. Source-bound Mix/Node, cross-language,
governance, dependency/leakage, archive, generated, JSON and patch checks are
required before completion. Phase 6 remains unauthorized until Phase 5 passes.

[DEFERRED] Unavailable OS/browser/device/manual-AT qualification remains with
the inherited platform, browser and accessibility owners, reactivating by BH-22.
It receives no pass or support credit under the [development policy](../../development-environment-and-deferred-qualification-policy.md).
