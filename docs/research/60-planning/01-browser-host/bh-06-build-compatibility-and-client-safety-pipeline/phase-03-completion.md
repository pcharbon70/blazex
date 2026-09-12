---
title: "BH-06 Phase 3 Completion Evidence"
kind: note
created: "2026-09-12"
maturity: developing
tags: [bh-06, build, client-safety, completion, evidence, native, server]
aliases: []
---

# BH-06 Phase 3 Completion Evidence

Back to the [plan](phase-03-server-native-client-safety-gate.md) and
[review](phase-03-review-and-reconciliation.md).

## Outcome

Phase 3 is complete with decision **accept**. Trusted application ownership is
now retained in path-free BEAM facts, every bounded reachable/external module
requires an exact policy explanation, and safety authorization precedes AVM
assembly. Server-only, native, unknown, NIF/port, contradictory, and unused
candidate policy cases fail closed with stable diagnostics.

## Reproduction

Two clean pinned-toolchain builds produced byte-identical trees. The exact
manifest contains seven governed artifacts totaling 8,380,636 bytes and has
SHA-256
`4a23f01f76b7a44e16405bda5e855b319b026b5ce5ec4e635e6c33c9d3e2ff14`.
The 740-byte canonical safety report has SHA-256
`4f79b17eaa8b7bccdcd66d25962756a275b632d075ad6560213ff44ca36b36af`;
its normalized policy SHA-256 is
`84c41a120c7aff18a0062aee84dbc9266f3a3bc87ea89efea8be50f29187f428`.

The accepted report records 1 client-safe reachable module, 1 runtime-safe
external module, 6 forbidden primitive signatures checked, and 0 violations.
The negative matrix covers server-only, native, unknown ownership, missing
external coverage, NIF loading, port operations, duplicate/malformed policy,
unused declarations, policy mutation, report mutation, and pre-assembly stop.

Two Chrome/Firefox runs were byte-identical before normalization; raw report
SHA-256 was
`f4932488befa84b596090121576045f098e7ed4c483eb6b1f3e63d513392ab8e`.
The committed normalized replay is
[phase-03-browser-replay-v0.1.0.json](../../../../../integration/bh-06/phase-03-browser-replay-v0.1.0.json).

## Bound evidence

- Phase 3 manifest SHA-256: `4a23f01f76b7a44e16405bda5e855b319b026b5ce5ec4e635e6c33c9d3e2ff14`.
- Committed policy SHA-256: `9570e080b377103607218050e469ce44e285fef4795683b39f7926caa1973ade`.
- Committed safety evidence SHA-256: `9785ca745749495b1a486f48acbe525544e68322b718423172113491281ceaa8`.
- Canonical policy SHA-256: `84c41a120c7aff18a0062aee84dbc9266f3a3bc87ea89efea8be50f29187f428`.
- Canonical safety asset SHA-256: `4f79b17eaa8b7bccdcd66d25962756a275b632d075ad6560213ff44ca36b36af`.
- Browser replay evidence SHA-256: `9b3acc29b8000162b98c235b43969a28c42ad004b283beeacf0407b0f14483e3`.
- Client-safety implementation SHA-256: `169b5ee1d14602eea1d6579846c81d0ecafbb18210fabdf21374a8c35dbd8735`.
- Section 3.3 revision: `b0989974e1250755a2c5ce8628e737745233bbf5`.

Further BH-06 decomposition requires separate planning and authorization.
LiveView and LocalLiveView remain deferred; no production support or BH-07
authority is implied.
