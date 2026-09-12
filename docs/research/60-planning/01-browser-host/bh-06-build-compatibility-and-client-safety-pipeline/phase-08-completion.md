---
title: "BH-06 Phase 8 Completion Evidence"
kind: note
created: "2026-09-12"
maturity: developing
tags: [bh-06, brotli, build, completion, payload, wasm]
aliases: []
---

# BH-06 Phase 8 Completion Evidence

Back to the [plan](phase-08-payload-budgets-and-public-artifact-accounting.md)
and [review](phase-08-review-and-reconciliation.md).

## Outcome

Phase 8 measurement and enforcement are complete, but the decision is
**revision-required**. Four budgets pass. The runtime/base owner measures
2,689,798 Brotli bytes against the frozen 1,638,400-byte threshold, an excess of
1,051,398 bytes. The threshold was not raised and the normal package command
promoted no rejected output.

The application feature is 2,124 decoded bytes and 1,117 Brotli bytes. Loader
and bootstrap total 168,562 decoded and 34,338 Brotli bytes. Public source maps
are exactly zero. Six build reports are classified private, live under
`evidence/`, and receive 404 from the local evidence server.

## Execution evidence

The twelve-artifact build manifest SHA-256 is
`11c393b9ebc03bed2e118c680d712e9de6c69f1fadc0799e377a853c2ebaca58`.
The payload report SHA-256 is
`78daf2dcd3b1cae3c2a8385fa469dd8fdc9893f3c150c2b322179385d72a72d1`.
Two builds, all Brotli sidecars, and payload reports were byte-identical.

Chrome 140 and Firefox 153 negotiated Brotli for the manifest, feature, runtime
module, runtime Wasm, and base AVM while decoded integrity, dynamic feature load,
interaction, and disposal continued to pass with no page errors. Both browser
reports were byte-identical; their SHA-256 is
`78311019097b285cf03d8b613d6663b03e8f2a4cad51416d5377f80ea3ead53f`.

## Boundary

Acceptance requires a separately planned reduction of the runtime/base closure,
not a budget waiver. This local Brotli proof does not qualify Phoenix, Plug,
proxy, CDN, or production caching behavior. LiveView and LocalLiveView remain
**[DEFERRED]**; no production support, BH-07, or BH-19 authority is implied.
