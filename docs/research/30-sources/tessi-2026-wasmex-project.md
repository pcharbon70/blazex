---
title: "Wasmex: embedding Wasmtime in Elixir"
kind: source
created: "2026-09-02"
authors:
  - "Wasmex contributors"
published: null
citation_key: "tessi-2026-wasmex"
container: "Wasmex source repository and documentation"
edition: "0.15 series"
isbn: null
doi: null
url: "https://github.com/tessi/wasmex"
accessed: "2026-09-02"
tags:
  - elixir
  - wasmtime
  - wasmex
  - webassembly
aliases:
  - "Wasmex runtime"
---

# Wasmex: embedding Wasmtime in Elixir

## Reference

Wasmex contributors. [Wasmex source
repository](https://github.com/tessi/wasmex) and
[documentation](https://hexdocs.pm/wasmex). Accessed 2026-09-02.

## Research question or contribution

Wasmex runs WebAssembly and WASI modules inside an Elixir backend using
Wasmtime through a Rust NIF. It tests where Wasm-in-BEAM fits within the
revised host-neutral runtime matrix.

## Findings

- Wasmex starts Wasmtime instances from Elixir and exposes calls through a
  GenServer-oriented API.
- Its main use cases are server-side sandboxing, language-neutral shared logic,
  and running libraries/plugins within the BEAM host.
- The embedding direction is Wasm inside Elixir/BEAM, not Elixir/BEAM inside a
  browser Wasm runtime.
- It supports Core Wasm, WASI, and current Component Model development paths
  on the server runtime.

## Relevance

Wasmex is not a runtime for executing portable BlazeX Elixir components and
does not provide a DOM or native-control renderer. It may still be valuable
for running restricted native-Wasm kernels or plugins inside a BEAM-hosted
server or desktop application, enabling conformance tests and language-neutral
extensions.

## Limits

Rust NIF and Wasmtime behavior on a server says nothing about browser DOM
integration or AtomVM compatibility. No Wasmex code was executed in this
research pass.

## Derived work

- [Main synthesis](../20-notes/elixir-webassembly-component-framework-for-phoenix-and-plug.md)
- [Elixir WebAssembly components map](../10-maps/elixir-webassembly-components.md)
- [Host-neutral BlazeX architecture](../20-notes/host-neutral-blazex-architecture-and-native-control-backends.md)
- [Host-neutral and native-renderer map](../10-maps/host-neutral-and-native-renderer-architecture.md)
