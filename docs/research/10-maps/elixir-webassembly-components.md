---
title: "Elixir WebAssembly components"
kind: map
created: "2026-09-02"
tags:
  - blazor
  - components
  - elixir
  - phoenix
  - webassembly
aliases:
  - "BlazeX research map"
---

# Elixir WebAssembly components

## Scope

This map covers browser and non-browser execution of Elixir-authored UI
components, the architectural lessons from Blazor and Phoenix LiveView,
current Elixir/Wasm toolchains, and the boundaries among runtime substrate,
execution host, renderer, capability provider, and Phoenix/Plug remote
services.

MudBlazor v9.9.0 is the target product catalog and interaction reference.
Blazor's built-ins remain lower-level runtime/framework evidence only. Neither
source creates a .NET compatibility objective.

## Start here

- [The browser and toolchain support
  policy](../20-notes/blazex-browser-and-toolchain-support-policy.md) defines
  the unproven BH-00 candidate envelope and the evidence BH-01 must produce
  before any browser/profile combination can claim support.
- [The rendering and profile mode
  contract](../20-notes/blazex-browser-rendering-and-profile-modes.md) defines
  surface ownership, activation behavior, adapter separation, profile
  capabilities, and the Plug transitive-dependency gate.
- [The browser trust, deployment, and fallback
  policy](../20-notes/blazex-browser-trust-deployment-and-fallback-policy.md)
  defines server authority, command validation, deployment prerequisites, and
  bounded failure behavior.
- [The browser-host milestone
  roadmap](../20-notes/browser-host-implementation-milestones.md) consolidates
  all current findings into 24 ordered outcome gates from feasibility through
  browser 1.0.
- [The main synthesis](../20-notes/elixir-webassembly-component-framework-for-phoenix-and-plug.md)
  develops the complete comparison, recommended architecture, risks, and
  staged implementation plan.
- [The host-neutral architecture
  amendment](../20-notes/host-neutral-blazex-architecture-and-native-control-backends.md)
  makes browser Popcorn/AtomVM the first profile rather than the component ABI
  and defines the native-control destination.
- [The MudBlazor-inspired component-system
  study](../20-notes/mudblazor-inspired-component-system-for-blazex.md) defines
  the target visual catalog, native package architecture, exhaustive family
  dispositions, and F0–F4 delivery plan.
- [The Blazor framework-semantics
  study](../20-notes/blazor-framework-semantics-beneath-blazex.md) uses each
  built-in framework family as a lower-level design prompt for the renderer
  and host substrate.
- [The active inquiry](../40-inquiries/can-elixir-webassembly-components-integrate-with-phoenix-and-plug.md)
  states what evidence is still needed before calling the approach viable for
  production.
- [The research journal](../50-journal/2026-09-02-elixir-webassembly-components-deep-dive.md)
  records versions, inspection methods, measurements, and evidence boundaries.

## Trails

### Host-neutral and native-control architecture

- [Host-neutral and native-renderer
  map](host-neutral-and-native-renderer-architecture.md) routes through
  semantic UI, non-web hosts, desktop embedding, the webview middle profile,
  native controls, and early cross-renderer gates.
- [WebAssembly non-web embeddings and
  WASI](../30-sources/webassembly-community-group-2026-non-web-embeddings-and-wasi.md)
  establishes host-independent Wasm and capability-supplied imports.
- [Wasmtime embedding](../30-sources/bytecode-alliance-2026-wasmtime-embedding-and-platform-support.md)
  provides the principal native Wasm-host evidence.
- [Tauri](../30-sources/tauri-2026-desktop-webview-architecture.md) documents
  the optional desktop webview middle profile.
- [WASI graphics/windowing status](../30-sources/webassembly-wasi-2026-webgpu-and-windowing-status.md)
  explains why BlazeX cannot assume a standard native-widget API.

### MudBlazor as the target visual catalog

- [MudBlazor-inspired component-system map](mudblazor-inspired-component-system.md)
  routes through the exact v9.9.0 inventory, official catalog, native BlazeX
  architecture, family tiers, and open experiments.
- [MudBlazor v9.9.0 source architecture](../30-sources/mudblazor-project-2026-v9-9-source-architecture.md)
  records the component, state, provider, theme, form, browser-service, asset,
  and test subsystems.
- [MudBlazor component documentation](../30-sources/mudblazor-project-2026-component-documentation.md)
  supplies user-facing catalog and interaction evidence.

### Blazor as the shared-runtime and framework reference

- [Blazor framework semantics map](blazor-framework-semantics.md)
  provides the dedicated trail through concrete component ideas and proposed
  BlazeX substrate priorities.
- [Blazor render modes and components](../30-sources/microsoft-2026-blazor-render-modes-and-components.md)
  establishes the unified component model across static, server, WebAssembly,
  and Auto modes.
- [Blazor component contracts and
  interop](../30-sources/microsoft-2026-blazor-component-contracts-styling-and-interop.md)
  inventories props, callbacks, fragments, lifecycle, cascades, binding,
  styling, and JavaScript.
- [Blazor forms, routing, and authorization
  components](../30-sources/microsoft-2026-blazor-forms-routing-and-authorization-components.md)
  inventories the principal concrete built-in families.
- [Blazor layout, error, virtualization, and QuickGrid
  components](../30-sources/microsoft-2026-blazor-layout-sections-errors-virtualization-and-quickgrid.md)
  covers the cross-tree and data-intensive facilities.
- [Blazor WebAssembly runtime, build, and deployment](../30-sources/microsoft-2026-blazor-webassembly-runtime-build-and-deployment.md)
  separates interpreted IL/Webcil from optional native Wasm AOT.
- [ASP.NET Core component renderer source](../30-sources/dotnet-project-2025-aspnetcore-component-renderer-source.md)
  traces component state, render trees, diffs, batches, events, and JavaScript
  DOM updates.
- [.NET browser runtime and Webcil](../30-sources/dotnet-project-2026-browser-wasm-runtime-and-webcil.md)
  records the boot-resource and managed-assembly model.

### Phoenix, Plug, HEEx, and LiveView

- [Phoenix 1.8 documentation](../30-sources/phoenix-framework-2026-phoenix-1-8-documentation.md)
  defines the endpoint, router, controller, component, Channel, and PubSub
  layers.
- [LiveView 1.2 documentation and source](../30-sources/phoenix-framework-2026-liveview-1-2-documentation-and-source.md)
  explains processes, assigns, compiled HEEx, compact diffs, LiveComponents,
  and browser DOM patching.
- [LiveView UI foundation
  surfaces](../30-sources/phoenix-framework-2026-liveview-ui-foundation-surfaces.md)
  records the attrs, slots, forms, upload, navigation, layout, viewport,
  JavaScript, and security contracts used by the design matrix.
- [Plug 1.20 documentation](../30-sources/elixir-plug-team-2026-plug-1-20-documentation.md)
  defines the minimal host contract available without Phoenix.

### The existing Elixir-in-Wasm path

- [Popcorn documentation and source](../30-sources/software-mansion-2026-popcorn-documentation-and-source.md)
  documents AtomVM compiled to Wasm, BEAM bytecode bundles, iframe isolation,
  JavaScript interop, and current limitations.
- [LocalLiveView first release and source](../30-sources/software-mansion-2026-local-live-view-first-release.md)
  demonstrates browser-local LiveView processes and reuse of the existing
  LiveView diff/DOM protocol.
- [AtomVM's WebAssembly runtime](../30-sources/atomvm-project-2026-webassembly-runtime.md)
  supplies the underlying BEAM-compatible execution substrate.

### Alternative and complementary paths

- [Orb](../30-sources/royal-icing-2026-orb-project.md) generates tiny native
  Core Wasm through an Elixir DSL, but explicitly does not execute arbitrary
  Elixir or own the DOM.
- [Hologram](../30-sources/bartblast-2026-hologram-project.md) compiles
  client-reachable Elixir to JavaScript and is valuable as a framework/compiler
  comparison even though it does not target Wasm.
- [Wasmex](../30-sources/tessi-2026-wasmex-project.md) runs Wasm inside a BEAM
  server and therefore solves the opposite embedding direction.
- [Firefly](../30-sources/getfirefly-2024-firefly-project.md) pursued general
  BEAM-language AOT compilation, but the project was archived in 2024.

### Host and standards boundaries

- [WebAssembly JavaScript and Web APIs](../30-sources/webassembly-community-group-2026-javascript-and-web-api.md)
  establishes that the browser embedder supplies host APIs and DOM access.
- [Component Model and Jco](../30-sources/bytecode-alliance-2026-webassembly-component-model-and-jco.md)
  clarifies why WIT composition is not itself a UI framework.
- [Cross-origin isolation](../30-sources/mozilla-2026-cross-origin-isolation-documentation.md)
  records the deployment implications of `SharedArrayBuffer`.

## Open questions

- What exact Elixir/OTP/HEEx subset can be guaranteed and checked at build
  time?
- Can the renderer dependency become public and versioned upstream?
- What is the minimum cold payload after practical tree shaking?
- Can one component module render identically on BEAM and AtomVM?
- What state-transfer format supports safe SSR activation and schema evolution?
- Which server bridge semantics remain portable between Phoenix Channels and
  plain Plug?
- Which BlazeX capability rows can move from proposed or inferred to tested
  under the pinned browser runtime?
- Which authoring and semantic-tree contracts survive both DOM and actual
  native-control renderers?
- Which native toolkit/runtime combination should provide the first desktop
  proof?
