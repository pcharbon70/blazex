---
title: "MudBlazor v9.9 component catalog and documentation"
kind: source
created: "2026-09-02"
authors:
  - "MudBlazor contributors"
published: 2026
citation_key: "mudblazor-project-2026-component-documentation"
container: "MudBlazor documentation and API index"
edition: "v9.9"
isbn: null
doi: null
url: "https://mudblazor.com/docs/overview"
accessed: "2026-09-02"
tags:
  - component-catalog
  - documentation
  - material-design
  - mudblazor
aliases:
  - "MudBlazor component catalog"
---

# MudBlazor v9.9 component catalog and documentation

## Reference

MudBlazor contributors. *MudBlazor component documentation* and
[API index](https://mudblazor.com/api), current for the 9.x line. Accessed
2026-09-02. Documentation source and 646 examples were also inspected in the
official repository at tag `v9.9.0`.

## Research question or contribution

What user-facing component families and interaction contracts make up
MudBlazor, independently of its C# implementation details?

## Findings

The documentation covers a broad UI system rather than Blazor's small set of
renderer and form primitives. Its principal families include:

- **theme and responsive context:** theme, RTL, breakpoint, and hidden
  providers;
- **layout:** app bar, drawer, layout/main content, container, grid/item,
  stack, spacer, toolbar, divider, paper, and split panel;
- **content and feedback:** typography, icons, images, avatars, badges, cards,
  alerts, skeletons, progress, overlays, tooltips, snackbars, dialogs, and
  message boxes;
- **actions:** buttons, icon buttons, floating action buttons and menus,
  button groups, chips, ratings, and toggle groups;
- **navigation:** links, breadcrumbs, nav menus/groups/links, menus, tabs,
  pagination, steppers, page-content navigation, and scroll-to-top;
- **forms:** forms, fields, text and numeric fields, masks, checkbox, switch,
  radio, select, autocomplete, slider, date/date-range/time/color pickers, and
  file upload;
- **structured content and data:** lists, collapse/expansion panels,
  carousel, timeline, simple table, table, DataGrid, tree view,
  virtualization, highlighting, and charts;
- **browser interaction helpers:** focus trap, hotkeys, exit prompt, swipe
  area, drag/drop zones, popovers, and viewport observers.

Many “components” are compound protocols. For example, a DataGrid includes a
grid, pager, property/template/select/hierarchy columns, header/filter/footer
cells, group rows, definitions, provider state, and editing forms. A dialog
requires provider, service, container, dynamic content, focus/keyboard rules,
overlay, and result semantics. A picker shares field/input, popover, keyboard,
conversion, localization, and validation infrastructure.

The docs expose several quality requirements that a catalog-only port could
miss:

- keyboard navigation and focus behavior are documented for menus, selects,
  autocomplete, lists, tabs, dialogs, grids, and other interactive controls;
- responsive layout and RTL affect many components rather than one wrapper;
- validation includes conversion failures and stable ARIA error relationships;
- overlays share provider and z-index policy;
- tables and grids distinguish local collections from asynchronous server data;
- templates/child content are central to cards, lists, navigation, columns,
  rows, empty/loading states, and actions;
- global configuration affects snackbars, dialogs, popovers, resize behavior,
  localization, and other services.

## Relevance

This is the correct target catalog for BlazeX's visual component framework.
Blazor's built-in components remain useful only as renderer/runtime context.
BlazeX should adopt the problem coverage, interaction quality, Material-style
tokens, composability, documentation discipline, and test breadth of
MudBlazor while defining native Elixir/Phoenix APIs.

The docs also show why implementation order matters. Leaf presentation
components can follow a theme and CSS foundation. Selects, menus, pickers,
tooltips, dialogs, and snackbars depend on a shared overlay/effect subsystem.
Forms depend on shared conversion and validation. Tables, grids, trees, and
charts are distinct product subsystems and should not block an initial core
release.

## Limits

The documentation is first-party product documentation, not an independent
usability comparison. The live API page is generated and changes with the
current site; exact source claims in the synthesis are pinned to repository
tag `v9.9.0`. Documentation directories are not a one-to-one count of public
components because some pages group compound children and charts have
separate pages by type.

## Derived work

- [MudBlazor-inspired component system for BlazeX](../20-notes/mudblazor-inspired-component-system-for-blazex.md)
- [MudBlazor component-system map](../10-maps/mudblazor-inspired-component-system.md)
- [MudBlazor component-family inquiry](../40-inquiries/which-mudblazor-component-families-should-blazex-build.md)
