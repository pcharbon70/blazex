---
title: "BH-06 Phase 9 Completion Evidence"
kind: note
created: "2026-09-12"
maturity: developing
tags: [bh-06, build, completion, pruning, wasm]
aliases: []
---

# BH-06 Phase 9 Completion Evidence

Back to the [plan](phase-09-audited-runtime-closure-reduction.md) and
[review](phase-09-review-and-reconciliation.md).

## Outcome

Phase 9 is **complete — accept**. The client-only base starts from 692 modules
and 19,536,608 BEAM bytes. Audited graph and function reduction produces 423
modules and 7,683,472 BEAM bytes: 269 modules, 1,035 functions, and 11,853,136
bytes are removed. Fifty-seven reachable BEAMs without compiler metadata are
carried byte-for-byte; 121 analyzable modules imported by those opaque callers
are retained as explicit bridge roots.

The reduced base AVM plus AtomVM Wasm measure 1,570,291 Brotli bytes against the
unchanged 1,638,400-byte runtime threshold, passing by 68,109 bytes. All four
other Phase 8 budgets also pass. The only payload-policy extension classifies
the new closure report as private build evidence; public roles, owners,
compression settings, metrics, and thresholds are unchanged.

## Execution evidence

Two independent package runs produced byte-identical trees, Brotli sidecars,
manifests, closure reports, and payload reports. The closure report SHA-256 is
`98cb99ead3012096b28ac696238ba4e90b838a11919a18fa91ee5a049a904bed`;
the payload report is
`a641e7a3dbb36db52516aa75652039ea1e9fcae58018303c0002a974b6c6286a`;
and the thirteen-artifact manifest is
`c115777a23bead3963cef9341d0cd6df797ea6f607bae19080acbb21535338d3`.

Chrome 140 and Firefox 153 both pass AtomVM readiness, Brotli negotiation,
feature absence and dynamic load, duplicate-load rejection, mount, semantic
render, browser interaction, Elixir state transition, DOM update, and disposal
with no page errors. Integrity mutations fail closed and private evidence
returns 404. Independent browser reports are byte-identical with SHA-256
`4462360f45f267419bd3e43bbf96894952a75e86dd02f76cef7d0e478c52f3ed`.

## Boundary

This is one pinned development fixture, not a general application tree-shaker
or production release qualification. The 68,109-byte runtime margin is real but
narrow and must not be treated as a universal budget. Production serving,
route orchestration, predictive prefetch, support promotion, BH-07, and BH-19
remain outside scope. LiveView and LocalLiveView remain **[DEFERRED]**.
