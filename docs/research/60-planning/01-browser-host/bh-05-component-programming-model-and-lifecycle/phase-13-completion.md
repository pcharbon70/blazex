---
title: "BH-05 Phase 13 Completion Evidence"
kind: note
created: "2026-09-10"
maturity: developing
tags: [bh-05, cleanup, completion, evidence]
aliases: []
---

# BH-05 Phase 13 Completion Evidence

Back to the [Phase 13 plan](phase-13-bounded-paged-cleanup-and-scaling-requalification.md), [review and reconciliation](phase-13-review-and-reconciliation.md), and [machine-readable completion](../../../assets/bh-05-baseline/cleanup-scaling-completion-v0.1.0.json).

## Outcome

Phase 13 is complete with decision **revise**. The implementation gate passes:
Core reports 103 tests, Effects 12, UI Tree 68, Test 7, and conformance 93,
all with zero failures. Formatting, browser bundle construction, validator
mutation tests, JSON parsing, diff hygiene, and the research archive validator
pass. Historical Phase 12 count, cleanup, browser-conformance,
cross-runtime-conformance, reconciliation, and release-decision validators
continue to validate their immutable records; source-freeze validators report
expected inherited-source drift after Phase 13 and are not relabeled as passes.

The acceptance gate fails. In the second clean pinned browser build, both
engines pass the representative 64, 65, and 256 boundaries. At 512, Chrome
completed all 513 callbacks in eight lease pages in 267 ms with zero unresolved
identities. Firefox completed 448 callbacks in seven pages, exceeded the same
1,000 ms deadline at 3,121 ms total, and retained 65 exact unresolved
identities. The semantic result matches both final probes; timing variance is
retained. AtomVM byte counts remain explicitly unavailable because both
available byte-size observations materially distort this deadline path.

## Closure

The source implementation is bound by section commit `d27abac`, the completion
commit containing this document, the pinned AtomVM hash and second-build bundle
hash in the completion ledger, and hashes of all append-only browser attempts.
No Phase 13 file asserts BH-05 acceptance, BH-06 eligibility, browser support,
or release support. LiveView and LocalLiveView remain deferred and outside this
host implementation.

Re-entry is exactly the open `BH05-P13-FIREFOX-DEADLINE` finding. It requires
compact but exact bounded terminal-result representation on Firefox followed by
the unchanged Phase 12 repeat and complete pre-registered Phase 13 matrix. The
deadline, fixture size, page size, active browsers, and retained failures may
not be weakened.
