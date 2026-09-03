---
title: "Slint desktop UI runtime, backends, renderers, and accessibility"
kind: source
created: "2026-09-03"
authors:
  - "Slint contributors"
published: null
citation_key: "slint-project-2026-desktop-ui-runtime"
container: "Slint documentation, source, and maintainer discussions"
edition: "Slint 1.16"
isbn: null
doi: null
url: "https://docs.slint.dev/latest/docs/slint/guide/backends-and-renderers/backends_and_renderers/"
accessed: "2026-09-03"
tags:
  - accessibility
  - desktop
  - rendering
  - rust
  - slint
  - toolkit
aliases:
  - "Slint native host evidence"
---

# Slint desktop UI runtime, backends, renderers, and accessibility

## Reference

Slint contributors. [Backends and renderers](https://docs.slint.dev/latest/docs/slint/guide/backends-and-renderers/backends_and_renderers/),
[winit backend](https://docs.slint.dev/latest/docs/slint/guide/backends-and-renderers/backend_winit/),
[Rust features](https://docs.slint.dev/latest/docs/rust/slint/docs/cargo_features/),
[accessible properties](https://docs.slint.dev/latest/docs/slint/reference/common/),
[event-loop handoff](https://docs.slint.dev/latest/docs/rust/slint/fn.invoke_from_event_loop),
and [licensing terms](https://slint.dev/terms-and-conditions). Maintainer
discussions [10390](https://github.com/slint-ui/slint/discussions/10390) and
[11316](https://github.com/slint-ui/slint/discussions/11316). Accessed
2026-09-03.

## Research question or contribution

Does Slint offer a leaner, Rust-native integrated alternative to assembling
SDL3, Skia, text, and accessibility services?

## Findings

- Slint cleanly separates OS/window backends from renderer backends. Its winit
  backend covers Windows, macOS, Wayland, and X11; renderer options include
  Skia, wgpu, FemtoVG/OpenGL, Qt, and software paths.
- Its semantic accessibility properties feed AccessKit and therefore the
  platform accessibility APIs.
- UI components and the event loop normally live on the UI thread;
  `invoke_from_event_loop` is the supported cross-thread handoff.
- Renderer choice materially affects text rasterization and output. Recent
  maintainer discussions describe continued work on software/FemtoVG text
  quality, which makes complex-script and small-size testing essential.
- Slint has Rust and C++ integration surfaces. Licensing choices include GPL,
  a royalty-free license with conditions/attribution, and commercial terms.

## Relevance

Slint is the most interesting lean custom-drawn comparison because its
backend/renderer separation resembles the proposed BlazeX architecture and
it already uses AccessKit. It should be a second prototype, not an assumed
production dependency.

## Limits

No build, license review, complex-text test, accessibility inspection, or
binary measurement was performed. Renderer combinations have different
feature and quality envelopes.

## Derived work

- [Cross-platform native host and renderer architecture](../20-notes/cross-platform-native-host-and-renderer-architecture.md)
- [Native renderer architecture map](../10-maps/host-neutral-and-native-renderer-architecture.md)

