---
title: "Hologram's Elixir-to-JavaScript client component architecture"
kind: source
created: "2026-09-02"
authors:
  - "Bart Blast"
  - "Hologram contributors"
published: null
citation_key: "bartblast-2026-hologram"
container: "Hologram source repository and documentation"
edition: null
isbn: null
doi: null
url: "https://github.com/bartblast/hologram"
accessed: "2026-09-02"
tags:
  - compilers
  - components
  - elixir
  - hologram
  - javascript
aliases:
  - "Hologram architecture"
---

# Hologram's Elixir-to-JavaScript client component architecture

## Reference

Bart Blast and Hologram contributors. [Hologram source
repository](https://github.com/bartblast/hologram) and project usage/architecture
documentation. Accessed 2026-09-02.

## Research question or contribution

Hologram demonstrates another route to client-side Elixir authoring: compile
client-reachable Elixir to JavaScript and supply an independent page,
component, state, template, and client/server command framework.

## Findings

- Hologram compiles selected client-side Elixir code to JavaScript, not Wasm.
- Pages and components are framework-specific and use `~HOLO`, not HEEx or
  LiveView callbacks.
- Client actions update browser state; server commands handle database,
  session, cookie, and privileged work.
- The compiler traces client-reachable code and bundles needed protocol and
  runtime support.
- Only the implemented subset of Elixir/standard-library behavior is
  available on the client.
- JavaScript interop is explicit and supports imported modules, calls,
  callbacks, properties, promises, and DOM/event operations.

## Relevance

Hologram is not a Wasm foundation for BlazeX, but its compiler reachability,
client/server split, explicit interop, bundle budget, and security boundaries
are highly relevant design comparisons. It also shows the cost of departing
from HEEx/LiveView compatibility: a separate template and component ecosystem
must be built and maintained.

## Limits

The project is fast-moving and this review did not execute its compiler or
measure bundles. Its JavaScript target has different performance and sandbox
properties from AtomVM/Wasm.

## Derived work

- [Main synthesis](../20-notes/elixir-webassembly-component-framework-for-phoenix-and-plug.md)
- [Elixir WebAssembly components map](../10-maps/elixir-webassembly-components.md)
