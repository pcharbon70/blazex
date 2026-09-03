# Packages

This directory contains reusable Elixir libraries. Each child directory marks
an intended package boundary, not merely a source-code namespace.

Activated packages are independent Mix projects with explicit dependency
declarations and tests. They may use path
dependencies inside this monorepo while retaining the option to be versioned or
published independently.

BH-01 Phase 1 activates only `blazex_runtime_popcorn`, `blazex_host_browser`,
`blazex_renderer_dom`, `blazex_renderer_dom_liveview`, and `blazex_phoenix` as
dependency-free experimental skeletons. All other packages remain inactive;
the activated module roots are ownership markers rather than stable APIs.

## Host-neutral foundation

- `blazex_core` — component model, lifecycle, identity, state, and events.
- `blazex_effects` — host-neutral effects, capabilities, and resource ownership.
- `blazex_ui_tree` — versioned semantic UI representation.
- `blazex_renderer` — renderer contracts shared by all backends.
- `blazex_renderer_headless` — deterministic nonvisual renderer.
- `blazex_build` — compilation, reachability, bundling, and manifests.
- `blazex_test` — reusable test harnesses and compatibility fixtures.

## Component libraries

- `blazex_ui` — design foundations and general-purpose components.
- `blazex_forms` — forms, fields, validation, and input semantics.
- `blazex_surfaces` — dialogs, menus, popovers, snackbars, and overlays.
- `blazex_data` — data providers, tables, grids, trees, and virtualization.
- `blazex_charts` — optional chart components and chart data contracts.

## Browser runtime and rendering

- `blazex_runtime_popcorn` — Popcorn/AtomVM runtime integration.
- `blazex_host_browser` — browser host capabilities and lifecycle.
- `blazex_renderer_dom` — standalone DOM renderer with no Phoenix dependency.
- `blazex_renderer_dom_liveview` — optional LiveView/LocalLiveView DOM lowering.

## Server integrations

- `blazex_phoenix` — reusable Phoenix integration.
- `blazex_plug` — smaller framework-independent Plug integration.

Packages must depend toward the host-neutral foundation. No server, runtime, or
renderer adapter may become part of the public component semantics. The Plug
profile must not depend on `blazex_renderer_dom_liveview` directly or
transitively.
