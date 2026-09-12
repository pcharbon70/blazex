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

Later phase decomposition remains a separate planning decision. Phases 1-4 do
not authorize secret scanning, licenses, payload
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

### Subdirectories

None.

## Maintaining this index

Add phases only when need and authority are explicit. Every phase gets one
commit per section and one pull request after its truthful integration gate.
Preserve failed active-browser results; never turn them into deferrals.
