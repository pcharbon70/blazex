# BlazeX DOM Renderer

Lowers the semantic UI tree into server-framework-independent browser DOM
operations and maps native browser events back into BlazeX semantic events. It
will own DOM reconciliation, attributes, styles, accessibility mappings, focus,
and browser surface effects.

This package must not depend on Phoenix, LiveView, LocalLiveView, or Plug. The
optional LiveView patching integration belongs in
`blazex_renderer_dom_liveview`, allowing the Plug and future WebView profiles to
reuse the DOM renderer without inheriting Phoenix dependencies.

Status: experimental BH-01 Phase 5 fixture adapter. The dependency-free
JavaScript module owns one closed, value-only DOM operation set for the
disposable local-browser feasibility scenario. It maps opaque fixture kinds to
fixed elements, normalizes five allowlisted browser events, tracks every root
and listener by generation, and disposes them deterministically. It rejects
arbitrary tags, HTML, selectors, styles, properties, events, host objects,
network access, and executable values. This is not a general renderer or stable
public API and must be replaced by BH-02 contracts.
