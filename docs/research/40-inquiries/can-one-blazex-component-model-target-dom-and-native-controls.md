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

## Outcome

Open. The architecture is now constrained correctly, but no native renderer
has been implemented. Resolution requires one portable vertical slice passing
the shared state, event, focus, accessibility, capability, resource, and
disposal suite under both DOM and native-control backends.
