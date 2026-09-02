---
title: "WASI WebGPU and windowing status"
kind: source
created: "2026-09-02"
authors:
  - "WebAssembly WASI Subgroup contributors"
published: null
citation_key: "webassembly-wasi-2026-webgpu-windowing"
container: "WebAssembly WASI proposal repositories and meeting record"
edition: null
isbn: null
doi: null
url: "https://github.com/WebAssembly/wasi-webgpu"
accessed: "2026-09-02"
tags:
  - graphics
  - native-ui
  - wasi
  - webassembly
  - windowing
aliases:
  - "WASI native graphics boundary"
---

# WASI WebGPU and windowing status

## Reference

WebAssembly WASI Subgroup contributors. [`wasi:webgpu` proposal
repository](https://github.com/WebAssembly/wasi-webgpu) and [WASI meeting
record discussing surface stability](https://github.com/WebAssembly/meetings/blob/main/wasi/2026/WASI-07-09.md).
Accessed 2026-09-02.

## Research question or contribution

Can BlazeX assume that WASI or the Component Model will provide a portable
desktop window, native-control, or screen-rendering API?

## Findings

- `wasi:webgpu` is a proposal for GPU access and compute/rendering resources,
  not a native widget toolkit.
- Its documented non-goals explicitly place display-to-screen and windowing
  outside the WebGPU interface.
- WASI discussion records describe the surface/windowing side as insufficiently
  stable for the `wasi` namespace and separate from WebGPU progress.
- Even a stable GPU and surface API would provide drawing primitives, not
  buttons, fields, menus, accessibility trees, text editing, input methods,
  native dialogs, or platform conventions.
- A BlazeX native-widget backend therefore needs an owned renderer protocol
  and toolkit adapters. Future WASI graphics work may implement a custom-drawn
  scene backend, but it cannot be treated as the current portability layer.

## Relevance

This negative finding prevents the design from postponing native rendering
behind an assumed future standard. BlazeX should keep WIT/WASI as possible
host ABIs while defining its semantic UI and accessibility contracts now.

## Limits

The proposals are active and may change. This note does not survey every
third-party graphics runtime or experimental windowing implementation. It
distinguishes standards-track interfaces from product-ready native controls.

## Derived work

- [Host-neutral BlazeX architecture and native control backends](../20-notes/host-neutral-blazex-architecture-and-native-control-backends.md)
- [Host-neutral and native-renderer map](../10-maps/host-neutral-and-native-renderer-architecture.md)
- [Native-control portability inquiry](../40-inquiries/can-one-blazex-component-model-target-dom-and-native-controls.md)
