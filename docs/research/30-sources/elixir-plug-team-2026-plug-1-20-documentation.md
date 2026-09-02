---
title: "Plug 1.20 connection, pipeline, and adapter model"
kind: source
created: "2026-09-02"
authors:
  - "Elixir Plug team"
published: 2026
citation_key: "plug-2026-documentation"
container: "Plug v1.20.3 documentation"
edition: "1.20.3"
isbn: null
doi: null
url: "https://plug.hexdocs.pm/readme.html"
accessed: "2026-09-02"
tags:
  - elixir
  - http
  - plug
  - web-frameworks
aliases:
  - "Plug architecture documentation"
---

# Plug 1.20 connection, pipeline, and adapter model

## Reference

Elixir Plug team. Plug v1.20.3 documentation, [Plug
README](https://plug.hexdocs.pm/readme.html) and [`Plug.Conn.Adapter`](https://plug.hexdocs.pm/Plug.Conn.Adapter.html).
Accessed 2026-09-02.

## Research question or contribution

The documentation defines the lowest-level conventional Elixir web-host
contract available to BlazeX without depending on Phoenix.

## Findings

- `%Plug.Conn{}` represents the request/response connection and is transformed
  immutably through functions.
- Module plugs implement `init/1` and `call/2`; function plugs accept a
  connection and options. Both compose into pipelines.
- A connection is the direct interface to the web-server adapter for sending,
  streaming, and response metadata.
- Plug can serve static artifacts, set Wasm and isolation headers, issue signed
  bootstrap data, and host HTTP or upgraded transports.
- Plug does not provide HEEx component semantics, LiveView's diff renderer,
  Channels/PubSub, or Phoenix's session/routing conventions by itself.

## Relevance

This establishes a clean separation between `blazex_core` and optional host
packages. A Plug adapter can be small and useful, but it cannot promise the
same feature set as the Phoenix/LiveView adapter without shipping additional
renderer and realtime infrastructure.

## Limits

The source does not prescribe a BlazeX protocol or WebSocket implementation.
Those remain framework design work.

## Derived work

- [Main synthesis](../20-notes/elixir-webassembly-component-framework-for-phoenix-and-plug.md)
- [BlazeX feasibility inquiry](../40-inquiries/can-elixir-webassembly-components-integrate-with-phoenix-and-plug.md)
