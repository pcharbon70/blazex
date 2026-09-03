---
title: "Zed GPUI custom GPU rendering and Linux platform engineering"
kind: source
created: "2026-09-03"
authors:
  - "Antonio Scandurra"
  - "Thorsten Ball"
  - "Mikayla Maki"
  - "Nathan Sobo"
published: "2023-2024"
citation_key: "zed-industries-2023-2024-gpui"
container: "Zed Blog"
edition: null
isbn: null
doi: null
url: "https://zed.dev/blog/videogame"
accessed: "2026-09-03"
tags:
  - blog
  - desktop
  - gpu
  - linux
  - rendering
  - rust
aliases:
  - "GPUI engineering evidence"
---

# Zed GPUI custom GPU rendering and Linux platform engineering

## Reference

Antonio Scandurra. [Leveraging Rust and the GPU to render user interfaces at
120 FPS](https://zed.dev/blog/videogame), 2023-03-07. Nathan Sobo and Antonio
Scandurra. [Optimizing the Metal pipeline to maintain 120
FPS](https://zed.dev/blog/120fps), 2024-02-07. Thorsten Ball and Mikayla Maki.
[Linux when?](https://zed.dev/blog/zed-decoded-linux-when), 2024-05-07.
Accessed 2026-09-03.

## Research question or contribution

What implementation work hides behind a high-performance custom-drawn Rust
desktop UI that later expands across operating systems?

## Method

These are practitioner reports from one application's authors, not controlled
benchmarks or general toolkit evaluations. They document design choices,
specific failures, and platform-port experience.

## Findings

- GPUI reduced its GPU vocabulary to application-relevant rectangles,
  shadows, text, icons, and images and used specialized shaders rather than a
  general path engine.
- Text shaping and rasterization remained separate, cached services, with
  platform APIs used to match native output.
- A macOS synchronization choice behaved differently between compositor
  modes and required a platform-specific correction despite a working
  renderer.
- Linux support required new renderer/platform work plus explicit X11,
  Wayland, desktop-environment, system-dialog, and packaging decisions.

## Relevance

The reports demonstrate both the performance potential and ownership cost of
a custom scene engine. BlazeX should begin with a mature drawing library and a
retained scene contract, then introduce specialized GPU primitives only after
measured need.

## Limits

The results are specific to Zed's text-editor workload and hardware. The
articles do not establish comparative performance against current Skia,
Vello, Qt, or Flutter, and they do not supply BlazeX accessibility evidence.

## Derived work

- [Cross-platform native host and renderer architecture](../20-notes/cross-platform-native-host-and-renderer-architecture.md)
- [Native renderer architecture map](../10-maps/host-neutral-and-native-renderer-architecture.md)

