---
title: "Phoenix 1.8 request, component, channel, and endpoint architecture"
kind: source
created: "2026-09-02"
authors:
  - "Phoenix Framework contributors"
published: 2026
citation_key: "phoenix-2026-framework-docs"
container: "Phoenix v1.8.13 documentation"
edition: "1.8.13"
isbn: null
doi: null
url: "https://phoenix.hexdocs.pm/overview.html"
accessed: "2026-09-02"
tags:
  - channels
  - components
  - phoenix
  - pubsub
  - web-frameworks
aliases:
  - "Phoenix 1.8 architecture documentation"
---

# Phoenix 1.8 request, component, channel, and endpoint architecture

## Reference

Phoenix Framework contributors. Phoenix v1.8.13 documentation. Accessed
2026-09-02. Principal pages: [request
lifecycle](https://phoenix.hexdocs.pm/request_lifecycle.html),
[`Phoenix.Endpoint`](https://phoenix.hexdocs.pm/Phoenix.Endpoint.html),
[routing](https://phoenix.hexdocs.pm/routing.html), [Components and
HEEx](https://phoenix.hexdocs.pm/components.html), and
[Channels](https://phoenix.hexdocs.pm/channels.html).

## Research question or contribution

The documentation defines the server-side layers available to host browser
runtime artifacts and to supply rendering, routing, sessions, realtime
commands, and application integration.

## Findings

- The web-server adapter hands requests into a supervised Phoenix endpoint,
  which is itself a Plug pipeline.
- The endpoint runs common plugs and dispatches into a router. Router pipelines
  transform matched requests before controllers, LiveViews, channels, or other
  plugs handle them.
- Controller/view HTML rendering is separate from domain contexts.
- Function components are functions accepting assigns and returning HEEx;
  Phoenix's HTML concerns are provided through Phoenix HTML and LiveView
  packages rather than the core router alone.
- Channels multiplex logical topics over one WebSocket or long-poll
  connection, normally with a lightweight server process per joined topic.
- PubSub distributes topic messages within and across nodes.
- Static serving, asset digests, sockets, sessions, and endpoint headers are
  natural integration points for a BlazeX host adapter.

## Relevance

Phoenix provides much more than Wasm file hosting. It supplies the environment
needed for a cohesive component product: HEEx, browser/session security,
Channels, PubSub, routing, assets, and LiveView compatibility. That supports a
Phoenix-first adapter while keeping the runtime core host-neutral.

## Limits

The documents describe public framework behavior, not a performance
measurement. LiveView internals are recorded separately. Version 1.8.13 is the
baseline, not a permanent compatibility promise.

## Derived work

- [Main synthesis](../20-notes/elixir-webassembly-component-framework-for-phoenix-and-plug.md)
- [Elixir WebAssembly components map](../10-maps/elixir-webassembly-components.md)
