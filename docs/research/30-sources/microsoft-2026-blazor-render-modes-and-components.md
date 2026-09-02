---
title: "ASP.NET Core Blazor render modes and Razor components (.NET 10)"
kind: source
created: "2026-09-02"
authors:
  - "Microsoft"
published: 2026
citation_key: "microsoft-2026-blazor-components"
container: "Microsoft Learn"
edition: ".NET 10"
isbn: null
doi: null
url: "https://learn.microsoft.com/en-us/aspnet/core/blazor/components/render-modes?view=aspnetcore-10.0"
accessed: "2026-09-02"
tags:
  - blazor
  - components
  - dotnet
  - rendering
aliases:
  - "Blazor render modes documentation"
---

# ASP.NET Core Blazor render modes and Razor components (.NET 10)

## Reference

Microsoft. “ASP.NET Core Blazor render modes.” .NET 10 documentation. Accessed
2026-09-02. The reading also used the linked .NET 10 documentation for
[Razor components](https://learn.microsoft.com/en-us/aspnet/core/blazor/components/?view=aspnetcore-10.0),
[component rendering](https://learn.microsoft.com/en-us/aspnet/core/blazor/components/rendering?view=aspnetcore-10.0),
[lifecycle](https://learn.microsoft.com/en-us/aspnet/core/blazor/components/lifecycle?view=aspnetcore-10.0),
[routing](https://learn.microsoft.com/en-us/aspnet/core/blazor/fundamentals/routing?view=aspnetcore-10.0),
and [prerendering](https://learn.microsoft.com/en-us/aspnet/core/blazor/components/prerender?view=aspnetcore-10.0).

## Research question or contribution

The documentation defines the modern Blazor Web App's common component model
and the points at which component execution moves between static server
rendering, interactive server circuits, browser WebAssembly, and Auto mode.

## Findings

- Razor markup compiles into .NET component classes; render mode determines
  where a component instance executes, not a different component language.
- Static Server, Interactive Server, Interactive WebAssembly, and Interactive
  Auto are the four documented modes.
- Interactive modes are prerendered by default.
- WebAssembly and Auto components belong in a client project included in the
  downloaded app bundle.
- Auto uses server interactivity initially while browser resources download,
  then chooses browser execution on later visits. It does not migrate an
  already-live component instance.
- Interactive render modes propagate through a component subtree. A child
  cannot switch to a different interactive mode from its parent.
- Parameters crossing a static-to-interactive boundary must be serializable;
  delegates and render fragments cannot cross it directly.
- Component lifecycle APIs distinguish prerender from interactive DOM
  availability. After-render callbacks do not run during prerendering.

## Relevance

Blazor's key transferable idea is one component contract with renderer/host
variation. That supports a BlazeX API that can execute on server BEAM, local
AtomVM, or static rendering without pretending that each UI component is a
separate Wasm module.

## Limits

This is framework documentation, not an independent performance evaluation.
Details apply to the .NET 10 baseline and may change in later releases. Source
inspection is recorded separately for renderer internals.

## Derived work

- [Main synthesis](../20-notes/elixir-webassembly-component-framework-for-phoenix-and-plug.md)
- [BlazeX feasibility inquiry](../40-inquiries/can-elixir-webassembly-components-integrate-with-phoenix-and-plug.md)
- [Elixir WebAssembly components map](../10-maps/elixir-webassembly-components.md)
