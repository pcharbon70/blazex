---
title: "BH-05 supervised root lifecycle contract"
kind: note
created: "2026-09-09"
maturity: developing
tags: [bh-05, lifecycle, supervision]
aliases: []
---

# BH-05 supervised root lifecycle contract

Implements [Phase 6](phase-06-process-root-local-view-lifecycle-and-supervision.md).
The [authority](../../../assets/bh-05-baseline/root-authorization-v0.1.0.json)
binds accepted Phase 5 merge `f2fdc745118f0ad84e5b3ab53ea9e5221310f957`.
Delivery: four verified section commits on `codex/bh05-phase6-root-lifecycle`,
one PR, merge, checkout main, synchronize origin, then delete the feature branch.
Unrelated README/demo edits are preserved separately. No later phase is authorized.

## Ownership and ports

Core owns an independently supervised root coordinator and its final/candidate
records. It imports no UI-tree, concrete renderer, host, browser or runtime
adapter. Trusted composition supplies evaluator, commit and host port modules
and private configuration. Component callbacks receive only validated Phase 2
immutable envelopes. Port configuration, evaluator tokens, process references,
renderer objects and accepted framework records never enter those envelopes.

Start data binds root, unique instance, owner correlation, public component ID,
static root-role module, schema-normalized bootstrap props/slots, declared
capabilities, fallback contract (`none` or an inert public fallback ID), and a
bounded acknowledgement deadline. Fallback execution is deferred. The evaluator
normalizes input before a process starts and prepares mount/update/replacement
candidates. It returns a Core candidate with a portable state summary, state
and semantic-output digests, exact correlation, and an opaque private token.
That token retains the candidate table, output and disposal plan outwardly;
Core stores it without interpreting concrete semantic types.

The renderer port submits one correlated candidate or disposal, and cancels
an abandoned transaction. It must acknowledge only after its atomic commit or
confirmed rollback. The host port receives bounded registered, pending, ready,
rejected, removal/shutdown, disposed and crashed records; no props, state, error
terms, stack traces, PIDs or adapter objects. These are trusted runtime ports,
not browser message authentication. Browser wire translation remains outward.

Public handles contain root/instance/owner only. The runtime supplies a private
supervisor reference; OTP child startup necessarily uses PIDs internally, never
as component references. One temporary guardian per root monitors its linked
coordinator, preserves redacted terminal metadata (including untrappable kill),
and does not restart or replay it. Terminal handles remain inspectable until an
explicit new instance replaces the terminal child. Sibling guardians survive.
Root IDs are unique within that supervisor; instance IDs must not be reused.

## State machine

| State | Legal next states and cause |
| --- | --- |
| dormant | starting after validated explicit start |
| starting | mounting; failed on startup failure |
| mounting | evaluating |
| evaluating | awaiting-commit; ready on rejected update; failed on rejected mount |
| awaiting-commit | ready on exact commit; ready on confirmed rejected update; failed on mount rejection or uncertain rollback; stopping on removal/shutdown |
| ready | updating, replacing, stopping; failed on crash |
| updating | evaluating |
| replacing | evaluating; old accepted generation remains final until commit |
| stopping | disposed after disposal acknowledgement and callback cleanup; failed on cleanup/acknowledgement failure |
| disposed | terminal; explicit new instance starts a new lifecycle |
| failed | terminal; explicit new instance only, no retry/replay |

Mount begins at generation 1/revision 0/sequence 0 with no accepted table.
Each submission has root, instance, owner, generation, proposed revision,
monotonically increasing attempt sequence, operation and transaction ID.
Updates propose accepted revision + 1; replacement proposes generation + 1
and revision 1. Failed attempts consume sequence numbers but do not change
accepted counters/digests. Duplicate, stale, wrong-owner and wrong-operation
acknowledgements cannot promote a candidate. Counters use safe integers.

At most one transition is admitted; busy requests reject rather than entering
a framework backlog. Core copies candidate state/output/table into final
ownership only on the exact commit acknowledgement. No-op updates still commit
a new revision. Semantic rejection never submits. Confirmed renderer rejection
preserves the old final record. Lost acknowledgement triggers cancellation;
only confirmed cancellation permits return to ready. Uncertain cancellation
fails closed, never declaring the renderer and final state synchronized.

Replacement initializes a fresh complete root generation. Old nested disposal
and root termination are planned during evaluation and executed only after the
replacement commit. Stop/removal first invalidate admission, cancel pending
work, submit renderer disposal, then execute deepest-first nested disposal and
root termination exactly once after disposal acknowledgement. Failures are
terminal and redacted, never implicit retries. No new candidate is published
after terminal admission closes. A crash cannot promise external cleanup.

## Reviewed successor changes and limits

The existing private composition planner and nested callback engine gain an
explicit root-enabled mode. Default pure and Phase 5 mixed-role behavior stays
unchanged. A new outward root evaluator uses that mode and full semantic
acceptance; it does not call Phase 5 reconciliation (which disposes before
return). Root-owned candidate tables and deferred disposal are separate from
Phase 5's immutable accepted nested table contract. All callback envelopes are
validated, including disposal/termination payloads.

Inherited bounds remain: depth 12, 128 invocations, 256 nodes, portable state,
stable nested keys. Root Phase 6 rejects action emissions, including parent
notifications; event/message dispatch and effects are not activated here.
No user handle_info, event backlog, application timers, effect/command execution,
context/registry resolution, automatic recovery, LiveView or LocalLiveView.
Acknowledgement deadlines are coordinator infrastructure, not application timers.
Callbacks and ports are trusted, terminating code; this is not a preemptive
sandbox or an external side-effect rollback guarantee. Digests are ERTS integrity
observations, not authentication or AtomVM byte-for-byte parity. ERTS execution
and a pinned AtomVM supervision compatibility analysis are distinct evidence;
Wasm execution parity remains Phase 11. Support remains unsupported.
