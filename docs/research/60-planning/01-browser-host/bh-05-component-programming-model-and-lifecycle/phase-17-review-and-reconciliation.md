---
title: "BH-05 Phase 17 Review and Reconciliation"
kind: note
created: "2026-09-11"
maturity: developing
tags: [atomvm, bh-05, cleanup, reconciliation, release-ticket, reliability]
aliases: []
---

# BH-05 Phase 17 Review and Reconciliation

Back to the [Phase 17 plan](phase-17-provider-issued-release-tickets-and-owner-free-disposal.md), [contract](provider-release-ticket-contract.md), and [attempt ledger](../../../../../integration/bh-05/provider-release-ticket-attempts-v0.1.0.json).

## Decision

The decision is **revise**. Phase 17 closes
`BH05-P16-DEEP-OWNER-RELEASE-DESCRIPTOR`: providers now issue bounded opaque
release tickets after full authority validation, normal disposal transports no
owner fields, and exact full descriptors remain available only for failed
ticket release and forced recovery. Core reports 118 tests, Effects 14, and
conformance 93, all with zero failures.

ERTS passes every factor and canonical row in 0–1 ms. Chrome passes all seven
factor profiles at 256 and 512 in 52–251 ms, the canonical `64, 65, 256, 512`
rows in `8, 10, 150, 225` ms, and maximum-512 in 200 ms. All successful rows
prepare exactly one ticket per lease, retain zero ticket owner fields, converge
the runtime inventory to zero, and retain zero unresolved identities.

Firefox does not return the final factor, canonical, or maximum observation.
The deadline-bound RecoveryPort session exits and AtomVM reports `noproc`.
Two explicitly nonqualifying diagnostic runs with a temporary 5000 ms wait
released all 512 tickets and converged the lease inventory, but took 2062 and
2006 ms. The diagnostic relaxation was reverted before the retained bundle.

## Review findings

`BH05-P17-FIREFOX-TICKET-SESSION-DEADLINE` is blocking. The owner-path cause is
removed: Chrome factor shape is flat, successful ticket pages contain no owner
fields, and Firefox can release the complete inventory when observed outside
the gate. The remaining failure is the Firefox AtomVM cost of executing the
ordered 512-ticket session and bounded outcome reconciliation within 1000 ms.

The retained correction uses an ordered inventory cursor so each page sends
only its count and the provider route; validated compact ticket tuples remain
inside the runtime-owned session. Failed positions alone hydrate exact recovery
descriptors. Active ledger owners are encoded after ticket registration and
expanded only where lifecycle authority requires them. Public snapshots retain
their existing owner shape, immediate release is unchanged, and malformed,
missing, stale, or wrong-provider tickets fail closed.

The attempt ledger retains every architecture probe, including the temporary
deadline relaxation. The 1000 ms deadline, 64-ticket pages, 512 count, both
browsers, callback accounting, owner-field gate, and prior failures were not
weakened or deleted. This is implementation-agent review, not independent human
attestation.

LiveView and LocalLiveView remain **[DEFERRED]**. No browser, platform, profile,
public API, release, or support state is promoted. BH-06 remains ineligible and
unauthorized.

## Connections

- [Phase 17 plan](phase-17-provider-issued-release-tickets-and-owner-free-disposal.md)
- [Provider release-ticket contract](provider-release-ticket-contract.md)
- [Phase 17 attempt ledger](../../../../../integration/bh-05/provider-release-ticket-attempts-v0.1.0.json)
- [Phase 16 review](phase-16-review-and-reconciliation.md)
