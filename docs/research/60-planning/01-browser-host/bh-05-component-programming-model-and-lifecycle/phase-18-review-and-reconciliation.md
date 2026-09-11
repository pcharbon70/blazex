---
title: "BH-05 Phase 18 Review and Reconciliation"
kind: note
created: "2026-09-11"
maturity: developing
tags: [atomvm, bh-05, cleanup, compact-acknowledgement, reconciliation]
aliases: []
---

# BH-05 Phase 18 Review and Reconciliation

Back to the [Phase 18 plan](phase-18-compact-ticket-acknowledgements-and-deadline-safe-reconciliation.md), [provider contract](provider-release-ticket-contract.md), and [attempt ledger](../../../../../integration/bh-05/compact-ticket-acknowledgement-attempts-v0.1.0.json).

## Decision

The decision is **accept**. Phase 18 closes
`BH05-P17-FIREFOX-TICKET-SESSION-DEADLINE` without changing the 1000 ms
deadline, 64-ticket page, 512-ticket maximum, or active browser set. A provider
may return scalar `:released` only for unanimous success from the private
prepared-page callback. Mixed, failed, malformed, partial, unavailable, and
legacy public results remain exact positional vectors and fail closed.

ERTS passes every retained factor row in 0–1 ms, canonical `64, 65, 256, 512`
in `0, 0, 1, 0` ms, and maximum-512 in 0 ms. Chrome passes factor rows in
24–95 ms, canonical rows in `6, 5, 73, 83` ms, and maximum-512 in 77 ms.
Firefox passes factor rows in 170–564 ms, canonical rows in
`31, 27, 165, 560` ms, and maximum-512 in 515 ms. Every 512-ticket result
records eight compact acknowledgement pages, 512 compact acknowledgement
items, zero positional success items, zero unresolved identities, zero
terminal leases, and inventory convergence to zero.

The retained adverse/growth scenario also passes: Chrome cleanup takes 102 ms,
Firefox cleanup takes 629 ms, both retain zero unresolved and terminal leases,
and both finish 100 lifecycle cycles with zero unexpected process growth.

## Review findings

Correctness and authority pass. RootPort accepts compact success only from the
provider-authorized internal callback. Public callbacks retain validated map
envelopes. Invalid scalar and partial results become full error vectors, while
mixed vectors retain their exact failed positions. Inventory convergence is
therefore derived only from provider-confirmed success and cannot be
manufactured by a malformed compact response.

Portability and performance pass for the active development runtimes. The same
Elixir cleanup path and bundle run under ERTS, Linux Chrome, and Linux Firefox;
cross-browser structural observations match exactly after timing and
unavailable runtime metrics are excluded. The retained maximum Firefox result
is 515 ms, leaving 485 ms of the frozen deadline without a warm-up exemption.

Migration and compatibility pass. Existing individual and public page release
callbacks remain supported. Providers opt into compact success only by
implementing the private prepared-page callback, and mixed/failure behavior is
unchanged. The action/component public facade and version-2 cleanup outcome
shape do not change.

Security and anti-concealment pass. Tickets remain bounded, opaque,
provider-scoped, runtime-owned, and owner-free on normal disposal. Explicit
counters expose compact pages/items and positional result items, while the
Phase 13–17 process, inventory, preparation, owner-field, factor, outcome, and
growth gates remain in force. This is implementation-agent review, not
independent human attestation.

LiveView and LocalLiveView remain **[DEFERRED]**. No browser, platform, profile,
public API, release, or support state is promoted. Passing Phase 18 makes BH-06
eligible for separate planning and authorization; it does not authorize BH-06.

## Connections

- [Phase 18 plan](phase-18-compact-ticket-acknowledgements-and-deadline-safe-reconciliation.md)
- [Phase 18 attempt ledger](../../../../../integration/bh-05/compact-ticket-acknowledgement-attempts-v0.1.0.json)
- [Phase 17 review](phase-17-review-and-reconciliation.md)
- [Provider release-ticket contract](provider-release-ticket-contract.md)
