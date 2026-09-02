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

- [Host-neutral BlazeX architecture and native control
  backends](../20-notes/host-neutral-blazex-architecture-and-native-control-backends.md) — authoritative decomposition, semantic render tree, capability protocol,
  native-control strategies, package boundaries, and N0–N4 gates.
- [Can one BlazeX component model target DOM and native
  controls?](../40-inquiries/can-one-blazex-component-model-target-dom-and-native-controls.md) — executable criteria for proving that the abstraction is real.
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
- a native toolkit spike creating actual control resources;
- shared button, field, selection, list, surface, focus, file, and disposal
  traces; and
- static checks preventing DOM, CSS, JavaScript, Phoenix, and native toolkit
  types from leaking into portable packages.

## Open questions

- Which authoring syntax can preserve Phoenix ergonomics while producing a
  renderer-neutral semantic tree?
- Which native toolkit should prove the protocol first?
- Can current AtomVM be embedded natively, or should desktop initially use
  ERTS while the browser uses AtomVM?
- Is a standalone Wasmtime/AtomVM host valuable enough to justify a new import
  target?
- Which MudBlazor families map to native controls, native composites, or
  framework-drawn scenes?
- How should visual-profile differences be documented and tested?
