---
title: "BlazeX component disposition, tier, and package policy"
kind: note
created: "2026-09-03"
maturity: stable
tags:
  - bh-00
  - component-catalog
  - packages
  - product-governance
aliases:
  - "BH-00 component disposition policy"
  - "BlazeX F0-F4 package policy"
---

# BlazeX component disposition, tier, and package policy

## Decision and scope

The Phase 4 product classification is a versioned layer over the immutable
[Phase 3 source catalog](../assets/component-catalog/blazex-component-catalog-v0.1.0.json).
This separation preserves the exact MudBlazor v9.9.0 inventory while allowing
BlazeX product intent to change through reviewed classifications rather than
rewriting upstream evidence.

The authoritative classification artifact is [component classification
v0.1.0](../assets/component-catalog/blazex-component-classification-v0.1.0.json),
validated by the [classification schema](../assets/component-catalog/blazex-component-classification.schema.json).
Every family and source-closure exception has one explicit outcome. No default
or absent row means “later.”

## Disposition vocabulary

| Disposition | Meaning | Required rationale |
| --- | --- | --- |
| `build-natively` | BlazeX owns an idiomatic Elixir component for the product need. | State the BlazeX behavior basis and reject copied Razor/C# API shape. |
| `adapt-concept` | Upstream use cases and interaction lessons inform a redesigned BlazeX family. | Name the semantic value retained and the state/composition/API independence. |
| `replace-with-platform-pattern` | The product need is met by a BlazeX framework primitive, recipe, context, or mode rather than a matching component. | Name the replacement and why a one-to-one component would be misleading. |
| `renderer-specific-extension` | The need is intentionally confined to an allowlisted renderer extension. | State the backend boundary and portable alternative. |
| `defer` | The family is intentionally postponed outside the current delivery program. | Name owner, trigger, fallback, and review point. |
| `omit` | BlazeX intentionally provides no family. | Explain user alternative, accessibility consequence, and why omission is durable. |

`unresolved` is not a valid Phase 4 disposition. A family may be planned for a
late tier without being deferred; tier F4 is an explicit optional delivery
position, not an ambiguous backlog.

Source-closure exceptions use distinct outcomes: omit from product, retain as
infrastructure, retain as service evidence, confirm no entry, or defer review.
These records cannot acquire component packages or public identities.

## Compatibility and design independence

“Inspired by MudBlazor” means that use cases, interaction lessons, and catalog
coverage informed product analysis. It does not promise:

- C#, Razor, generic type, parameter, callback, service, or lifecycle API
  compatibility;
- assembly, NuGet, binary, source, namespace, or package compatibility;
- identical DOM, CSS, JavaScript, native-widget, or rendering behavior;
- pixel-identical MudBlazor or Material appearance;
- identical component decomposition, nesting, defaults, validation, or event
  timing; or
- that a MudBlazor example can be translated mechanically.

BlazeX public identities are provisional native Elixir namespaces. They are
product-planning references, not implemented modules or runtime atoms. Runtime
mapping must use an allowlisted static registry.

## Delivery tiers

| Tier | Product meaning | Dependency rule |
| --- | --- | --- |
| `F0` | Kernel-facing primitives and shared contexts needed to prove the semantic component system. | May depend only on same/earlier F0 records and inner framework contracts. |
| `F1` | Foundational visual language, content, layout, app shell, and common actions. | Depends on F0 and same-tier primitives without host-heavy behavior. |
| `F2` | Application core: controlled inputs, forms, selection, navigation, and disclosure. | Depends on F0–F2; remote behavior remains optional unless declared. |
| `F3` | Advanced host-coordinated interaction, surfaces, files, gestures, measurement, and window behavior. | Depends on F0–F3 and must have capability/fallback classification. |
| `F4` | Optional data, virtualization, and visualization systems with separate payload/performance gates. | Depends on earlier tiers or explicit F4 foundations; cannot leak into core payloads. |
| `post-1.0` | Approved but outside browser 1.0. | Requires trigger, owner, and user-facing alternative. |
| `not-applicable` | Only for omitted/non-component outcomes. | No package, prerequisites, or public component identity. |

Tier records order product dependencies; they do not state that implementation
exists or that every family in a tier ships simultaneously.

## Package ownership and layering

| Package | Owns | Allowed component-family dependencies |
| --- | --- | --- |
| `blazex_ui_tree` | Semantic dynamic-region and allowlisted renderer-extension identities. | Same package only. |
| `blazex_ui` | Tokens, layout, content, navigation, common actions, and general UI contexts. | `blazex_ui_tree` and `blazex_ui`. |
| `blazex_surfaces` | Focus scopes, overlay/surface stack, popovers, menus, dialogs, drawers, tooltips, snackbars. | UI tree, UI, and surfaces. |
| `blazex_forms` | Form/field/input state, selection, conversion, validation, and pickers. | UI tree, UI, surfaces, and forms. |
| `blazex_data` | Lists, tables, grids, trees, providers, and virtualization. | UI tree, UI, surfaces, forms, and data. |
| `blazex_charts` | Optional chart semantics, scenes, interactions, and nonvisual alternatives. | UI tree, UI, surfaces, data, and charts. |

Profiles, browser/runtime hosts, DOM/LiveView adapters, Phoenix, and Plug own no
portable component behavior. They implement runtime, renderer, capability, or
remote contracts consumed by these packages.

Forms and surfaces are independently optional at application assembly even
though advanced forms may depend on surface contracts. Data and charts are
separately optional; charts do not enter the data package. Optional package
metadata is a payload boundary, not proof of tree shaking or measured size.

## Payload and extraction rules

- `core` records belong to UI tree/UI and must justify every shared asset.
- `optional` records live in forms or surfaces and are included only when the
  application selects those packages.
- `runtime-heavy` data families require provider, virtualization, and
  performance gates before release.
- `asset-heavy` charts require independent scene/asset loading and accessible
  nonvisual representations.
- A family moves packages only through a classification-version change,
  dependency-cycle review, payload diff, public-identity review, and generated
  catalog update.
- Shared behavior moves inward only when at least two packages need the same
  host-neutral contract; browser/Phoenix convenience is not an extraction
  reason.

## Coherence rules

- Every planned family has one F0–F4 tier, one approved component package, one
  provisional BlazeX identity, and a nonempty rationale.
- Prerequisites cite stable family IDs, exist in the source catalog, precede or
  share the dependent tier, and form an acyclic graph.
- A package may depend only on the allowed layers above. A family cannot use a
  profile, renderer, host, Phoenix, Plug, or runtime package as its owner.
- `defer` and `omit` cannot carry active package/tier/public-identity claims.
- Product classification state is `accepted`; implementation state remains
  `unknown` with no implementation evidence.

## Connections

- [Component catalog schema and governance](blazex-component-catalog-schema-and-governance.md)
- [MudBlazor reference and inventory policy](blazex-mudblazor-reference-and-inventory-policy.md)
- [MudBlazor-inspired component system](mudblazor-inspired-component-system-for-blazex.md)
- [BH-00 Phase 4 plan](../60-planning/01-browser-host/bh-00-product-boundary-catalog-and-acceptance-contract/phase-04-disposition-capability-fallback-and-portability-classification.md)

## Sources

- [MudBlazor v9.9.0 source architecture](../30-sources/mudblazor-project-2026-v9-9-source-architecture.md)
- [MudBlazor component documentation](../30-sources/mudblazor-project-2026-component-documentation.md)
