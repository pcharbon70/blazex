---
title: "BH-06 Build, Compatibility, and Client-Safety Pipeline"
kind: map
created: "2026-09-11"
tags: [archive-navigation, bh-06, build, client-safety, directory-index]
aliases: ["BH-06 implementation plan"]
---

# BH-06 Build, Compatibility, and Client-Safety Pipeline

## Purpose

Turn browser releases into inspectable, deterministic products with explicit
entrypoints, reachability, compatibility, manifests, assets, integrity, size,
and client-safety diagnostics. Build logic belongs to `packages/blazex_build`;
runtime facts remain owned by `packages/blazex_runtime_popcorn`.

LiveView and LocalLiveView are **[DEFERRED]** and are not build inputs,
entrypoints, compatibility targets, or completion gates for this milestone.

## What belongs here

- Phase plans, build contracts, browser-Wasm evidence, and reconciliation.
- Ownership and stop rules for manifests, bundles, assets, and client safety.
- Active Linux Chrome/Firefox evidence and explicitly deferred qualification.

## Ordered phases

| Phase | Status | Delivery | Dependency |
| --- | --- | --- | --- |
| [1 — First Continuous Browser-Wasm Vertical Slice](phase-01-first-continuous-browser-wasm-vertical-slice.md) | complete — accept | Package one public Elixir component through a candidate entrypoint, deterministic manifest/bundle/assets, then prove mount, semantic render, interaction, state transition, DOM commit, and disposal in Chrome and Firefox. | Accepted BH-05 and explicit authorization |
| [2 — Explicit Entrypoints and Deterministic Reachability](phase-02-explicit-entrypoints-and-deterministic-reachability.md) | complete — accept | Inventory supplied BEAMs, traverse static imports from explicit client roots, retain reason chains/external references/unused modules, and reject ambiguous dispatch. | Phase 1 and explicit authorization |
| [3 — Server and Native Client-Safety Gate](phase-03-server-native-client-safety-gate.md) | complete — accept | Classify every reachable and external dependency exactly, then reject server-only, native, unknown, and forbidden runtime primitives before bundle assembly. | Phase 2 and explicit authorization |
| [4 — Exact Runtime Compatibility Profiles](phase-04-exact-runtime-compatibility-profiles.md) | complete — accept | Match runtime identity/version/ABI, protocol versions, and required features exactly, then reject incompatibility before bundle assembly. | Phase 3 and explicit authorization |
| [5 — Secret-Bearing Input Exclusion](phase-05-secret-bearing-input-exclusion.md) | complete — accept | Account for and scan candidate bundle/browser inputs and explicit public configuration, then reject redacted findings before AVM assembly. | Phase 4 and explicit authorization |
| [6 — License and Provenance Inventory](phase-06-license-and-provenance-inventory.md) | complete — accept | Bind every Phase 5 input to one declared component and exact license/provenance records, verify notices, and reject gaps before AVM assembly. | Phase 5 and explicit authorization |
| [7 — Deterministic Feature Bundles](phase-07-deterministic-feature-bundles.md) | complete — accept | Assign every BEAM to base or exact feature ownership, then verify and dynamically load the counter feature AVM into the existing browser AtomVM. | Phase 6 and explicit authorization |
| [8 — Payload Budgets and Public Artifact Accounting](phase-08-payload-budgets-and-public-artifact-accounting.md) | active | Classify public payload versus private build evidence, measure deterministic Brotli/decoded bytes, enforce budgets and zero public source maps, and prove local negotiation. | Phase 7 and explicit authorization |

Later phase decomposition remains a separate planning decision. Phases 1-8 do
not authorize route orchestration, predictive prefetch, payload
budgets, production releases, support promotion, or BH-07.

## Index

### Documents

- [Phase 1 — First Continuous Browser-Wasm Vertical Slice](phase-01-first-continuous-browser-wasm-vertical-slice.md)
- [Phase 1 review and reconciliation](phase-01-review-and-reconciliation.md)
- [Phase 1 completion evidence](phase-01-completion.md)
- [Phase 2 — Explicit Entrypoints and Deterministic Reachability](phase-02-explicit-entrypoints-and-deterministic-reachability.md)
- [Entrypoint and reachability contract](entrypoint-and-reachability-contract.md)
- [Phase 2 review and reconciliation](phase-02-review-and-reconciliation.md)
- [Phase 2 completion evidence](phase-02-completion.md)
- [Phase 3 — Server and Native Client-Safety Gate](phase-03-server-native-client-safety-gate.md)
- [Client-safety policy contract](client-safety-policy-contract.md)
- [Phase 3 review and reconciliation](phase-03-review-and-reconciliation.md)
- [Phase 3 completion evidence](phase-03-completion.md)
- [Phase 4 — Exact Runtime Compatibility Profiles](phase-04-exact-runtime-compatibility-profiles.md)
- [Compatibility profile contract](compatibility-profile-contract.md)
- [Phase 4 review and reconciliation](phase-04-review-and-reconciliation.md)
- [Phase 4 completion evidence](phase-04-completion.md)
- [Phase 5 — Secret-Bearing Input Exclusion](phase-05-secret-bearing-input-exclusion.md)
- [Secret-exclusion contract](secret-exclusion-contract.md)
- [Phase 5 review and reconciliation](phase-05-review-and-reconciliation.md)
- [Phase 5 completion evidence](phase-05-completion.md)
- [Phase 6 — License and Provenance Inventory](phase-06-license-and-provenance-inventory.md)
- [License and provenance contract](license-and-provenance-contract.md)
- [Phase 6 review and reconciliation](phase-06-review-and-reconciliation.md)
- [Phase 6 completion evidence](phase-06-completion.md)
- [Phase 7 — Deterministic Feature Bundles](phase-07-deterministic-feature-bundles.md)
- [Feature-bundle contract](feature-bundle-contract.md)
- [Phase 7 review and reconciliation](phase-07-review-and-reconciliation.md)
- [Phase 7 completion evidence](phase-07-completion.md)
- [Phase 8 — Payload Budgets and Public Artifact Accounting](phase-08-payload-budgets-and-public-artifact-accounting.md)
- [Payload-accounting contract](payload-accounting-contract.md)

### Subdirectories

None.

## Maintaining this index

Add phases only when need and authority are explicit. Every phase gets one
commit per section and one pull request after its truthful integration gate.
Preserve failed active-browser results; never turn them into deferrals.
