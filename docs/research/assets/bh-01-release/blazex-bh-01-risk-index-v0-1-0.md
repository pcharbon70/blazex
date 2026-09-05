---
title: "BH-01 Risk Index"
kind: map
created: "2026-09-05"
tags:
  - bh-01
  - generated-index
  - feasibility
aliases:
  - "BH-01 Risk Index generated view"
---

# BH-01 Risk Index

> Generated from `BX-BH01-FEASIBILITY-BASELINE-0.1.0` (`2e8f96b2afe2e139543c898249161b8e5794a4876eccd8bac679a4347e1134ff`). Edit canonical evidence, not this view.

- `BX-BH01-RISK-AUTHENTICATED-COMMAND` — **accepted-residual**, low/critical: Production identity, persistence, distributed limits, TLS, audit sinks, and penetration testing are not established. Trigger: Before production authority or authentication design
- `BX-BH01-RISK-BROWSER-PREREQUISITES` — **accepted-residual**, medium/high: Only exact Linux Chrome and a Firefox development binary have current evidence; all remain unsupported. Trigger: Browser pin, prerequisite, deployment, or BH-22 change
- `BX-BH01-RISK-DEPENDENCY-ACCESS` — **accepted-residual**, low/high: Upstream availability and registries remain external dependencies despite retained identities. Trigger: Any dependency source, checksum, license, or registry change
- `BX-BH01-RISK-MOBILE-PERFORMANCE` — **deferred-bh22**, unknown-deferred/unknown-deferred: Mobile viability is undecided; desktop or emulated evidence cannot reduce this uncertainty. Trigger: Representative Android or iOS/iPadOS environment becomes available or BH-22 starts
- `BX-BH01-RISK-PRIVATE-API-COUPLING` — **accepted-residual**, high/high: No adjacent package range is qualified; upgrades can disable the optional adapter. Trigger: Phoenix, LiveView, LocalLiveView, or adapter pin changes
- `BX-BH01-RISK-RUNTIME-SEMANTICS` — **accepted-residual**, medium/high: AtomVM timer cancellation reports false and scale/fairness/long-soak coverage remains experimental. Trigger: Runtime/Popcorn/OTP change or semantic-contract design
- `BX-BH01-RISK-TOOLCHAIN-REPRODUCIBILITY` — **accepted-residual**, low/critical: Both authoritative runs used one physical Linux host, and Elixir macro literals remain path-sensitive outside the canonical root. Trigger: Tool identity, build path contract, source revision, or second-machine availability changes
- `BX-BH01-RISK-WASM-ARTIFACT-ACCOUNTING` — **accepted-residual**, high/high: The unpruned application AVM dominates payload and fails decoded and compressed application budgets. Trigger: Before release/profile hardening or any runtime/bundle composition change

## Connections

- [BH-01 plan](../../60-planning/01-browser-host/bh-01-reproducible-browser-feasibility-baseline/README.md)
