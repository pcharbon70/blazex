---
title: "Phoenix LiveView 1.2 lifecycle, HEEx diff, and browser renderer"
kind: source
created: "2026-09-02"
authors:
  - "Phoenix LiveView contributors"
published: 2026
citation_key: "phoenix-2026-liveview-renderer"
container: "Phoenix LiveView v1.2.11 documentation and source"
edition: "1.2.11"
isbn: null
doi: null
url: "https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.html"
accessed: "2026-09-02"
tags:
  - components
  - heex
  - liveview
  - phoenix
  - rendering
aliases:
  - "LiveView architecture documentation"
---

# Phoenix LiveView 1.2 lifecycle, HEEx diff, and browser renderer

## Reference

Phoenix LiveView contributors. Phoenix LiveView v1.2.11 documentation and
current source. Accessed 2026-09-02. Principal references:

- [`Phoenix.LiveView`](https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.html)
- [`Phoenix.LiveComponent`](https://phoenix-live-view.hexdocs.pm/Phoenix.LiveComponent.html)
- [`Phoenix.LiveView.Engine`](https://github.com/phoenixframework/phoenix_live_view/blob/main/lib/phoenix_live_view/engine.ex)
- [`Phoenix.LiveView.Diff`](https://github.com/phoenixframework/phoenix_live_view/blob/main/lib/phoenix_live_view/diff.ex)
- [browser `Rendered`](https://github.com/phoenixframework/phoenix_live_view/blob/main/assets/js/phoenix_live_view/rendered.js)
- [browser `DOMPatch`](https://github.com/phoenixframework/phoenix_live_view/blob/main/assets/js/phoenix_live_view/dom_patch.js)

## Research question or contribution

This material documents the Elixir-facing process/component model and exposes
the compiled HEEx and browser-patching architecture that a local Wasm runtime
can reuse.

## Method

The review traced initial HTTP rendering, connected mount, event dispatch,
assign changes, HEEx output, server diff construction, client rendered-state
merge, and DOM patch application. LiveView and LiveComponent process ownership
were checked against current API documentation.

## Findings

- A LiveView is a server process with state held in socket assigns. It receives
  browser events and BEAM messages and sends render diffs.
- Initial output uses an ordinary HTTP response; JavaScript then establishes a
  channel connection and mounts the connected view.
- HEEx compiles templates into static fragments, a dynamic function, and a
  fingerprint. Changed assigns allow unchanged dynamic entries to return
  `nil`, reducing computation and transmission.
- LiveComponents have state and lifecycle but execute inside their parent
  LiveView process. Function components are stateless functions.
- The browser client captures events, merges compact diffs, maintains view and
  component identity, and patches the DOM while accounting for forms, focus,
  hooks, navigation, and ignored regions.
- The server `Diff` and browser `Rendered`/`DOMPatch` code form a coupled
  protocol even though not all of that boundary is a documented public API.

## Relevance

LiveView supplies the most valuable parts of a BlazeX MVP: familiar callbacks,
HEEx as a structured render IR, and a mature browser DOM patcher. Local
execution can replace the network leg with an AtomVM/JavaScript boundary while
retaining optional Phoenix Channels for trusted server commands.

## Limits

Some implementation links track the source repository's main branch while the
API baseline is 1.2.11. LocalLiveView's use of internal modules is not thereby
guaranteed or supported. No independent renderer performance test was run.

## Derived work

- [Main synthesis](../20-notes/elixir-webassembly-component-framework-for-phoenix-and-plug.md)
- [BlazeX feasibility inquiry](../40-inquiries/can-elixir-webassembly-components-integrate-with-phoenix-and-plug.md)
- [Deep-dive journal](../50-journal/2026-09-02-elixir-webassembly-components-deep-dive.md)
