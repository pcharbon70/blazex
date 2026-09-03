---
title: "2026-09-03 cross-platform native-host deep dive"
kind: journal
created: "2026-09-03"
tags:
  - accessibility
  - desktop
  - drawing
  - native-controls
  - rendering
  - runtime
aliases:
  - "SDL Skia native host research session"
---

# 2026-09-03 cross-platform native-host deep dive

## Observations

- The request's “SDLC” was interpreted as SDL after no relevant UI/drawing
  project named SDLC was identified.
- The search initially framed “drawing primitive” too broadly. Candidate
  evidence became clearer after separating OS shell, GPU abstraction, 2D
  scene renderer, text, accessibility, native controls, runtime integration,
  and packaging.
- SDL3 is a strong low-level application shell and input layer, but neither
  its simple renderer nor its modern GPU API is a complete UI drawing/text
  system.
- Skia is the strongest mature common 2D implementation found. Cairo is a
  credible pinned software-raster comparison/fallback, while Pango/HarfBuzz
  is a separate text-layout comparison; neither replaces the headless
  semantic oracle.
- The first synthesis pass hid layout inside the retained-scene box. The audit
  exposed that gap, so final geometry, intrinsic measurement, scrolling, hit
  testing, focus order, and native-control sizing are now an explicit
  renderer-local subsystem with Taffy, Yoga, toolkit layout, and bounded
  constraint alternatives.
- A custom-drawn renderer is compatible with BlazeX's semantic architecture
  but is not the same as actual native controls. The existing ADR-0007 gate
  therefore needs a second adapter proof.
- Qt, wxWidgets, GTK, and Slint optimize different goals; ranking them as one
  undifferentiated toolkit list hides the most important tradeoffs.
- Main-thread rules and native fault containment made the runtime decision
  less ambiguous: begin with a separate native process and a normal
  target-specific ERTS release.
- Packaging, signing, JIT entitlements, portals, and per-target ABI builds
  must be proof gates rather than late release work.
- A final contradiction audit also corrected two scope errors: the
  custom-scene program is not part of ADR-0007's accepted resolution, and an
  SDL–Skia recommendation remains a spike hypothesis until surface/swapchain
  ownership is proven on each OS.

## Environment

- Research date: 2026-09-03
- Workspace: `/home/ducky/code/blazex`
- Target operating-system families: Windows, macOS, and Linux
- Linux display configurations in scope: Wayland and X11
- Existing architecture constraints: host-neutral semantic component kernel,
  renderer separation, capability-scoped resources, and ADR-0007 actual
  native-control proof before F0 stability
- No native toolkit, renderer, ERTS release, signed package, accessibility
  inspector, IME, or screen reader was executed in this session

## Evidence

### Search lanes

The research used parallel, bounded lanes and then a contradiction pass:

1. window/input shells and drawing/GPU stacks;
2. integrated toolkits, text, accessibility, and actual-control claims;
3. BEAM/AtomVM/Wasmtime integration plus platform packaging; and
4. research papers and practitioner reports that test the assumptions behind
   a custom UI framework.

The broad comparison stopped when each consequential layer had primary
support and further searching mostly repeated known candidates. Remaining
uncertainty is implementation evidence rather than missing library names.

### Primary project and platform evidence

- [SDL3](../30-sources/libsdl-project-2026-sdl3-desktop-host-primitives.md)
  documents the three-OS shell, IME events, native handles, simple render API,
  GPU API, and main-thread constraints.
- [Skia](../30-sources/google-2026-skia-2d-graphics-library.md) documents the
  mature cross-platform canvas and its embedding/text boundaries.
- [Cairo/Pango/HarfBuzz](../30-sources/cairo-pango-harfbuzz-2026-rendering-and-text-stack.md)
  document the software vector, paragraph, and shaping split.
- [Taffy/Yoga](../30-sources/dioxuslabs-meta-2026-taffy-and-yoga-layout-engines.md)
  and [Cassowary](../30-sources/badros-borning-stuckey-2001-cassowary-layout-constraints.md)
  establish embeddable flow-layout and specialized incremental-constraint
  candidates without supplying scrolling or hit testing.
- [winit/wgpu/Vello](../30-sources/rust-windowing-gfx-rs-linebender-2026-native-graphics-stack.md)
  establish the best Rust shell alternative, raw GPU boundary, and promising
  but experimental Vello 0.9 Classic/CPU/Hybrid family.
- [AccessKit/UIA/NSAccessibility/AT-SPI](../30-sources/accesskit-platform-vendors-2026-desktop-accessibility-bridges.md)
  establish the three platform adapters and the need for a semantic tree.
- [Qt](../30-sources/qt-project-2026-desktop-ui-platform.md),
  [GTK4](../30-sources/gtk-project-2026-gtk4-desktop-ui-platform.md),
  [wxWidgets](../30-sources/wxwidgets-project-2026-native-control-toolkit.md),
  [Slint](../30-sources/slint-project-2026-desktop-ui-runtime.md), and
  [libui-ng](../30-sources/libui-ng-project-2026-portable-native-gui.md)
  establish the integrated-toolkit trade space.
- [ERTS/Elixir/Rustler documentation](../30-sources/erlang-elixir-2026-releases-ports-and-native-integration.md)
  supports target-specific releases and an external process rather than a GUI
  NIF.
- [Platform distribution documentation](../30-sources/desktop-platform-vendors-2026-packaging-signing-and-sandboxing.md)
  establishes macOS signing/notarization, Windows package signing, and Linux
  portal constraints.

### Papers and engineering reports

- [Billah et al.](../30-sources/billah-et-al-2016-platform-agnostic-screen-reading.md)
  show that a generic semantic representation can bridge otherwise different
  accessibility systems and that pixels alone are insufficient.
- [Mascetti et al.](../30-sources/mascetti-et-al-2021-cross-platform-accessibility.md)
  find gaps between native accessibility APIs and the subset exposed by
  cross-platform frameworks.
- [Pandey et al.](../30-sources/pandey-et-al-2022-ui-framework-accessibility.md)
  provide mixed-methods evidence that toolkit/platform accessibility and
  testing differences materially affect developers.
- [Levien](../30-sources/levien-2022-gpu-tree-scene-rendering.md) supplies an
  algorithmic basis for a retained GPU-capable tree scene without establishing
  production readiness for the full UI stack.
- [Flutter](../30-sources/flutter-project-2026-desktop-embedder-architecture.md)
  supplies production architecture precedent for a portable engine with
  platform-specific embedders.
- [Zed/GPUI](../30-sources/zed-industries-2023-2024-custom-gpu-ui-engineering.md)
  documents the performance opportunity and platform-integration cost of a
  specialized custom GPU UI.
- [Hickson](../30-sources/hickson-2025-building-a-ui-framework.md) supplies a
  system-level checklist beyond the drawing API.

### Contradictions resolved

- **SDL provides graphics / SDL is not the drawing solution:** both are true.
  SDL provides surfaces, primitive rendering, and GPU access; BlazeX still
  needs a rich retained 2D and text layer.
- **Skia draws text / Skia does not shape text:** core Canvas can draw glyphs,
  while optional SkShaper/SkParagraph or a separate shaping stack computes
  them.
- **Qt is native / Qt controls are not OS controls:** Qt is a native
  application toolkit with platform integration and native-looking styles;
  most child widgets are Qt-owned unless specifically native.
- **wxWidgets uses native controls / native accessibility is not automatic:**
  native stock controls inherit platform behavior, while generic and
  owner-drawn content still needs explicit accessibility.
- **AccessKit is cross-platform / accessibility remains platform-specific:**
  the common tree and adapters reduce work but do not erase differing control
  patterns, text interfaces, notifications, or test environments.
- **NIF is lower latency / external process is preferred:** unmeasured IPC
  savings do not outweigh UI-thread ownership and VM fault containment for
  the first proof.
- **AtomVM Wasm exists / it is not a Wasmtime desktop guest:** the current
  artifact relies on Emscripten, JavaScript glue, pthreads, and browser/Node
  assumptions; a standalone WASI/component target remains new work.
- **One software oracle / three validation roles:** the deterministic
  headless renderer checks semantics and traces; Skia Raster versus Cairo
  compares already-shaped pixels under pinned inputs; SkParagraph versus
  Pango/HarfBuzz compares text shaping and layout.
- **ADR-0007 needs a native renderer / custom scene is not its gate:** the
  accepted decision requires headless, DOM, and actual toolkit-control proof.
  The custom scene is an additional product-renderer research program.

## Threads

- [Cross-platform native host and renderer architecture](../20-notes/cross-platform-native-host-and-renderer-architecture.md)
  is the canonical synthesis and recommendation.
- [Host-neutral parent architecture](../20-notes/host-neutral-blazex-architecture-and-native-control-backends.md)
  retains the semantic/component and profile boundary.
- [Native renderer map](../10-maps/host-neutral-and-native-renderer-architecture.md)
  routes through the new sources.
- [Cross-renderer inquiry](../40-inquiries/can-one-blazex-component-model-target-dom-and-native-controls.md)
  remains open until executable evidence exists.

## Follow-ups

- Define the native protocol schema, connection epochs, scene sequences,
  capability handshake, resource generations, error model, and trace format.
- Build Gate A with an SDL3 shell, renderer-local layout/hit testing, and
  raster Skia; render the same already-shaped display list with Cairo under
  pinned fonts, resources, versions, color space, and tolerances.
- Prove raster upload first, then one Skia-owned GPU surface/swapchain path on
  Windows, macOS, X11, and Wayland without mixing SDL and Skia ownership.
- Decide SkParagraph versus direct HarfBuzz/ICU/platform font services through
  complex-text fixtures, including a separate Pango/HarfBuzz comparison,
  rather than API comparison alone.
- Test AccessKit coverage for editable text, grids, trees, virtualization,
  focus restoration, live regions, and platform-only actions.
- Build the bounded wxWidgets actual-control slice required by ADR-0007.
- Use Qt Widgets and Qt Quick as separate integration-oracle results.
- Establish measured startup, binary, memory, patch, frame, idle-power, and
  accessibility budgets before promoting any production dependency.
- Produce a signed/notarized clean-machine artifact for each target family
  before claiming a native profile.
