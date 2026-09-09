---
title: "BH-05 Phase 5 nested state implementation evidence"
kind: note
created: "2026-09-09"
maturity: developing
tags: [bh-05, state, reconciliation, implementation-evidence]
aliases: []
---

# BH-05 Phase 5 nested state implementation evidence

Implements the [Phase 5 plan](phase-05-nested-stateful-identity-and-update-reconciliation.md)
and [nested-state contract](nested-contract.md).

Decision: **Phase 5 complete — in-memory root-owned nested state on ERTS**.
Phase 6 is eligible but unauthorized; BH-06 remains ineligible. No root process,
external message, effect execution, renderer commit or Wasm parity is granted.

The [source-frozen gates](../../../assets/bh-05-baseline/nested-gates-v0.1.0.json)
and [completion record](../../../assets/bh-05-baseline/nested-completion-v0.1.0.json)
bind 15 passing gates to identical before/after/current executable and contract
source hashes:

- 284 package/conformance tests: Core 31, Effects 9, UI Tree 45, Renderer 8,
  Headless 6, DOM 116, Test 3 and cross-package conformance 66;
- 213 JavaScript runtime tests and seven DOM driver tests;
- five inherited authoring/schema compile integration tests;
- seven current evidence mutation groups, seven each from frozen Phases 4, 3
  and 2, ten Phase 1 groups, and the accepted BH-04 corrective replay;
- complete historical tooling sweep including 438 Python tests and all its
  validators/generator checks;
- current authority, ownership, boundary, fixture, archive, JSON and hygiene
  checks, including 444 JSON files in the final staged-source run.

The logs record commands, outputs, versions, normalized hashes and timings.
Archive/JSON/final evidence checks are repeated after publishing this note and
the two completion artifacts. Those additions do not change the tested
executable/contract source closure. No failed or stale result receives pass credit.

## Section delivery

| Section | Commit | Scope |
| --- | --- | --- |
| 5.1 | `ca2b221` | Authority, local/controlled state ownership, replacement and disposal rules |
| 5.2 | `ff7cc9e` | Immutable Core table, mixed-role planning and candidate initialization/update |
| 5.3 | `aa25a80` | Keyed reconciliation, local event candidates, replacement and atomic disposal |
| 5.4 | this delivery commit | Public/headless fixtures, root public-ID correction and frozen evidence |

The synchronized base is Phase 4 merge `ea09d05a2709a163ff0c8776c4039f1a712a95de`.
Branch `codex/bh05-phase5-nested-state` is delivered as one PR after four section
commits, then merge, checkout main, sync origin and branch deletion. Unrelated
README/demo work is preserved in stash
`36d1ea3e282da974aca97d7c94b20aecad9d5bed` for exact restoration after delivery.

## Implemented state and identity model

The [state-machine/fixture inventory](../../../../../integration/bh-05/nested-index-v0.1.0.json)
binds `BlazeX.Component.NestedTable`, `BlazeX.UITree.Nested`, the private candidate
engine, reviewed shared planner extension, package tests,
[public fixtures](../../../../../integration/bh-05/nested-fixtures.exs) and
[conformance tests](../../../../../integration/conformance/test/bh05_nested_test.exs).

Core owns the immutable accepted record/table contract without a UI-tree or
renderer dependency. UI Tree owns candidate orchestration and semantic acceptance.
The only changed inherited runtime module is the internal composition planner:
an opt-in role list permits nested stateful records and captures their literal
metadata. Default Phase 4 pure-only behavior still passes its original fixtures
with identical output, trace and headless digests. Other inherited runtime,
package dependencies and historical evidence remain unchanged.

Records contain stable identity and parent, public/static component metadata,
schema/contract fingerprint, normalized props/slots and invocation digest,
portable state, accepted subtree digest, generation/revision/sequence, status
and empty owned action references. All graph inputs normalize before callbacks.
Pure and inert records have absent state; stateful records retain present
portable state. Nonportable invocation/state, unstable ordinal stateful keys,
duplicate identity, impossible ancestry and overflow reject.

Mount initializes new stateful identities and renders parent-first. Compatible
input changes call optional update, while no-op or missing update preserves state;
all components still render. Keyed reorder within a parent preserves state.
Changing parent scope removes/inserts, rather than transplanting state. Public
identity, module, role or schema incompatibility at the same structural identity
requires an explicit replacement path. Parent replacement resets descendants;
next-generation replacement resets all instances and rejects old events.

Local events require an accepted binding, shared-root ownership, matching
generation, exact next sequence and expected revision. They route to the nearest
stateful ancestor and become immutable candidates. Typed `message/parent`
notifications are bounded data in the result, never sent or recursively handled.
Effects, commands, timers, releases and mutable/opaque state references reject.
The owner must carry forward the latest accepted session; this is not a global
concurrent compare-and-swap service or a mailbox scheduler.

Candidate records and complete semantic output validate before publication.
Removed/replaced stateful records dispose deepest-first, with reverse accepted
order breaking ties. Plans expose public identity, reason, state digest and
optional callback outcome; they do not retain resources. Disposal rejection
rejects the complete transition. Every failed update/event returns the exact
previous session, with no candidate output, state, actions or disposal plan.

## Determinism and negative evidence

The public four-transition script mounts nested pure/stateful controls, increments
one local state, reorders keyed children, and inserts/removes identities. Its
complete output matches independently constructed semantic output and headless
snapshots at every step. Twenty repetitions reproduce the same complete sessions.
Both two-key permutations run thirty compatible reconciliations each without
reinitialization. Script/headless/final-state digests are bound in the inventory
and checked against gate stdout, not copied from an unverified candidate.

Tests cover initialization/update/no-change/local events, nested disposal,
module/schema/public-ID/parent/generation replacement, parent-scope changes,
invalid props/state/output/actions, callback rejection/exception, disposal
failure, duplicate/ordinal keys, foreign roots, stale sequence/revision, accepted
table drift, graph/counter overflow and exactly 128 versus 129 notifications.
Inherited pure-composition tests retain depth/node/invocation boundary coverage.
Canonical traces contain public transition observations and digests, never raw
props/state, module-private names, exception details, clocks or PIDs.

Review found that root public-ID changes were not part of the compatibility
fingerprint because root structural identity has an empty path. The fingerprint
now includes the public ID and a regression requires explicit root replacement
and descendant reinitialization. This corrected source passed all local tests
and the full fresh gate. An early unused test alias warning was also removed.

The initial full run at `/tmp/bh05-phase5-gates-yivWTh` was invalidated by the
identity correction; its source-closure guard correctly returned failure even
though its individual commands passed. It is retained externally and was not
published. A subsequent passing run at `/tmp/bh05-phase5-final-gates-ZH52vG`
was superseded after the final staged-patch check found an extra blank line at
the end of a new Python test file. The line was removed and the hygiene gate
now checks `git diff --check HEAD`, covering staged and unstaged changes.
Those draft gate/completion records are retained at
`/tmp/bh05-phase5-superseded-XPjwvA`. The unchanged final run at
`/tmp/bh05-phase5-staged-gates-B597og` alone supplies completion credit. No
sealed validator was widened or old evidence rehash substituted for new testing.

Frozen replays use Phase 4 `ea09d05`, Phase 3 `fc5048d`, Phase 2 `5cd382c`,
Phase 1 `968013b`, corrective BH-04 `506c254`, and historical tooling `d61e103`.
Current mutation tests reject authority/inherited drift, unknown surfaces,
private application imports, premature future completion, false runtime credit,
and missing, failed, stale or digest-mismatched gate records.

## Limits and next phase

Sessions and static modules are trusted in-memory/build-authored values, not
authenticated host payloads or an adversarial Elixir sandbox. Hashes do not
provide authenticity or secret-content detection. Import/opcode checks are not
a transitive purity or termination proof. Side-effect-free callbacks are required;
there is no rollback of arbitrary external side effects or callback timeout.
Hot code loading is not a state migration protocol; explicit static module/schema
replacement initializes fresh state instead of silently migrating it.

All nested instances share one future owning root process and failure boundary.
Phase 6 owns process-root lifecycle; Phase 7 owns scheduling; Phase 8 owns typed
effect/resource authority and execution. Renderer commit, external messaging,
dynamic registry/context resolution and independent subtree recovery remain
outside Phase 5. ERTS term-encoding determinism and headless parity do not establish
browser AtomVM/Wasm execution parity, which remains Phase 11. LiveView and
LocalLiveView remain explicitly deferred, and support remains unsupported.
