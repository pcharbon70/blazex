---
title: "BH-06 Phase 2 Review and Reconciliation"
kind: note
created: "2026-09-12"
maturity: developing
tags: [beam, bh-06, build, reconciliation, reachability]
aliases: []
---

# BH-06 Phase 2 Review and Reconciliation

Back to the [plan](phase-02-explicit-entrypoints-and-deterministic-reachability.md)
and [completion evidence](phase-02-completion.md).

## Decision

The decision is **accept** for the bounded Phase 2 entrypoint and reachability
slice. Two clean builds under the pinned Elixir 1.17.3 toolchain are byte
identical. Their exact manifest SHA-256 is
`700dd4c1fc69182872050335d8454dd48073e79a5c3d8f6a47b3c26bf63cd515`;
the manifest binds the canonical reachability report SHA-256
`6e68b90b14157d8358bb8b097bd224b3b9e7de0709e4b8cd9837ea5579f051be`.

The explicit `counter` root reaches one inventoried component module. Four
Erlang runtime imports remain visible as external references, no dynamic
dispatch is allowlisted, and the deliberately inventoried `Unused` module is
reported but excluded from the AVM. Unit gates additionally exercise multiple
roots, cycles, lexical tie-breaking, missing roots, duplicate modules,
malformed BEAMs, undeclared dynamic dispatch, report mutation, and path-free
determinism.

## Browser and package reconciliation

Linux Chrome 140 and Firefox 153 both execute the exact Phase 2 AtomVM/Wasm
package through mount, semantic render, DOM commit, browser interaction,
Elixir state transition, updated commit, and disposal. Their observable
results match exactly, page errors are empty, and corrupting the bundle digest
still fails before runtime startup.

All version-compatible package and integration tests passed, including Build
11, Core 123, Effects 15, UI Tree 68, Renderer 8, Headless 6, DOM 116, Test 7,
and conformance 93. Exact-version Host 4, Popcorn runtime 4, Phoenix 10, and the
deferred LiveView adapter 4 also passed in the pinned image. The clean
`browser_host` fixture could not reacquire its Hex SCM archive in that image;
the direct Chrome/Firefox Phase 2 replay passed against the built Wasm package.
JavaScript runtime 31 and browser demo 7 tests passed.

The corpus-wide `check_all.py` remains red on inherited historical source-hash
and superseded-phase validators that already treat later accepted work as
drift. Its archive validator and both BH-06 validators pass. Phase 2 does not
rewrite earlier milestone evidence to conceal that accumulated maintenance
debt.

## Boundary

This phase proves deterministic reachability over a trusted, explicitly
supplied BEAM inventory. It does not claim whole-program call-graph precision,
server/native dependency safety, secret scanning, compatibility profiles,
license accounting, payload budgets, production release support, or BH-07.
Those remain later, separately authorized BH-06 work.

LiveView and LocalLiveView remain **[DEFERRED]** and were not entrypoints,
dependencies, or acceptance gates.
