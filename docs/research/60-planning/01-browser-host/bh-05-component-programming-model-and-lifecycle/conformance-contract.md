---
title: "BH-05 Cross-Runtime Conformance Contract"
kind: note
created: "2026-09-10"
maturity: developing
tags:
  - atomvm
  - bh-05
  - conformance
aliases: []
---

# BH-05 Cross-Runtime Conformance Contract

Back to [Phase 11](phase-11-erts-browser-atomvm-and-cross-backend-conformance.md).

## Authority and matrix

Phase 11 compares one fixed public application corpus at the component-contract
boundary. Active rows are local ERTS with headless rendering, the standalone DOM
path, browser AtomVM in Linux Chrome and the available Firefox development binary,
and the retained direct GTK portability slice. These are development observations,
not product support. Windows, macOS, Safari/WebKit product qualification, Android,
iOS, physical devices and unavailable manual assistive-technology pairings are
`[DEFERRED]` to BH-22 and excluded from active pass rates.

LiveView and LocalLiveView remain separately deferred and are not runtime rows.
Phoenix is profile plumbing, never part of the portable application or equality model.

## Canonical observations

Every scenario has a stable ID, contract version and deterministic input steps.
Canonical observations include declaration/schema acceptance, callback entry and
exit, public component identity, candidate and accepted revision/state, semantic
output, events/messages/timers, action request/result/resource ownership, context
and registry selection, commit, failure/fallback/retry, disposal and final state.
Each mismatch identifies scenario, step, root/component identity, generation,
revision and contract version. Fixtures may use only documented public BlazeX
facades and portable values; browser/runtime branches and private implementation
imports are forbidden.

## Equivalence

Portable observations and final-state digests match exactly. Runtime name,
browser/tool versions, elapsed measurements and bounded resource counts are retained
as evidence but are allowed runtime variation. PIDs, references, monotonic clock
origins, scheduler reductions, stack traces, adapter transactions, browser-generated
IDs and private module names are excluded before hashing. Normalization is one
versioned deterministic program; manual edits are forbidden.

Result states are `exact-match`, `allowed-runtime-variation`, `fail`, `blocked`,
`not-applicable` and `deferred`. Active semantic divergence is blocking, whether
caused by harness, component contract or unsupported AtomVM behavior. A workaround
may not introduce browser-specific behavior into public fixtures.

## Claim boundary

The fixed bundle proves only the declared corpus is expressible and executes through
the accepted runtime path. It does not grant BH-06 general reachability/build support,
native packaging, broad browser/platform support or public API stability. GTK is a
portability gate. Phase 12 remains separately authorized.

## Connections

- [Recovery contract](recovery-contract.md)
- [Development qualification policy](../../development-environment-and-deferred-qualification-policy.md)
