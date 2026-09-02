---
title: "2026-09-02 MudBlazor component-system deep dive"
kind: journal
created: "2026-09-02"
tags:
  - component-library
  - mudblazor
  - package-audit
  - research-session
aliases:
  - "MudBlazor v9.9 source audit session"
---

# 2026-09-02 MudBlazor component-system deep dive

## Observations

- The target visual catalog is MudBlazor, not Blazor's basic component
  infrastructure.
- The URL supplied by the user duplicated the repository URL. The canonical
  repository is `https://github.com/MudBlazor/MudBlazor`.
- An initial search result reported v9.7.0 as latest, but opening the current
  official release page showed v9.9.0 as latest on 2026-09-02. The checkout was
  corrected before synthesis.
- MudBlazor is a full Material-style component framework with compound
  services and providers, not a collection of independent view helpers.
- Theme, parameter state, forms, surfaces, browser services, CSS/assets,
  documentation, and tests are prerequisites for the visible catalog.
- The native BlazeX design remains Elixir/Phoenix-oriented and does not seek
  .NET compatibility.

## Environment

- Workspace: `/home/ducky/code/blazex` on Linux x86-64.
- Research date: 2026-09-02.
- Temporary source checkout: `/tmp/mudblazor_research`.
- Exact baseline: `v9.9.0`, commit
  `3d85eed63a2c886d0a2e37f9f0cad78be655ad1c`.
- Commit date: 2026-08-23; GitHub release date: 2026-08-24.
- Existing BlazeX baselines: Phoenix 1.8, Phoenix LiveView 1.2.11,
  LocalLiveView 0.1.0, Popcorn 0.3.3.

## Acquisition

The repository was first cloned at `v9.7.0` because a stale search result
presented it as latest:

```text
git clone --depth 1 --branch v9.7.0 \
  https://github.com/MudBlazor/MudBlazor.git \
  /tmp/mudblazor_research
```

After checking the live release page, the current stable tag was fetched and
checked out:

```text
git fetch --depth 1 origin tag v9.9.0
git checkout --detach v9.9.0
```

The user repository was not modified by this checkout; it exists only under
`/tmp` for research.

## Measurements

Commands were run against the exact tag. Results:

| Measurement | Result |
| --- | ---: |
| First-level component source directories | 83 |
| `.razor` files under components | 166 |
| `.razor.cs` files under components | 162 |
| Lines in component `.razor`, `.razor.cs`, supporting `.cs` | 70,843 |
| `[Parameter...]` declarations in component C# files | 1,808 |
| SCSS files | 111 |
| Top-level JavaScript source modules | 26 |
| `*Tests.cs` component test files | 211 |
| First-level component documentation directories | 79 |
| Component documentation examples | 646 |
| Material icon constants per inspected family | 2,122 |
| Inspected generated Material icon families | 5 |

The counts are reproducible repository-shape measurements, not claims about
stable public API size. Internal parts and grouped families affect any
“component count.”

## Principal source paths

```text
README.md
LICENSE
CONTRIBUTING.md
src/MudBlazor/MudBlazor.csproj
src/MudBlazor/Base/MudComponentBase.cs
src/MudBlazor/Base/ComponentBaseWithState.cs
src/MudBlazor/Base/MudFormComponent.cs
src/MudBlazor/State/ParameterState.cs
src/MudBlazor/Extensions/ServiceCollectionExtensions.cs
src/MudBlazor/Themes/
src/MudBlazor/Styles/
src/MudBlazor/TScripts/
src/MudBlazor/Components/
src/MudBlazor.Docs/Pages/Components/
src/MudBlazor.UnitTests/
```

Focused complex-system inspection included:

```text
Components/Autocomplete/
Components/Dialog/
Components/Popover/
Components/Form/
Components/Select/
Components/Table/
Components/DataGrid/
Components/TreeView/
Components/Chart/
Components/DropZone/
Components/ThemeProvider/
Services/Dialog/
Services/Popover/
Components/Snackbar/SnackbarService.cs
```

## Evidence summary

- `MudComponentBase` establishes common class/style/tag/unmatched attrs,
  effective IDs, logging, and first-render JavaScript availability.
- `ComponentBaseWithState` and `ParameterState<T>` implement tracked parameter
  changes and controlled-value behavior.
- `AddMudServices` registers dialog, snackbar, viewport/resize, key, scroll,
  JavaScript, popover, pointer, and localization services.
- Official installation/layout docs identify theme, popover, dialog, and
  snackbar providers as core root components and warn that static rendering
  alone is unsupported.
- The theme generates CSS variables for palettes, typography, shadows, layout,
  z-index, and direction/mode behavior.
- Forms implement conversion, validation, required/touched state, nested form
  registration, error IDs, async validation, and reset behavior.
- DataGrid and Table are large compound systems. DataGrid source includes
  column types, cells, filters, sorting, grouping, aggregates, editing,
  selection, paging, hierarchy, virtualization, and server data.
- JavaScript remains necessary for browser geometry, listeners, caret/input,
  popovers, resize, scroll, pointer/drag, split panels, theme preference, and
  related behavior despite MudBlazor's “minimal JS” goal.

## What was not demonstrated

- MudBlazor was not compiled or executed.
- No upstream screenshots or browser behavior were reproduced.
- No accessibility tool or screen reader was run against MudBlazor.
- Built CSS/JavaScript package sizes were not measured because generated
  release assets were not present in the source checkout.
- No BlazeX component was implemented.
- No LocalLiveView portal, focus, resize, upload, drag/drop, or DataGrid
  experiment was run.
- The custom/brand icon sets were not individually audited.
- This pass does not decide exact visual fidelity or final BlazeX names.

## Threads

- [MudBlazor-inspired component-system synthesis](../20-notes/mudblazor-inspired-component-system-for-blazex.md)
- [MudBlazor component-system map](../10-maps/mudblazor-inspired-component-system.md)
- [MudBlazor component-family inquiry](../40-inquiries/which-mudblazor-component-families-should-blazex-build.md)
- [MudBlazor source architecture](../30-sources/mudblazor-project-2026-v9-9-source-architecture.md)
- [MudBlazor component documentation](../30-sources/mudblazor-project-2026-component-documentation.md)

## Follow-ups

- Convert Appendix A into a machine-readable component manifest.
- Decide the BlazeX visual/token profile.
- Prototype the F0 theme, controlled-state, effect, and surface contracts.
- Build a small F1 gallery under server LiveView and LocalLiveView.
- Measure per-family CSS, JS/effect, icon, BEAM, startup, and memory cost.
- Test nested portal/focus behavior in LocalLiveView's actual DOM arrangement.
- Prototype the client-safe form state before implementing all fields.
- Treat table, virtualizer, DataGrid, tree, and charts as separate experiments.
