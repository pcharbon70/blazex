---
title: "LiveView and LocalLiveView Integration Deferral"
kind: note
created: "2026-09-08"
maturity: stable
tags:
  - bh-04
  - deferred-qualification
  - implementation-planning
  - liveview
aliases:
  - "Deferred framework integration ledger"
---

# LiveView and LocalLiveView Integration Deferral

## Decision and authority

On 2026-09-08 the repository owner explicitly directed that LiveView and
LocalLiveView should not be concerns of the current host implementation and
should be deferred throughout planning. This decision supersedes the earlier
request to implement BH-04 Phase 8. It authorizes planning changes, not new
runtime behavior, dependency removal, commits, publication or phase execution.

**[DEFERRED]** means excluded from active scope and completion calculations,
not implemented, passed, waived, removed permanently or supported. This is a
product-scope decision, not a technical impossibility finding or a consequence
of unavailable test environments. Restricted-template adapter design is also
deferred; no new component-authoring restriction is adopted.

## Current host boundary

The browser path executes Elixir BEAM bytecode in AtomVM compiled to
WebAssembly, with BlazeX semantic rendering translated to standalone DOM
transactions and JavaScript applying browser updates. This is not a promise
of one independently compiled WebAssembly Component Model binary per control.
LiveView and LocalLiveView are not required for that execution or rendering.

Standalone DOM, root lifecycle, interactions, effects, accessibility, focus,
selection, disposal and failure isolation remain current concerns. Dependency
and source guards excluding framework coupling remain active. Phoenix server
integration is a separate axis: this decision does not defer all Phoenix work,
change server authorization requirements or imply Plug support.

Existing BH-01 adapter fixtures, profile dependencies and lock files remain
unchanged by this planning revision. Historical evidence is preserved, not
credited as real framework rendering. A later authorized implementation must
prove the active host/asset/dependency path does not require or activate the
deferred integration; this document does not claim that code cleanup occurred.

## Owned deferral ledger

| ID | Deferred work | Owner | Reactivation rule |
| --- | --- | --- | --- |
| BX-DEF-LIVEVIEW-IMPLEMENTATION | Entire BH-04 Phase 8: LiveView/LocalLiveView render data, patching, lifecycle, transport and optional profile activation | liveview-adapter-owner; architecture-owner | Separate optional framework-integration work after BH-04 acceptance, explicitly authorized by the repository owner; no assigned automatic milestone |
| BX-DEF-LIVEVIEW-CONFORMANCE | Adapter equivalence, private-surface probes, version mismatch tests, Chrome/Firefox adapter scenarios and adapter performance | liveview-adapter-owner; renderer/conformance owner | Same explicit reactivation, with exact versions, fixtures and independent evidence gates defined before implementation |
| BX-DEF-LIVEVIEW-DOWNSTREAM | LiveView embedding, foundation parity, prerender coupling, packaging, compatibility and support claims in later milestones | product-owner; Phoenix adapter owner | Separate framework-integration scope review after BH-04; BH-07, BH-08, BH-18, BH-19 and BH-22 do not activate this automatically |

The product and architecture owners retain these rows in downstream entry and
release ledgers until explicitly reactivated or superseded. Reactivation must
preserve host-neutral semantics, standalone independence, one-way adapter
dependencies and Plug exclusion. It requires a new bounded plan and current
source qualification; old framework pins do not establish compatibility.

## Active gate overrides

| Planning surface | Current rule |
| --- | --- |
| BH-04 Phase 8 | Entire phase [DEFERRED]; retained numbering/checklist is future work, not a completion obligation |
| BH-04 Phase 9 | Eligible from completed Phases 1–7 and this decision; still separately unauthorized. Compare standalone DOM with headless semantics; adapter execution is deferred |
| BH-04 Phase 10 | Require completion evidence for Phases 1–7 and 9, plus this deferral; do not require a Phase 8 implementation or passing adapter suite |
| BH-04 completion denominator | Nine active phases: 1–7, 9 and 10. Seven complete, two remaining. One deferred phase; no pass credit |
| BX-ACC-ROADMAP-BH-04 | Retain standalone correctness, semantic outcomes and dependency isolation. Defer adapter implementation, private coupling qualification and adapter equivalence |
| BH-05 | Still awaits BH-04 acceptance; carry this deferral rather than demand Phase 8 completion. BlazeX local-view lifecycle is not LocalLiveView integration |
| Later roadmap milestones | LiveView/LocalLiveView-specific outputs remain deferred even where retained optional architecture describes them; standalone and separately scoped server work continue |

This dated document is a prospective scope overlay for acceptance and release
generation. Do not rewrite immutable accepted registries, source bindings,
historical completion records, raw results or generated historical reports.
New acceptance overlays must cite this decision and carry all three deferral
IDs with owners and reactivation rules. All active standalone failures still
block where their original gates require it; no correctness threshold changes.

## Exact roadmap amendment binding

This decision authorizes only the following roadmap transition:

- Previous environment-policy amendment SHA-256:
  `a23f08ce1bf6021a6d1e9d1dd5998f85e37a7604d23bc032e0618f1c5facddb0`
- Current framework-deferral amendment SHA-256:
  `3b855d8a847104ea7f9df42159df3590a4b1fcdabf39d3eff719b20491ab8bdf`

The accepted BH-00 source remains unchanged. This is not an open-ended
stale-source exception; any further roadmap change needs a new explicit binding.

## Handoff reminders

At full BH-04 acceptance, present the requested prominent **scripts move
warning** to the owner. Deferring Phase 8 does not complete BH-04 and does not
authorize moving scripts.

## Connections

- [Planning index](README.md)
- [Browser-host stream](01-browser-host/README.md)
- [BH-04 plan](01-browser-host/bh-04-dom-renderer-and-interaction-transport/README.md)
- [Deferred Phase 8 outline](01-browser-host/bh-04-dom-renderer-and-interaction-transport/phase-08-liveview-and-local-liveview-adapter-isolation.md)
- [Browser-host roadmap](../20-notes/browser-host-implementation-milestones.md)
- [Renderer backend separation](../20-notes/architecture-decisions/adr-0004-renderer-backend-separation.md)
- [Profile composition](../20-notes/architecture-decisions/adr-0006-profile-composition.md)
- [Environment qualification policy](development-environment-and-deferred-qualification-policy.md)
