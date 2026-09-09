---
title: "BH-05 Phase 7 bounded local scheduling evidence"
kind: note
created: "2026-09-09"
maturity: developing
tags: [bh-05, scheduling, timers, conformance]
aliases: []
---

# BH-05 Phase 7 bounded local scheduling evidence

Implements the [Phase 7 plan](phase-07-event-message-timer-and-transition-scheduling.md)
and [scheduling contract](scheduling-contract.md). The
[authority](../../../assets/bh-05-baseline/scheduling-authorization-v0.1.0.json)
binds accepted Phase 6 merge `e373e96891207ea4b6c2fdfae9533181334b3cab`.

## Delivery and ownership

Four verified section commits on `codex/bh05-phase7-scheduling`, one PR, merge,
checkout main, synchronize origin, then local/remote feature-branch deletion.
Unrelated README and demo migration work is retained in a stash and restored
after cleanup. External delivery is pending when immutable evidence is created.

Core owns opt-in typed ingress, immutable bounded queues, private coordinator,
owned timer tokens, guardian crash accounting and abstract scheduling ports.
The outward UI-tree evaluator resolves committed bindings and executes declared
root/stateful callbacks against immutable candidates. The concrete headless
renderer remains outside Core. Default Phase 6 LocalView behavior and its three
normalized integration digests remain unchanged.

`ScheduledView` uses a static producer policy, declared event/message schemas,
identity-only handles and exact producer sequences. These local capabilities
are not browser authentication. Renderer acknowledgement, stop, replacement,
runtime loss and explicit timer cancellation bypass application FIFO work.
Cancellation remains admissible when that queue is full. A valid replacement
request cancels old queued work and timers before preparing its new generation;
a malformed or stale replacement request does not cancel anything.

## Executed coverage and retained records

The [source inventory](../../../../../integration/bh-05/scheduling-index-v0.1.0.json)
binds the public fixtures, runtime implementations, package tests, limits and
normalized digests. The
[gate record](../../../assets/bh-05-baseline/scheduling-gates-v0.1.0.json) retains
exact commands, output, raw queue samples, outcome order and terminal timer
inventory. The
[completion record](../../../assets/bh-05-baseline/scheduling-completion-v0.1.0.json)
binds authority, gates and inventory.

The overload script holds a renderer transaction while admitting 256 total
items, including that active item. A 257th accepted receipt replaces an explicitly
supersedable queued tail; the next admission is rejected without consuming its
producer sequence. Raw depths are `1..256, 256, 0`. Exactly 256 receipts commit,
one is coalesced, and one unadmitted attempt is rejected. Committed receipts are
`1..255, 257`, in that order. Independent semantic construction verifies every
candidate, and a separate headless session verifies final rendered content,
bindings and accessibility, excluding renderer-local revision/digest fields.

- Sample digest: `384aec1f071fbfd8e24382f908b98ea87400dcd0ca3764ea78b692f888027764`.
- Outcome trace: `35cb4e2c103c987180e5a1af4949a169f194faf2efe93b4e565eb12d90b93b74`.
- Final state: `3b2d037102c2f2cc0924d679ed166e850eab0370808e16a2c1817a351eae78f4`.

Other integration cases interleave child messages, parent messages, root events,
parent updates and renderer commits across independently progressing roots.
A trusted test-owned graph snapshot models nested removal, without introducing
a runtime component registry. Removal preserves the child's timer until commit,
then cancels it and the queued child message. The terminal timer inventory has
zero active entries and one cancellation. Rejected renderer transactions,
replay, bad schemas, foreign targets and late acknowledgements preserve both
accepted component summaries and renderer state.

One-shot and repeating ticks also execute through the real UI-tree evaluator
and headless renderer. Explicit cancellation rolls back an in-flight repeating
tick and rejects its late acknowledgement without changing accepted state.

Core/UI-tree tests additionally cover pure emitters and nearest stateful event
owners, self/child/parent/root routing, declared schemas, unbound/pure targets,
counter reservations, per-class limits, candidate-only actions, one-shot and
fixed-delay repeating timers, forged/duplicate/old-epoch ticks, owner replacement,
priority cancellation of an in-flight tick, shutdown, runtime loss, unknown
mailbox input and crash accounting. Messages and timer actions are validated
before renderer submission and executed only after commit. Rejection discards
them. Repeating timers have only one outstanding tick and rearm after its terminal
outcome. Direct VM messages never become component `handle_info` calls.

## Gate method and limitations

`python3 docs/research/70-tools/record_bh05_phase7.py` records 18 ordered gates
against identical before/after source hashes and publishes only complete passes.
The package/conformance gate covers Core, Effects, UI-tree, Renderer, Headless,
DOM, Test and the ERTS scheduling stress fixture. Other gates cover JavaScript,
compile fixtures, pinned Popcorn patch/subset analysis, frozen Phase 6 through 1,
the BH-04 corrective replay, the historical Python sweep, seven current mutation
groups, current validator/generator, archive links, all JSON and patch hygiene.
Predecessor validators, accepted hashes and evidence are never rewritten.

The first integration run exposed two fixture errors: its removal graph retained
an unreachable child, and its independent artifact assertion used a nonexistent
field. The fixture now removes that graph entry and compares the public snapshot
content. The passing rerun retained the expected bounds and ordering.

Final review found that explicit cancellation also needed to remove queued and
candidate-only timer registrations, not only active resources/ticks. A regression
test now covers both cases. The initial gate attempt was retained at
`/tmp/bh05-phase7-gates-o470T2/execution.json`; its source closure became stale
during this correction and its inventory checks failed, so it was not published.
The complete gate run was repeated against the corrected, frozen sources.

Final result: all **18 gates passed**, with **1,059 source hashes unchanged**
before and after `/tmp/bh05-phase7-final-gates-mlx4EG/execution.json`.
The package/conformance gate passed **335 tests**: Core 64, Effects 9, UI-tree 53,
Renderer 8, Headless 6, DOM 116, Test 3 and Conformance 76. Compile fixtures passed
five tests; current evidence mutations passed seven groups. Archive validation
checked 270 documents and 30 directories. The committed gate record retains the
exact results without requiring the temporary output path.

This is ERTS execution evidence, not Wasm execution parity or support promotion.
The [inherited runtime analysis](root-supervision-compatibility.md) still applies:
standalone AtomVM 0.6.6 is incompatible, Popcorn patches/upstream APIs are analyzed
only, and the runtime-profile owner must qualify Wasm execution, packaging and
crash-log privacy in Phase 11. Timers use the same process timer primitives plus
private reference tokens; the subset check is not an execution test.

Callbacks and ports must terminate; this is not a preemptive sandbox or a bound
on the raw VM mailbox. Receipt delivery is an in-process host observation, not a
durable exactly-once transport across loss of the whole VM. No effects/provider
results, remote commands, dynamic registry/context, forms or automatic restart
are enabled. LiveView and LocalLiveView remain explicitly deferred. Successful
completion makes Phase 8 eligible, not authorized.

## Connections

- [BH-05 plan](README.md)
- [Scheduling fixtures](../../../../../integration/bh-05/scheduling-fixtures.exs)
- [Integration tests](../../../../../integration/conformance/test/bh05_scheduling_test.exs)
- [Phase 6 evidence](root-lifecycle-evidence.md)
