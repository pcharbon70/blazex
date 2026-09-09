---
title: "BH-05 typed action and authority contract"
kind: note
created: "2026-09-09"
maturity: developing
tags: [bh-05, actions, effects, resources, commands]
aliases: []
---

# BH-05 typed action and authority contract

Implements [Phase 8](phase-08-effects-resources-and-typed-command-intent.md).
Base: accepted Phase 7 merge `08dec098fde98b506d554bf8c3ff64bc65de6add`.
Delivery: four verified section commits on `codex/bh05-phase8-actions`, one PR,
merge, checkout main, synchronize origin, then delete local/remote branch.
Preserve and restore unrelated root README and demo migration work separately.

## Scope and ownership

An explicit action-enabled root opts into this successor. Phase 6/7 default
APIs and normalized traces remain unchanged. Core owns closed portable records,
bounded scheduling, abstract action ports and root/component correlations.
The Effects package supplies outward capability-contract integration; UI-tree
owns declared callback admission and complete semantic candidates. Provider
configuration and handles remain runtime-private. No Core dependency on Effects,
UI-tree, a renderer, browser, OS toolkit or server framework is added.

Concrete Web API providers, uploads, navigation, persistence, arbitrary tasks,
Phoenix/Plug transport and server authorization are excluded. LiveView and
LocalLiveView remain deferred. ERTS execution does not grant Wasm parity or
support; the runtime-profile owner retains Phase 11 qualification.

## Closed records and static declarations

`Action` version 1 records have exactly `version`, `kind`, `id`, `sequence`,
`owner` and `body`. The owner is the existing plain component identity. IDs are
bounded names; sequences are positive safe integers, strictly increasing per
component incarnation. A candidate batch has at most 16 actions, 65,536 encoded
bytes, and no duplicate owner/ID. Each record is at most 16,384 bytes. Bodies are
closed per kind: local message, timer start/cancel, effect request/cancel,
resource transfer/release, and command intent. Legacy generic tuples are rejected
in action-enabled roots, even though Phase 7 retains its original tuple API.

Effect and command requests name static manifest declarations rather than
modules/functions, URLs, providers or transports. Declarations bind schema
version, public request/result/error schemas, permitted component public IDs,
capability/operation, fallback and resource acquisition allowance. Manifest
metadata is inspectable for BH-06 reachability and BH-07 registration without
dynamic module resolution. Explicit owner grants and actual component capability
declarations are both required for an effect request. Unknown or malformed
actions reject the entire candidate before renderer submission.

All public values pass portable-data, size and closed-schema validation.
Reserved authority/credential/transport/handle field names reject recursively.
This is structural prevention, not a claim to detect secrets hidden in arbitrary
strings: adapters and schema authors remain responsible for public-data policy.

## Commit barrier, results and bounds

Validation and reservation are side-effect-free. Action sequences and IDs are
consumed only by a successful semantic/renderer commit. No effect or command
submission occurs for a rejected candidate. Provider negotiation is a read-only,
deny-by-default abstract port. A negotiated provider/fallback name is metadata,
never a handle. Missing grants produce a typed denial/fallback outcome, not
an undeclared provider call.

Effect and command requests share a ceiling of **128 pending requests per root**.
Every pending request reserves one terminal-result slot in the existing
**256-work root bound**, including active work and candidate reservations.
Terminal results replace their reservation with FIFO work, so a full producer
queue cannot force loss of a previously admitted result. Result callbacks use
root `effect_result/1` or nested `handle_info/1`, with closed typed payloads;
they never receive arbitrary provider mailbox messages.

Request correlations include root instance/runtime owner, component identity,
generation, action ID and action sequence. Accepted, denied, completed, failed,
timed-out, canceled, stale and disconnected states are distinct. Accepted is
submission/progress accounting; a request has at most one terminal callback.
Timeouts are bounded to 10–60,000 ms and use private timer tokens. Unknown,
duplicate, wrong-owner, wrong-generation, late or post-disposal results reject
before callbacks. Callback rejection does not replay the external operation.
Provider outcomes are observations, not renderer commit authority.

The runtime never automatically replays requests, including non-idempotent ones,
after renderer rejection, crash/retry, reconnect or runtime loss. Idempotency
keys are advisory correlation data for a future authoritative adapter, not
permission for automatic retries. No unbounded seen-ID set is retained: bounded
per-incarnation sequence watermarks and full request correlations reject replay.
There are at most 128 owner watermarks per root generation, including removed
owners. A new owner beyond that budget is rejected until a new generation
commits. A rejected replacement cannot erase the old generation's watermarks.

## Leases and cleanup

At most **512 simultaneous leases** exist per root, including reserved potential
acquisitions. A request may declare at most 16 leases. Results admit only opaque
IDs of the declared kind; they cannot introduce provider objects or authority.
Each lease records current component owner, root generation, acquisition request,
opaque ID, bounded transfer history and release/terminal state. Active opaque IDs
are unique. Full acquisition correlation distinguishes reuse after release.
Public diagnostics expose the complete live inventory in pages of at most 128
leases, preserving the existing portable collection-size bound even at 512 leases.

Acquisition occurs when a valid provider result arrives, because the external
resource already exists. If its callback transition is rejected, newly acquired
leases are released rather than leaked. Transfers are same-root/generation only,
to live stateful/root identities and along statically allowed routes. Transfer
history is capped at 16. Unknown, duplicate, stale and post-disposal operations
reject without ownership changes. Acquired, transferred, released and lost
states are explicitly accounted for with bounded diagnostics.

Nested removal/replacement, root failure, shutdown and runtime loss produce
bounded cancellation/release work for the abstract provider. Phase 8 executes
deterministic cleanup port outcomes; Phase 10 owns expanded disposal coordination
and recovery. Release failure is recorded as lost, never as successful cleanup.
The guardian retains private bounded cleanup inventory for coordinator crashes.
No automatic resource reacquisition or request replay follows cleanup.
Cleanup ports must be idempotent: a crash between an external cleanup and its
checkpoint can repeat cancellation/release. This is not an exactly-once external
side-effect guarantee. A candidate may operate on a particular lease only once,
avoiding ambiguous transfer/release ordering within the same batch.

## Remote command trust

Command intent carries stable declaration/schema ID, public payload, correlation,
idempotency key, bounded timeout, local optimistic-revision annotation and public
result/error schemas. It is always labeled **untrusted client input**. There is
no component-supplied authorization decision or direct transport selection.
The future server adapter must independently authenticate, authorize, validate,
enforce idempotency, audit and normalize results. A deterministic adapter double
may deny the intent; a local capability grant never grants server authority.

## Evidence

Exercise delayed/denied/fallback/failed/timed-out/canceled/disconnected requests,
commit barriers, stale results, root isolation, owner removal, lease transfer/
release/loss, untrusted command denial and numeric/queue limits. Retain raw
pending/lease traces, normalized hashes, exact commands, failure attempts and
limitations. Run all current suites plus frozen Phase 7 and earlier validators;
do not rewrite sealed predecessor tools or accepted evidence. Only passing
source-frozen gates make Phase 8 complete and Phase 9 eligible, unauthorized.

## Connections

- [BH-05 plan](README.md)
- [Phase 7 scheduling contract](scheduling-contract.md)
- [Effect authority ADR](../../../20-notes/architecture-decisions/adr-0003-host-neutral-effects-capabilities-and-resources.md)
- [Server trust ADR](../../../20-notes/architecture-decisions/adr-0005-server-adapter-and-trust-boundary.md)
