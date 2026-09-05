---
title: "BH-02 Host-Neutral Semantic Kernel Gate"
kind: map
created: "2026-09-05"
tags:
  - archive-navigation
  - bh-02
  - browser
  - directory-index
  - host-neutral
  - implementation-planning
aliases:
  - "BH-02 implementation plan"
  - "BlazeX semantic kernel plan"
---

# BH-02 Host-Neutral Semantic Kernel Gate

## Purpose

This plan turns the successful BH-01 feasibility baseline into the first
host-neutral BlazeX contracts. It must prove that one semantic interaction set
can drive deterministic headless, standalone DOM, and direct native-control
adapters without importing browser, server-framework, runtime, or platform
objects into portable component code.

The milestone remains an experiment and contract gate. It does not establish
browser support, native-host support, a stable public component API, product
component families, production accessibility, or release readiness.

## Authorization status

The repository owner explicitly authorized BH-02 Phase 3 on 2026-09-05 after
Phase 2 passed and merged. The request retains section-ordered implementation,
one commit per section, one pull request for the phase, and cleanup of the
feature branch after returning to a synchronized `main`. Phase 3 is active;
Phases 4–8 remain planned and unauthorized. The completed gates are preserved
in the [Phase 1 implementation
evidence](phase-01-implementation-evidence.md) and [Phase 2 implementation
evidence](phase-02-implementation-evidence.md).

## What belongs here

- The exact BH-01 handoff, authorization, conditions, limitations, and
  disposable lessons inherited by BH-02.
- Versioned semantic-node, identity, event, effect, capability, resource,
  layout, token, accessibility, focus, selection, and renderer contracts.
- A deterministic headless oracle and common conformance fixtures.
- Standalone DOM lowering through the existing adapter boundary.
- A bounded direct Win32/AppKit/GTK native-control experiment.
- Automated dependency, forbidden-token, API-surface, and cross-renderer
  conformance gates.

Product component families, production profiles, broad native catalog work,
custom-scene production selection, and release qualification remain later
milestone work.

## Authoritative inputs

- [BH-02 conditional entry manifest](../../../assets/bh-01-release/blazex-bh-02-entry-manifest-v0-1-0.md)
- [BH-01 feasibility baseline](../../../assets/bh-01-release/blazex-bh-01-feasibility-baseline-v0.1.0.json)
- [Browser-host milestone roadmap](../../../20-notes/browser-host-implementation-milestones.md)
- [Host-neutral architecture](../../../20-notes/host-neutral-blazex-architecture-and-native-control-backends.md)
- [Direct native-host revision](../../../20-notes/cross-platform-native-host-and-renderer-architecture.md)
- [Development environment and deferred qualification policy](../../development-environment-and-deferred-qualification-policy.md)

## Ordered phases

| Phase | Status | Delivery | Dependency |
| --- | --- | --- | --- |
| [1 — Authorization, Input Reconciliation, and Foundation Activation](phase-01-authorization-input-reconciliation-and-foundation-activation.md) | complete — gate passed | Bind the BH-01 handoff, activate only the neutral foundation projects and evidence locations, and prove their dependency/leakage boundary. | Completed BH-01 and explicit authorization |
| [2 — Semantic Nodes, Identity, and Portable Component Evaluation](phase-02-semantic-nodes-identity-and-component-evaluation.md) | complete — gate passed | Define the first versioned semantic node/identity vocabulary and the smallest pure/stateful component evaluation contract. | Phase 1 |
| [3 — Events, Effects, Capabilities, and Resource Ownership](phase-03-events-effects-capabilities-and-resource-ownership.md) | active — explicitly authorized | Define validated semantic events and generation-scoped effect/resource lifecycles without host objects. | Phase 2 |
| 4 — Layout, Tokens, Accessibility, Focus, and Selection Intent | planned — not authorized | Complete the portable intent needed by the representative interaction slice. | Phases 2–3 |
| 5 — Renderer Lifecycle and Deterministic Headless Oracle | planned — not authorized | Implement renderer negotiation, mount/update/dispose behavior, canonical normalization, and trace fixtures. | Phases 2–4 |
| 6 — Standalone DOM Lowering and Browser Conformance | planned — not authorized | Replace disposable BH-01 DOM operations with a conforming renderer adapter and browser evidence. | Phase 5 |
| 7 — Direct Native-Control Portability Spike | planned — not authorized | Exercise the same slice through direct Win32, AppKit, and GTK adapters; unavailable target execution remains deferred under policy. | Phase 5 |
| 8 — Cross-Backend Reconciliation and BH-02 Acceptance | planned — not authorized | Resolve semantic leaks, review every required output and condition, and accept, revise, or block later framework work. | Phases 6–7 |

## Shared delivery rules

1. Obtain separate authorization before each phase.
2. Begin from synchronized `main` on a `codex/` branch.
3. Complete sections in order and create exactly one coherent commit for each
   completed section.
4. Open one pull request only after the phase integration gate passes or
   records a truthful stop decision.
5. Keep APIs experimental until Phase 8 accepts them; a compiled skeleton is
   not a stable component contract.
6. Preserve the BH-01 baseline and entry manifest as immutable evidence.
7. Apply the development-environment policy: unavailable Windows, macOS,
   physical-device, stable-browser, and manual assistive-technology evidence
   is `[DEFERRED]`, not passing evidence.
8. Exclude Qt and wxWidgets directly and transitively. The native proof uses
   direct Win32, AppKit, and GTK controls.
9. No portable project may depend on Phoenix, Plug, LiveView, LocalLiveView,
   Popcorn, AtomVM, DOM/JavaScript APIs, or native platform/toolkit objects.
10. Stop if implementation requires redefining BH-00, promoting a disposable
    BH-01 fixture shape, weakening a proof, or hiding host-specific behavior.

## Milestone exit

BH-02 exits only when the same layout, action, field, selection, keyed-list,
surface, focus, file-choice, and disposal traces pass the deterministic
headless oracle, standalone DOM adapter, and direct native-control experiment;
all required outputs and inherited conditions are reconciled; forbidden edges
and object leakage are absent; and independent review accepts or rejects the
first portable contract version without making a support claim.

## Index

### Subdirectories

- None yet.

### Documents

- [Phase 1 — Authorization, Input Reconciliation, and Foundation Activation](phase-01-authorization-input-reconciliation-and-foundation-activation.md)
- [Phase 1 — Implementation Evidence](phase-01-implementation-evidence.md)
- [Phase 2 — Semantic Nodes, Identity, and Portable Component Evaluation](phase-02-semantic-nodes-identity-and-component-evaluation.md)
- [Phase 2 — Implementation Evidence](phase-02-implementation-evidence.md)
- [Phase 3 — Events, Effects, Capabilities, and Resource Ownership](phase-03-events-effects-capabilities-and-resource-ownership.md)

## Maintaining this index

Add a phase document only after its implementation is explicitly authorized.
Keep status, dependencies, evidence, and deferred obligations synchronized with
the phase plan and BH-02 baseline assets. Preserve superseded contracts and
never convert unavailable external qualification into local completion credit.
