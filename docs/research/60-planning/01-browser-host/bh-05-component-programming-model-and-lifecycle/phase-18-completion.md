---
title: "BH-05 Phase 18 Completion Evidence"
kind: note
created: "2026-09-11"
maturity: developing
tags: [bh-05, cleanup, compact-acknowledgement, completion, evidence]
aliases: []
---

# BH-05 Phase 18 Completion Evidence

Back to the [Phase 18 plan](phase-18-compact-ticket-acknowledgements-and-deadline-safe-reconciliation.md), [review](phase-18-review-and-reconciliation.md), and [attempt ledger](../../../../../integration/bh-05/compact-ticket-acknowledgement-attempts-v0.1.0.json).

## Outcome

Phase 18 is complete with decision **accept**. Provider-authorized unanimous
page success now crosses RootPort, RecoveryPort, disposal, and outcome
construction as scalar `:released`. Exact positional vectors remain mandatory
for mixed or failed work. Malformed scalar and partial results fail closed,
public callbacks retain validated ticket maps, and provider-issued ticket
authority remains intact.

The complete Elixir gate reports Core 123, Effects 15, UI Tree 68, Test 7,
Renderer 8, Headless renderer 6, DOM renderer 116, browser host 4, Phoenix
adapter 10, deferred LiveView adapter 4, Popcorn runtime 4, headless profile 6,
browser Phoenix profile 14, integration conformance 93, and native spike 9
tests, all with zero failures. DOM JavaScript 7, browser-runtime JavaScript 31,
and browser demo 7 tests also pass. The demo syntax check, pinned browser
packaging, JSON parsing, patch hygiene, and research archive checks pass.

## Runtime evidence

The first clean pinned build produces bundle
`7108ca99ad9e481467b5f3a1fe6ece75542390160b8d05922f673dd33f434b83`.
ERTS factor, canonical, and maximum rows pass in 0–1 ms. Chrome passes all
factor rows in 24–95 ms, canonical `64, 65, 256, 512` in
`6, 5, 73, 83` ms, and maximum-512 in 77 ms. Firefox passes all factor rows in
170–564 ms, canonical rows in `31, 27, 165, 560` ms, and maximum-512 in
515 ms. The adverse/growth scenario passes at 102 ms in Chrome and 629 ms in
Firefox, with zero unexpected growth after 100 lifecycle cycles.

Every retained row remains within 1000 ms and converges with zero unresolved
identities, zero terminal leases, and zero runtime inventory. Each 512 row
records eight compact pages, 512 compact items, and zero positional success
items. Exact cross-browser structure matches after timing and unavailable
runtime metrics are excluded.

## Reproducibility and closure

A second clean offline build is byte-identical. Chrome repeats canonical rows
in `6, 6, 30, 82` ms and maximum-512 in 76 ms. Firefox repeats canonical rows
in `28, 32, 187, 534` ms and maximum-512 in 563 ms. Both repeats preserve full
convergence and the frozen deadline.

`BH05-P17-FIREFOX-TICKET-SESSION-DEADLINE` is closed. BH-05 is accepted for
bounded development and BH-06 becomes eligible for separate planning and
explicit authorization. No BH-06 implementation is authorized here. LiveView
and LocalLiveView remain deferred, and no browser, platform, profile, public
API, release, or support state is promoted.
