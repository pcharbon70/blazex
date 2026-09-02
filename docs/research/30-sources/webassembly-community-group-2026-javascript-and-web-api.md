---
title: "WebAssembly JavaScript and Web embedding APIs"
kind: source
created: "2026-09-02"
authors:
  - "WebAssembly Community Group"
published: 2026
citation_key: "webassembly-cg-2026-js-web-api"
container: "WebAssembly specifications"
edition: null
isbn: null
doi: null
url: "https://webassembly.github.io/spec/js-api/"
accessed: "2026-09-02"
tags:
  - browser-apis
  - javascript
  - standards
  - webassembly
aliases:
  - "WebAssembly browser embedding specification"
---

# WebAssembly JavaScript and Web embedding APIs

## Reference

WebAssembly Community Group. [WebAssembly JavaScript
Interface](https://webassembly.github.io/spec/js-api/) and [WebAssembly Web
API](https://webassembly.github.io/spec/web-api/). Editor's drafts accessed
2026-09-02.

## Research question or contribution

The specifications define how a host JavaScript environment constructs,
compiles, instantiates, imports into, exports from, and exchanges values with
Core WebAssembly modules.

## Findings

- Core WebAssembly deliberately does not define interaction with the
  surrounding execution environment; an embedder supplies that connection.
- The JavaScript API defines module/instance construction, import objects,
  exported functions, memory, tables, globals, and errors.
- The Web API adds browser-specific behavior such as streaming compilation and
  response/media-type integration.
- The DOM is not a Core Wasm API. A UI framework must reach it through host
  imports, generated bindings, JavaScript glue, or a higher-level embedding.
- Wasm linear memory and browser object graphs have different representations,
  making ABI and batching choices material to performance.

## Relevance

These standards establish why every BlazeX backend needs a JavaScript host and
why a compact render batch is preferable to high-frequency individual DOM
calls from Wasm.

## Limits

The specifications define embedding mechanics, not a UI component framework
or a performance model for any specific browser.

## Derived work

- [Main synthesis](../20-notes/elixir-webassembly-component-framework-for-phoenix-and-plug.md)
- [Elixir WebAssembly components map](../10-maps/elixir-webassembly-components.md)
