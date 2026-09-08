---
title: "BH-05 Component Programming Model and Lifecycle"
kind: map
created: "2026-09-06"
tags:
  - archive-navigation
  - bh-05
  - browser-host
  - component-model
  - directory-index
  - implementation-planning
aliases:
  - "BH-05 implementation plan"
  - "BlazeX component lifecycle plan"
---

# BH-05 Component Programming Model and Lifecycle

## Current framework scope — 2026-09-08

LiveView and LocalLiveView integration are **[DEFERRED]** under the
[planning deferral](../../liveview-integration-deferral.md). None of this
milestone's twelve phases requires their APIs, rendering, lifecycle, transport,
or compatibility tests. A BlazeX “local view” means a BlazeX process-root
component, not a LocalLiveView component. BH-05 still requires accepted BH-04
Phases 1–7, 9 and 10 plus the retained Phase 8 deferral, not Phase 8 implementation.


## Purpose

This plan turns the accepted BH-04 renderer and interaction contracts into an
idiomatic Elixir component model. It defines pure composition, nested stateful
components, and process-root local views while preserving one host-neutral
semantic contract for the BEAM, browser AtomVM, and future renderer backends.

BH-05 does not provide .NET compatibility, a MudBlazor-equivalent product
catalog, Phoenix command transport, release packaging, or production support.
Those remain later milestones. Browser execution is the first active host;
other unavailable platforms and browsers remain governed deferrals.

## Authorization status

The twelve-phase decomposition is approved as planning. Implementation is not
authorized and cannot begin until BH-04 is accepted and its handoff is
reconciled. Each phase requires separate authorization before implementation.

## What belongs here

- Public component roles, authoring conventions, callbacks, props, and slots.
- Controlled and local state, stable identity, nested reconciliation, and
  process-root local-view supervision.
- Local events, messages, timers, transitions, effects, resources, and typed
  command intent.
- Scoped context, manifest-bounded dynamic components, failures, retries,
  replacement, and deterministic disposal.
- Matching BEAM and browser-AtomVM contract evidence, with other host evidence
  deferred when unavailable.

Renderer patching, host boot, protected server operations, product component
families, application routing, and deployment assembly do not belong here.

## Authoritative inputs

- [Browser-host milestone roadmap](../../../20-notes/browser-host-implementation-milestones.md)
- [Development environment and deferred qualification policy](../../development-environment-and-deferred-qualification-policy.md)
- The accepted BH-02 semantic-kernel and BH-03 browser-host baselines.
- The future accepted BH-04 DOM rendering and interaction handoff.

## Ordered phases

| Phase | Status | Delivery | Dependency |
| --- | --- | --- | --- |
| [1 — Authorization, BH-04 Handoff Reconciliation, and Boundary Activation](phase-01-authorization-bh-04-handoff-reconciliation-and-boundary-activation.md) | planned — unauthorized | Bind the accepted BH-04 handoff, freeze ownership and vocabulary, and activate empty implementation/evidence boundaries. | Accepted BH-04 and explicit authorization |
| [2 — Component Roles, Authoring Facade, and Callback Algebra](phase-02-component-roles-authoring-facade-and-callback-algebra.md) | planned — unauthorized | Define the three component roles and a public Elixir authoring surface over explicit callback results. | Phase 1 |
| [3 — Prop, Slot, and Host-Boundary Contracts](phase-03-prop-slot-and-host-boundary-contracts.md) | planned — unauthorized | Add deterministic validation and separate public browser data from trusted server state. | Phase 2 |
| [4 — Pure Composition and Atomic Semantic Evaluation](phase-04-pure-composition-and-atomic-semantic-evaluation.md) | planned — unauthorized | Evaluate pure components deterministically into atomic semantic output with bounded recursion. | Phases 2–3 |
| [5 — Nested Stateful Identity and Update Reconciliation](phase-05-nested-stateful-identity-and-update-reconciliation.md) | planned — unauthorized | Define controlled/local state, keyed identity, update decisions, moves, replacement, and child-first cleanup. | Phase 4 |
| [6 — Process-Root Local-View Lifecycle and Supervision](phase-06-process-root-local-view-lifecycle-and-supervision.md) | planned — unauthorized | Introduce supervised local-view roots without making every nested component a process. | Phase 5 |
| [7 — Event, Message, Timer, and Transition Scheduling](phase-07-event-message-timer-and-transition-scheduling.md) | planned — unauthorized | Serialize local stimuli through bounded deterministic scheduling and stale-generation rejection. | Phase 6 |
| [8 — Effects, Resources, and Typed Command Intent](phase-08-effects-resources-and-typed-command-intent.md) | planned — unauthorized | Execute capability-checked effects, own resources, and emit typed remote-command intent without granting authority. | Phase 7 |
| [9 — Scoped Context and Manifest-Bounded Dynamic Components](phase-09-scoped-context-and-manifest-bounded-dynamic-components.md) | planned — unauthorized | Add explicit context propagation and closed-world dynamic component resolution. | Phases 5–8 |
| [10 — Failure Containment, Retry, Replacement, and Disposal](phase-10-failure-containment-retry-replacement-and-disposal.md) | planned — unauthorized | Contain component failures, bound retry policy, replace safely, and guarantee deterministic cleanup. | Phases 6–9 |
| [11 — ERTS, Browser AtomVM, and Cross-Backend Conformance](phase-11-erts-browser-atomvm-and-cross-backend-conformance.md) | planned — unauthorized | Prove matching lifecycle semantics on the BEAM and active browser AtomVM profile; retain unavailable hosts as deferrals. | Phases 2–10 |
| [12 — Reliability Measurement, Review, and BH-05 Acceptance](phase-12-reliability-measurement-review-and-bh-05-acceptance.md) | planned — unauthorized | Measure the bounded lifecycle budgets, reconcile findings, and accept, revise, or block BH-06 eligibility. | Phases 1–11 |

## Shared delivery rules

1. Obtain separate authorization before each phase.
2. Begin from synchronized `main` on a `codex/` branch.
3. Complete sections in order and create one coherent commit per section.
4. Open one pull request only after the phase integration section passes or
   records a truthful stop decision.
5. Keep application code dependent only on public BlazeX contracts; private
   runtime and renderer modules cannot enter public component code.
6. Keep nested components lightweight. Only declared local-view roots receive
   process ownership and supervision.
7. Keep local events separate from typed remote-command intent, and keep
   public browser state separate from trusted server state.
8. Reject unknown component types, callbacks, versions, capabilities, stale
   generations, and unbounded work before execution.
9. Preserve deterministic identity, ordering, final state, and disposal across
   the BEAM, browser AtomVM, and headless oracle.
10. Mark unavailable OS, browser, device, native host, and manual accessibility
    work `[DEFERRED]`; it neither passes nor blocks active Linux Chrome/Firefox
    development.

## Milestone exit

BH-05 exits only when pure, nested stateful, and process-root local-view
semantics have matching BEAM and browser-AtomVM evidence for validation,
ordering, identity, updates, events, messages, timers, effects, context,
failures, retries, replacement, and final disposal. The active reliability
budgets must pass, public application code must remain outside private runtime
and renderer modules, and review must accept or reject BH-06 eligibility
without claiming product-catalog completeness or production support.

## Index

### Subdirectories

- None yet.

### Documents

- [Phase 1 — Authorization, BH-04 Handoff Reconciliation, and Boundary Activation](phase-01-authorization-bh-04-handoff-reconciliation-and-boundary-activation.md)
- [Phase 2 — Component Roles, Authoring Facade, and Callback Algebra](phase-02-component-roles-authoring-facade-and-callback-algebra.md)
- [Phase 3 — Prop, Slot, and Host-Boundary Contracts](phase-03-prop-slot-and-host-boundary-contracts.md)
- [Phase 4 — Pure Composition and Atomic Semantic Evaluation](phase-04-pure-composition-and-atomic-semantic-evaluation.md)
- [Phase 5 — Nested Stateful Identity and Update Reconciliation](phase-05-nested-stateful-identity-and-update-reconciliation.md)
- [Phase 6 — Process-Root Local-View Lifecycle and Supervision](phase-06-process-root-local-view-lifecycle-and-supervision.md)
- [Phase 7 — Event, Message, Timer, and Transition Scheduling](phase-07-event-message-timer-and-transition-scheduling.md)
- [Phase 8 — Effects, Resources, and Typed Command Intent](phase-08-effects-resources-and-typed-command-intent.md)
- [Phase 9 — Scoped Context and Manifest-Bounded Dynamic Components](phase-09-scoped-context-and-manifest-bounded-dynamic-components.md)
- [Phase 10 — Failure Containment, Retry, Replacement, and Disposal](phase-10-failure-containment-retry-replacement-and-disposal.md)
- [Phase 11 — ERTS, Browser AtomVM, and Cross-Backend Conformance](phase-11-erts-browser-atomvm-and-cross-backend-conformance.md)
- [Phase 12 — Reliability Measurement, Review, and BH-05 Acceptance](phase-12-reliability-measurement-review-and-bh-05-acceptance.md)

## Maintaining this index

Add implementation evidence only after explicit phase authorization. Keep
status, dependencies, evidence, budgets, and deferred obligations synchronized
with each phase. Never convert an unavailable external qualification into
local completion credit or a public support claim.
