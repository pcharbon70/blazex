---
title: "ASP.NET Core component renderer source at v10.0.0"
kind: source
created: "2026-09-02"
authors:
  - ".NET project contributors"
published: 2025
citation_key: "dotnet-2025-aspnetcore-renderer"
container: "dotnet/aspnetcore source repository"
edition: "v10.0.0"
isbn: null
doi: null
url: "https://github.com/dotnet/aspnetcore/tree/v10.0.0/src/Components"
accessed: "2026-09-02"
tags:
  - blazor
  - components
  - rendering
  - source-audit
  - webassembly
aliases:
  - "Blazor renderer source"
---

# ASP.NET Core component renderer source at v10.0.0

## Reference

.NET project contributors. `dotnet/aspnetcore`, tag `v10.0.0`,
`src/Components`. Accessed 2026-09-02. Principal files:

- [`ComponentBase.cs`](https://github.com/dotnet/aspnetcore/blob/v10.0.0/src/Components/Components/src/ComponentBase.cs)
- [`Renderer.cs`](https://github.com/dotnet/aspnetcore/blob/v10.0.0/src/Components/Components/src/RenderTree/Renderer.cs)
- [`RenderTreeDiffBuilder.cs`](https://github.com/dotnet/aspnetcore/blob/v10.0.0/src/Components/Components/src/RenderTree/RenderTreeDiffBuilder.cs)
- [`WebAssemblyRenderer.cs`](https://github.com/dotnet/aspnetcore/blob/v10.0.0/src/Components/WebAssembly/WebAssembly/src/Rendering/WebAssemblyRenderer.cs)

## Research question or contribution

The source shows how component lifecycle, render scheduling, logical render
trees, diff construction, event identity, disposal, and browser-specific
display updates compose beneath the public Razor API.

## Method

The research followed the path from `ComponentBase.StateHasChanged` and its
render fragment into `Renderer` queues and batch construction, then through
`RenderTreeDiffBuilder.ComputeDiff` and the WebAssembly renderer's display
update boundary.

## Findings

- The renderer owns component-state dictionaries, event-handler IDs, pending
  render queues, disposal queues, and a batch builder.
- Generated render trees contain typed frames rather than opaque HTML.
- Compile-time sequence numbers and explicit keys help the diff algorithm
  preserve identity and understand control-flow structure.
- A render batch contains updated component diffs, reference frames, disposed
  component IDs, and disposed event-handler IDs.
- The WebAssembly renderer sends the completed batch to JavaScript, which
  applies actual DOM updates. The in-process path can expose batch memory
  synchronously while the managed heap is held stable.
- Incoming events and rendering are ordered through the renderer/dispatcher
  work queue.

## Relevance

This confirms that Blazor's core abstraction is a shared logical renderer and
batch protocol. BlazeX needs equivalent ownership of identity, events,
disposal, and host updates even if HEEx supplies a different render IR.

## Limits

The audit was source-oriented, not a dynamic trace. Links are pinned to
v10.0.0 where available; later fixes may change implementation details without
changing the high-level architecture.

## Derived work

- [Main synthesis](../20-notes/elixir-webassembly-component-framework-for-phoenix-and-plug.md)
- [Elixir WebAssembly components map](../10-maps/elixir-webassembly-components.md)
