---
title: "BH-06 Phase 7 - Deterministic Feature Bundles"
kind: note
created: "2026-09-12"
maturity: developing
tags: [bh-06, build, feature-bundles, implementation-planning, wasm]
aliases: ["BH-06 phase 7"]
---

# BH-06 Phase 7 - Deterministic Feature Bundles

Back to the [milestone](README.md).

- [ ] 7 Phase - Deterministic Feature Bundles.
  - Need: Phase 6 inventories one monolithic application AVM, so feature code
    cannot be acquired, verified, or loaded independently of shared startup code.
  - Outcome: a versioned bundle policy assigns every BEAM input exactly once to
    base or feature ownership; the browser verifies and dynamically loads the
    counter feature AVM into the existing AtomVM instance before mounting it.
  - Boundary: this phase owns decomposition, conflict rejection, content
    identity, acquisition, integrity, and real dynamic load, not route orchestration,
    predictive prefetch, payload budgets, production support, LiveView,
    LocalLiveView, BH-07, or BH-19 package distribution.

  - [x] 7.1 Section - Bind Phase 6 and freeze bundle authority.
    - [x] Bind accepted Phase 6 evidence, exact base, delivery workflow, and deferrals.
    - [x] Freeze base/feature identity, startup ownership, module exclusivity,
      limits, ordering, diagnostics, acquisition, integrity, and load rules.
    - [x] Activate versioned policy and plan schemas without claiming a pass.

  - [x] 7.2 Section - Implement deterministic bundle planning.
    - [x] Validate bounded policies and path-free module declarations without
      creating atoms or retaining filesystem paths.
    - [x] Assign every candidate BEAM exactly once, require exact feature module
      sets and base-owned startup modules, and emit stable reason records.
    - [x] Reject missing, duplicate, unknown, overlapping, malformed, or
      overflowed declarations with deterministic diagnostics.

  - [ ] 7.3 Section - Package and dynamically load the first feature AVM.
    - [ ] Run safety, compatibility, secret, license, and bundle gates before
      creating separate base and counter archives.
    - [ ] Bind the plan and each archive by content identity in the manifest;
      verify the counter archive in the browser before loading it once.
    - [ ] Prove absent-before-load, real AtomVM dynamic load, mount, interaction,
      disposal, duplicate-load rejection, tamper rejection, and browser parity.

  - [ ] 7.4 Section - Reproduce, review, and publish completion.
    - [ ] Run package, browser-Wasm, validator, mutation, deterministic-repeat,
      archive, runtime, JavaScript, demo, syntax, and patch-hygiene gates.
    - [ ] Publish exact counts, hashes, commands, failures, limitations, and deferrals.
    - [ ] Accept only if every BEAM has one bundle owner and the separately
      verified feature executes in both active browsers through one shared VM.

## Exit gate

Equivalent policy and inputs must produce identical plans and archives. Every
candidate BEAM has exactly one owner; feature membership exactly matches policy;
startup modules remain in base. The feature module is absent before load,
integrity-verified before transfer, added exactly once to the running AtomVM,
and used by the existing lifecycle proof. Missing, duplicate, conflicting, or
tampered inputs and any active-browser regression block completion.

## Connections

- [Phase 6 completion](phase-06-completion.md)
- [Feature-bundle contract](feature-bundle-contract.md)
- [Framework packaging synthesis](../../../20-notes/elixir-webassembly-component-framework-for-phoenix-and-plug.md)
