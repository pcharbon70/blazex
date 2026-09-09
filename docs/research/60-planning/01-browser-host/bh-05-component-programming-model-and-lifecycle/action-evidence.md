---
title: "BH-05 Phase 8 Action Evidence"
kind: note
created: "2026-09-09"
maturity: developing
tags:
  - bh-05
  - effects
  - resources
  - commands
aliases: []
---

# BH-05 Phase 8 Action Evidence

Back to [milestone](README.md) and [action contract](action-contract.md).

## Implemented boundary

Action-enabled roots opt into closed version-1 messages, timers, effects,
resource transfers/releases and untrusted commands. Portable callbacks use
`BlazeX.Component.Result.action/5`; the frozen compiler allowlist is unchanged.
Root capability declarations, public manifest grants and runtime capabilities
must agree. The outward Effects bridge selects only configured providers,
denies by default, and binds existing effect/resource contracts.

No provider submission occurs before renderer commit. A terminal callback slot
is reserved for every pending request inside the 256-work scheduler budget.
Results are generation/instance/owner/action/sequence correlated; root callbacks
use `effect_result/1`, nested callbacks use `handle_info/1`. Failure, timeout,
cancellation, denial and disconnection remain distinct. No request is replayed
automatically. A private guardian checkpoint covers coordinator death during
submission; cleanup ports must tolerate repetition after crash uncertainty.

Lease acquisition reserves capacity before submission. Opaque IDs cannot be
reused while live; acquisition correlations distinguish later reuse. Transfers
require declared same-root/generation routes. Removal, replacement, shutdown,
runtime loss and rejected result transitions clean up owned work. Failed release
is counted as lost. Public inventory is paged in groups of 128 to retain the
existing portable collection-size limit.

Commands retain declaration/schema IDs, payload, correlation/idempotency data,
timeout, optimistic revision and expected result/error schemas. They are always
untrusted client intent. A deterministic adapter denies them without undoing
the already committed local state. Authentication, authorization, validation,
idempotency, auditing and result normalization remain future server obligations.

## Fixtures and raw evidence

- [Action fixtures](../../../../../integration/bh-05/action-fixtures.exs) use public
  component, evaluator, Effects and headless interfaces, with no private evaluator
  or root-coordinator imports.
- [Integration tests](../../../../../integration/conformance/test/bh05_actions_test.exs)
  exercise delayed/denied/fallback/failed/timed-out/disconnected results,
  commit ordering, nested result routing and owner removal, leases, command denial,
  root isolation, runtime loss and post-disposal rejection.
- [Fixture inventory](../../../../../integration/bh-05/action-index-v0.1.0.json)
  binds changed/new Elixir sources and normalized digests.

Pending samples are `1..128,128`: request 129 is rejected before rendering.
Lease samples are `16,32,...,512,512,0`: further acquisition is rejected and
shutdown releases all 512 leases. Core tests separately cover stale acquisition
references, duplicate/unknown transfer/release, cancellation tokens, resource
reservation accounting, bounded history and hard coordinator death.

The independent headless oracle checks both semantic output and rendered final
state. Three action hashes plus all six inherited root/scheduling hashes must
match. Raw samples and exact outcome markers are retained in the gate log,
not inferred from an aggregate pass count.

## Validation and publication

All 19 gates passed against **1,076 source hashes**. The accepted run is
`/tmp/bh05-phase8-gates-UOeorA/execution.json`, published without source changes:

- [Frozen gates](../../../assets/bh-05-baseline/action-gates-v0.1.0.json): exact
  commands, environment, raw output, timings and source closure.
- [Completion](../../../assets/bh-05-baseline/action-completion-v0.1.0.json): bound
  artifact hashes, unsupported status, Phase 9 eligible and unauthorized.

Package/conformance counts: Core 75, Effects 12, UI-tree 54, Renderer 8,
Headless 6, DOM 116, Test 3 and Conformance 84 — **358 tests**, zero failures.
JavaScript: **213 runtime + 7 DOM-driver tests**, zero failures. Compile fixtures:
**2 authoring + 3 schema tests**, zero failures. Successor evidence mutation
suite: **7 tests**, all passing. All nine action/root/scheduling digests matched.

Replay checkouts are pinned and validated clean before use: Phase 7 at
`08dec098fde98b506d554bf8c3ff64bc65de6add`; Phase 6 at
`e373e96891207ea4b6c2fdfae9533181334b3cab`; Phase 5 at
`f2fdc745118f0ad84e5b3ab53ea9e5221310f957`; Phase 4 at
`ea09d05a2709a163ff0c8776c4039f1a712a95de`; Phase 3 at
`fc5048d4db7cc80fd21b492e0638182abceda1af`; Phase 2 at
`5cd382c23c5589404efc8dd7121432dd24c4cd96`; Phase 1 at
`968013b9794664fc454619ee08788c3d0c39551f`. BH-04 corrective and historical
replays remain at their accepted `506c254` and `d61e103` snapshots.

The Phase 8 recorder executes 19 gates against a source closure captured both
before and after execution. They include eight package/conformance suites,
JavaScript and authoring/schema fixtures, runtime subset analysis, frozen
Phase 1–7 and BH-04 replays, historical dependency/security checks, successor
mutation tests and validator, generated authority, archive links, JSON and patch
hygiene. Missing, duplicate, failed, stale or altered trace evidence blocks
publication. Exact commands, environment, outputs and counts are recorded in
the published machine-readable gates; publication is exclusive-create only.

Development failures were resolved before publication: fixture helper imports,
implicit protocol calls and map compiler intrinsics were outside the existing
portable compiler boundary; the initial oracle reversed binding ownership; a
flat live lease inventory exceeded the portable list bound at 257 entries.
Fixtures now compile under the unchanged authoring policy, bindings match an
independently constructed oracle, and inventory paging preserves the old bound.
Lifecycle assertions follow the existing disposal commit/runtime-loss contracts.

## Limits and deferred work

Evidence is ERTS-only with terminating trusted ports/callbacks, not a hostile
mailbox bound, preemptive sandbox or exactly-once external cleanup guarantee.
At most 128 owner watermarks survive per generation, 128 requests are pending,
512 leases exist or are reserved, 16 actions occur per candidate, and transfer
history has at most 16 entries. Public reserved-field validation is structural,
not detection of secrets hidden in otherwise ordinary strings.

Concrete browser providers, server transports/authority, uploads, navigation,
persistence and arbitrary tasks are excluded. Phase 10 owns expanded disposal
coordination. Wasm execution, packaging and qualification remain Phase 11;
the pinned Popcorn API/patch audit is analysis, not execution parity or support.
LiveView and LocalLiveView remain explicitly deferred. Passing Phase 8 makes
Phase 9 eligible, not authorized, and does not activate BH-06.
