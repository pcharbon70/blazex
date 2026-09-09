---
title: "BH-05 nested state and reconciliation contract"
kind: note
created: "2026-09-09"
maturity: developing
tags: [bh-05, state, identity, reconciliation]
aliases: []
---

# BH-05 nested state and reconciliation contract

Implements the [Phase 5 plan](phase-05-nested-stateful-identity-and-update-reconciliation.md).
The [authority record](../../../assets/bh-05-baseline/nested-authorization-v0.1.0.json)
binds accepted Phase 4 merge `ea09d05a2709a163ff0c8776c4039f1a712a95de`.
Owner delivery is four verified section commits on `codex/bh05-phase5-nested-state`,
one PR, merge, checkout main, sync origin, then branch deletion. Preserve unrelated
README/demo work. No later phase is authorized by this work.

## Ownership and API

`BlazeX.Component.NestedTable` owns immutable root/revision/sequence and instance
records without depending on UI Tree. `BlazeX.UITree.Nested` owns in-memory
mount, reconcile and local event candidates plus complete semantic acceptance.
Sessions are trusted opaque in-memory values, not host-deserializable authority.
Digests detect accidental drift, not forgery or authentication.

The Phase 4 static invocation graph, schema, identity, traversal and bounds are
retained. A reviewed internal planner extension admits pure and stateful modules
for this successor; default pure-only evaluation remains unchanged. The root
record remains pure and stateful records must be nested. No root process is
started. Props and slots are normalized parent-controlled snapshots; retained
local state is portable component-owned data, never a mutable parent reference.
No closures or opaque handles are admitted to a retained invocation/state.

Every accepted record contains identity, parent, static module/public ID, role,
schema/contract fingerprint, normalized invocation/digest, state, output digest,
generation, revision, sequence, accepted status and empty owned action references.
Pure/inert records have absent state. Stateful records have present portable
state. The accepted table and output advance together, never by in-place edits.

## Transitions

Mount plans the whole graph, then traverses parent-first: stateful `init`, then
`render`; pure `render`; inert slots contribute data. Initialization permits only
`{:state, portable}`. Compatible reconciliation compares normalized props/slots,
not map insertion order or child position. Changed input invokes optional
`update`; absent callbacks or `:no_change` preserve local state. Every compatible
component still renders, even on a no-op. Revisions advance once per accepted
root transition, including no-ops. Rejected transitions preserve the exact prior
session and its counters. Counters are safe integers, never wrapped.

Local event candidates use an existing semantic Event with the shared root as
owner, a bound source in the accepted document, matching generation, the next
global sequence and an expected current revision. Routing selects the nearest
stateful source ancestor and invokes its optional `handle_event`. Unbound events,
missing handlers and stale/gapped sequences reject; no mailbox is involved.
The callback receives a portable name/data/source payload, not a component
handle. Accepted event candidates rerender the complete graph atomically.

Update/event results may be `:no_change`, `{:state, portable}`, or a bounded
`{:actions, portable, [{:message, "parent", %{name: semantic_event, payload: map}}]}`.
Only these typed child-to-parent notification candidates are retained in the
transition result. Their target is the nearest stateful parent or shared root.
They are not delivered, recursively executed or sent externally. Effects,
commands, timers, releases, arbitrary closures and direct child calls reject.
Initialization/render/disposal cannot emit notifications. Total notifications
per root transition are limited to 128; owned resource/action references stay
empty because Phase 8 authority and execution are not active.

## Identity and replacement

Explicit structural keys survive reorder only within the same parent scope.
Optional ordinal slot keys cannot carry retained state in this phase. Parent,
public ID, call site or key changes are removal/insertion, not a cross-parent
move. A same-identity module, role or schema fingerprint change requires an
explicit replacement path in the reconcile request. Replacing a parent also
replaces its descendants. Unknown/redundant replacement paths reject.
Root generation may remain equal or advance exactly once; advancing it replaces
all instances, while a changed root ID or stale generation rejects. No implicit
state migration occurs: replacement means dispose old and initialize new, not
an invocation of the optional future `replace` callback.

New candidate initialization/render and complete semantic acceptance happen
before disposal callbacks. Removed/replaced stateful records dispose deepest
first, with reverse accepted traversal order breaking ties. Optional `dispose`
accepts only `:ok`; its rejection/exception rejects the whole transition. Plans
contain public identity/reason/state digest and callback outcome, not state or
resource handles. Failed candidate state/actions/output/disposal observations
are discarded. Pure code and disposal callbacks remain trusted and must be
side-effect free: this phase does not roll back arbitrary external side effects.

## Atomic acceptance and traces

Existing semantic constructors validate the complete output. Accepted output,
all records, counters, notifications and disposal plans publish together.
Public traces identify init/update/no-change/render, typed notification,
retain/insert/replace/remove, disposal and final digests without raw props/state,
private module names, clocks, PIDs, exception details or stack traces. Rejection
returns one fixed diagnostic/trace and the unchanged prior session. ERTS
deterministic term encoding provides output/table/trace hashes, not Wasm parity.

## Deferrals

All nested state shares one future root process and failure boundary. No
GenServer, mailbox scheduling, external messages/timers, concrete effects,
commands, renderer commit, dynamic registry/context resolution, independent
subtree recovery, LiveView or LocalLiveView is implemented. Trusted build code
and import checks are not an adversarial Elixir sandbox or termination proof.
Phase 6 becomes eligible only after Phase 5 gates pass; it remains unauthorized.
