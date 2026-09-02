---
title: "MudBlazor v9.9.0 source architecture"
kind: source
created: "2026-09-02"
authors:
  - "MudBlazor contributors"
published: 2026
citation_key: "mudblazor-project-2026-v9-9-source"
container: "MudBlazor GitHub repository"
edition: "v9.9.0 (3d85eed63a2c886d0a2e37f9f0cad78be655ad1c)"
isbn: null
doi: null
url: "https://github.com/MudBlazor/MudBlazor/tree/v9.9.0"
accessed: "2026-09-02"
tags:
  - component-library
  - material-design
  - mudblazor
  - source-audit
aliases:
  - "MudBlazor source audit"
---

# MudBlazor v9.9.0 source architecture

## Reference

MudBlazor contributors. *MudBlazor*, release `v9.9.0`, commit
`3d85eed63a2c886d0a2e37f9f0cad78be655ad1c`, released 2026-08-24.
Accessed 2026-09-02 from the [official repository](https://github.com/MudBlazor/MudBlazor)
and inspected from a shallow local checkout at the exact tag.

The repository describes MudBlazor as a Material Design component framework
for Blazor, implemented primarily in C# and CSS with JavaScript used where
browser-only behavior requires it. The package is distributed under the MIT
license.

## Research question or contribution

What architectural subsystems sit beneath MudBlazor's component catalog, and
which of them must a native Elixir/Phoenix framework build before it can offer
a similarly broad set of controls?

## Measured inventory

The following measurements were made against the exact `v9.9.0` checkout:

- 83 first-level directories under `src/MudBlazor/Components`;
- 166 `.razor` component/template files and 162 `.razor.cs` code-behind files;
- 70,843 lines across component `.razor`, `.razor.cs`, and supporting `.cs`
  files as reported by `wc -l`;
- 1,808 `[Parameter...]` declarations in component C# files;
- 111 SCSS source files under `src/MudBlazor/Styles`;
- 26 top-level JavaScript source modules under `src/MudBlazor/TScripts`;
- 211 `*Tests.cs` files under `src/MudBlazor.UnitTests`;
- 79 first-level component documentation directories and 646 component
  example `.razor` files;
- five generated Material icon families with 2,122 string constants each in
  the inspected files, before custom icon sets.

These are repository-shape measurements, not counts of stable public APIs.
Internal render fragments, compound children, chart internals, and generated
artifacts make “number of components” dependent on the counting rule.

## Findings

### Component and parameter state

- `MudComponentBase` adds common `Class`, `Style`, `Tag`, unmatched HTML
  attributes, generated/effective field IDs, logging, and a post-render signal
  for JavaScript availability.
- `ComponentBaseWithState` and the `ParameterState<T>` subsystem track values
  received from a parent separately from locally updated values, attach change
  handlers, coordinate two-way callback behavior, and discourage logic in
  parameter setters.
- Compound controls rely heavily on cascading context. Parent/child
  registration is central to forms, lists, chips, radio groups, tables,
  DataGrid columns, tabs, expansion panels, steppers, timelines, and trees.

This is not merely Blazor ceremony. BlazeX needs an explicit answer for
controlled values, local pending values, parent acknowledgement, nested
registration, identity, and disposal.

### Styling and themes

- Component markup builds stable `mud-*` classes from parameters through
  utilities such as `CssBuilder` and `StyleBuilder`.
- SCSS is organized into core/reset/animation/elevation/RTL rules, layout,
  component styles, and utility classes.
- `MudTheme` holds light and dark palettes, shadows, typography, layout
  properties, z-indexes, and pseudo-CSS scoping.
- `MudThemeProvider` emits CSS variables, switches light/dark palettes, and
  can observe the browser's preferred color scheme through JavaScript.

The styling system is a runtime contract: component variants, color roles,
spacing, elevation, typography, breakpoints, RTL behavior, animation, and
overlay stacking all depend on shared tokens and classes.

### Providers and services

`AddMudServices` registers dialog, snackbar, browser viewport, resize
observer, key interception, JavaScript-event, scroll manager/listener/spy,
JavaScript API, popover, pointer-event, and localization services. The
documentation identifies four root providers as especially important:
theme, popover, dialog, and snackbar.

- The popover service owns a collection of detached overlay fragments,
  notifies providers, batches updates, and coordinates JavaScript positioning.
- The dialog service creates dynamic component fragments and coordinates a
  provider-managed stack, result handles, options, and close requests.
- The snackbar service owns a timed, deduplicated queue and reacts to
  navigation.
- Viewport, resize, key, scroll, pointer, and focus facilities are shared
  browser capabilities used by multiple controls.

A BlazeX implementation therefore needs root-scoped process/service state and
a browser-effect host. Reimplementing every overlay or observer independently
would produce inconsistent focus, stacking, disposal, and performance.

### Forms and conversion

`MudFormComponent<T,U>`, `MudBaseInput<T>`, `MudForm`, converters, masks, and
localization provide a coherent form subsystem. It tracks raw and typed
values, conversion failures, required state, touched state, multiple validation
shapes, nested forms, disabled/read-only context, debouncing, error IDs, and
ARIA relationships.

BlazeX cannot obtain this behavior by styling ordinary inputs alone. It needs
a client-safe form state, conversion protocol, validation contract, and field
registration model that can run under both server LiveView and browser
AtomVM.

### Complex component systems

The largest files are not leaf controls. `MudDataGrid`, `MudSelect`,
`MudTabs`, `MudAutocomplete`, `MudMenu`, `MudTable`, pickers, `MudTreeView`,
charts, and drop zones combine parent/child registration, async state,
keyboard handling, browser measurement, templating, and disposal.
`MudDataGrid` alone has property/template/select/hierarchy columns, filter and
sort definitions, grouping, aggregates, editing, selection, paging,
virtualization, server data, and many internal cells/rows.

### Build, assets, and tests

- The package targets .NET 8, 9, and 10 and builds SCSS/JavaScript assets into
  package static web assets.
- The repository marks the package trimmable and ships analyzers/code fixes.
- The contribution guide requires tests for components containing logic and
  identifies unit-test and visual-test projects.
- The README and installation docs state that static rendering alone is not
  supported; providers must share an interactive render scope with their
  consumers.

The BlazeX analogue should use a Hex package manifest, per-family CSS/JS
assets, build-time reachability, generated docs, unit/browser/accessibility
tests, and explicit host-mode support. It should not bundle the complete icon
catalog or every complex component into the initial Wasm payload.

## Limits

The source was inspected and measured but not compiled or executed. Test-file
counts do not establish test completeness. `[Parameter]` counts include
compound/internal components. No visual screenshots, browser timings,
accessibility audits, or package-size measurements were reproduced. The
repository changes frequently; all findings are pinned to `v9.9.0`.

## Derived work

- [MudBlazor-inspired component system for BlazeX](../20-notes/mudblazor-inspired-component-system-for-blazex.md)
- [MudBlazor component-system map](../10-maps/mudblazor-inspired-component-system.md)
- [MudBlazor component-family inquiry](../40-inquiries/which-mudblazor-component-families-should-blazex-build.md)
- [MudBlazor deep-dive journal](../50-journal/2026-09-02-mudblazor-component-system-deep-dive.md)
