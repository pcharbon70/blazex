---
title: "BH-06 Phase 9 - Audited Runtime Closure Reduction"
kind: note
created: "2026-09-12"
maturity: developing
tags: [bh-06, build, payload, pruning, reachability, wasm]
aliases: ["BH-06 phase 9"]
---

# BH-06 Phase 9 - Audited Runtime Closure Reduction

Back to the [milestone](README.md).

- [x] 9 Phase - Audited Runtime Closure Reduction.
  - Need: Phase 8 correctly rejects 2,689,798 runtime Brotli bytes against the
    frozen 1,638,400-byte limit. Module-only packbeam pruning still measures
    1,861,444 bytes, so the base needs explicit function-level reduction.
  - Outcome: a closed policy roots the boot/browser and known dynamic code,
    records every removed module/function, packages only the reduced base, and
    re-runs the unchanged payload and browser gates.
  - Boundary: this corrective phase owns one pinned Popcorn treeshake profile,
    audit evidence, archive construction, and regression proof. It does not
    authorize generic user configuration, route orchestration, prefetch,
    production serving/support, LiveView, LocalLiveView, BH-07, or BH-19.

  - [x] 9.1 Section - Bind Phase 8 failure and freeze reduction authority.
    - [x] Bind Phase 8 evidence, exact revision, failed budget, workflow, and deferrals.
    - [x] Freeze keep/leave/ignore/drop declarations, original-input identity,
      tool identity, scaling limits, diagnostics, and fail-closed rules.
    - [x] Activate policy and report schemas without assuming budget success.

  - [x] 9.2 Section - Implement audited closure reduction.
    - [x] Validate declarations without creating atoms and reject unknown,
      duplicate, overlapping, missing, or over-limit entries.
    - [x] Run deterministic import-graph reduction over the whole base and the
      pinned function reducer over compiler-metadata-bearing BEAMs; carry every
      reachable opaque BEAM byte-for-byte and report it explicitly.
    - [x] Preserve the feature archive boundary and emit stable module/function
      deltas; reject output additions, identity drift, missing roots, empty output,
      non-subset results, and nondeterministic reports.

  - [x] 9.3 Section - Package and replay the reduced candidate.
    - [x] Feed only the audited reduced base to archive assembly and bind the
      closure report as private evidence before payload evaluation.
    - [x] Extend the closed role policy only for that private report, then re-run
      the unchanged Phase 8 owners, metrics, compression, thresholds, and normal
      promotion path.
    - [x] Prove feature absence/load, interaction, disposal, Brotli negotiation,
      private-evidence denial, integrity negatives, and Chrome/Firefox parity.

  - [x] 9.4 Section - Reproduce, review, and publish completion.
    - [x] Run package, browser-Wasm, validator, mutation, deterministic-repeat,
      archive, runtime, JavaScript, demo, syntax, and patch-hygiene gates.
    - [x] Publish exact before/after modules, functions, bytes, hashes, budgets,
      failures, limitations, and deferrals.
    - [x] Accept only when the unchanged runtime threshold passes and both active
      browsers execute the reduced archive without missing-code failures.

## Exit gate

Equivalent authorized inputs produce identical reduced BEAMs, closure reports,
archives, Brotli sidecars, manifests, and browser reports. Output modules are a
non-empty subset of the base inputs; every removal is reported; all declared
roots survive. The original payload policy passes without reclassification or
threshold drift, and Chrome/Firefox complete the existing one-runtime feature
and lifecycle proof.

## Connections

- [Phase 8 completion](phase-08-completion.md)
- [Runtime-closure contract](runtime-closure-contract.md)
- [Payload-accounting contract](payload-accounting-contract.md)
