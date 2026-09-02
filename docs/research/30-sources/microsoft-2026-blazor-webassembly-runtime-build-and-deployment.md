---
title: "Blazor WebAssembly runtime, build, deployment, and packaging"
kind: source
created: "2026-09-02"
authors:
  - "Microsoft"
published: 2026
citation_key: "microsoft-2026-blazor-wasm-build"
container: "Microsoft Learn"
edition: ".NET 10"
isbn: null
doi: null
url: "https://learn.microsoft.com/en-us/aspnet/core/blazor/webassembly-build-tools-and-aot?view=aspnetcore-10.0"
accessed: "2026-09-02"
tags:
  - ahead-of-time-compilation
  - blazor
  - dotnet
  - packaging
  - webassembly
aliases:
  - "Blazor WebAssembly build documentation"
---

# Blazor WebAssembly runtime, build, deployment, and packaging

## Reference

Microsoft. “ASP.NET Core Blazor WebAssembly build tools and ahead-of-time
(AOT) compilation.” .NET 10 documentation. Accessed 2026-09-02. Related
first-party pages reviewed were [host and deploy Blazor
WebAssembly](https://learn.microsoft.com/en-us/aspnet/core/blazor/host-and-deploy/webassembly/?view=aspnetcore-10.0),
[lazy-load assemblies](https://learn.microsoft.com/en-us/aspnet/core/blazor/webassembly-lazy-load-assemblies?view=aspnetcore-10.0),
[Razor Class Libraries](https://learn.microsoft.com/en-us/aspnet/core/blazor/components/class-libraries?view=aspnetcore-10.0),
[project structure](https://learn.microsoft.com/en-us/aspnet/core/blazor/project-structure?view=aspnetcore-10.0),
and [JavaScript interop](https://learn.microsoft.com/en-us/aspnet/core/blazor/javascript-interoperability/call-javascript-from-dotnet?view=aspnetcore-10.0).

## Research question or contribution

This documentation set distinguishes the default managed-IL execution model
from native WebAssembly AOT, and describes the publish, asset, package, lazy
loading, and JavaScript-boundary mechanics relevant to an Elixir analogue.

## Findings

- The .NET Wasm build tools use Emscripten.
- Without AOT, the browser runs a .NET IL interpreter implemented in Wasm with
  partial JIT support called the Jiterpreter.
- AOT compiles application methods to native WebAssembly, improving
  CPU-intensive execution while increasing publication time and download size.
- Microsoft states that most AOT apps are about twice the size of their
  IL-compiled counterparts. Managed assemblies still ship for reflection
  metadata and runtime features.
- Release publication trims/linker-prunes managed code and can precompress
  framework assets.
- Webcil is the default managed-assembly transport wrapper in modern releases;
  it is not evidence that each assembly's instructions are native Wasm.
- Lazy loading operates at managed-assembly granularity inside the shared
  runtime.
- Razor Class Libraries package components and static assets, conventionally
  hosted below `_content/{package}`.
- Browser APIs remain behind JavaScript interop; Wasm does not directly own
  the DOM.

## Relevance

The runtime/bytecode distinction maps directly to AtomVM plus `.avm` bundles.
The packaging and lazy-loading model supports shared BlazeX runtime assets,
Hex-distributed component metadata/assets, and feature-level application
bundles rather than per-component runtimes.

## Limits

Microsoft's approximate size comparison is ecosystem guidance, not a BlazeX
benchmark. .NET's compiler, runtime, GC, metadata, and library behavior cannot
be assumed for AtomVM.

## Derived work

- [Main synthesis](../20-notes/elixir-webassembly-component-framework-for-phoenix-and-plug.md)
- [Deep-dive journal](../50-journal/2026-09-02-elixir-webassembly-components-deep-dive.md)
