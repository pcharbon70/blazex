---
title: "Compact Cleanup Outcome Contract"
kind: note
created: "2026-09-11"
maturity: developing
tags:
  - bh-05
  - cleanup
  - contract
  - reliability
  - scaling
aliases:
  - "BH-05 compact outcome pages"
---

# Compact Cleanup Outcome Contract

Back to milestone: [README](README.md)

## Bound corrective evidence

Phase 14 starts from `7798903bf74250ead754955502fe33ccb5e4a974`.
The immutable Phase 13 inputs are bound at their starting hashes:

| Input | SHA-256 |
| --- | --- |
| `phase-13-bounded-paged-cleanup-and-scaling-requalification.md` | `f42eaf9164e0f04d1654f9dcae83493ac0ac38e663c089ac44b3bb94097ad1bd` |
| `phase-13-completion.md` | `70f500b7eb52130f76372f76db3925e26094b64852e3d8cbd68c4b43b4c54e2b` |
| `phase-13-review-and-reconciliation.md` | `30e6b6d75fa3129b8f3b20b65a4738f9d7d83d5d81b292c9dec7f115e25ddf14` |
| `assets/bh-05-baseline/bh-05-phase13-acceptance-overlay-v0.1.0.json` | `9ff67af8ab055cca740e0b513b4f033383668937f9f0d96ebee2d2631604ccda` |
| `assets/bh-05-baseline/bh-06-phase13-entry-decision-v0.1.0.json` | `2d6c28e243c94ee66df291e258ff744bbdb2843ad0ba592b250e29bbd1dbd682` |
| `integration/bh-05/cleanup-scaling-attempts-v0.1.0.json` | `c45e35e02af3a5c727184a23c1cd9c802c379b8c32a760c955f3953923863b47` |
| `packages/blazex_core/lib/blazex/component/recovery_cleanup.ex` | `e67d82a75c1a22612cc8e90ab0be059166c22130420d64a7a9c2e8f65e16bac4` |
| `packages/blazex_core/lib/blazex/component/root_port.ex` | `3c28373d6282037ca7863bf99bb5f817fdf0c02d197de83e450228dac6dca50d` |
| `packages/blazex_core/lib/blazex/component/action_ledger.ex` | `dd310f6e544f43753420cd3578abf685c05b4d311c3c6b251cf494cd2090629f` |

The Phase 13 outcome remains `revise`. Firefox's retained 512-resource result
is a real deadline failure and may not be relabeled or removed.

## Version 1 page

A lease outcome page has `version: 1`, `kind: :lease`, an ordered non-empty
`identities` list of at most 64 `{owner, lease_id}` pairs, and `elapsed_ms`.
Each of `status`, `force_status`, and `unresolved` is either a scalar shared by
the page or a vector whose length equals the identity count. Normal statuses
are `:completed`, `:failed`, or `:timed_out`; forced statuses are
`:not_requested`, `:completed`, `:failed`, or `:timed_out`; unresolved values
are booleans.

This preserves exact per-resource truth while encoding common outcomes once.
Acquisition payload and adapter-private lease data are not cleanup identity and
must not be copied into the report. The timed path may fold pages but must not
expand them into diagnostic row maps.

## Required operations

- Construction validates identity and outcome cardinality.
- Folding visits every correlated item in order and rejects malformed pages.
- Unresolved extraction returns exact ordered owner and lease ID pairs.
- Diagnostic expansion is bounded to 512 rows, explicitly counted, and only
  used by tests and evidence readers outside the timed path.
- Forced cleanup updates exact failed positions and cannot mask one failure.
- Ledger reconciliation consumes the ordered terminal vector atomically and
  rejects count or identity mismatch.

## Invariants retained unchanged

The deadline includes inventory, sorting, sessions, result collation, forced
cleanup, report encoding, and ledger finalization. Page size remains 64,
maximum page size remains 128, resource count remains 512, and success requires
zero live plus zero unresolved leases. Linux Chrome and Firefox are active;
unavailable environments are **[DEFERRED]** to BH-22. LiveView and
LocalLiveView remain **[DEFERRED]**.

## Connections

- [Phase 14 plan](phase-14-compact-cleanup-outcomes-and-firefox-requalification.md)
- [Phase 13 completion](phase-13-completion.md)
- [Cleanup scaling contract](cleanup-scaling-contract.md)
