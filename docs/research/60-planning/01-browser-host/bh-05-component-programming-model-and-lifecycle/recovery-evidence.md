---
title: "BH-05 Phase 10 Recovery Evidence"
kind: note
created: "2026-09-10"
maturity: developing
tags:
  - bh-05
  - failure-recovery
  - disposal
aliases: []
---

# BH-05 Phase 10 Recovery Evidence

Back to [milestone](README.md) and [recovery contract](recovery-contract.md).

## Implemented boundary

Opt-in recovery roots use one Core guardian, generation-bound retry and a
callback-independent semantic fallback. Ordinary roots retain their accepted
Phase 1–9 behavior. UI-tree produces a status announcement, named retry/reload
action and focus target; the renderer commits it under a failure correlation.
If rendering fails, diagnostics identify the declared host-owned static fallback.
No failing application callback is needed to construct fallback output.

Diagnostics contain safe codes, public identity, correlation, fingerprint,
retry counts and cleanup inventory, never raw exceptions or application values.
Retries require declared source, exact failed generation and fingerprint, and
confirmed cleanup. Every retry starts fresh state in a new generation. Automatic
retry is opt-in, bounded to three restarts in five seconds and then terminal.
Effects and commands are never implicitly replayed. Runtime loss does not restart.

Cleanup cancels ingress, queues, timers and requests, then disposes deepest
component owners, resource leases and renderer ownership under one 1000 ms
deadline. Failed adapter release gets bounded forced cleanup. Unconfirmed release
remains a blocking diagnostic even after a subsequent empty-ledger disposal;
it cannot silently become a pass. Repeated terminal disposal returns the same result.

## Fixtures and retained evidence

- [Public fixtures](../../../../../integration/bh-05/recovery-fixtures.exs) define portable faulting components and runtime-owned test ports.
- [Acceptance tests](../../../../../integration/conformance/test/bh05_recovery_test.exs) use an independent headless semantic oracle and observable resource inventory.
- [Source inventory](../../../../../integration/bh-05/recovery-index-v0.1.0.json) binds changed/new Elixir files, bounds and fifteen exact normalized digests.

The component gate covers 17 mount, nested initialization/render, event, message
and update failures including raises, rejection, invalid result/state and invalid
semantic output. It verifies fallback semantics, sibling survival and redaction.
The cleanup gate covers effect-result failure, removal, replacement, crash,
runtime loss, callback errors, cancellation, focus restoration and late results.
Persistent failure yields automatic-window samples `0,1,2,3,3`: three admissions
and one denied attempt. Four generation timestamps must span less than five seconds.
The cleanup timing samples must each be below 1000 ms; a deliberately slow release
times out at approximately 100 ms and succeeds through forced cleanup.

Unit tests cover 512 leases, portable paged inventories, unresolved forced cleanup,
helper process/monitor cleanup, stale retry, fresh generation state, deep disposal,
renderer unavailability, renderer rejection and commit deadlines. Negative leak
injection is expected to remain failed; successful acceptance scenarios have zero
unresolved resources. These negative fixtures are not suppressed active leaks.

## Validation and publication

All **21 gates passed** against **1,112 unchanged source hashes** in
`/tmp/bh05-phase10-gates-oJFiiv/execution.json`.
The first run at `/tmp/bh05-phase10-gates-8YRRZN` was not accepted because a
review correction changed its source closure. The fresh complete run supersedes it.

- [Frozen gates](../../../assets/bh-05-baseline/recovery-gates-v0.1.0.json) retain commands, raw outputs, timing and source hashes.
- [Completion](../../../assets/bh-05-baseline/recovery-completion-v0.1.0.json) binds accepted artifacts and Phase 11 eligibility without authorization.

Package/conformance counts are Core 90, Effects 12, UI-tree 68, Renderer 8,
Headless 6, DOM 116, Test 3 and Conformance 92: **395 tests**, zero failures.
JavaScript has **213 runtime + 7 DOM-driver tests**, zero failures. The accepted
cleanup samples are **0 and 101 ms**, with zero unresolved resources; the slow
sample includes one timed-out release and one successful forced cleanup.

The Phase 10 recorder runs twenty-one source-frozen gates: package/conformance
suites, JavaScript, compile fixtures, runtime/dependency audit, pinned Phase 1–9
and BH-04 replays, historical security/dependency sweep, seven successor mutation
tests, validator, generated authority, archive, JSON and patch hygiene. It rejects
failed, missing, duplicated, stale, altered-digest or out-of-bound timing evidence.
Accepted gate and completion records are exclusive-create, never overwritten.

Phase 9 is replayed at `77bf199bebb680b24efef0130b19d93ef181f4d5`.
Earlier replay pins remain unchanged. All twelve inherited normalized hashes
remain exact; three recovery hashes extend rather than replace them.

Development corrections included portable fixture construction rejected by the
compiler's dependency rules, the exact update ingress name, fallback binding owner
and focus target, draining linked-helper exit messages, retained cleanup callback
errors, preventing later disposal from hiding an unconfirmed release, and
preventing replacement from proceeding after a failed disposal callback.

## Limits and qualification

Evidence is ERTS/headless only: Elixir 1.17.3, OTP 26.0.2, pinned offline image
`a2386c21edd5`. New linked/monitored helpers, kill/unlink and monotonic deadlines
require Phase 11 runtime-profile qualification; API inspection grants no Wasm
execution parity. Browser/native adapter wiring and cross-backend execution belong
to Phase 11. Whole-VM recovery, BH-15 offline persistence, production error reporting,
command replay and hostile arbitrary callback sandboxing are excluded.
Runtime configuration and idempotent adapter cleanup implementations are trusted.

LiveView and LocalLiveView remain explicitly deferred. Support remains unsupported.
Phase 10 completion makes Phase 11 eligible, not authorized; BH-06 remains ineligible.
