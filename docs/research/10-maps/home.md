---
title: "BlazeX Research"
kind: map
created: "2026-09-02"
tags:
  - blazor
  - elixir
  - phoenix
  - webassembly
aliases:
  - "Home"
---

# BlazeX Research

This is the selective entry point to research on an Elixir-authored,
host-neutral component framework with browser, webview, native-control, and
headless profiles, including WebAssembly execution. See the [archive
guide](../README.md) for corpus structure and working conventions.

## Research objective

Determine whether a useful subset of Elixir's component, process, and
rendering model can execute across browser and non-browser hosts with
acceptable startup cost, compatibility, security, accessibility, and tooling,
while Phoenix or Plug can remain a trusted remote boundary where needed.

The objective deliberately separates a WebAssembly-hosted Elixir runtime from
native AOT compilation and from WebAssembly Component Model packaging. It also
separates runtime substrate, execution host, render backend, capability
provider, and remote adapter.

## Active inquiry

- [Can one BlazeX component model target DOM and native
  controls?](../40-inquiries/can-one-blazex-component-model-target-dom-and-native-controls.md) —
  defines the cross-renderer vertical slice and proof required before F0 API
  stability.
- [Which MudBlazor component families should BlazeX
  build?](../40-inquiries/which-mudblazor-component-families-should-blazex-build.md) —
  defines the product catalog, dependency tiers, host support, accessibility,
  payload, and validation gates for native BlazeX components.
- [Can Elixir WebAssembly components integrate with Phoenix and
  Plug?](../40-inquiries/can-elixir-webassembly-components-integrate-with-phoenix-and-plug.md) —
  defines falsifiable runtime, rendering, hosting, payload, security, and
  maintainability criteria.
- [Which foundational component semantics does BlazeX
  need?](../40-inquiries/which-foundational-component-semantics-does-blazex-need.md) —
  defines executable acceptance criteria for the renderer, lifecycle, form,
  effect, and host substrate beneath the visual library.

## Topic map

- [BlazeX repository ownership and dependency
  map](blazex-repository-ownership-and-dependency-map.md) — enumerates all
  current monorepo owners, allowed dependency directions, profile
  compositions, invalid edges, and experiment promotion rules.
- [Host-neutral and native-renderer
  architecture](host-neutral-and-native-renderer-architecture.md) — routes
  through non-web Wasm, embedded runtimes, semantic UI, renderer protocols,
  webview middle deployment, and the native-control target.
- [MudBlazor-inspired component system](mudblazor-inspired-component-system.md) —
  routes through the v9.9.0 catalog, source architecture, native BlazeX
  design, component-family dispositions, and staged delivery program.
- [Elixir WebAssembly components](elixir-webassembly-components.md) — routes
  through Blazor's shared-runtime architecture, Phoenix and LiveView's render
  system, browser constraints, Popcorn/LocalLiveView, and alternative compiler
  strategies.
- [Blazor framework semantics](blazor-framework-semantics.md) — routes through
  built-in Razor framework families as lower-level design evidence for the
  native renderer and host substrate; it is not the visual catalog.

## Main synthesis

- [Architecture decision
  register](../20-notes/architecture-decisions/README.md) — the permanent BH-00
  decision IDs, accepted boundaries, ownership, impact analysis, review
  triggers, and supersession workflow.
- [BlazeX MudBlazor reference and inventory
  policy](../20-notes/blazex-mudblazor-reference-and-inventory-policy.md) — the
  immutable v9.9.0 reference identity, 83-family extraction boundary,
  normalization rules, explicit exclusions, and later-reference diff process.
- [BlazeX component catalog schema and
  governance](../20-notes/blazex-component-catalog-schema-and-governance.md) —
  stable family identities, source relationships, deferred Phase 4 fields,
  delivery-state semantics, and canonical/generated stewardship.
- [BlazeX component disposition, tier, and package
  policy](../20-notes/blazex-component-disposition-tier-and-package-policy.md) —
  explicit product outcomes, F0–F4 dependency order, package ownership,
  payload boundaries, and native-Elixir compatibility nonclaims.
- [BlazeX component capability, remote, and fallback
  policy](../20-notes/blazex-component-capability-remote-and-fallback-policy.md) —
  portable host/renderer capabilities, lifecycle ownership, remote authority,
  trust boundaries, and nine explicit degradation conditions.
- [BlazeX component portability, native, and visual-profile
  policy](../20-notes/blazex-component-portability-native-and-visual-profile-policy.md) —
  semantic portability, future native-control mapping, visual-profile
  differences, and backend evidence gates without premature support claims.
- [BlazeX browser and toolchain support
  policy](../20-notes/blazex-browser-and-toolchain-support-policy.md) — the
  candidate browser windows, evidence classes, toolchain states, review
  cadence, and BH-01 promotion records; no stack is supported yet.
- [BlazeX browser rendering and profile
  modes](../20-notes/blazex-browser-rendering-and-profile-modes.md) — the
  observable static, server, prerender, local, activation, and headless
  contracts plus independent Phoenix, Plug, and headless capability matrices.
- [BlazeX browser trust, deployment, and fallback
  policy](../20-notes/blazex-browser-trust-deployment-and-fallback-policy.md) —
  the browser/server authority boundary, command controls, deployment matrix,
  and accessible fail-closed behavior for seven failure classes.
- [BlazeX canonical
  vocabulary](../20-notes/blazex-canonical-vocabulary.md) — the BH-00
  normative meanings for architecture dimensions, product terms, rendering
  modes, WebAssembly terms, and support language.
- [Browser host implementation
  milestones](../20-notes/browser-host-implementation-milestones.md) — the
  consolidated BH-00–BH-23 delivery program for the browser profile, spanning
  feasibility, platform foundations, the MudBlazor-inspired catalog,
  production hardening, and browser 1.0.
- [Host-neutral BlazeX architecture and native control
  backends](../20-notes/host-neutral-blazex-architecture-and-native-control-backends.md) —
  the authoritative architecture amendment: semantic render tree, independent
  runtime/host/renderer axes, host capabilities, native-control strategies,
  package boundaries, and N0–N4 gates.
- [MudBlazor-inspired component system for
  BlazeX](../20-notes/mudblazor-inspired-component-system-for-blazex.md) — the
  product-level architecture, exhaustive 83-family disposition, native API
  direction, package model, and F0–F4 roadmap. MudBlazor is a catalog and UX
  reference, never a .NET compatibility target.
- [Elixir WebAssembly component framework for Phoenix and
  Plug](../20-notes/elixir-webassembly-component-framework-for-phoenix-and-plug.md) —
  the complete runtime and server-integration report. It concludes that
  Popcorn/AtomVM and LocalLiveView are the shortest browser path while the
  public component model remains renderer-neutral.
- [Blazor framework semantics beneath
  BlazeX](../20-notes/blazor-framework-semantics-beneath-blazex.md) — the
  lower-level component/runtime matrix for identity, forms, lifecycle,
  navigation, effects, and host boundaries.

## Research record

- [2026-09-02 host-neutral native-renderer design
  revision](../50-journal/2026-09-02-host-neutral-native-renderer-design-revision.md) —
  records the non-web/desktop evidence and why HEEx cannot be the universal
  component ABI.
- [2026-09-02 MudBlazor component-system deep
  dive](../50-journal/2026-09-02-mudblazor-component-system-deep-dive.md) —
  records the exact v9.9.0 checkout, source inventory, architecture paths,
  measurements, and evidence limitations.
- [2026-09-02 Elixir WebAssembly components deep
  dive](../50-journal/2026-09-02-elixir-webassembly-components-deep-dive.md) —
  records source selection, version baselines, source inspection, local package
  measurements, and evidence limitations.
- [2026-09-02 Blazor component semantics deep
  dive](../50-journal/2026-09-02-blazor-component-semantics-deep-dive.md) —
  records the built-in API inventory, LocalLiveView feature inspection, and
  semantic-adaptation classification method.

## Unsettled threads

- Which semantic authoring syntax can preserve Phoenix ergonomics without
  making HTML canonical?
- Which native toolkit and local runtime should prove actual controls first?
- Whether AtomVM needs a native embedding target or separate Wasmtime/WASI
  import profile for desktop execution.
- Which MudBlazor families should be native-preferred, native-composite,
  framework-drawn, host-service, or DOM-specific.
- Which MudBlazor families belong in the first public BlazeX release, and
  which should be deferred or intentionally omitted?
- Whether a shared overlay/surface outlet, focus manager, responsive service,
  and effect protocol can behave consistently in server and browser-local
  modes.
- Which visual profile, icon subset, and package split can achieve a coherent
  design system without exceeding mobile startup budgets.
- Whether LocalLiveView can expose or obtain a public, versioned LiveView
  renderer interface instead of relying on private modules and JavaScript
  internals.
- Whether AtomVM/Popcorn can support a practical browser-runtime profile without
  exact OTP and Elixir pins.
- Whether server-rendered HEEx can hydrate into local AtomVM state without
  duplicated side effects or visible DOM replacement.
- Whether cross-origin isolation is acceptable for the target application
  classes and third-party integrations.
- Which payload, startup, memory, and local-event latency thresholds define an
  acceptable product.
- Whether Plug-only support should ship LiveView's browser renderer or use a
  smaller independent render protocol.
- Which P0 BlazeX contracts survive executable Phoenix/LocalLiveView tests,
  especially forms, lifecycle cleanup, keys, and effects.
