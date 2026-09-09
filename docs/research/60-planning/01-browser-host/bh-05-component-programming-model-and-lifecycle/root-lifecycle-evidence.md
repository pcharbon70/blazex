---
title: "BH-05 Phase 6 supervised root lifecycle evidence"
kind: note
created: "2026-09-09"
maturity: developing
tags: [bh-05, lifecycle, supervision, conformance]
aliases: []
---

# BH-05 Phase 6 supervised root lifecycle evidence

Implements the [Phase 6 plan](phase-06-process-root-local-view-lifecycle-and-supervision.md)
and [root lifecycle contract](root-lifecycle-contract.md), with the
[compatibility analysis](root-supervision-compatibility.md).
The [authority](../../../assets/bh-05-baseline/root-authorization-v0.1.0.json)
binds accepted Phase 5 merge `f2fdc745118f0ad84e5b3ab53ea9e5221310f957`.

## Delivery and boundaries

Four section commits on `codex/bh05-phase6-root-lifecycle`, followed by one PR,
merge, checkout main, synchronize origin, then local/remote branch deletion.
Unrelated README/demo work is preserved in a retained Git stash and restored
after cleanup. Sections 6.1–6.3 were verified before their respective commits.
All 17 gates passed with 1,045 source hashes unchanged before/after the run.
The [gate record](../../../assets/bh-05-baseline/root-gates-v0.1.0.json) contains
the exact commands/results, and the
[completion record](../../../assets/bh-05-baseline/root-completion-v0.1.0.json)
binds authority, gates and inventory. External PR/merge/cleanup delivery was
pending when those immutable records were created.

Core owns identity-only handles, the private root coordinator, temporary guardian
and abstract ports. The outward UI-tree evaluator owns root/nested candidate
tables and semantic acceptance. No concrete renderer or UI-tree dependency is
added to Core, and no process/renderer dependency is added to the evaluator.
The explicit root mode is a reviewed successor to the private planner/engine;
Phase 4 pure and Phase 5 mixed-role defaults remain unchanged.

## Executable coverage

The [public fixture inventory](../../../../../integration/bh-05/root-index-v0.1.0.json)
hashes every new runtime/test source and both reviewed predecessor changes.
Public fixtures import only public facades/ports/semantic constructors and the
headless Session. White-box crash injection is isolated to Core package tests.

The supervised script executes mount, update, no-op, generation replacement,
host removal, renderer disposal and idempotent stop. At each step, an independent
semantic oracle is rendered through a separate headless Session and compared
with the actual adapter artifact. Root revisions start at 1 while the accepted
renderer Session starts at 0; the outward adapter owns that explicit translation.
The candidate's semantic digest is independent of that renderer-local counter.

Negative cases cover invalid bootstrap/roles, callback mount/update/render
failure, invalid semantics, prohibited action emissions, malformed/stale/
duplicate/wrong-owner acknowledgements, busy admission, stale revision,
confirmed renderer rejection, failed submission, lost acknowledgement before
and after renderer commit, uncertain rollback, cleanup failure, disposal timeout,
and crashes before/after initial commit with an independently ready sibling.
ERTS system-status tests prove private tokens/configuration are redacted.

Accepted state/output/final digest changes only after a matching renderer commit.
Rejected candidates preserve the exact prior accepted summary. Replacement
cleanup is delayed until commit; cleanup failure retains the newly committed
summary but marks the root failed rather than ready. Removal closes admission,
disposes the renderer, then performs deepest-first nested cleanup and root
termination. Repeated stop cannot replay cleanup. Terminal guardian metadata
survives coordinator death without automatic restart. Explicit remount requires
a new instance; the superseded handle becomes stale.

Normalized script digests (rechecked against integration stdout by the validator):

- Script: `4eacd556df14a281187e78ae51edb4a2312f4897aa0553aaacc2c150f85f9138`.
- Host trace: `e062e88cee0a7866964aff1fa1695577bf70660cef031c139d262afd99c9c9e7`.
- Final committed state: `937d347b5a168a432c2a0a6eb45c1b2acaa5ae8440884617906445420aee400d`.

## Gate method

`python3 docs/research/70-tools/record_bh05_phase6.py` records 17 ordered gates,
exact argument arrays, environments, stdout/stderr, exit codes and immutable
before/after source hashes. Publication refuses failed, missing, duplicated,
stale or digest-mismatched results. Mutation tests exercise these refusals and
inherited authority/tooling/fixture protections in isolated shared clones.

The package gate covers Core, Effects, UI-tree, Renderer, Headless, DOM, Test and
Conformance. Other gates cover JavaScript runtime/DOM drivers, compile fixtures,
the SHA-pinned Popcorn supervision patch audit, frozen Phase 5/4/3/2/1 and BH-04
corrective replay, the full historical Python sweep, current validator mutation
tests, generator checks, archive links, all repository JSON and staged/unstaged
patch hygiene. Historical checkouts are pinned and checked clean; no accepted
predecessor evidence or sealed tool is regenerated to accommodate this phase.

Results: **309 package/conformance tests**, zero failures (Core 46, Effects 9,
UI-tree 50, Renderer 8, Headless 6, DOM 116, Test 3, Conformance 71). The compile
fixtures passed 5 tests; the current boundary mutation suite passed 7 groups;
frozen Phase 5/4/3/2 mutation suites passed 7 groups each, and Phase 1 passed 10.
The historical sweep passed 438 Python tests plus its validators/generator checks.
JavaScript runtime and DOM-driver suites passed. Archive validation checked 268
documents and 30 directories. JSON validation checked 446 files before publishing
the two new gate/completion records; both new records are validated on publication.
The final recorder output is `/tmp/bh05-phase6-gates-irX67G/execution.json`;
the committed gate record retains the evidence without requiring that temporary path.

## Findings and limits

During implementation, two remount tests exposed OTP's automatic deletion of
temporary child specifications. Explicit remount now accepts the already-removed
child specification, and the tests pass. The compatibility review replaced an
assumed Elixir `Process.exit/2` wrapper with the verified VM primitive
`:erlang.exit/2`. System-status formatting preserves the required status keys
while replacing private content, verified with actual ERTS status requests.

This is ERTS lifecycle/headless evidence, not new browser-Wasm execution credit.
The pinned Popcorn patch/API analysis is not a VM run. Standalone AtomVM 0.6.6
is incompatible with the required child-management API; upstream alpha's
GenServer lacks format-status support. Runtime/profile execution and crash-log
privacy remain explicitly unqualified for Phase 11 under the runtime profile
owner. No runtime upgrade is made. The existing BH-04 transaction suites are
retained, not reclassified as tests of a new browser root-port binding.

Callbacks and ports remain trusted, terminating code; no adversarial sandbox,
preemptive callback deadline, external-effect rollback, forced-crash cleanup or
support claim is made. Static graph configuration does not activate a registry.
Root event/message/timer dispatch, optional commit-ack callback delivery, effects,
commands, fallback execution, context resolution and automatic recovery remain
later work. LiveView and LocalLiveView remain deferred. Phase 7 becomes eligible
only after sealed completion and remains unauthorized; BH-06 remains ineligible.
