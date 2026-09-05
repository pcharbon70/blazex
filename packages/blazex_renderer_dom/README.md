# BlazeX DOM Renderer

Lowers the semantic UI tree into server-framework-independent browser DOM
operations and maps native browser events back into BlazeX semantic events. It
will own DOM reconciliation, attributes, styles, accessibility mappings, focus,
and browser surface effects.

This package must not depend on Phoenix, LiveView, LocalLiveView, or Plug. The
optional LiveView patching integration belongs in
`blazex_renderer_dom_liveview`, allowing the Plug and future WebView profiles to
reuse the DOM renderer without inheriting Phoenix dependencies.

Status: experimental BH-02 Phase 6 standalone renderer. The Elixir backend
lowers all current semantic nodes and presentation intent to deterministic,
versioned full-root wire projections. It depends only on the neutral Phase 5
contract graph. Incremental reconciliation, hydration, server integration,
visual qualification, stable APIs, and support remain outside this package.
