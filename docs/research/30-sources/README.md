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

- [AccessKit and desktop platform accessibility bridges](accesskit-platform-vendors-2026-desktop-accessibility-bridges.md) — connects one semantic tree to Windows UI Automation, macOS NSAccessibility, and Linux AT-SPI while preserving platform-specific proof requirements.
- [The Cassowary Linear Arithmetic Constraint Solving Algorithm](badros-borning-stuckey-2001-cassowary-layout-constraints.md) — supplies the incremental required/preferred linear-constraint model considered for specialized renderer-local layout relationships.
- [A Platform Agnostic Remote Desktop System for Screen Reading](billah-et-al-2016-platform-agnostic-screen-reading.md) — demonstrates that semantic accessibility information, unlike pixels alone, can be translated across otherwise incompatible OS screen-reader APIs.
- [Cairo, Pango, and HarfBuzz rendering and text stack](cairo-pango-harfbuzz-2026-rendering-and-text-stack.md) — separates Cairo's pinned raster comparison/fallback from Pango/HarfBuzz text-layout conformance and the headless semantic oracle.
- [Desktop packaging, signing, notarization, and sandbox capabilities](desktop-platform-vendors-2026-packaging-signing-and-sandboxing.md) — establishes target-specific macOS, Windows, and Flatpak distribution constraints and their effect on host capabilities.
- [Taffy and Yoga embeddable UI layout engines](dioxuslabs-meta-2026-taffy-and-yoga-layout-engines.md) — compares reusable Block/Flexbox/Grid and Flexbox geometry engines while preserving BlazeX-owned measurement, scrolling, and hit testing.
- [ERTS releases, external ports, and native integration](erlang-elixir-2026-releases-ports-and-native-integration.md) — supports a target-specific BEAM release plus a separate native process rather than a main-thread GUI NIF.
- [Flutter desktop engine and platform embedder architecture](flutter-project-2026-desktop-embedder-architecture.md) — provides production precedent for a portable engine surrounded by platform-specific event-loop, input, accessibility, surface, and packaging adapters.
- [Skia cross-platform 2D graphics library](google-2026-skia-2d-graphics-library.md) — establishes the leading mature common scene backend and its window/context/text boundaries.
- [GTK4 cross-platform desktop UI platform](gtk-project-2026-gtk4-desktop-ui-platform.md) — records GDK/GSK, Pango/IME, accessibility, C-ABI, threading, and non-Linux packaging tradeoffs.
- [Building a UI Framework](hickson-2025-building-a-ui-framework.md) — supplies a system-level design checklist spanning performance, power, input, focus, accessibility, rendering, and adoption.
- [Fast GPU bounding boxes on tree-structured scenes](levien-2022-gpu-tree-scene-rendering.md) — supports a retained GPU-capable scene model while leaving Vello production maturity as a separate question.
- [libui-ng portable native GUI library](libui-ng-project-2026-portable-native-gui.md) — records the attractive C/native API and the project's explicit mid-alpha production limitation.
- [SDL3 desktop host, input, and graphics primitives](libsdl-project-2026-sdl3-desktop-host-primitives.md) — establishes SDL3 as a credible three-OS shell while showing why its render/GPU APIs are not a complete BlazeX renderer.
- [Developing Accessible Mobile Applications with Cross-Platform Development Frameworks](mascetti-et-al-2021-cross-platform-accessibility.md) — finds that cross-platform frameworks can omit native accessibility capabilities and require platform-specific escape code.
- [Accessibility of UI Frameworks and Libraries for Programmers with Visual Impairments](pandey-et-al-2022-ui-framework-accessibility.md) — supplies mixed-methods evidence for actual framework, OS, and screen-reader testing.
- [Direct Windows, AppKit, and GTK native-control APIs](platform-vendors-2026-direct-native-control-apis.md) — supports the active three-adapter actual-control proof with official platform lifecycle, control, and accessibility documentation.
- [Qt 6 desktop UI, rendering, input, and accessibility platform](qt-project-2026-desktop-ui-platform.md) — historical comparison retained for provenance; Qt is excluded from the active native-host design as of 2026-09-04.
- [Rust window, GPU, and vector-rendering stack](rust-windowing-gfx-rs-linebender-2026-native-graphics-stack.md) — pins winit 0.30.12, wgpu 30, and Vello 0.9.0 while separating windowing, GPU substrate, and the experimental Classic/CPU/Hybrid renderer family.
- [Slint desktop UI runtime, backends, renderers, and accessibility](slint-project-2026-desktop-ui-runtime.md) — records the leading lean Rust/custom-scene toolkit comparison and its renderer-dependent text and licensing questions.
- [wxWidgets cross-platform native-control toolkit](wxwidgets-project-2026-native-control-toolkit.md) — historical comparison retained for provenance; wxWidgets is excluded from the active native-host design as of 2026-09-04.
- [Zed GPUI custom GPU rendering and Linux platform engineering](zed-industries-2023-2024-custom-gpu-ui-engineering.md) — documents both the performance opportunity and platform-integration cost of a specialized custom GPU UI.
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
