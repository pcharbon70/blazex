---
title: "MudBlazor-inspired component system"
kind: map
created: "2026-09-02"
tags:
  - component-library
  - material-design
  - mudblazor
  - phoenix
aliases:
  - "BlazeX UI catalog map"
---

# MudBlazor-inspired component system

## Scope

This map covers MudBlazor as the reference catalog and interaction/design
system for BlazeX UI. It routes through the exact v9.9.0 source inventory,
official component documentation, Phoenix/LocalLiveView foundations, native
BlazeX design, delivery tiers, and unresolved experiments.

MudBlazor is design and product evidence, not a .NET compatibility target.
BlazeX components remain native Elixir modules producing renderer-neutral
semantic UI. HEEx/DOM and native widgets are separate adapters with
BlazeX-owned names, state contracts, tokens, packages, host protocols, and
tests.

## Start here

- [BlazeX MudBlazor reference and inventory
  policy](../20-notes/blazex-mudblazor-reference-and-inventory-policy.md) locks
  the exact v9.9.0 source truth and defines how families, compound parts,
  services, infrastructure, aliases, and later reference updates are counted.
- [BlazeX component catalog schema and
  governance](../20-notes/blazex-component-catalog-schema-and-governance.md)
  separates permanent BlazeX IDs from source evidence and reserves truthful
  classification, capability, portability, state, and evidence fields.
- [Generated normalized component
  inventory](../assets/component-catalog/blazex-component-catalog-v0-1-0-generated.md)
  presents all 83 source-complete families and explicit exception classes while
  preserving every Phase 4 product decision as unresolved.
- [Generated product
  classification](../assets/component-catalog/blazex-component-classification-v0-1-0-generated.md)
  layers accepted BlazeX dispositions, F0–F4 tiers, package ownership, and
  prerequisites plus capability, remote, and fallback contracts over that
  immutable source catalog.
- [Browser host implementation
  milestones](../20-notes/browser-host-implementation-milestones.md) turns the
  F0–F4 dependency tiers into the consolidated BH-00–BH-23 browser delivery
  and release program.
- [MudBlazor-inspired component system for BlazeX](../20-notes/mudblazor-inspired-component-system-for-blazex.md) — complete architecture, exhaustive family disposition,
  native package model, component-by-component matrices, examples, and staged
  delivery plan.
- [Which MudBlazor component families should BlazeX
  build?](../40-inquiries/which-mudblazor-component-families-should-blazex-build.md) — turns the catalog into product, dependency, host, payload, accessibility,
  and validation decisions.
- [2026-09-02 MudBlazor component-system deep
  dive](../50-journal/2026-09-02-mudblazor-component-system-deep-dive.md) — records the exact checkout, measurements, source paths, and evidence limits.

## Central decisions

- Use MudBlazor v9.9.0 as the initial catalog and UX reference.
- Keep Blazor's built-ins as lower-level runtime/rendering background only.
- Design idiomatic Elixir/Phoenix APIs rather than translating Razor/C# APIs.
- Keep browser Popcorn/AtomVM as the first execution profile, not a permanent
  host or renderer assumption.
- Preserve fully native controls as the ultimate desktop renderer goal;
  webview packaging is an intermediate profile.
- Require a semantic render tree, headless renderer, DOM adapter, and native
  vertical slice before F0 API stability.
- Build theme, controlled state, overlays, effects, forms, icons, and tests
  before maximizing component count.
- Keep authorization, uploads, remote data, and mutations
  Phoenix-authoritative.
- Declare server LiveView, browser-local, static, effect, and Plug support per
  component.
- Split surfaces, forms, data, charts, and icons into independently budgeted
  packages.
- Treat accessibility, RTL, responsive behavior, focus, and cleanup as core
  semantics.

## Primary evidence

- [MudBlazor v9.9.0 source
  architecture](../30-sources/mudblazor-project-2026-v9-9-source-architecture.md) — exact-tag metrics and architecture for state, providers, themes, forms,
  browser services, data components, build assets, and tests.
- [MudBlazor component catalog and
  documentation](../30-sources/mudblazor-project-2026-component-documentation.md) — user-facing component families, interaction contracts, compound controls,
  and documentation evidence.
- [Material Icons licensing and
  delivery](../30-sources/google-2024-material-icons-license-and-delivery.md) — asset provenance and why icons should be build-selected rather than BEAM
  constants.

## Elixir/Phoenix foundations

- [Phoenix LiveView UI foundation
  surfaces](../30-sources/phoenix-framework-2026-liveview-ui-foundation-surfaces.md) — attrs, slots, forms, navigation, upload, hooks, responsive events, and
  security.
- [Phoenix LiveView lifecycle and
  renderer](../30-sources/phoenix-framework-2026-liveview-1-2-documentation-and-source.md) — process ownership, HEEx diffs, identity, and DOM patching.
- [LocalLiveView implementation](../30-sources/software-mansion-2026-local-live-view-first-release.md) — browser-local process/event loop, renderer reuse, navigation, and current
  gaps.
- [Popcorn architecture](../30-sources/software-mansion-2026-popcorn-documentation-and-source.md) — AtomVM/Wasm runtime, package reachability, JavaScript bridge, and
  restrictions.

## Delivery trails

### F0 — foundation

- renderer-neutral semantic nodes, events, resources, accessibility, and
  layout/tokens;
- renderer/capability protocols and independent runtime/host manifests;
- headless renderer, DOM/LiveView lowering, and native-control vertical slice;
- theme/tokens and CSS variables;
- common attrs, slots, IDs, controlled-state convention;
- RTL and responsive contexts;
- browser-effect protocol and lifecycle cleanup;
- portal/surface outlet, focus, keyboard, and z-index policy;
- icon extraction and asset manifest; and
- server/local component test gallery.

### F1 — presentational core

- typography, icon, image, paper, container, grid, stack, divider, skeleton;
- app shell, app bar, toolbar, card;
- button, icon button, alert, avatar, badge, chip, and progress; and
- simple links, breadcrumbs, lists, and tables.

### F2 — controlled interaction and forms

- form/field/conversion/validation state;
- text, numeric, checkbox, switch, radio, slider, toggles;
- select and autocomplete contracts;
- nav menu, pagination, expansion panels, tabs, stepper; and
- snackbar queue and controlled disclosure/selection.

### F3 — browser-coordinated controls

- popover, menu, tooltip, dialog/message box, overlays, focus trap;
- responsive drawer and scroll/page navigation;
- date/range/time/color pickers;
- file selection and upload adapters;
- hotkeys, exit prompt, swipe, split panel, drag/drop, mask, and carousel.

### F4 — complex data systems

- template table and remote provider contract;
- measured virtualization;
- tree view;
- DataGrid slices for columns, sort/page, select, filter, edit,
  group/aggregate, hierarchy, and virtualization; and
- optional chart families.

## Open questions

- Which visual profile should BlazeX adopt: close MudBlazor appearance,
  Material 3, or a BlazeX-branded token system with the same catalog?
- Can a page-level surface outlet work across LocalLiveView's iframe/DOM
  arrangement without private renderer coupling?
- Which browser effects can share one implementation between LiveView and
  LocalLiveView?
- What icon subset and sprite strategy meets the mobile startup budget?
- How should late server validation and provider replies merge with newer
  local revisions?
- What is the public upload path for a local component?
- Which complex components remain useful under plain Plug?
- Which upstream behaviors should BlazeX intentionally omit?
- Which authoring syntax preserves HEEx ergonomics without making HTML the
  renderer ABI?
- Which native toolkit and runtime combination should prove actual controls
  first?
- Which component families are native-preferred, native-composite,
  framework-drawn, host-service, or DOM-specific?

## Related lower-level research

- [Host-neutral and native-renderer architecture](host-neutral-and-native-renderer-architecture.md) — semantic component ABI, non-browser hosts, desktop profiles, and native-control gates.
- [Blazor framework semantics](blazor-framework-semantics.md) — renderer and framework concepts only; not the target visual catalog.
- [Elixir WebAssembly components](elixir-webassembly-components.md) — runtime, build, host, and WebAssembly architecture.
