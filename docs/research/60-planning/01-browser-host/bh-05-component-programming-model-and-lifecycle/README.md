---
title: "BH-05 Component Programming Model and Lifecycle"
kind: map
created: "2026-09-06"
tags:
  - archive-navigation
  - bh-05
  - component-model
  - directory-index
  - elixir
  - implementation-planning
  - lifecycle
aliases:
  - "BH-05 implementation plan"
  - "BlazeX component model plan"
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

This plan turns the accepted semantic kernel and the eventual BH-04 renderer
handoff into an idiomatic Elixir programming model for portable BlazeX
applications. It distinguishes pure composition, nested stateful components,
and process-root local views; defines validated props and slots; and makes
state, identity, events, messages, effects, command intent, context, failure,
retry, and disposal behavior deterministic across ERTS and browser AtomVM.

BH-05 provides a Phoenix-familiar Elixir experience without making Phoenix,
HEEx, LiveView, the DOM, Popcorn, or AtomVM implementation types part of the
component contract. It does not implement forms, product component families,
navigation, Phoenix command transport, Plug integration, build reachability,
prerender/activation, or release support owned by later milestones.

## Authorization status

The repository owner approved this phase decomposition on 2026-09-06.
Planning alone does not authorize implementation. The owner authorized Phase 1
after the accepted BH-04 corrective handoff merged in PR #51 at
`506c254ddd4a14dd8d1d4cbdba8fcf9556bd15cb`. Phase 1 activates governance only;
every later phase still requires separate explicit implementation authorization.
Phase 1 is now complete: all activation gates pass without new component
behavior. Phase 2 is eligible but unauthorized; BH-06 remains ineligible.

## What belongs here

- A public-facing but pre-1.0 Elixir authoring facade over host-neutral
  component contracts.
- Explicit pure, nested-stateful, and process-root component roles with honest
  state and failure boundaries.
- Versioned prop and slot schemas, local-versus-host boundary validation,
  defaults, required values, contextual slots, and stable diagnostics.
- Parent-controlled props, component-local state, keyed identity, nested
  reconciliation, transition scheduling, and commit/final-state rules.
- Root-local events, messages, timers, effect requests/results, typed remote
  command intent, queue bounds, ordering, cancellation, and stale rejection.
- Root-scoped named context and manifest-bounded dynamic component
  registration without arbitrary module dispatch.
- Process-root supervision, accessible fallback, bounded retry, generation
  replacement, deterministic disposal, and resource cleanup.
- Matching ERTS and browser-AtomVM traces plus headless, DOM, and retained
  native-spike portability checks.
- Governed BH-05 failure, resource, reliability, measurement, review, and
  acceptance evidence.

Forms and validation components belong to BH-10; Phoenix command execution and
server authority belong to BH-07; dynamic reachability and bundle generation
belong to BH-06; visual component families begin at BH-08.

## Authoritative inputs

- [Browser-host milestone roadmap](../../../20-notes/browser-host-implementation-milestones.md)
- [Host-neutral component-kernel decision](../../../20-notes/architecture-decisions/adr-0001-host-neutral-semantic-component-kernel.md)
- [Versioned semantic UI tree](../../../20-notes/architecture-decisions/adr-0002-versioned-semantic-ui-tree.md)
- [Host-neutral effects, capabilities, and resources](../../../20-notes/architecture-decisions/adr-0003-host-neutral-effects-capabilities-and-resources.md)
- [Renderer backend separation](../../../20-notes/architecture-decisions/adr-0004-renderer-backend-separation.md)
- [Server adapter and trust boundary](../../../20-notes/architecture-decisions/adr-0005-server-adapter-and-trust-boundary.md)
- [Blazor framework semantics beneath BlazeX](../../../20-notes/blazor-framework-semantics-beneath-blazex.md)
- [Foundational component-semantics inquiry](../../../40-inquiries/which-foundational-component-semantics-does-blazex-need.md)
- [BH-02 internal contract baseline](../../../assets/bh-02-baseline/blazex-bh-02-contract-baseline-v0.1.0.json)
- [Development environment and deferred qualification policy](../../development-environment-and-deferred-qualification-policy.md)

The accepted BH-04 release index, component-model entry manifest, renderer
contracts, conditions, and exact source revision become mandatory additional
inputs when Phase 1 is authorized.

## Component-unit model

| Unit | State and execution | Failure boundary | Intended use |
| --- | --- | --- | --- |
| Pure component | No retained local state; deterministic props/slots-to-semantic-output evaluation in its caller | Owning root | Reusable composition and presentation semantics |
| Nested stateful component | Retained keyed state scheduled within one process-root evaluation | Owning root; not independently supervised | Reusable interactive fragments with local state |
| Process-root local view | Owns one supervised process, mailbox, renderer root, generation, effects, resources, fallback, and retry policy | Independent local-view root | Interactive island, mailbox owner, recovery unit, and host/server boundary |

No nested component may imply process isolation it does not have. An
application that needs independent failure containment uses another
process-root local view.

## Required dependency and ownership boundaries

| Boundary | Owns | Must not own or depend on |
| --- | --- | --- |
| `packages/blazex_core` | Authoring metadata, component roles, props/slots, identity, state transitions, lifecycle, event/message scheduling, context, registry, command intent, diagnostics, and root process contract | Phoenix, Plug, HEEx/HTML as canonical output, DOM/JavaScript, Popcorn internals, concrete renderer/host, server authority, or native toolkit |
| `packages/blazex_ui_tree` | Validated semantic composition and output acceptance | Component scheduling, runtime process ownership, renderer behavior, or host objects |
| `packages/blazex_effects` | Typed effects/results, capability negotiation, pending work, resource leases, cancellation, timeout, and disposal | Concrete browser/OS handles, renderer mutation, server execution, or component registry policy |
| `packages/blazex_test` | Public component fixtures, lifecycle scripts, deterministic schedulers/providers, trace normalization, and cross-runtime assertions | Production lifecycle ownership or one-host assumptions |
| Runtime/host adapters | Execute accepted root lifecycle and provide negotiated effects | Define component roles, callback meaning, state authority, or public APIs |
| Renderers | Consume accepted semantic output and report commit/failure outcomes | Invoke arbitrary component callbacks or own application state |
| Server adapters | Execute authenticated and authorized remote commands later | Trust browser state or redefine local event/message semantics |
| `integration/bh-05` | BH-05 fixtures, cross-runtime/browser traces, failures, measurements, reviews, and acceptance overlays | Rewriting historical milestone evidence |

Public application fixtures may import only documented BlazeX component,
semantic, effect, and test contracts. Private runtime, renderer, host, and
adapter modules are forbidden even when available in the monorepo.

## Ordered phases

| Phase | Status | Delivery | Dependency |
| --- | --- | --- | --- |
| [1 — Authorization, BH-04 Handoff Reconciliation, and Boundary Activation](phase-01-authorization-bh-04-handoff-reconciliation-and-boundary-activation.md) | complete — governance only | Bind accepted BH-04 evidence, reconcile nine BH-05 acceptance obligations, activate component evidence boundaries, and prove fail-closed ownership. | Accepted BH-04 and explicit authorization |
| [2 — Component Roles, Authoring Facade, and Callback Algebra](phase-02-component-roles-authoring-facade-and-callback-algebra.md) | eligible — unauthorized | Define the Phoenix-familiar but host-neutral module facade, three component roles, lifecycle vocabulary, callback inputs, and closed return forms. | Phase 1 |
| [3 — Prop, Slot, and Host-Boundary Contracts](phase-03-prop-slot-and-host-boundary-contracts.md) | planned — unauthorized | Implement schema declarations, defaults, required/cardinality rules, contextual slots, local/host boundary validation, and diagnostics. | Phase 2 |
| [4 — Pure Composition and Atomic Semantic Evaluation](phase-04-pure-composition-and-atomic-semantic-evaluation.md) | planned — unauthorized | Evaluate pure nested composition deterministically and accept output only after complete semantic validation. | Phase 3 |
| [5 — Nested Stateful Identity and Update Reconciliation](phase-05-nested-stateful-identity-and-update-reconciliation.md) | planned — unauthorized | Retain keyed nested state, reconcile insert/move/update/remove/replace operations, and define controlled-prop versus local-state ownership. | Phase 4 |
| [6 — Process-Root Local View Lifecycle and Supervision](phase-06-process-root-local-view-lifecycle-and-supervision.md) | planned — unauthorized | Implement the independent local-view process, mount/update/render/commit/info/terminate lifecycle, root generation, and supervision boundary. | Phase 5 and accepted BH-03/BH-04 contracts |
| [7 — Event, Message, Timer, and Transition Scheduling](phase-07-event-message-timer-and-transition-scheduling.md) | planned — unauthorized | Serialize root transitions, route local events and messages, bound backlogs, reject stale work, and make rendering/final-state ordering explicit. | Phase 6 |
| [8 — Effects, Resources, and Typed Command Intent](phase-08-effects-resources-and-typed-command-intent.md) | planned — unauthorized | Replace generic emissions with typed effects/resources/command intents and enforce authority, result, cancellation, timeout, and ownership boundaries. | Phases 6–7 |
| [9 — Scoped Context and Manifest-Bounded Dynamic Components](phase-09-scoped-context-and-manifest-bounded-dynamic-components.md) | planned — unauthorized | Implement root-scoped named context and deterministic stable-ID component registries suitable for BH-06 reachability analysis. | Phases 3–8 |
| [10 — Failure Containment, Retry, Replacement, and Disposal](phase-10-failure-containment-retry-replacement-and-disposal.md) | planned — unauthorized | Contain failures at honest process-root boundaries, render accessible fallback, bound retries, invalidate generations, and release all owned work. | Phases 5–9 |
| [11 — ERTS, Browser-AtomVM, and Cross-Backend Conformance](phase-11-erts-browser-atomvm-and-cross-backend-conformance.md) | planned — unauthorized | Run matching public component scenarios under ERTS/headless and browser AtomVM/DOM, with retained native-spike portability checks. | Phases 2–10 and accepted BH-04 browser path |
| [12 — Reliability Measurement, Review, and BH-05 Acceptance](phase-12-reliability-measurement-review-and-bh-05-acceptance.md) | planned — unauthorized | Measure six first-responsible budgets, close two failure gates, review the candidate, and accept, revise, or block BH-06 eligibility. | Phases 1–11 |

## Acceptance ownership

| Acceptance condition | BH-05 obligation |
| --- | --- |
| `BX-ACC-ROADMAP-BH-05` | Produce matching ERTS and browser-AtomVM traces for ordering, identity, updates, failures, and final state while application code imports no private runtime or renderer modules. |
| `BX-ACC-BUDGET-BX-BUD-RELIABILITY-EVENT-BACKLOG-COUNT` | Bound normalized per-root event backlog at 256 or fewer with explicit admission, coalescing/rejection, and ordering evidence. |
| `BX-ACC-BUDGET-BX-BUD-RELIABILITY-PENDING-EFFECTS-COUNT` | Bound pending effects per root at 128 or fewer through delay, denial, timeout, cancellation, and cleanup scenarios. |
| `BX-ACC-BUDGET-BX-BUD-RELIABILITY-RESOURCE-COUNT` | Bound simultaneous resource leases per root at 512 or fewer with complete owner and terminal-state inventory. |
| `BX-ACC-BUDGET-BX-BUD-RELIABILITY-RESTART-INTENSITY` | Bound automatic runtime/component-boundary restarts to three or fewer within five seconds and enter terminal fallback afterward. |
| `BX-ACC-BUDGET-BX-BUD-RESOURCE-CLEANUP-MS` | Measure root disposal through idempotent resource release at a proposed p95 of 1000 ms or less. |
| `BX-ACC-BUDGET-BX-BUD-RESOURCE-PROCESS-GROWTH-COUNT` | Show exactly zero unexpected live-process growth after one hundred root lifecycle cycles. |
| `BX-ACC-FAILURE-BX-FAIL-COMPONENT` | Contain callback or contract failure to the governed root, render accessible fallback, preserve siblings, diagnose, and dispose owned resources. |
| `BX-ACC-FAILURE-BX-FAIL-RESOURCE-CLEANUP` | Invalidate failed/replaced generations, cancel pending work, release leases idempotently, restore/redirect focus, and reject late completions. |

## Shared delivery rules

1. Obtain separate authorization before every phase; this plan grants none.
2. Begin each phase from synchronized `main` on a `codex/` feature branch.
3. Complete sections in order with one coherent commit per section and one PR
   per phase after its integration gate passes or records a truthful stop.
4. Preserve accepted BH-02 through BH-04 artifacts as immutable inputs and
   bind each phase to exact revisions.
5. Use Phoenix-familiar Elixir names only where their semantics are explicit;
   do not expose Phoenix sockets, HEEx/HTML, LiveView assigns, or callbacks as
   the portable contract.
6. Keep pure, nested-stateful, and process-root units distinct. Do not claim
   nested process isolation or mutable component-instance references.
7. Validate all host-boundary values before component callbacks. Local browser
   state, public auth presentation, and command intent remain untrusted at the
   server boundary.
8. Bound events, messages, timers, pending effects, resources, retries,
   dynamic dispatch, diagnostics, and cleanup; reject stale generations and
   sequences before state or host mutation.
9. Apply the development-environment policy. Linux Chrome and Firefox plus
   local ERTS/headless are active; unavailable operating systems, Safari,
   physical devices, and manual assistive-technology pairings are `[DEFERRED]`
   to BH-22 and grant no support credit.
10. Stop on host/renderer/server leakage, arbitrary module dispatch, state/DOM
    divergence, ambiguous final-state ordering, cross-root ownership,
    unbounded restart/resource behavior, or incompatible ERTS/AtomVM semantics.

## Milestone exit

BH-05 exits only when public application fixtures use the documented BlazeX
facade to exercise props, slots, pure composition, keyed nested state,
process-root lifecycle, events, messages, effects, command intent, context,
dynamic registration, failure, retry, and disposal; canonical traces match
between local ERTS and browser AtomVM for all supported semantics; headless and
DOM outcomes remain contract-equivalent; the nine BH-05 acceptance conditions
have reproducible evidence or explicit blocking records; and independent
review accepts, revises, or rejects the candidate without claiming .NET,
Phoenix, browser, native-host, or release compatibility.

## Index

### Subdirectories

- None yet.

### Documents

- [Phase 1 implementation evidence](activation-evidence.md)

- [Phase 1 — Authorization, BH-04 Handoff Reconciliation, and Boundary Activation](phase-01-authorization-bh-04-handoff-reconciliation-and-boundary-activation.md)
- [Phase 2 — Component Roles, Authoring Facade, and Callback Algebra](phase-02-component-roles-authoring-facade-and-callback-algebra.md)
- [Phase 3 — Prop, Slot, and Host-Boundary Contracts](phase-03-prop-slot-and-host-boundary-contracts.md)
- [Phase 4 — Pure Composition and Atomic Semantic Evaluation](phase-04-pure-composition-and-atomic-semantic-evaluation.md)
- [Phase 5 — Nested Stateful Identity and Update Reconciliation](phase-05-nested-stateful-identity-and-update-reconciliation.md)
- [Phase 6 — Process-Root Local View Lifecycle and Supervision](phase-06-process-root-local-view-lifecycle-and-supervision.md)
- [Phase 7 — Event, Message, Timer, and Transition Scheduling](phase-07-event-message-timer-and-transition-scheduling.md)
- [Phase 8 — Effects, Resources, and Typed Command Intent](phase-08-effects-resources-and-typed-command-intent.md)
- [Phase 9 — Scoped Context and Manifest-Bounded Dynamic Components](phase-09-scoped-context-and-manifest-bounded-dynamic-components.md)
- [Phase 10 — Failure Containment, Retry, Replacement, and Disposal](phase-10-failure-containment-retry-replacement-and-disposal.md)
- [Phase 11 — ERTS, Browser-AtomVM, and Cross-Backend Conformance](phase-11-erts-browser-atomvm-and-cross-backend-conformance.md)
- [Phase 12 — Reliability Measurement, Review, and BH-05 Acceptance](phase-12-reliability-measurement-review-and-bh-05-acceptance.md)

## Maintaining this index

Add implementation-evidence documents only after the corresponding phase is
authorized and executed. Keep statuses, callback and schema versions,
acceptance ownership, deferred qualifications, package boundaries, and
cross-runtime evidence synchronized. Never treat Phoenix familiarity as a
license to import Phoenix semantics into the kernel or a browser result as
proof of another host.
