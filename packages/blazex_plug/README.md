# BlazeX Plug

Provides a smaller Plug-based integration for serving browser bundles,
bootstrap metadata, and HTTP-oriented command endpoints without requiring
Phoenix.

This package proves and preserves the boundary between BlazeX and Phoenix. It
must have no transitive Phoenix, LiveView, LocalLiveView, or
`blazex_renderer_dom_liveview` dependency.

Status: directory scaffold only; create the Mix project when its implementation
milestone begins.
