# BlazeX Phoenix

Provides reusable Phoenix integration for applications that host BlazeX browser
components. Expected concerns include endpoint/static integration, bootstrap
metadata, sessions, server commands, telemetry, and optional server rendering
or LiveView interoperability.

Phoenix is a replaceable server adapter. Component libraries, runtime contracts,
and renderer contracts must not depend on this package. LiveView render-data and
patch coupling belongs to `blazex_renderer_dom_liveview`; this package may
coordinate that adapter but must not absorb the standalone DOM renderer.

Status: experimental BH-01 server-adapter Mix skeleton. The project has no
dependencies and contains no Phoenix implementation or authority-bearing
command path. Its module root is not a stable public API.
