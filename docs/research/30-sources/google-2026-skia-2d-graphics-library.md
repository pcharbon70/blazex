---
title: "Skia cross-platform 2D graphics library"
kind: source
created: "2026-09-03"
authors:
  - "Google"
  - "Skia contributors"
published: null
citation_key: "google-2026-skia-2d-graphics"
container: "Skia documentation and source"
edition: "Milestone 152 snapshot at commit 008936396810061e26f6d457484fe1c6602fb6ef"
isbn: null
doi: null
url: "https://skia.org/docs/"
accessed: "2026-09-03"
tags:
  - desktop
  - drawing
  - rendering
  - skia
  - text
aliases:
  - "Skia renderer evidence"
---

# Skia cross-platform 2D graphics library

## Reference

Google and Skia contributors. [Skia documentation](https://skia.org/docs/),
[API overview](https://skia.org/docs/user/api/), [Canvas
creation](https://skia.org/docs/user/api/skcanvas_creation/), [text
overview](https://docs.skia.org/docs/dev/design/text_overview/), and [FAQ and
tips](https://skia.org/docs/user/tips/). The evidence baseline is the
[Milestone 152 release-note section at immutable commit
`008936396810061e26f6d457484fe1c6602fb6ef`](https://github.com/google/skia/blob/008936396810061e26f6d457484fe1c6602fb6ef/RELEASE_NOTES.md),
resolved from repository `HEAD` on 2026-09-03.

## Research question or contribution

Is Skia a sufficiently mature common 2D drawing implementation for a
Windows/macOS/Linux BlazeX scene renderer?

## Findings

- Skia supplies cross-platform 2D canvas operations for paths, paint, images,
  transforms, clips, blending, surfaces, and glyph output. It supports raster
  and GPU-backed surfaces and is used by production systems including Chrome,
  Android, Flutter, and Firefox.
- The documented desktop platforms include current Windows, macOS, and Linux
  configurations.
- Skia does not create the application window, OpenGL context, or Vulkan
  device; those belong to the embedding shell.
- Core glyph drawing is not equivalent to full text shaping. SkShaper and
  SkParagraph are optional layers that can use HarfBuzz, Unicode services,
  and platform font managers.
- Skia is BSD-licensed, but integrating it introduces a substantial C++20,
  GN, dependency, and binary-distribution surface.

## Relevance

Skia is the strongest mature implementation candidate for BlazeX's retained
scene/display-list backend. BlazeX should own a narrow scene contract above
Skia so the component model does not depend on C++ objects or one graphics
engine.

## Limits

No Skia build, FFI shim, software raster comparison, GPU backend, font
manager, or binary-size measurement was performed. GPU support varies by
backend and build configuration and must be proven per target. Skia's main
branch moves continuously; an implementation spike must pin an exact commit,
GN arguments, third-party dependency lock, and produced artifact hash rather
than treating the research snapshot's immutable source commit alone as a
reproducible build specification.

## Derived work

- [Cross-platform native host and renderer architecture](../20-notes/cross-platform-native-host-and-renderer-architecture.md)
- [Native renderer architecture map](../10-maps/host-neutral-and-native-renderer-architecture.md)
