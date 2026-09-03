# BlazeX DOM Renderer

Lowers the semantic UI tree into server-framework-independent browser DOM
operations and maps native browser events back into BlazeX semantic events. It
will own DOM reconciliation, attributes, styles, accessibility mappings, focus,
and browser surface effects.

This package must not depend on Phoenix, LiveView, LocalLiveView, or Plug. The
optional LiveView patching integration belongs in
`blazex_renderer_dom_liveview`, allowing the Plug and future WebView profiles to
reuse the DOM renderer without inheriting Phoenix dependencies.

Status: experimental BH-01 Mix skeleton. The project has no dependencies and
contains no DOM implementation; standalone behavior remains unexecuted. Its
module root is not a stable public API.
