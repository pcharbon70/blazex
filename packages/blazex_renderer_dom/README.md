# BlazeX DOM Renderer

Lowers the semantic UI tree into browser DOM operations and maps native browser
events back into BlazeX semantic events. It will own DOM reconciliation,
attributes, styles, accessibility mappings, focus, and browser surface effects.

Any dependency on LiveView, LocalLiveView, or browser implementation details
must be explicit and version-pinned here rather than leaking into component or
renderer contracts.

Status: directory scaffold only; create the Mix project when its implementation
milestone begins.

