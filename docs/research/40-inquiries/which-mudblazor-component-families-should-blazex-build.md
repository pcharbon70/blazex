---
title: "Which MudBlazor component families should BlazeX build?"
kind: inquiry
created: "2026-09-02"
status: open
tags:
  - component-library
  - material-design
  - mudblazor
  - product-scope
  - research-program
aliases:
  - "BlazeX MudBlazor catalog inquiry"
---

# Which MudBlazor component families should BlazeX build?

## Why this matters

MudBlazor supplies the correct breadth for the intended product, but its
catalog cannot be translated file by file. Some controls map to semantic
content or native widgets; some depend on a shared form model; some depend on
surfaces, focus, measurement, and host listeners; DataGrid and charts are
independent subsystems. Starting from visible components without their
semantic and renderer foundations would create incompatible state,
interaction, and host rules inside BlazeX itself.

The question is therefore not whether every `Mud*` class can be renamed. It is
which user problems BlazeX should cover, which native Elixir/Phoenix contract
solves each problem, what shared dependency must exist first, and what evidence
is required before the family is shipped.

## Operational question

For every row in the [MudBlazor-inspired component-system
study](../20-notes/mudblazor-inspired-component-system-for-blazex.md), can BlazeX:

1. state the user-facing problem without relying on C# or Razor terminology;
2. define idiomatic semantic nodes/regions/messages/processes plus ergonomic
   renderer adapters;
3. specify controlled, local, initial, and derived state ownership;
4. identify theme, form, surface, effect, icon, data, and host dependencies;
5. define renderer-neutral accessibility, keyboard, focus, adaptive, RTL, and
   reduced-motion behavior plus DOM/native mappings;
6. run under every claimed runtime, renderer, capability, and remote profile;
7. clean up every listener, timer, task, portal, file handle, and data request;
8. keep authorization, upload acceptance, data access, and mutation on the
   trusted Phoenix/Plug side;
9. meet an incremental compressed payload and event-to-paint budget;
10. provide examples, unit tests, semantic/headless tests, browser and native
    renderer tests, accessibility checks, and per-profile visual baselines;
11. record source/assets provenance without implying MudBlazor affiliation or
    .NET compatibility; and
12. classify the family as portable semantic, native-preferred,
    native-composite, framework-drawn, host-service, or renderer-specific?

A family is ready only when all applicable dimensions are evidenced. A static
screenshot or component name is not sufficient.

## Working hypotheses

- **H1 — F0 dominates schedule quality:** tokens, controlled state, effects,
  surfaces, forms, icons, and tests remove more total risk than quickly
  producing leaf controls.
- **H2 — most F1 controls are highly feasible:** semantic content/layout nodes
  can lower to HEEx/CSS and native toolkit primitives with little
  runtime-specific logic.
- **H3 — one form model can serve multiple profiles:** a serializable
  raw/typed field model can run under BEAM and AtomVM while DOM/native
  renderers and server adapters map presentation and normalized errors.
- **H4 — one surface manager should serve menus, select, autocomplete,
  pickers, tooltip, dialog, and snackbar:** shared focus, placement, stacking,
  outside-click, and cleanup are essential.
- **H5 — icons must be asset-selected:** embedding the full generated icon
  catalog as BEAM constants will violate startup budgets.
- **H6 — DataGrid must follow table, forms, menu, provider, and virtualizer:**
  otherwise it will embed private copies of unstable foundations.
- **H7 — Phoenix remains authoritative:** local components improve latency and
  offline interaction but never authorize or finalize protected work.
- **H8 — visual similarity needs a named profile:** component coverage and
  interaction quality can be committed before exact screenshot fidelity.

## Paths to explore

### Foundation reference gallery

- Implement semantic nodes, renderer/capability protocols, theme tokens,
  dark/light mode, RTL, adaptive tokens, icon extraction, and visual states.
- Render typography, surface, layout, button, card, alert, avatar, badge,
  progress, skeleton, and chip examples under headless, server LiveView,
  LocalLiveView, and the native vertical slice.
- Record semantic trees, DOM/CSS, native control trees, screenshots,
  accessibility trees, assets, startup, and event-to-paint timings.

### Cross-renderer native-control proof

- Implement button, text field, checkbox, keyed list, menu/popover, dialog,
  focus restoration, and file choice through one native toolkit adapter.
- Prove that portable modules contain no HTML tags, CSS selectors, DOM events,
  JavaScript objects, Phoenix sockets, or toolkit widget classes.
- Compare platform-native, BlazeX Material, and hybrid visual profiles without
  requiring one pixel model across renderers.

### Controlled-state torture tests

- Exercise a toggle, tabs, expansion group, and drawer with parent-controlled,
  local, rejected, delayed, and reset updates.
- Reorder/remove components while focused and while an async update is in
  flight.
- Crash/remount the local root and prove generation-scoped cleanup.

### Surface manager

- Prototype nested menu, select, tooltip, dialog, and snackbar simultaneously.
- Test collision/flip, clipping, scroll, resize, nested z-index, outside click,
  escape, focus trap/restore, and root removal.
- Run hosted and standalone LocalLiveView layouts to determine whether the
  portal can live in the page DOM without private coupling.

### Form reference application

- Include text, invalid intermediate numeric input, checkbox, radio, select,
  autocomplete, slider, date, and file selection.
- Mix local pure validation, delayed server validation, stale replies,
  reconnect/remount, and screen-reader announcements.
- Compare Phoenix upload reuse with a BlazeX-owned upload adapter.

### Data systems

- Build a simple semantic table before the provider table.
- Specify one bounded local/server `DataRequest` protocol with cancellation
  and stale generations.
- Build a fixed-height virtualizer before DataGrid.
- Stage DataGrid capabilities and measure each incremental package.
- Prototype one SVG line chart with table fallback before committing to all
  chart families.

### Licensing and assets

- Identify any MudBlazor source/CSS/tests adapted directly and preserve MIT
  notices.
- Generate an SBOM entry for Material Icons under Apache 2.0.
- Audit custom and brand icons separately.
- Establish BlazeX naming and visual-brand boundaries.

## Findings

- The exact v9.9.0 [source audit](../30-sources/mudblazor-project-2026-v9-9-source-architecture.md)
  demonstrates that forms, providers, browser services, styles, tests, and
  build assets are structural dependencies, not optional polish.
- The [component documentation](../30-sources/mudblazor-project-2026-component-documentation.md)
  confirms approximately eighty documented families spanning layout, action,
  navigation, forms, feedback, data, and browser interactions.
- Presentational components map well to a semantic tree and then to
  Phoenix.Component/HEEx; a native-control proof is still required.
- Current LocalLiveView evidence supports a local process/event/render loop,
  nested components, form event decoding, and patch navigation, but not the
  complete surface, upload, viewport, icon, or data-grid infrastructure.
- MudBlazor itself states that static rendering alone is not supported for its
  interactive provider model. BlazeX should declare static fallbacks per
  family rather than making one universal promise.

## Outcome

Open. The catalog and dependency order are clear enough to begin F0 design and
a small F1 reference gallery. The inquiry resolves only after the manifest has
an explicit catalog and renderer disposition for every v9.9.0 family and
executable evidence exists for the shared semantic tree, theme, state, effect,
surface, form, icon, runtime, renderer, capability, and remote contracts.
