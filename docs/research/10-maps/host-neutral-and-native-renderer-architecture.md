---
title: "Host-neutral and native-renderer architecture"
kind: map
created: "2026-09-02"
tags:
  - desktop
  - host-abstraction
  - native-ui
  - rendering
  - webassembly
aliases:
  - "BlazeX multi-host map"
---

# Host-neutral and native-renderer architecture

## Scope

This map covers the correction from a browser-defined component framework to
a host-neutral semantic UI architecture. Browser Popcorn/AtomVM remains the
first implementation. Fully native desktop controls are the ultimate
renderer target, with a webview shell retained as an intermediate profile.

## Start here

- [Architecture decision
  register](../20-notes/architecture-decisions/README.md) — records the
  accepted host-neutral kernel, semantic UI, effects, renderer, server,
  profile, native-proof, and non-.NET-compatibility boundaries.
- [BlazeX canonical
  vocabulary](../20-notes/blazex-canonical-vocabulary.md) — fixes the meanings
  of runtime, execution host, renderer, capability provider, server adapter,
  shell, profile, and portable component contract used by this map.
- [BlazeX repository ownership and dependency
  map](blazex-repository-ownership-and-dependency-map.md) — maps those
  dimensions onto the current packages and profiles and records forbidden
  dependency edges.
- [Browser host implementation
  milestones](../20-notes/browser-host-implementation-milestones.md) applies
  the host-neutral constraints to the first production host while keeping the
  native-control work limited to the early portability gate.
- [Host-neutral BlazeX architecture and native control
  backends](../20-notes/host-neutral-blazex-architecture-and-native-control-backends.md) — authoritative decomposition, semantic render tree, capability protocol,
  native-control strategies, package boundaries, and N0–N4 gates.
- [Cross-platform native host and renderer
  architecture](../20-notes/cross-platform-native-host-and-renderer-architecture.md) —
  deep comparison of SDL3, winit, Skia, Cairo/Pango, AccessKit, direct
  Win32/AppKit/GTK controls, Slint, BEAM integration, platform packaging, and
  the recommended multi-proof program. Qt and wxWidgets are excluded from the
  active design.
- [Can one BlazeX component model target DOM and native
  controls?](../40-inquiries/can-one-blazex-component-model-target-dom-and-native-controls.md) — executable criteria for proving that the abstraction is real.
- [2026-09-04 direct native-control host
  revision](../50-journal/2026-09-04-direct-native-control-host-revision.md) —
  records why direct Win32/AppKit/GTK adapters supersede the earlier wrapper-
  toolkit recommendation.
- [2026-09-02 host-neutral native-renderer design
  revision](../50-journal/2026-09-02-host-neutral-native-renderer-design-revision.md) — records the reasoning, source pass, and negative findings.

## Architectural rule

Keep these dimensions independent:

1. runtime substrate;
2. execution host;
3. render backend;
4. capability provider;
5. server/remote adapter; and
6. deployment shell.

A portable component emits semantic UI nodes and semantic events. HEEx,
HTML, CSS, DOM events, JavaScript handles, native toolkit classes, Popcorn,
and Phoenix sockets are adapter concerns.

## Deployment trails

### Browser-local reference

- [Popcorn](../30-sources/software-mansion-2026-popcorn-documentation-and-source.md)
  supplies browser AtomVM execution and build tooling.
- [LocalLiveView](../30-sources/software-mansion-2026-local-live-view-first-release.md)
  supplies the current process/render/event proof and DOM adapter path.
- [Phoenix LiveView](../30-sources/phoenix-framework-2026-liveview-1-2-documentation-and-source.md)
  supplies the first mature renderer and server integration reference.

### Non-browser and embedded hosts

- [Non-web WebAssembly and WASI](../30-sources/webassembly-community-group-2026-non-web-embeddings-and-wasi.md)
  establishes host-independent Core Wasm and capability-supplied imports.
- [Wasmtime embedding](../30-sources/bytecode-alliance-2026-wasmtime-embedding-and-platform-support.md)
  demonstrates desktop-native Wasm embedding and custom host functions.
- [Wasmex](../30-sources/tessi-2026-wasmex-project.md) supplies the reverse
  Wasm-in-BEAM direction for plugins and pure kernels.

### Desktop middle profile

- [Tauri desktop webview architecture](../30-sources/tauri-2026-desktop-webview-architecture.md)
  supports static HTML/CSS/JS/Wasm in a system webview plus explicit native
  commands. It is a packaging/capability bridge, not a native-control backend.

### Native rendering boundary

- [WASI WebGPU and windowing status](../30-sources/webassembly-wasi-2026-webgpu-and-windowing-status.md)
  establishes that current WASI graphics work does not provide a portable
  native-widget system.
- [Component Model and Jco](../30-sources/bytecode-alliance-2026-webassembly-component-model-and-jco.md)
  provides a possible future host ABI, not a renderer or UI framework.

### Desktop shell and custom-scene trail

- [SDL3 desktop host primitives](../30-sources/libsdl-project-2026-sdl3-desktop-host-primitives.md)
  establishes a credible C-ABI window, input, IME-transport, and native-handle
  layer while showing why SDL rendering is not the BlazeX scene contract.
- [Skia cross-platform 2D graphics](../30-sources/google-2026-skia-2d-graphics-library.md)
  supports the leading mature scene backend; [Cairo, Pango, and
  HarfBuzz](../30-sources/cairo-pango-harfbuzz-2026-rendering-and-text-stack.md)
  support separate pinned raster and text-layout comparisons.
- [Taffy and Yoga](../30-sources/dioxuslabs-meta-2026-taffy-and-yoga-layout-engines.md)
  supply embeddable layout-engine candidates, while the
  [Cassowary paper](../30-sources/badros-borning-stuckey-2001-cassowary-layout-constraints.md)
  bounds the role of incremental constraints. Scrolling, hit testing, focus,
  and native-control measurement remain renderer work.
- [Rust window, GPU, and vector rendering](../30-sources/rust-windowing-gfx-rs-linebender-2026-native-graphics-stack.md)
  separates winit windowing, wgpu/Dawn GPU substrates, and the experimental
  Vello 0.9 Classic/CPU/Hybrid renderer family.
- [AccessKit and platform accessibility
  bridges](../30-sources/accesskit-platform-vendors-2026-desktop-accessibility-bridges.md)
  connect one semantic tree to UI Automation, NSAccessibility, and AT-SPI
  without eliminating platform tests.
- [ERTS releases, ports, and native
  integration](../30-sources/erlang-elixir-2026-releases-ports-and-native-integration.md)
  supports the split-process runtime/host boundary.

### Direct platform-control trail

- [Direct Windows, AppKit, and GTK native-control
  APIs](../30-sources/platform-vendors-2026-direct-native-control-apis.md)
  support three bounded platform materializers behind the same semantic
  protocol and are the required ADR-0007 control-proof path.
- [GTK4](../30-sources/gtk-project-2026-gtk4-desktop-ui-platform.md) provides
  the deeper Linux toolkit, text, accessibility, and display-server context.
- [Slint](../30-sources/slint-project-2026-desktop-ui-runtime.md) remains an
  optional lean Rust/custom-scene comparison only when configured without an
  excluded backend.
- [Qt](../30-sources/qt-project-2026-desktop-ui-platform.md) and
  [wxWidgets](../30-sources/wxwidgets-project-2026-native-control-toolkit.md)
  are retained as historical comparisons and are excluded from active
  implementation, proof, benchmarking, dependencies, and fallbacks.
- [Flutter's embedder architecture](../30-sources/flutter-project-2026-desktop-embedder-architecture.md)
  provides production precedent for portable engine plus platform-specific
  surfaces, input, accessibility, event loop, and packaging.

## Product trails

- [MudBlazor-inspired component system](mudblazor-inspired-component-system.md)
  defines catalog and interaction semantics that must lower through each
  renderer profile.
- [Elixir WebAssembly components](elixir-webassembly-components.md) covers
  language runtime, build, Phoenix/Plug, and browser evidence.
- [Blazor framework semantics](blazor-framework-semantics.md) provides
  lower-level lifecycle, identity, forms, and renderer lessons without
  defining the portable output format.

## Required early proofs

- versioned semantic node/event/effect/accessibility contracts;
- deterministic headless renderer;
- DOM/LiveView lowering behind an adapter;
- direct Win32, AppKit, and GTK 4 spikes creating actual control resources;
- shared button, field, selection, list, surface, focus, file, and disposal
  traces; and
- static checks preventing DOM, CSS, JavaScript, Phoenix, and native toolkit
  types from leaking into portable packages.

These bullets are the existing early portability program. ADR-0007 itself
resolves only when the same representative slice passes deterministic
headless, standalone DOM, and direct actual-native-control proofs. The
custom-scene work below is a separate native-host research program and does
not silently expand that decision.

## Additional native-host research program (not ADR-0007)

- a split-process native host proving version negotiation, scene sequences,
  generation-safe resources, backpressure, crash cleanup, and full remount;
- a renderer-local layout, intrinsic-measurement, scrolling, hit-testing, and
  focus subsystem;
- the headless semantic oracle, a pinned Skia Raster/Cairo comparison driven
  by one already-shaped display list, and a separate
  SkParagraph/Pango-HarfBuzz text-layout comparison;
- a GPU-capable renderer driven by the same retained display list, including
  an explicit SDL–Skia surface/swapchain ownership proof per OS;
- complex text, IME, accessibility-tree, and screen-reader evidence on each
  target OS; and
- signed/installable Windows, macOS, and Linux artifacts under the selected
  sandbox and capability policies.

## Open questions

- Which authoring syntax can preserve Phoenix ergonomics while producing a
  renderer-neutral semantic tree?
- How much implementation can the Win32, AppKit, and GTK adapters share
  through generated protocol bindings and fixtures without creating another
  widget abstraction?
- Does SDL3 + Skia + AccessKit have lower measured total ownership than a
  winit/Slint custom-scene host configured without excluded backends?
- Can the full F0 slice preserve equivalent event, focus, accessibility,
  resource, and disposal semantics across the three direct adapters?
- Should the production text path use SkParagraph/SkShaper or direct
  HarfBuzz/ICU plus platform font services?
- Can current AtomVM be embedded natively, or should desktop initially use
  ERTS while the browser uses AtomVM?
- Is a standalone Wasmtime/AtomVM host valuable enough to justify a new import
  target?
- Which MudBlazor families map to native controls, native composites, or
  framework-drawn scenes?
- How should visual-profile differences be documented and tested?
