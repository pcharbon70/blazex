---
title: "BH-06 Phase 8 - Payload Budgets and Public Artifact Accounting"
kind: note
created: "2026-09-12"
maturity: developing
tags: [bh-06, build, brotli, payload, source-maps, wasm]
aliases: ["BH-06 phase 8"]
---

# BH-06 Phase 8 - Payload Budgets and Public Artifact Accounting

Back to the [milestone](README.md).

- [ ] 8 Phase - Payload Budgets and Public Artifact Accounting.
  - Need: Phase 7 identifies base and feature archives, but the candidate still
    has no enforced decoded/Brotli budgets, public/private artifact boundary, or
    executable zero-public-source-map gate.
  - Outcome: every output is classified as public payload or private build
    evidence, every public byte is measured reproducibly, and an over-budget or
    source-map-bearing candidate is rejected before promotion.
  - Boundary: this phase measures and gates the existing candidate. It does not
    authorize reachability optimization, route orchestration, predictive
    prefetch, cache/CDN qualification, production support, LiveView,
    LocalLiveView, BH-07, or BH-19.

  - [x] 8.1 Section - Bind Phase 7 and freeze payload authority.
    - [x] Bind the accepted Phase 7 evidence, exact base revision, workflow, and deferrals.
    - [x] Freeze public/private ownership, Brotli settings, repetitions,
      thresholds, source-map exclusion, ordering, and diagnostics.
    - [x] Activate versioned policy and report schemas without presuming a pass.

  - [x] 8.2 Section - Implement deterministic payload measurement and gates.
    - [x] Validate the policy without creating atoms or accepting unknown roles.
    - [x] Brotli-compress each public artifact three times at quality 11 and
      reject nondeterministic output, missing/extra ownership, or identity drift.
    - [x] Enforce decoded/compressed budgets and exact zero public source maps
      with stable, machine-readable failures.

  - [ ] 8.3 Section - Apply the gate to the browser-Wasm candidate.
    - [ ] Mark diagnostic reports private and prevent the evidence server from serving them.
    - [ ] Generate a bound payload report and precompressed public artifacts,
      negotiate Brotli in the active browser server, and retain decoded integrity.
    - [ ] Prove Chrome/Firefox parity, negotiation, tamper rejection, and truthful
      rejection of any exceeded budget before candidate promotion.

  - [ ] 8.4 Section - Reproduce, review, and publish completion.
    - [ ] Run package, browser-Wasm, validator, mutation, deterministic-repeat,
      archive, runtime, JavaScript, demo, syntax, and patch-hygiene gates.
    - [ ] Publish exact counts, bytes, hashes, commands, failures, limitations, and deferrals.
    - [ ] Accept only if every required budget passes; otherwise close the phase
      as measured revision-required evidence without weakening thresholds.

## Exit gate

Equivalent policy and public inputs produce byte-identical Brotli sidecars and
reports. Each output has exactly one public/private disposition. Every public
artifact is identity-bound and counted once; every private evidence path is
unservable; public source maps are exactly zero. Threshold excess, missing or
extra accounting, nondeterministic compression, exposure drift, or browser
negotiation/integrity regressions block acceptance.

## Connections

- [Phase 7 completion](phase-07-completion.md)
- [Payload-accounting contract](payload-accounting-contract.md)
- [Quality budget policy](../../../20-notes/blazex-quality-budget-and-measurement-policy.md)
