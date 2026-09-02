---
title: "WebAssembly Component Model and Jco browser tooling"
kind: source
created: "2026-09-02"
authors:
  - "WebAssembly Component Model contributors"
  - "Bytecode Alliance"
published: 2026
citation_key: "bytecode-alliance-2026-component-model-jco"
container: "Component Model and Jco documentation"
edition: null
isbn: null
doi: null
url: "https://github.com/WebAssembly/component-model/blob/main/design/mvp/Explainer.md"
accessed: "2026-09-02"
tags:
  - component-model
  - jco
  - standards
  - webassembly
  - wit
aliases:
  - "Wasm Component Model research"
---

# WebAssembly Component Model and Jco browser tooling

## Reference

WebAssembly Component Model contributors. [Component Model MVP
explainer](https://github.com/WebAssembly/component-model/blob/main/design/mvp/Explainer.md)
and [WIT specification](https://github.com/WebAssembly/component-model/blob/main/design/mvp/WIT.md).
Bytecode Alliance. [Jco repository](https://github.com/bytecodealliance/jco) and
[transpiling documentation](https://github.com/bytecodealliance/jco/blob/main/docs/src/transpiling.md).
Accessed 2026-09-02.

## Research question or contribution

The Component Model defines typed, language-neutral composition above Core
Wasm; Jco makes such components usable from JavaScript and browser ES modules.
The research asks whether this is the same kind of component BlazeX needs.

## Findings

- Components define typed imports/exports and instances, usually described
  with WIT.
- The Canonical ABI specifies how high-level values cross otherwise
  shared-nothing Core Wasm memories.
- Components can compose multiple Core modules and restrict capabilities.
- Jco can transpile a component into JavaScript ES modules plus Core Wasm for
  Node or browser execution.
- Browser WASI shims and automatic WebIDL bindings are available but still
  described as experimental.
- The model does not define DOM rendering, event delegation, UI lifecycle,
  CSS, routing, state management, SSR, or an Elixir compiler.

## Relevance

The Component Model may later define typed BlazeX plugin or service boundaries,
especially for restricted native-Wasm kernels. It should not be confused with
Razor, Phoenix, or BlazeX UI components and should not block the first
AtomVM/DOM adapter. WIT worlds may later encode host capabilities, but they do
not remove the need for BlazeX's semantic UI and renderer protocols.

## Limits

The standard and tools continue to evolve. Browser-native component loading is
not assumed; Jco's generated ES module path is the practical current bridge.
No component was built or run in this research pass.

## Derived work

- [Main synthesis](../20-notes/elixir-webassembly-component-framework-for-phoenix-and-plug.md)
- [Elixir WebAssembly components map](../10-maps/elixir-webassembly-components.md)
- [Host-neutral BlazeX architecture](../20-notes/host-neutral-blazex-architecture-and-native-control-backends.md)
- [Host-neutral and native-renderer map](../10-maps/host-neutral-and-native-renderer-architecture.md)
