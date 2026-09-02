---
title: "BH-00 Product Boundary, Catalog, and Acceptance Contract"
kind: map
created: "2026-09-02"
tags:
  - archive-navigation
  - bh-00
  - browser
  - directory-index
  - implementation-planning
aliases:
  - "BH-00 implementation plan"
  - "BlazeX product contract plan"
---

# BH-00 Product Boundary, Catalog, and Acceptance Contract

## Purpose

This plan decomposes BH-00 into six ordered phases that establish the governed
browser-product contract before BlazeX activates a Mix or JavaScript project.
The work freezes terminology, support claims, catalog classifications, quality
budgets, and observable acceptance conditions. It does not prove the runtime
stack or implement framework behavior; that begins in BH-01.

Every phase uses the established phase, section, task, and subtask hierarchy.
Each phase has four sections, eight tasks, and twenty-four subtasks. Every phase,
section, and task begins with a description, and Section 4 is always the
phase-ending integration-test and completion-evidence section.

## What belongs here

- BH-00 phase plans and their delivery status.
- Traceability from BH-00 work to the browser roadmap and host-neutral research.
- Documentation, schema, catalog, review, and acceptance activities required to
  satisfy the BH-00 completion signal.
- Evidence rules that distinguish a completed product contract from an
  implementation demonstration.

Runtime feasibility experiments, Mix project initialization, JavaScript package
initialization, component implementation, and browser execution belong to
BH-01 or later milestones and are excluded here.

## Authoritative inputs

- [Browser host implementation milestones](../../../20-notes/browser-host-implementation-milestones.md) — defines the BH-00 goal, required work, ownership, and completion signal.
- [Host-neutral BlazeX architecture and native control backends](../../../20-notes/host-neutral-blazex-architecture-and-native-control-backends.md) — fixes the runtime, host, renderer, capability, server-adapter, and profile distinctions.
- [MudBlazor-inspired component system for BlazeX](../../../20-notes/mudblazor-inspired-component-system-for-blazex.md) — supplies the catalog reference, component families, and delivery-order evidence.
- [Blazor framework semantics beneath BlazeX](../../../20-notes/blazor-framework-semantics-beneath-blazex.md) — supplies lifecycle and framework-semantic questions the catalog must classify.
- [Can one BlazeX component model target DOM and native controls?](../../../40-inquiries/can-one-blazex-component-model-target-dom-and-native-controls.md) — constrains portability metadata and prevents browser leakage.
- [Can Elixir WebAssembly components integrate with Phoenix and Plug?](../../../40-inquiries/can-elixir-webassembly-components-integrate-with-phoenix-and-plug.md) — constrains browser-product and server-integration claims.

## Ordered phases

| Phase | Status | Delivery | Dependency |
| --- | --- | --- | --- |
| [1 — Terminology and Architecture Decision Baseline](phase-01-terminology-and-architecture-decision-baseline.md) | complete | Freeze canonical vocabulary, independent architecture axes, package ownership, and durable decision governance. | Current research corpus and merged monorepo scaffold |
| [2 — Browser Product and Support Envelope](phase-02-browser-product-and-support-envelope.md) | complete | Define browser, toolchain, rendering-mode, server-integration, trust, deployment, and fallback claims without claiming feasibility. | Phase 1 |
| [3 — Catalog Schema and Locked Inventory](phase-03-catalog-schema-and-locked-inventory.md) | planned | Pin the MudBlazor reference, create stable BlazeX family identities, and establish a complete machine-validatable catalog. | Phases 1–2 |
| [4 — Disposition, Capability, Fallback, and Portability Classification](phase-04-disposition-capability-fallback-and-portability-classification.md) | planned | Assign every family a BlazeX disposition, delivery tier, package owner, capability contract, fallback, and backend-portability status. | Phase 3 |
| [5 — Quality Budgets and Acceptance Traceability](phase-05-quality-budgets-and-acceptance-traceability.md) | planned | Define measurable quality budgets and map every product and catalog claim to observable acceptance evidence. | Phases 2 and 4 |
| [6 — Governance Review and BH-00 Acceptance](phase-06-governance-review-and-bh-00-acceptance.md) | planned | Reconcile all records, conduct independent review, publish the versioned contract, and authorize or block BH-01 truthfully. | Phase 5 |

## Shared conventions and delivery rules

1. Start each phase from synchronized `main` on a `codex/` feature branch.
2. Complete sections in order, verify each section, and commit once per completed
   section.
3. Open one PR after a complete phase; do not merge without a later authorized
   request.
4. Keep every checkbox open until the described artifact and reproducible
   evidence exist. Planning completeness is not delivery evidence.
5. Use stable IDs for decisions, catalog rows, support claims, budgets, and
   acceptance conditions so later milestones can cite them without prose
   matching.
6. Change the governing research and decision record before changing a durable
   product boundary. Never allow generated views to become the source of truth.
7. Preserve the monorepo dependency direction: profiles compose packages;
   renderer, runtime, host, and server adapters never define portable component
   semantics.
8. Perform no BH-01 runtime build, dependency pinning proof, authenticated
   command demonstration, Mix project initialization, or JavaScript package
   initialization as part of BH-00.

## Non-goals

- Selecting or proving exact Popcorn, AtomVM, Phoenix, LiveView, Elixir, or
  Erlang versions.
- Implementing the component kernel, effects, semantic UI tree, renderer, host,
  server adapter, build pipeline, or reference profile.
- Claiming .NET, Razor, Blazor binary, MudBlazor API, or NuGet compatibility.
- Selecting a production native toolkit or promising native-control parity.
- Turning the WebAssembly Component Model into the UI component abstraction.
- Treating a schema-valid catalog as evidence that any component works.

## Milestone exit

BH-00 exits only when every planned product and component claim is represented
by stable, versioned records; every MudBlazor v9.9.0 family has an explicit
BlazeX disposition, delivery tier, package owner, capability need, fallback,
and portability status; browser and server-integration claims have bounded
support semantics; quality budgets and acceptance conditions are complete; all
cross-document and machine validation passes; and independent review confirms
that the contract implies neither .NET compatibility nor automatic native-host
support. The BH-01 entry decision must name any remaining risks and may remain
blocked.

## Index

### Subdirectories

- None yet.

### Documents

- [Phase 1 — Terminology and Architecture Decision Baseline](phase-01-terminology-and-architecture-decision-baseline.md)
- [Phase 1 — Implementation Evidence](phase-01-implementation-evidence.md)
- [Phase 2 — Browser Product and Support Envelope](phase-02-browser-product-and-support-envelope.md)
- [Phase 2 — Implementation Evidence](phase-02-implementation-evidence.md)
- [Phase 3 — Catalog Schema and Locked Inventory](phase-03-catalog-schema-and-locked-inventory.md)
- [Phase 4 — Disposition, Capability, Fallback, and Portability Classification](phase-04-disposition-capability-fallback-and-portability-classification.md)
- [Phase 5 — Quality Budgets and Acceptance Traceability](phase-05-quality-budgets-and-acceptance-traceability.md)
- [Phase 6 — Governance Review and BH-00 Acceptance](phase-06-governance-review-and-bh-00-acceptance.md)

## Maintaining this index

Keep phase order and dependencies synchronized with the phase documents. Record
delivery status without rewriting unchecked work as history. If evidence changes
the decomposition, update this index and the governing BH-00 roadmap together,
preserve superseded decisions, and do not renumber delivered phases.
