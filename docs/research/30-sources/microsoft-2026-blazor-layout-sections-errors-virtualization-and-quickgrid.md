---
title: "Blazor .NET 10 layouts, sections, errors, virtualization, and QuickGrid"
kind: source
created: "2026-09-02"
authors:
  - "Microsoft"
published: null
citation_key: "microsoft-2026-blazor-layout-data-components"
container: "Microsoft Learn"
edition: ".NET 10"
isbn: null
doi: null
url: "https://learn.microsoft.com/en-us/aspnet/core/blazor/components/sections?view=aspnetcore-10.0"
accessed: "2026-09-02"
tags:
  - blazor
  - components
  - error-handling
  - layouts
  - virtualization
aliases:
  - "Blazor layout and data component catalog"
---

# Blazor .NET 10 layouts, sections, errors, virtualization, and QuickGrid

## Reference

Microsoft. ASP.NET Core / Blazor .NET 10 API and framework documentation.
Accessed 2026-09-02. Principal references:

- [layouts](https://learn.microsoft.com/en-us/aspnet/core/blazor/components/layouts?view=aspnetcore-10.0)
- [sections](https://learn.microsoft.com/en-us/aspnet/core/blazor/components/sections?view=aspnetcore-10.0)
- [head content](https://learn.microsoft.com/en-us/aspnet/core/blazor/components/control-head-content?view=aspnetcore-10.0)
- [error handling and error boundaries](https://learn.microsoft.com/en-us/aspnet/core/blazor/fundamentals/handle-errors?view=aspnetcore-10.0)
- [`Microsoft.AspNetCore.Components.Web` API catalog](https://learn.microsoft.com/en-us/dotnet/api/microsoft.aspnetcore.components.web?view=aspnetcore-10.0)
- [`Microsoft.AspNetCore.Components.Sections` API catalog](https://learn.microsoft.com/en-us/dotnet/api/microsoft.aspnetcore.components.sections?view=aspnetcore-10.0)
- [virtualization](https://learn.microsoft.com/en-us/aspnet/core/blazor/components/virtualization?view=aspnetcore-10.0)
- [`Microsoft.AspNetCore.Components.Web.Virtualization` API catalog](https://learn.microsoft.com/en-us/dotnet/api/microsoft.aspnetcore.components.web.virtualization?view=aspnetcore-10.0)
- [`QuickGrid` guide](https://learn.microsoft.com/en-us/aspnet/core/blazor/components/quickgrid?view=aspnetcore-10.0)
- [`Microsoft.AspNetCore.Components.QuickGrid` API catalog](https://learn.microsoft.com/en-us/dotnet/api/microsoft.aspnetcore.components.quickgrid?view=aspnetcore-10.0)

## Research question or contribution

This source set covers components that coordinate content outside an ordinary
parent/child slot, contain failures, or render large data sets efficiently.
Those are the areas where a Phoenix/LocalLiveView port is least likely to be a
one-line wrapper.

## Findings

- `LayoutComponentBase` exposes a `Body` render fragment. `LayoutView` renders
  content through the selected layout and nested layouts.
- `SectionContent` supplies a fragment to a matching `SectionOutlet` by name or
  identity. If multiple providers match, the most recently rendered provider
  wins. Section content can originate below the outlet's ordinary component
  ancestry.
- `PageTitle` and `HeadContent` provide output to `HeadOutlet`. In standalone
  WebAssembly, `HeadOutlet` is registered as a root component against the
  document head.
- `ErrorBoundary` catches exceptions from child content, substitutes an error
  fragment, exposes recovery, and can be subclassed through
  `ErrorBoundaryBase` for logging or policy.
- `Virtualize<TItem>` renders only the visible region plus overscan. It can
  consume an in-memory collection or call an asynchronous provider with a
  start index, requested count, and cancellation token.
- QuickGrid is a separate first-party package, not part of the minimal
  component assembly. It is both a common grid and a reference/performance
  baseline.
- `QuickGrid<TGridItem>` accepts queryable items or an asynchronous provider,
  supports sorting, pagination, virtualization, item keys, and row events.
  `PropertyColumn` renders a selected value, `TemplateColumn` renders a
  contextual template, and `Paginator` manipulates `PaginationState`.

## Relevance

Phoenix layouts and slots cover ordinary layout composition; `@page_title`
covers title updates. Named sections, arbitrary head updates, subtree error
boundaries, and measured viewport virtualization require new BlazeX behavior.
LiveView streams and viewport events are useful implementation ingredients but
are not identical to `Virtualize`. A QuickGrid analogue should be an optional
later package after the component kernel and form model are stable.

## Limits

QuickGrid documentation describes its intended behavior but is not an
independent comparison against commercial grids. Virtualization behavior is
sensitive to element sizing, scrolling containers, latency, and accessibility;
none were benchmarked here. Error behavior differs materially between Blazor
renderers, Phoenix processes, and a shared AtomVM runtime.

## Derived work

- [Blazor framework semantics beneath BlazeX](../20-notes/blazor-framework-semantics-beneath-blazex.md)
- [BlazeX component semantics inquiry](../40-inquiries/which-foundational-component-semantics-does-blazex-need.md)
- [Component-semantics deep-dive journal](../50-journal/2026-09-02-blazor-component-semantics-deep-dive.md)
