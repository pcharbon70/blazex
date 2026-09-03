---
title: "libui-ng portable native GUI library"
kind: source
created: "2026-09-03"
authors:
  - "libui-ng contributors"
published: null
citation_key: "libui-ng-project-2026-portable-native-gui"
container: "libui-ng repository and API documentation"
edition: "commit 43ba1ef553c8993a43a67f1ce6e35983a2660d8c; no tagged stable release found"
isbn: null
doi: null
url: "https://github.com/libui-ng/libui-ng"
accessed: "2026-09-03"
tags:
  - desktop
  - libui
  - native-controls
  - toolkit
aliases:
  - "libui-ng assessment"
---

# libui-ng portable native GUI library

## Reference

libui-ng contributors. [libui-ng README at immutable commit
`43ba1ef553c8993a43a67f1ce6e35983a2660d8c`](https://github.com/libui-ng/libui-ng/blob/43ba1ef553c8993a43a67f1ce6e35983a2660d8c/README.md), [C API
documentation](https://libui-ng.github.io/libui-ng/ui_8h.html), and [historical
roadmap/news](https://libui-ng.github.io/libui-ng/md_old_news.html). Accessed
2026-09-03. The commit was resolved from repository `HEAD` on that date.

## Research question or contribution

Can a small MIT-licensed C API over Win32, Cocoa, and GTK provide the BlazeX
native-control and drawing host with less integration cost?

## Findings

- libui-ng exposes native windows and basic controls for Win32, Cocoa, and
  GTK3 through a compact C API, plus a portable drawing area, paths, brushes,
  attributed strings, and text layouts.
- The pinned repository README explicitly described the project as
  **mid-alpha**; no tagged stable release was found in this pass.
- Its component catalog is intentionally small relative to BlazeX's target,
  and historical project material treats accessibility for custom drawing
  and controls as unfinished work.
- The MIT license and C ABI are attractive, but interface shape cannot offset
  the production maturity and accessibility risk.

## Relevance

libui-ng is a useful comparison showing the appeal of a narrow C/native
toolkit. It should not become BlazeX's production foundation. At most, it
could be a disposable experiment if its API helps test the host protocol.

## Limits

Project status is self-reported at the pinned commit and may change. No code,
open-issue census, screen-reader test, or catalog-coverage prototype was
performed; newer commits must be rechecked before any experiment.

## Derived work

- [Cross-platform native host and renderer architecture](../20-notes/cross-platform-native-host-and-renderer-architecture.md)
- [Native renderer architecture map](../10-maps/host-neutral-and-native-renderer-architecture.md)
