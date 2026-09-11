---
title: "BH-05 Phase 17 Completion Evidence"
kind: note
created: "2026-09-11"
maturity: developing
tags: [bh-05, cleanup, completion, evidence, release-ticket, scaling]
aliases: []
---

# BH-05 Phase 17 Completion Evidence

Back to the [Phase 17 plan](phase-17-provider-issued-release-tickets-and-owner-free-disposal.md), [review](phase-17-review-and-reconciliation.md), and [attempt ledger](../../../../../integration/bh-05/provider-release-ticket-attempts-v0.1.0.json).

## Outcome

Phase 17 is complete with decision **revise**. Providers issue bounded opaque
release tickets after full lease authority validation. The runtime registers
them before acquisition becomes observable, replaces them after transfer,
drops them after explicit release, and uses ordered owner-free pages for normal
disposal. Failed positions alone recover their exact full descriptors for
forced cleanup. Immediate release and public snapshot shapes remain compatible.

The complete gate reports Core 118 tests, Effects 14, UI Tree 68, Test 7,
Renderer 8, Headless 6, DOM 116, DOM JavaScript 7, browser-runtime JavaScript
31, and conformance 93, all with zero failures. Browser-project formatting and
packaging, archive validation across 302 documents and 2500 links, JSON parsing,
dependency drift, and patch hygiene pass.

ERTS passes every Phase 17 factor, canonical, and maximum row in 0–1 ms. Chrome
passes all 256/512 factor rows in 52–251 ms, canonical `64, 65, 256, 512` in
`8, 10, 150, 225` ms, and maximum-512 in 200 ms. Every successful row has exact
ticket counts, zero preparation failures, zero owner fields, zero terminal
leases, and zero unresolved identities.

## Reproducibility and closure

Two clean offline builds from the pinned `a2386c21edd5` Elixir image produce the
byte-identical bundle
`a7475fed8e240a6cc50e252f7cccd8e8ba9635b73833a6d6d00b1df6d1cbb1fc`.
The second Chrome run records canonical `9, 8, 129, 215` ms and maximum-512
228 ms with the same complete convergence and zero owner fields.

Firefox reproducibly exits the deadline-bound ticket session with `noproc` in
factor, canonical, and maximum runs. A diagnostic-only relaxation, reverted
before both retained builds, proves all 512 ticket callbacks and lease cleanup
complete in 2062 and 2006 ms. The frozen 1000 ms gate therefore does not pass.

`BH05-P16-DEEP-OWNER-RELEASE-DESCRIPTOR` is closed. The successor blocker is
`BH05-P17-FIREFOX-TICKET-SESSION-DEADLINE`. Re-entry must reduce Firefox AtomVM
ordered ticket-session and outcome-reconciliation cost without increasing the
deadline, shrinking the matrix, excluding a browser, weakening per-ticket
correlation, or hiding preparation and failure work.

BH-05 remains revision-required. BH-06 remains ineligible and unauthorized.
LiveView and LocalLiveView remain deferred. No support state is promoted.
