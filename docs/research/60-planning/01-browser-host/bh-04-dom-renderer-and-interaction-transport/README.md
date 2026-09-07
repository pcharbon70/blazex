---
title: "BH-04 DOM Renderer and Interaction Transport"
kind: map
created: "2026-09-06"
tags:
  - archive-navigation
  - bh-04
  - browser
  - directory-index
  - dom
  - implementation-planning
  - renderer
aliases:
  - "BH-04 implementation plan"
  - "BlazeX DOM renderer plan"
---

# BH-04 DOM Renderer and Interaction Transport

## Purpose

This plan turns the accepted host-neutral renderer contracts and the eventual
BH-03 browser-host lifecycle into BlazeX's reference browser renderer. It
replaces the BH-02 full-root experimental projection with deterministic,
incremental, root-isolated DOM transactions and a bounded interaction return
path while preserving the semantic component boundary.

BH-04 establishes reusable browser rendering behavior. It does not define the
BH-05 public component model, authorize Phoenix commands, implement the Plug
profile, add product component families, complete prerender/activation, or
claim browser, accessibility, performance, or public-API support.

## Authorization status

The repository owner approved this phase decomposition on 2026-09-06 so BH-04
can be planned in parallel with BH-03. Planning does not authorize BH-04
implementation. Following the accepted BH-03 Phase 9 handoff, the repository
owner explicitly authorized Phase 1 on 2026-09-07. Every subsequent phase
requires separate implementation authorization. Phase 1 claimed no new renderer
behavior, support, public API stability, or BH-05 eligibility.

The owner subsequently authorized Phases 2 and 3 on 2026-09-07, explicitly
approving the v2 protocol correction needed to retain complete projection intent.
Both the protocol and pure keyed-reconciliation gates are complete. The owner
then authorized Phase 4 on 2026-09-07. Its atomic DOM and active Linux browser
gates are complete; Phase 5 is eligible but unauthorized. No support is claimed.

## What belongs here

- The BH-03 handoff and the BH-02 renderer, semantic, event, effect, resource,
  presentation-intent, and DOM contracts inherited by BH-04.
- Versioned renderer-transaction and interaction envelopes with bounded,
  fail-closed validation.
- Keyed incremental reconciliation, deterministic operation ordering, root
  ownership, revision sequencing, queue policy, stale rejection, and cleanup.
- Server-framework-independent DOM lowering and browser application in
  `packages/blazex_renderer_dom` and `js/blazex_runtime`.
- Event normalization, form-value transport, focus and selection continuity,
  post-commit effect ordering, and resource disposal.
- All LiveView and LocalLiveView render-data, patching, transport, and version
  coupling isolated in `packages/blazex_renderer_dom_liveview`.
- Deterministic fixtures, active Linux Chrome/Firefox browser scenarios,
  measurements, failure injection, and milestone acceptance evidence.

Phoenix command authority, Plug integration, product styling, visual
equivalence, native rendering, public component APIs, and release
qualification remain later milestone work.

## Authoritative inputs

- [BH-03 browser execution-host plan](../bh-03-browser-execution-host-and-runtime-boot-lifecycle/README.md)
- [BH-02 internal contract baseline](../../../assets/bh-02-baseline/blazex-bh-02-contract-baseline-v0.1.0.json)
- [Browser-host milestone roadmap](../../../20-notes/browser-host-implementation-milestones.md)
- [Renderer backend separation](../../../20-notes/architecture-decisions/adr-0004-renderer-backend-separation.md)
- [Versioned semantic UI tree](../../../20-notes/architecture-decisions/adr-0002-versioned-semantic-ui-tree.md)
- [Host-neutral effects, capabilities, and resources](../../../20-notes/architecture-decisions/adr-0003-host-neutral-effects-capabilities-and-resources.md)
- [Browser rendering and profile modes](../../../20-notes/blazex-browser-rendering-and-profile-modes.md)
- [Acceptance traceability and evidence policy](../../../20-notes/blazex-acceptance-traceability-and-evidence-policy.md)
- [Development environment and deferred qualification policy](../../development-environment-and-deferred-qualification-policy.md)

## Required dependency and ownership boundaries

| Boundary | Owns | Must not own or depend on |
| --- | --- | --- |
| `packages/blazex_renderer` | Host-neutral backend lifecycle, transaction capability requirements, diagnostics, and renderer-facing contracts | DOM nodes, browser events, LiveView data, Phoenix/Plug transport, or application component behavior |
| `packages/blazex_renderer_dom` | DOM lowering, incremental reconciliation, DOM transaction and interaction schemas, accessibility mapping, focus/selection intent, and standalone adapter state | Phoenix, Plug, LiveView, LocalLiveView, server authority, or direct browser objects in Elixir data |
| `packages/blazex_renderer_dom_liveview` | Optional pinned LiveView/LocalLiveView compatibility, render-data and patch translation, and adapter-specific lifecycle | Portable component semantics, standalone DOM ownership, Plug profile inclusion, or server authorization decisions |
| `js/blazex_runtime` | Strict wire validation, per-root transaction application, browser-event normalization, interaction delivery, focus/selection application, and browser-owned cleanup | Component state machine, semantic reconciliation policy, Phoenix authority, or a second component framework |
| `integration/conformance` | Cross-renderer and cross-path semantic outcome fixtures | Product-specific snapshots or support claims |
| `integration/bh-04` | BH-04 transactions, interactions, browser scenarios, failures, measurements, and acceptance overlays | Rewriting historical BH-01/BH-02/BH-03 evidence |

The standalone DOM dependency closure must contain no Phoenix, Plug,
LiveView, or LocalLiveView package. The optional LiveView adapter may depend
outward on the standalone DOM contract and exact compatible framework
versions; no dependency may point back from the standalone path.

## Ordered phases

| Phase | Status | Delivery | Dependency |
| --- | --- | --- | --- |
| [1 — Authorization, Handoff Reconciliation, and Renderer Boundary Activation](phase-01-authorization-handoff-reconciliation-and-renderer-boundary-activation.md) | complete — activation only | Bind accepted BH-03 inputs, reconcile the BH-04 ledger, activate only renderer evidence boundaries, and prove fail-closed ownership. | Accepted BH-03 handoff and explicit authorization |
| [2 — Versioned Render Transaction and Patch Protocol](phase-02-versioned-render-transaction-and-patch-protocol.md) | complete — internal protocol only | Define the closed transaction, patch-operation, acknowledgement, diagnostic, and compatibility contracts used by both DOM paths. | Phase 1 |
| [3 — Keyed Incremental Reconciliation and Deterministic Diffing](phase-03-keyed-incremental-reconciliation-and-deterministic-diffing.md) | eligible — unauthorized | Replace full-root-only updates with bounded keyed reconciliation and canonical operation generation in the standalone DOM package. | Phase 2 |
| [4 — Atomic DOM Application, Root Queues, and Stale Rejection](phase-04-atomic-dom-application-root-queues-and-stale-rejection.md) | planned — unauthorized | Apply validated transactions through isolated per-root queues with atomic failure behavior, rollback/fallback, and exact generation ordering. | Phase 3 and BH-03 root lifecycle |
| [5 — Semantic Event Normalization and Interaction Transport](phase-05-semantic-event-normalization-and-interaction-transport.md) | planned — unauthorized | Normalize bound browser events into bounded semantic interaction records and deliver them to the correct runtime root without server authority. | Phases 2 and 4 |
| [6 — Form Value, Focus, and Selection Continuity](phase-06-form-value-focus-and-selection-continuity.md) | planned — unauthorized | Preserve controlled values, form semantics, active element, text selection, composition, and focus intent across incremental updates. | Phases 3–5 |
| [7 — Effect Ordering, Resources, Disposal, and Failure Isolation](phase-07-effect-ordering-resources-disposal-and-failure-isolation.md) | planned — unauthorized | Order DOM commits and browser effects, bound owned resources, isolate malformed/failing roots, and converge cleanup. | Phases 4–6 |
| [8 — LiveView and LocalLiveView Adapter Isolation](phase-08-liveview-and-local-liveview-adapter-isolation.md) | planned — unauthorized | Implement the optional version-pinned adapter and prove all framework coupling remains outside the standalone DOM and Plug graphs. | Phases 2–7 and compatible pinned framework inputs |
| [9 — Cross-Path Accessibility and Browser Conformance](phase-09-cross-path-accessibility-and-browser-conformance.md) | planned — unauthorized | Reconcile standalone and optional LiveView outcomes against headless semantics in active Linux Chrome/Firefox scenarios. | Phases 3–8 |
| [10 — Measurement, Review, and BH-04 Acceptance](phase-10-measurement-review-and-bh-04-acceptance.md) | planned — unauthorized | Measure the first renderer budgets, execute multidisciplinary review and the complete gate, and accept, revise, or block BH-05 eligibility. | Phases 1–9 |

## Acceptance ownership

| Acceptance condition | BH-04 obligation |
| --- | --- |
| `BX-ACC-ROADMAP-BH-04` | Prove deterministic DOM, accessibility, event, focus, and disposal outcomes; neutral application dependencies; and exact standalone/LiveView package separation. |
| `BX-ACC-BUDGET-BX-BUD-INTERACTION-DOM-UPDATE-MS` | Produce the first governed keyed-update receipt-to-paint samples against the proposed 50 ms p95 budget without claiming release qualification. |
| `BX-ACC-BUDGET-BX-BUD-RELIABILITY-RENDERER-QUEUE-COUNT` | Prove each root's queued transaction count is bounded at 64 or fewer under the governed overload scenario. |
| `BX-ACC-BUDGET-BX-BUD-RELIABILITY-STALE-REJECTION-PERCENT` | Reject 100% of governed stale generation renderer/effect messages without DOM or state mutation. |
| `BX-ACC-FAILURE-BX-FAIL-RENDERER` | Atomically reject malformed or failed transactions, retain the last valid output or bounded fallback, isolate the root, diagnose failure, and release abandoned resources. |

## Shared delivery rules

1. Obtain separate authorization before each phase; this plan grants none.
2. Begin each phase from synchronized `main` on a `codex/` feature branch.
3. Complete sections in order with one coherent commit per section and one PR
   per phase after its integration gate passes or records a truthful stop.
4. Preserve accepted BH-02 and BH-03 artifacts as immutable inputs and bind
   each phase to exact input revisions.
5. Keep the renderer protocol internal and experimental throughout BH-04;
   BH-05 owns public component-lifecycle design.
6. Treat DOM transactions, browser events, LiveView data, and runtime messages
   as untrusted and validate them before mutation or dispatch.
7. Preserve root and generation isolation. One root may neither inspect,
   mutate, delay indefinitely, nor dispose another root.
8. Keep standalone DOM independent of Phoenix, Plug, LiveView, and
   LocalLiveView directly and transitively. Keep all version-sensitive
   framework code in the optional adapter.
9. Apply the development-environment policy. Linux Chrome and Firefox are the
   active matrix; unavailable operating systems, Safari, devices, and manual
   assistive-technology pairings are `[DEFERRED]` to BH-22 and grant no
   support credit.
10. Stop on semantic leakage, unbounded queues/retries/resources, non-atomic
    corruption, stale mutation, cross-root ownership, hidden framework
    coupling, or a requirement to weaken accepted contracts.

## Milestone exit

BH-04 exits only when deterministic fixtures and active browser scenarios show
equivalent documented semantic outcomes across the standalone DOM path and
the optional compatible LiveView path; keyed incremental updates preserve
identity, form values, accessibility, focus, and selection; malformed, stale,
overloaded, and failing traffic is bounded and root-isolated; resources
converge after disposal; the standalone dependency audit is clean; and the
five BH-04 acceptance conditions have truthful evidence or explicit blocking
records. Acceptance may make BH-05 eligible but does not authorize it or grant
public stability or browser support.

## Index

- [Phase 4 implementation evidence](phase-04-implementation-evidence.md) — atomic DOM, queue, stale, rollback and browser verification.

### Subdirectories

- None yet.

### Documents

- [Phase 4 atomic DOM contract](phase-04-atomic-dom-contract.md) — ownership, queue, commit, rollback and fallback policy.

- [Phase 3 implementation evidence](phase-03-implementation-evidence.md) — deterministic replay, cross-renderer parity, acknowledgement lifecycle and bounded completion.

- [Phase 3 reconciliation contract](phase-03-reconciliation-contract.md) — identity, bounds, protocol correction and acknowledgement policy.

- [Phase 2 implementation evidence](phase-02-implementation-evidence.md) — protocol, codec agreement and bounded completion.

- [Phase 2 protocol design](phase-02-protocol-design.md) — internal envelope, limits, canonical bytes and exclusions.

- [Phase 1 implementation evidence](phase-01-implementation-evidence.md) — activation gate, immutable handoff and bounded completion.

- [Phase 1 — Authorization, Handoff Reconciliation, and Renderer Boundary Activation](phase-01-authorization-handoff-reconciliation-and-renderer-boundary-activation.md)
- [Phase 2 — Versioned Render Transaction and Patch Protocol](phase-02-versioned-render-transaction-and-patch-protocol.md)
- [Phase 3 — Keyed Incremental Reconciliation and Deterministic Diffing](phase-03-keyed-incremental-reconciliation-and-deterministic-diffing.md)
- [Phase 4 — Atomic DOM Application, Root Queues, and Stale Rejection](phase-04-atomic-dom-application-root-queues-and-stale-rejection.md)
- [Phase 5 — Semantic Event Normalization and Interaction Transport](phase-05-semantic-event-normalization-and-interaction-transport.md)
- [Phase 6 — Form Value, Focus, and Selection Continuity](phase-06-form-value-focus-and-selection-continuity.md)
- [Phase 7 — Effect Ordering, Resources, Disposal, and Failure Isolation](phase-07-effect-ordering-resources-disposal-and-failure-isolation.md)
- [Phase 8 — LiveView and LocalLiveView Adapter Isolation](phase-08-liveview-and-local-liveview-adapter-isolation.md)
- [Phase 9 — Cross-Path Accessibility and Browser Conformance](phase-09-cross-path-accessibility-and-browser-conformance.md)
- [Phase 10 — Measurement, Review, and BH-04 Acceptance](phase-10-measurement-review-and-bh-04-acceptance.md)

## Maintaining this index

Add implementation-evidence documents only after the corresponding phase is
authorized and executed. Keep phase status, dependency identities, acceptance
conditions, deferred qualifications, and package ownership synchronized.
Never convert an unavailable qualification into passing evidence or an
optional LiveView optimization into the definition of standalone DOM behavior.
