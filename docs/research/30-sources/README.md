---
title: "Sources"
kind: map
created: "2026-09-02"
tags:
  - archive-navigation
  - directory-index
aliases:
  - "Sources index"
---

# Sources (`30-sources`)

## Purpose

Source notes preserve bibliographic records, supported findings, relevance,
and limitations for works used in the research.

## What belongs here

Put evidence-focused notes on official documentation, specifications, source
trees, release material, papers, and other substantively used works here.
Cross-source conclusions belong in `20-notes`.

## Index

### Subdirectories

- None yet.

### Documents

- [AtomVM WebAssembly runtime and BEAM execution model](atomvm-project-2026-webassembly-runtime.md) — records the compact VM, browser port, `.avm`
  packaging, process model, and compatibility boundary beneath Popcorn.
- [Hologram's Elixir-to-JavaScript client component architecture](bartblast-2026-hologram-project.md) — provides a non-Wasm comparison for client-code
  reachability, component state, server commands, and interop.
- [WebAssembly Component Model and Jco browser tooling](bytecode-alliance-2026-webassembly-component-model-and-jco.md) — separates typed WIT/Wasm composition
  from browser UI component semantics.
- [Wasmtime embedding APIs and desktop platform support](bytecode-alliance-2026-wasmtime-embedding-and-platform-support.md) — establishes native desktop
  embedding, custom host imports, and Windows/macOS/Linux runtime support
  without implying a GUI toolkit.
- [.NET browser WebAssembly runtime and Webcil design](dotnet-project-2026-browser-wasm-runtime-and-webcil.md) — describes the boot-resource graph and
  managed-assembly wrapper used by browser .NET.
- [ASP.NET Core component renderer source at v10.0.0](dotnet-project-2025-aspnetcore-component-renderer-source.md) — traces component state, render trees,
  diffs, batches, event identity, and DOM-boundary updates.
- [Plug 1.20 connection, pipeline, and adapter model](elixir-plug-team-2026-plug-1-20-documentation.md) — defines the minimal non-Phoenix Elixir host
  surface.
- [Firefly alternative BEAM compiler and WebAssembly target](getfirefly-2024-firefly-project.md) — records the archived general AOT compiler/runtime
  effort and why it is not a current foundation.
- [Google Material Icons licensing and delivery](google-2024-material-icons-license-and-delivery.md) — records the Apache 2.0 icon asset boundary and
  supports build-selected icon delivery rather than embedding whole generated
  constant catalogs.
- [Blazor component contracts, styling, and JavaScript interop](microsoft-2026-blazor-component-contracts-styling-and-interop.md) — inventories the core
  Razor component contract, lifecycle, parameter, cascading-value, dynamic
  component, keying, CSS isolation, and collocated-JavaScript surfaces.
- [Blazor forms, routing, and authorization components](microsoft-2026-blazor-forms-routing-and-authorization-components.md) — records the built-in router,
  navigation, form, input, validation, and authorization-aware UI contracts.
- [Blazor layouts, sections, errors, virtualization, and QuickGrid](microsoft-2026-blazor-layout-sections-errors-virtualization-and-quickgrid.md) — records the
  remaining built-in composition, document-head, error-boundary, virtualization,
  and data-grid ideas relevant to the native BlazeX framework design.
- [ASP.NET Core Blazor render modes and Razor components](microsoft-2026-blazor-render-modes-and-components.md) — defines the shared component model across
  static, server, WebAssembly, and Auto modes.
- [Blazor WebAssembly runtime, build, deployment, and packaging](microsoft-2026-blazor-webassembly-runtime-build-and-deployment.md) — distinguishes
  interpreted IL/Webcil from optional AOT and records packaging/lazy loading.
- [MudBlazor v9.9 component catalog and documentation](mudblazor-project-2026-component-documentation.md) — records the official user-facing families,
  compound controls, interaction expectations, and provider requirements used
  as BlazeX product evidence.
- [MudBlazor v9.9.0 source architecture](mudblazor-project-2026-v9-9-source-architecture.md) — records the exact-tag source inventory and architecture for
  state, themes, forms, overlays, browser services, data controls, assets, and
  tests.
- [Cross-origin isolation and SharedArrayBuffer deployment requirements](mozilla-2026-cross-origin-isolation-documentation.md) — records the COOP/COEP
  and cross-origin resource implications of the current runtime.
- [Phoenix 1.8 request, component, channel, and endpoint architecture](phoenix-framework-2026-phoenix-1-8-documentation.md) — defines the primary server
  host layers.
- [Phoenix LiveView 1.2 lifecycle, HEEx diff, and browser renderer](phoenix-framework-2026-liveview-1-2-documentation-and-source.md) — records process
  ownership, compiled templates, diff construction, and DOM patching.
- [Phoenix LiveView UI foundation surfaces](phoenix-framework-2026-liveview-ui-foundation-surfaces.md) — inventories the current attrs, slots,
  forms, uploads, navigation, layouts, JavaScript interop, colocated hooks,
  security, and stream/viewport surfaces available to BlazeX.
- [Orb: generating Core WebAssembly with Elixir](royal-icing-2026-orb-project.md) — evaluates the small native-Wasm DSL path.
- [LocalLiveView 0.1.0 first release and implementation](software-mansion-2026-local-live-view-first-release.md) — documents the existing browser-local
  LiveView architecture and current private API/SSR risks.
- [Popcorn 0.3.3 architecture, build pipeline, and limitations](software-mansion-2026-popcorn-documentation-and-source.md) — documents AtomVM-in-Wasm,
  BEAM bundle packaging, iframe interop, compatibility, and current limitations.
- [Tauri desktop webview architecture](tauri-2026-desktop-webview-architecture.md) — documents the native-shell/system-webview middle profile and its
  explicit native capability bridge.
- [Wasmex: embedding Wasmtime in Elixir](tessi-2026-wasmex-project.md) — distinguishes Wasm-in-BEAM execution from Elixir-in-Wasm and identifies its
  role for restricted kernels/plugins rather than UI rendering.
- [WebAssembly non-web embeddings and WASI host capabilities](webassembly-community-group-2026-non-web-embeddings-and-wasi.md) — establishes host-independent
  Core Wasm, host-supplied imports, non-browser execution, and WASI's
  capability role.
- [WebAssembly JavaScript and Web embedding APIs](webassembly-community-group-2026-javascript-and-web-api.md) — establishes the host/JavaScript boundary
  and absence of direct DOM ownership in Core Wasm.
- [WASI WebGPU and windowing status](webassembly-wasi-2026-webgpu-and-windowing-status.md) — records that current WASI graphics work does not provide a
  stable windowing or native-widget standard.

## Maintaining this index

Index every direct source note and identify its evidentiary role. Keep
bibliographic metadata exact, use primary sources where possible, and avoid
promoting source claims into archive conclusions without synthesis.
