# Packages

This directory contains reusable Elixir libraries. Each child directory marks
an intended package boundary, not merely a source-code namespace.

When implementation begins, packages should normally become independent Mix
projects with explicit dependency declarations and tests. They may use path
dependencies inside this monorepo while retaining the option to be versioned or
published independently.

## Host-neutral foundation

- `blazex_core` — component model, lifecycle, identity, state, and events.
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
- `blazex_renderer_dom` — DOM renderer backend.

## Server integrations

- `blazex_phoenix` — reusable Phoenix integration.
- `blazex_plug` — smaller framework-independent Plug integration.

Packages must depend toward the host-neutral foundation. No server, runtime, or
renderer adapter may become part of the public component semantics.

