---
title: "Wasmtime embedding APIs and desktop platform support"
kind: source
created: "2026-09-02"
authors:
  - "Bytecode Alliance"
  - "Wasmtime contributors"
published: null
citation_key: "bytecode-alliance-2026-wasmtime-embedding"
container: "Wasmtime documentation"
edition: null
isbn: null
doi: null
url: "https://docs.wasmtime.dev/lang.html"
accessed: "2026-09-02"
tags:
  - desktop
  - embedding
  - runtime
  - wasmtime
  - webassembly
aliases:
  - "Wasmtime desktop host"
---

# Wasmtime embedding APIs and desktop platform support

## Reference

Bytecode Alliance and Wasmtime contributors. [Using the Wasmtime
API](https://docs.wasmtime.dev/lang.html), [C/C++ API
reference](https://docs.wasmtime.dev/c-api/), and [platform
support](https://docs.wasmtime.dev/stability-platform-support.html).
Accessed 2026-09-02.

## Research question or contribution

Can a desktop process embed a production-oriented WebAssembly engine and
provide custom host capabilities to a BlazeX guest without using a browser or
webview?

## Findings

- Wasmtime is both a command-line runtime and an embeddable library for Core
  WebAssembly modules and Component Model components.
- Its officially developed embedding surfaces include Rust, C, and C++; the C
  API makes integration possible from other native languages and runtimes.
- An embedder can define host functions, memories, globals, and other imports.
  Those imports are how a non-browser BlazeX host would expose rendering,
  window, input, file, clipboard, timer, and application services.
- Wasmtime's primary operating-system support includes Windows, macOS, and
  Linux, with additional but less-tested platforms.
- WASI support is supplied through a separate Wasmtime package and linker
  configuration. Embedding Wasmtime does not automatically provide every
  WASI or application-specific capability.
- Host-defined functions can be synchronous or integrated with asynchronous
  host execution, subject to Wasmtime's async configuration and guest ABI.

## Relevance

Wasmtime proves that a native desktop shell can host Wasm without a webview.
It is a candidate execution host for an AtomVM-in-Wasm port or a future
restricted native-Wasm BlazeX runtime. It does not solve native UI rendering;
the desktop shell must still implement the BlazeX renderer and capability
protocol.

## Limits

This source does not show AtomVM, Popcorn, HEEx, or BlazeX running under
Wasmtime. Popcorn's current browser imports may require a separate AtomVM
target or host shim. No Wasmtime binary or embedding example was executed in
this research pass.

## Derived work

- [Host-neutral BlazeX architecture and native control backends](../20-notes/host-neutral-blazex-architecture-and-native-control-backends.md)
- [Host-neutral and native-renderer map](../10-maps/host-neutral-and-native-renderer-architecture.md)
- [Native-control portability inquiry](../40-inquiries/can-one-blazex-component-model-target-dom-and-native-controls.md)
