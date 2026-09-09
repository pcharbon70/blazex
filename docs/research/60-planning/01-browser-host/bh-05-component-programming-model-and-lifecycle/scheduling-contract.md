---
title: "BH-05 bounded root scheduling contract"
kind: note
created: "2026-09-09"
maturity: developing
tags: [bh-05, scheduling, events, messages, timers]
aliases: []
---

# BH-05 bounded root scheduling contract

Implements [Phase 7](phase-07-event-message-timer-and-transition-scheduling.md).
The [authority](../../../assets/bh-05-baseline/scheduling-authorization-v0.1.0.json)
binds Phase 6 merge `e373e96891207ea4b6c2fdfae9533181334b3cab`.
Delivery: four verified section commits on `codex/bh05-phase7-scheduling`, one PR,
merge, checkout main, synchronize origin, then local/remote branch deletion.
Preserve and restore the unrelated README and `demos/browser` migration separately.
Only Phase 7 is authorized; Phase 8 and BH-06 remain unauthorized/ineligible.

## Opt-in ownership and ingress

Scheduled roots opt in through a new public scheduling API and a static,
validated runtime policy. Existing Phase 6 LocalView calls retain their default
busy-reject behavior. Scheduled roots use the same private coordinator and
outward evaluator/renderer/host ports, not a second component-state owner.
Core imports no concrete UI-tree or renderer. Components never receive a PID,
port configuration, renderer object, opaque evaluator token or framework state.

Policy declares producer capabilities, source public component IDs, permitted
work classes/routes and bounded event/message schemas. Policy is trusted runtime
configuration, not data supplied by an event producer. Named capabilities are
authorization inside that composition, not authentication of browser wire data.
Outer host/transport adapters still authenticate and normalize their boundary.
No new component registry, arbitrary external send or server transport is added.

Every ingress envelope binds root handle, current generation/revision, producer,
producer sequence, class, source, target, name, portable payload and explicit
supersedability. Producer sequences are exact next integers, bounded by the safe
integer limit. Accepted/coalesced work consumes its sequence; rejected admission
does not. Each accepted item also receives a root-global receipt sequence, which
is separate from the renderer attempt sequence and remains unique across rejects.
Source/target identities and component fingerprints bind admission to committed
instances. Event bindings are resolved outwardly against committed semantic
output, never through a DOM handle.

## Queue, priority and revision rules

All application work uses stable FIFO receipt order. Control acknowledgements,
stop/removal/runtime loss, cancellation and internal cleanup bypass the work
queue. No application class has priority over another, so accepted older work
cannot starve behind newer work. Each root schedules independently.

The hard total budget is **256**, counting queued work, one active application
transition and candidate-reserved follow-up messages. Event work may use that
budget; updates, messages and timer ticks additionally have per-class bounds.
There are at most 32 active owned timers. Every admitted envelope and policy
schema is closed and size-bounded. Overload rejects explicitly before callbacks.
Metrics expose current/max depths, per-class depths, coalesced/rejected counts,
receipt order and bounded timer inventories, never payloads or private handles.
This bounds normalized framework work, not the raw VM mailbox of privileged
code that bypasses the public API; arbitrary mailbox values never invoke user
handle_info and are discarded with bounded diagnostics.

Coalescing is opt-in for declared supersedable event/update streams only, and
only replaces an equivalent queued tail (same producer/class/source/target/name).
It never replaces in-flight work or crosses another receipt. The superseded
receipt gets one terminal coalesced outcome; the replacement has its own receipt.
Messages and timer ticks are not implicitly merged.

Admission requires the currently committed generation/revision. Already-admitted
work may observe revision advances caused by earlier accepted FIFO work, but
dispatch revalidates generation, binding, source/target existence and fingerprints.
Replacement/removal invalidates old-generation/removed-owner work. Fresh ingress
with a stale revision, duplicate sequence or superseded instance rejects.

## Candidate and outcome ordering

One application transition is selected only when no renderer transaction is
pending. Evaluator admission is read-only; callbacks execute only at dispatch.
The outward scheduled evaluator returns a correlated semantic candidate plus
bounded typed follow-up intents. Core validates those intents and reserves
their queue/timer capacity before renderer submission. Rejection discards
candidate state and candidate-only work. Commit promotes state/output first,
performs removed-owner cleanup/cancellation, then admits follow-up work in
deterministic order. No message or timer emitted by a rejected candidate runs.

Each accepted application receipt emits exactly one redacted correlated terminal
outcome: committed, rejected, coalesced or canceled. Renderer correlation remains
the Phase 6 root/instance/owner/generation/revision/attempt/transaction record;
event/message/timer evaluations use its update operation. Scheduling resumes
only after the preceding commit or confirmed rollback/rejection is terminal.
Uncertain rollback fails the root and drops outstanding work. Cleanup failure
after renderer commit retains the committed final state but never reports ready.

## Dispatch and owned timers

Semantic events resolve committed bindings and a root/stateful callback target;
pure, missing, unbound or replaced targets reject. Typed messages use declared
names/schemas and explicit self, child, parent or root routing. Child means an
authorized descendant; parent is the nearest stateful ancestor. Message/timer
delivery invokes declared handle_info with an immutable typed envelope, never
an arbitrary received VM message. Root/nested callbacks remain facade-audited.

Message and timer action tuples are interpreted only in scheduled mode. Other
effects, commands, releases and provider results remain rejected. Candidate
intents are validated against the complete candidate tree before publication;
their recipients are rechecked against the committed tree at dispatch.

Timers have stable ID, owner, generation and monotonically distinct registration
identity; private wake-up references never leave runtime ownership. Delays and
repeat intervals are bounded. Repeating timers use fixed-delay scheduling with
at most one outstanding tick per timer, not catch-up bursts. Ticks use the same
admission queue and typed schema checks as messages. A terminal tick permits the
next repeating wake-up; one-shot timers terminate once. Late, duplicate,
canceled and wrong-generation wakes never invoke callbacks.

Explicit cancellation, owner removal, generation replacement, root failure,
disposal and runtime loss cancel timer resources and queued ticks. Stop drops
queued application work with cancellation outcomes rather than draining callbacks
after admission closes. Internal timer/cleanup terminal accounting is bounded;
there is no automatic replay or restart policy.

## Evidence and limits

Integration must cover committed event/message order, self/child/parent routes,
one-shot/repeating timers, cancellation races, nested removal, root replacement,
shutdown and independent roots. Producer-above-consumer stress retains raw depth
samples and normalized trace hashes and must prove the hard 256 budget. Preserve
accepted Phase 6 tests and frozen historical evidence through a successor
validator, not edits to sealed predecessors.

ERTS/headless execution is distinct from Wasm parity. Phase 6's pinned
supervision/Popcorn analysis and Phase 11 runtime qualification limits remain.
Callbacks/ports are trusted terminating code, not a preemptive sandbox. Effects,
provider results, commands, forms, context/registry resolution, retries and
support claims are excluded. LiveView and LocalLiveView remain deferred.
