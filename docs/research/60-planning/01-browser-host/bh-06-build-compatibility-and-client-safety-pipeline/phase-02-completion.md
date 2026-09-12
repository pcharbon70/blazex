---
title: "BH-06 Phase 2 Completion Evidence"
kind: note
created: "2026-09-12"
maturity: developing
tags: [beam, bh-06, build, completion, evidence, reachability]
aliases: []
---

# BH-06 Phase 2 Completion Evidence

Back to the [plan](phase-02-explicit-entrypoints-and-deterministic-reachability.md)
and [review](phase-02-review-and-reconciliation.md).

## Outcome

Phase 2 is complete with decision **accept**. Client roots are now explicit,
bounded, and atom-safe; trusted BEAM inputs produce deterministic, path-free
module facts; and static traversal records a shortest entrypoint-rooted reason
for every included inventory module. External imports and unused inventory are
visible, ambiguous `apply/2,3` dispatch fails without a bounded declaration,
and the report is a content-addressed candidate-manifest asset.

## Reproduction

Two clean Elixir 1.17.3 package builds produced byte-identical trees. The
generated manifest contains six governed artifacts totaling 8,379,344 bytes
and has SHA-256
`700dd4c1fc69182872050335d8454dd48073e79a5c3d8f6a47b3c26bf63cd515`.
The canonical 1,073-byte report has SHA-256
`6e68b90b14157d8358bb8b097bd224b3b9e7de0709e4b8cd9837ea5579f051be`.

The report accounts for 2 inventory modules: 1 reachable root with an exact
reason chain, 1 unused sentinel excluded from the AVM, 0 known in-inventory
edges, 4 retained external references, and 0 dynamic allowances. Direct AVM
listing contains Boot, Browser, and Counter, but not the unused sentinel.

Two complete Chrome/Firefox runs were byte-identical before normalization; the
raw Phase 2 browser report SHA-256 is
`34346868bd10be6daabad9b66cd1c9495bd994b29a1fd4fcd1f057c8c238e597`.
The committed normalized replay is
[phase-02-browser-replay-v0.1.0.json](../../../../../integration/bh-06/phase-02-browser-replay-v0.1.0.json).
Package, integration, JavaScript, validator, mutation, JSON, archive,
deterministic-repeat, syntax, dependency, and patch-hygiene gates pass subject
to the clean-container Hex archive limitation recorded in the review.

## Bound evidence

- Phase 2 manifest SHA-256: `700dd4c1fc69182872050335d8454dd48073e79a5c3d8f6a47b3c26bf63cd515`.
- Committed reachability evidence SHA-256: `ff5e1a42d18c9f538d748590f7ed1e6bab3fe1233b3e23fc727ad270d7dd24d0`.
- Canonical reachability asset SHA-256: `6e68b90b14157d8358bb8b097bd224b3b9e7de0709e4b8cd9837ea5579f051be`.
- Browser replay evidence SHA-256: `73954b543acdf182b92cbde8f7a08bcba9b3f5a5a09725f636732307b5d795e6`.
- Reachability implementation SHA-256: `74f26315bc38858222ca293dc6b3ffdbbc3a1adc7b844f460f9a64ee87dcbef6`.
- Section 2.3 revision: `32fabd71a98b01a0443c5baba7e836778236f97a`.

Further BH-06 decomposition requires separate planning and authorization.
LiveView and LocalLiveView remain deferred; no production support or BH-07
authority is implied.
