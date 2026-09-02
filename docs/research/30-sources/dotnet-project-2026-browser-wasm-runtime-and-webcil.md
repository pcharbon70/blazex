---
title: ".NET browser WebAssembly runtime and Webcil design"
kind: source
created: "2026-09-02"
authors:
  - ".NET project contributors"
published: null
citation_key: "dotnet-2026-browser-wasm-webcil"
container: "dotnet/runtime source repository"
edition: null
isbn: null
doi: null
url: "https://github.com/dotnet/runtime/blob/main/src/mono/wasm/features.md"
accessed: "2026-09-02"
tags:
  - dotnet
  - managed-runtimes
  - webassembly
  - webcil
aliases:
  - ".NET browser runtime design"
---

# .NET browser WebAssembly runtime and Webcil design

## Reference

.NET project contributors. [“Configuring and hosting .NET WebAssembly
applications”](https://github.com/dotnet/runtime/blob/main/src/mono/wasm/features.md)
and [“Webcil packaging
format”](https://github.com/dotnet/runtime/blob/main/docs/design/mono/webcil.md),
`dotnet/runtime`. Accessed 2026-09-02.

## Research question or contribution

These documents describe the resources and host layers in a .NET browser Wasm
application and explain why Webcil exists as a managed-assembly container.

## Findings

- A browser .NET application loads JavaScript boot/runtime glue, a native
  runtime Wasm module, base class libraries, application assemblies, and
  configuration/manifest data.
- Emscripten supplies operating-system-like and browser integration support
  needed by the native runtime.
- The loader coordinates resource acquisition and runtime startup; the app is
  not just one compiled component file.
- Webcil wraps an ECMA-335 managed assembly in a WebAssembly container so it
  can pass through infrastructure that blocks `.dll` files. The managed IL
  remains managed code consumed by the runtime.

## Relevance

This supports a manifest-driven BlazeX boot graph and precise wording around
runtime-in-Wasm versus native application Wasm. It also suggests separating
stable runtime assets from frequently changing application bundles for cache
efficiency.

## Limits

The documents describe .NET runtime infrastructure, not Blazor's full UI
framework and not AtomVM. The main branch is version-sensitive.

## Derived work

- [Main synthesis](../20-notes/elixir-webassembly-component-framework-for-phoenix-and-plug.md)
- [Deep-dive journal](../50-journal/2026-09-02-elixir-webassembly-components-deep-dive.md)
