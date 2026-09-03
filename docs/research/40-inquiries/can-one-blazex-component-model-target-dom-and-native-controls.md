---
title: "Can one BlazeX component model target DOM and native controls?"
kind: inquiry
created: "2026-09-02"
status: open
tags:
  - desktop
  - host-abstraction
  - native-ui
  - rendering
  - research-program
  - webassembly
aliases:
  - "BlazeX cross-renderer inquiry"
---

# Can one BlazeX component model target DOM and native controls?

## Why this matters

The browser path can move quickly by reusing HEEx, LiveView diffs, the DOM,
CSS, and Popcorn. If those mechanisms become the public component contract,
a future native desktop backend must emulate a browser or replace the catalog.
The native-control goal therefore has to shape F0 even if the first complete
renderer is browser-based.

## Operational question

Can the same portable component modules, state transitions, semantic trees,
events, effects, and accessibility contracts drive both a DOM renderer and a
materially different native-control renderer while:

1. keeping HTML tags, CSS selectors, DOM events, JavaScript objects, Phoenix
   sockets, and toolkit widget classes outside the portable dependency graph;
2. preserving controlled state, identity, ordering, focus, validation,
   surfaces, accessibility, cleanup, and stale-event rejection;
3. allowing explicit renderer extensions without reducing the entire system
   to the lowest common denominator;
4. reporting unsupported capabilities and fallbacks before mount;
5. producing useful platform-native behavior where stock controls exist;
6. using native composites or framework drawing where no stock control
   satisfies the component contract; and
7. keeping Phoenix-authoritative commands secure under browser, webview, and
   native application profiles?

A normalized screenshot is not sufficient evidence. The proof must include
event traces, accessibility trees, focus behavior, resource ownership,
failure paths, and real native control instances.

## Working hypotheses

- **H1 — semantic IR is necessary:** arbitrary HEEx/HTML is too lossy to be a
  native-widget ABI.
- **H2 — two implementations reveal leaks:** a headless renderer plus DOM is
  useful, but a native spike is required before API freeze.
- **H3 — events are portable at the intent level:** activation, change,
  selection, submit, expansion, and dismissal can map across platforms.
- **H4 — effects need opaque resources:** DOM handles, file objects, native
  widget pointers, and paths cannot enter portable state.
- **H5 — native controls will be hybrid:** fields and basic actions can prefer
  stock widgets; overlays, grids, charts, and Material-specific visuals will
  need composites or framework drawing.
- **H6 — visual profiles must diverge honestly:** exact MudBlazor appearance
  and exact OS-native appearance cannot both be universal requirements.
- **H7 — browser remains the first full backend:** host neutrality should
  constrain contracts without blocking the Popcorn/LocalLiveView prototype.

## Paths to explore

### Semantic kernel

- Specify versioned nodes, properties, semantic regions, events, effects,
  resources, accessibility, identity, and capability requirements.
- Build deterministic tree normalization and diff fixtures.
- Add dependency checks for web/toolkit leakage.

### Cross-renderer vertical slice

Implement the same examples in headless, DOM, and one native toolkit adapter:

- stack/text/button;
- controlled text field and checkbox;
- keyed list reorder;
- menu/popover;
- dialog with focus restoration;
- validation message/accessibility relation; and
- file-choice effect with an opaque resource.

### Runtime-host combinations

- Run the semantic kernel on ordinary BEAM first.
- Run the same traces on browser AtomVM.
- Evaluate native AtomVM embedding separately from AtomVM-in-Wasm under a
  Wasmtime-like host.
- Treat Tauri/webview as a capability and packaging test, not native-renderer
  evidence.

### Native toolkit selection

Compare at least one cross-platform toolkit and platform-specific adapters on:

- actual native controls and text input/IME behavior;
- accessibility APIs;
- main-thread/event-loop integration;
- embeddability and FFI from ERTS, AtomVM, or a Wasm host;
- packaging and licensing;
- theming/custom drawing;
- grids, trees, menus, dialogs, and popovers; and
- Windows, macOS, and Linux coverage.

## Findings

- [WebAssembly non-web embedding guidance](../30-sources/webassembly-community-group-2026-non-web-embeddings-and-wasi.md)
  confirms that Core Wasm is host-independent and that hosts supply imports.
- [Wasmtime](../30-sources/bytecode-alliance-2026-wasmtime-embedding-and-platform-support.md)
  demonstrates native desktop embedding and custom host functions, but does
  not provide a GUI toolkit.
- [WASI WebGPU/windowing evidence](../30-sources/webassembly-wasi-2026-webgpu-and-windowing-status.md)
  shows that current standards cannot be assumed to supply native widgets or
  stable windowing.
- [Tauri](../30-sources/tauri-2026-desktop-webview-architecture.md) is a
  practical middle shell but remains a DOM/webview renderer.
- The [host-neutral architecture synthesis](../20-notes/host-neutral-blazex-architecture-and-native-control-backends.md)
  establishes semantic rendering and the native vertical slice as F0 gates.
- The [cross-platform native-host deep
  dive](../20-notes/cross-platform-native-host-and-renderer-architecture.md)
  separates four choices that cannot safely be collapsed into one toolkit:
  the runtime boundary, OS shell, custom-scene renderer, and native-control
  materializer.
- [SDL3](../30-sources/libsdl-project-2026-sdl3-desktop-host-primitives.md)
  is a credible common window/input/IME shell but not a complete drawing,
  text, accessibility, or native-control system.
- [Skia](../30-sources/google-2026-skia-2d-graphics-library.md) is the leading
  mature common 2D implementation. A renderer still needs a separate
  text/paragraph service and accessibility tree.
- [AccessKit and the platform accessibility
  APIs](../30-sources/accesskit-platform-vendors-2026-desktop-accessibility-bridges.md)
  support a shared semantic tree with UI Automation, NSAccessibility, and
  AT-SPI adapters. Complex control patterns, editable text ranges, and actual
  screen-reader behavior remain prototype evidence.
- [ERTS release and interoperability
  guidance](../30-sources/erlang-elixir-2026-releases-ports-and-native-integration.md)
  supports a target-specific BEAM release plus an external native host. This
  gives the OS event loop a stable main thread and keeps native renderer faults
  outside the VM.
- A custom-drawn SDL3/Skia renderer cannot satisfy ADR-0007 by itself.
  [wxWidgets](../30-sources/wxwidgets-project-2026-native-control-toolkit.md)
  is the leading bounded actual-control proof, while
  [Qt](../30-sources/qt-project-2026-desktop-ui-platform.md) is the leading
  mature integration oracle and
  [Slint](../30-sources/slint-project-2026-desktop-ui-runtime.md) is the
  strongest lean Rust/custom-scene comparison.
- Research on [cross-platform accessibility
  gaps](../30-sources/mascetti-et-al-2021-cross-platform-accessibility.md),
  [semantic accessibility
  translation](../30-sources/billah-et-al-2016-platform-agnostic-screen-reading.md),
  and [framework use by programmers with visual
  impairments](../30-sources/pandey-et-al-2022-ui-framework-accessibility.md)
  supports platform escape hatches and an OS-by-screen-reader test matrix
  rather than a lowest-common-denominator role vocabulary.

### Current proof candidates

| Proof | Leading candidate | What it can establish | What it cannot establish alone |
| --- | --- | --- | --- |
| Custom scene | SDL3 + Skia + text service + AccessKit | one retained BlazeX Material renderer across all three OSes | actual OS controls or complete accessibility |
| Semantic oracle | existing headless renderer | deterministic normalized semantic tree, state/event traces, identity, and capabilities | pixels, platform text, or native controls |
| Pinned raster comparison | Skia Raster and Cairo over the same already-shaped display list | backend independence, fallback, and image tolerances under pinned fonts/resources/versions | deterministic cross-OS pixels or text shaping |
| Text-layout comparison | SkParagraph/SkShaper and Pango/HarfBuzz | shaping, line-break, cluster, caret, and selection conformance for pinned fixtures | final GPU behavior or native controls |
| Actual native controls | wxWidgets F0 adapter | semantic mapping to Win32/Cocoa/GTK controls where available | full-catalog consistency or custom-control accessibility |
| Mature integration oracle | Qt Widgets and Qt Quick, evaluated separately | expected text, IME, DPI, accessibility, graphics, and deployment baseline | exact OS ownership of most child controls |
| Rust alternative | winit + AccessKit + Skia, or Slint | lower-friction Rust host architecture | production maturity without measurements |

## Outcome

Open. Desk research now supplies a falsifiable host architecture and a ranked
proof program, but no native renderer or control adapter has been implemented.
Resolution still requires the same portable vertical slice to pass headless,
DOM, and actual-native-control evidence as required by ADR-0007, including
state, event, identity, focus, accessibility, effect/resource, and disposal
behavior. The custom-scene, full IME, host-failure, packaging, and three-OS
distribution program is valuable additional product-renderer evidence, but it
is not part of ADR-0007's resolution unless that accepted decision is formally
superseded.
