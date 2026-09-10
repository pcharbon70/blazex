---
title: "BH-05 Phase 11 Cross-Runtime Conformance Evidence"
kind: note
created: "2026-09-10"
maturity: developing
tags:
  - atomvm
  - bh-05
  - conformance
aliases: []
---

# BH-05 Phase 11 Cross-Runtime Conformance Evidence

Back to [milestone](README.md) and [conformance contract](conformance-contract.md).

## Active results

The fixed public component corpus passes under local ERTS/headless, standalone
DOM in Linux Chrome and Firefox, the direct GTK portability slice, and the pinned
AtomVM/Popcorn WebAssembly runtime in Chrome 140.0.7339.80 and Firefox 153.0.
Both AtomVM rows execute component mount/render/event/failure callbacks, a
supervised process root, correlated disposal, recovery fallback, linked/monitored
helper cleanup and 256-page shared memory. Their normalized callback, semantic,
root, failure, disposal, DOM and final-state record matches exactly at SHA-256
`06755c7f4dc215dcc2f0e2d5cee7541edc625562dd7a0a514f7098be70d9ffdd`.

The local reference executes 93 conformance tests. Across packages there are
397 Elixir tests and 220 JavaScript tests, all passing. Direct GTK materializes
the retained surface/group/text/action/field/selection/collection and file-choice
slice, with stale rejection and idempotent disposal. GTK remains portability-only.

## Findings and corrections

The first full AtomVM root run found two ERTS-only digest dependencies. Regex
lowercase-hex validation invoked the absent `re` NIF. After byte-level validation,
`term_to_binary/2` with `[:deterministic]` invoked another absent NIF. BlazeX now
uses a portable canonical term followed by external-term encoding for its
cross-runtime integrity digests.
All behavioral suites remain passing. Phase 1–10 gate records and hashes remain
immutable; Phase 11 publishes a reviewed successor digest baseline rather than
silently rehashing historical evidence.

An early Firefox `noproc` was a harness readiness race. The runner now waits for
Popcorn's actual `popcorn_app_ready` signal and has a ten-second scenario deadline.
Both browsers then match exactly. Temporary crash dumps and trial evidence are
not accepted; the final ledger contains the reproducible corrected runs.

## Scope and limitations

The bundle is a fixed conformance fixture built through the accepted pinned
runtime closure. It is not BH-06 general dependency reachability or build support.
No public fixture imports Popcorn, browser, DOM, Phoenix, server, LiveView,
LocalLiveView or private BlazeX evaluator/process modules. Host and runtime code
remain adapters. Runtime/browser versions and measurements are retained as
allowed variation but excluded from semantic equality.

`[DEFERRED]` to BH-22: Windows and macOS execution, Safari/WebKit product rows,
Android/iOS physical devices and unavailable manual assistive-technology pairings.
These are not passes. LiveView and LocalLiveView remain separately deferred.
Support remains unsupported. All fourteen source-frozen gates passed against an
unchanged 1,128-file closure; Phase 12 is now eligible but unauthorized.
