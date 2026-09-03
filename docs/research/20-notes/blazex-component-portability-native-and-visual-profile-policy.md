---
title: "BlazeX component portability, native, and visual-profile policy"
kind: note
created: "2026-09-03"
maturity: stable
tags:
  - bh-00
  - component-catalog
  - native-controls
  - portability
  - renderers
aliases:
  - "BH-00 renderer portability policy"
  - "BlazeX native component strategy"
---

# BlazeX component portability, native, and visual-profile policy

## Decision and scope

Phase 4 classifies intended semantic portability and future native strategy for
each family. These are architecture and product obligations, not evidence that
any renderer or native toolkit implements them. Every classified family keeps
`implementation_state: unknown` and no evidence IDs.

The machine assignments are part of [component classification
v0.1.0](../assets/component-catalog/blazex-component-classification-v0.1.0.json).
They name semantic nodes, events, effects, accessibility, layout, focus,
resources, renderer extensions, native strategy, visual profile, and future
backend gates without selecting a production desktop toolkit.

## Portability vocabulary

| Status | Meaning | Evidence needed before support |
| --- | --- | --- |
| `portable-semantic` | The family is expressed by backend-neutral semantic UI with no specialized host operation beyond core accessibility/rendering. | Headless trace, DOM evidence, BH-02 native spike, and backend accessibility mapping. |
| `portable-with-capabilities` | The semantic contract is backend-neutral but full behavior requires named focus, surface, file, measurement, window, pointer, or other capabilities. | All portable-semantic evidence plus capability grant/deny/fallback/lifecycle tests. |
| `renderer-extension` | A bounded allowlisted extension is intentionally renderer-specific; portable callers must have an alternative. | Per-renderer schema, validation, fallback, accessibility, disposal, and documentation. |
| `dom-specific` | The product behavior intentionally requires the DOM adapter. | DOM evidence and explicit exclusion/fallback for every other renderer. |
| `native-specific` | The product behavior intentionally requires a named native backend. | Native backend/toolkit evidence and explicit exclusion elsewhere. |
| `custom-scene` | The family uses backend-neutral scene semantics that each visual renderer draws. | Deterministic scene, interaction, nonvisual representation, performance, and backend drawing evidence. |
| `unsupported` | BlazeX intentionally makes no renderer support claim. | User-facing alternative and reviewed omission. |
| `unproven` | Classification is incomplete. | Not permitted in completed Phase 4 rows. |

`portable-semantic` and `portable-with-capabilities` state intended contract
shape only. They do not mean “runs everywhere,” native-compatible, or
WebAssembly Component Model compatible.

## Required semantic dimensions

Every planned family records:

- semantic node/content/region or collection/field/surface/scene roles;
- normalized activation, value, selection, navigation, disclosure, or dismiss
  events where interactive;
- capability effects and ownership without backend handles;
- accessibility names, roles, states, relationships, error/live semantics,
  focus order, and nonvisual alternatives;
- logical layout, tokenized sizing, adaptive measurement, and direction;
- focus movement/restoration/containment requirements; and
- owned opaque resources, generation invalidation, cancellation, and cleanup.

Renderer extensions are separate explicit identifiers. HTML tags, DOM events,
CSS, JavaScript, native widget classes, and toolkit callbacks are not semantic
dimensions.

## Native strategy

| Strategy | Intent |
| --- | --- |
| `native-preferred` | Use a stock platform control when it can satisfy BlazeX semantics, accessibility, state, and event contracts. |
| `native-composite` | Compose controls, layout, surfaces, and framework behavior when no single stock widget satisfies the family. |
| `custom-drawn` | Render a BlazeX scene while providing platform accessibility objects and nonvisual alternatives. |
| `dom-webview-only` | Intentionally supported only through the DOM/WebView profile. |
| `not-applicable` | The record is context, semantic infrastructure, or a renderer extension rather than a widget mapping. |
| `unproven` | No reviewed strategy; prohibited at Phase 4 completion. |

Native-preferred does not require identical controls across Windows, macOS,
Linux, mobile, embedded, or future hosts. A backend may use a composite or
custom implementation when a stock control cannot meet the semantic contract,
but it must document the deviation.

## Visual profiles and conflicts

- `platform-native` prioritizes OS behavior, accessibility, input method,
  conventions, and native theming. MudBlazor-like geometry or styling may
  intentionally differ.
- `blazex-material` uses BlazeX-owned tokens and drawn/composed visuals inspired
  by broad Material interaction lessons without claiming MudBlazor pixels.
- `hybrid` uses native controls/behavior where valuable and BlazeX tokenized
  composition around them. Exact cross-platform visual parity is not promised.
- `not-applicable` covers nonvisual contexts and bounded renderer extensions.

Documentation must name the active visual profile and material differences in
focus, input, typography, menu/dialog behavior, pickers, file selection,
animation, and accessibility. Screenshot similarity cannot override platform
semantics or accessibility.

## Future backend support gate

Before a backend claims support for a family it must provide:

1. deterministic headless semantic/event/effect/resource traces where
   applicable;
2. the declared DOM/browser evidence for the first host;
3. the BH-02 native-control spike for portable/native intent—headless plus DOM
   alone is explicitly insufficient;
4. backend accessibility mapping and assistive-technology evidence;
5. every denied/missing/unsupported fallback and lifecycle cleanup path;
6. backend-specific documentation, visual-profile differences, limitations,
   payload/performance results, and support matrix; and
7. implementation and evidence IDs promoted through the governed delivery
   states.

A renderer extension is evaluated only for backends that explicitly implement
it. A custom scene additionally requires keyboard access, nonvisual data,
contrast/forced-colors behavior, reduced motion, and bounded rendering cost.

## Current classification decisions

- No family is classified DOM-only, WebView-only, native-only, or unsupported.
- `Element` is the one bounded renderer extension and has no portable arbitrary
  tag or widget identity.
- `Chart` is a custom-scene family with a mandatory nonvisual representation.
- Families with named host/renderer capability needs are
  `portable-with-capabilities`; pure semantic/layout/content families are
  `portable-semantic`.
- Standard controls with adequate platform equivalents are native-preferred;
  compound/application families are native-composite; contexts and internal
  semantic primitives are not widget mappings.

These decisions preserve fully native controls as the long-term desktop goal
without rejecting a WebView middle profile or selecting one toolkit now.

## Connections

- [Capability, remote, and fallback policy](blazex-component-capability-remote-and-fallback-policy.md)
- [Host-neutral architecture](host-neutral-blazex-architecture-and-native-control-backends.md)
- [Native renderer inquiry](../40-inquiries/can-one-blazex-component-model-target-dom-and-native-controls.md)
- [BH-00 Phase 4 plan](../60-planning/01-browser-host/bh-00-product-boundary-catalog-and-acceptance-contract/phase-04-disposition-capability-fallback-and-portability-classification.md)

## Sources

- [Phoenix LiveView UI foundation surfaces](../30-sources/phoenix-framework-2026-liveview-ui-foundation-surfaces.md)
- [MudBlazor v9.9.0 source architecture](../30-sources/mudblazor-project-2026-v9-9-source-architecture.md)
