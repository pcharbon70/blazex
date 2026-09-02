---
title: "2026-09-02 host-neutral native-renderer design revision"
kind: journal
created: "2026-09-02"
tags:
  - desktop
  - host-abstraction
  - native-ui
  - rendering
  - webassembly
aliases:
  - "BlazeX native controls correction session"
---

# 2026-09-02 host-neutral native-renderer design revision

## Observations

- WebAssembly is not browser-only; the architecture had nevertheless allowed
  the first browser implementation to define too much of the component model.
- Popcorn is a browser-oriented toolchain/runtime path and AtomVM is a
  runtime. Neither should be called the universal BlazeX host.
- Fully native controls cannot be obtained reliably by translating arbitrary
  HEEx/HTML after the catalog is built.
- A webview desktop shell is useful for deployment and native capability
  integration, but still materializes HTML controls.
- The architecture needs separate runtime, execution-host, renderer,
  capability-provider, remote-adapter, and packaging-shell dimensions.
- MudBlazor remains valuable at the semantic/catalog level; its Razor, DOM,
  CSS, JavaScript, and provider implementation are not portable contracts.

## Environment

- Research date: 2026-09-02
- Workspace: `/home/ducky/code/blazex`
- Initial browser profile: Popcorn 0.3.3, LocalLiveView 0.1.0, AtomVM Wasm
- Server profile: Phoenix 1.8, LiveView 1.2.11, Plug 1.20
- Desktop/runtime evidence: official WebAssembly non-web documentation, WASI
  documentation, Wasmtime embedding/platform documentation, Tauri v2
  documentation, and WASI WebGPU/windowing proposal material

## Evidence

- Official WebAssembly guidance describes non-web execution in server,
  desktop/mobile, IoT, embedded, JavaScript-VM, and non-JavaScript hosts.
- Core Wasm supplies imports rather than host APIs; artifact portability
  depends on the target host satisfying those imports.
- WASI supplies capability-oriented system APIs but not native controls.
- Wasmtime supports embedding in native applications and custom host
  functions on Windows, macOS, and Linux.
- Tauri can package HTML/CSS/JavaScript/Wasm in a system webview and expose
  native commands, confirming the middle-profile option.
- `wasi:webgpu` explicitly excludes screen/windowing from its interface, and
  surface/windowing work remains insufficiently stable to serve as a BlazeX
  native UI foundation.

No Wasmtime, Tauri, native AtomVM, or native widget prototype was executed.
The native-control architecture remains proposed until the inquiry's
vertical slice is implemented.

## Threads

- [Host-neutral BlazeX architecture and native control backends](../20-notes/host-neutral-blazex-architecture-and-native-control-backends.md)
- [Host-neutral and native-renderer map](../10-maps/host-neutral-and-native-renderer-architecture.md)
- [Native-control portability inquiry](../40-inquiries/can-one-blazex-component-model-target-dom-and-native-controls.md)
- [MudBlazor-inspired component system](../20-notes/mudblazor-inspired-component-system-for-blazex.md)
- [Parent WebAssembly architecture](../20-notes/elixir-webassembly-component-framework-for-phoenix-and-plug.md)

## Follow-ups

- Specify semantic node, event, effect, resource, accessibility, and renderer
  protocol drafts.
- Choose a minimal native toolkit spike after comparing main-thread,
  accessibility, FFI, and packaging constraints.
- Inventory Popcorn/AtomVM browser imports before claiming a standalone
  Wasmtime or WASI profile.
- Build a headless conformance renderer before expanding the visual catalog.
- Amend component manifests to separate runtimes, renderers, capabilities,
  remote adapters, and fallbacks.
