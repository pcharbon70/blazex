# BlazeX DOM Renderer

Lowers the semantic UI tree into server-framework-independent browser DOM
operations and maps native browser events back into BlazeX semantic events. It
owns experimental DOM reconciliation, attributes, styles, accessibility mappings, focus,
and browser surface effects.

This package must not depend on Phoenix, LiveView, LocalLiveView, or Plug. The
LiveView and LocalLiveView integration is explicitly deferred, outside the
current host implementation. Any future adapter belongs outside this package,
allowing other profiles to reuse the DOM renderer without Phoenix dependencies.

Status: experimental BH-04 standalone renderer. The Elixir backend lowers
semantic nodes and presentation intent to deterministic wire projections and
incremental transactions. Internal sessions exercise reconciliation, controlled
form continuity, interaction transport and capability-gated effects with the
browser runtime. These contracts are not a stable public component API.
Hydration, server integration, production Wasm-carrier qualification, physical
visual qualification and release support remain outside the demonstrated scope.
