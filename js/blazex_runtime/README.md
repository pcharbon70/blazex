# BlazeX Browser Runtime

Provides the small JavaScript companion for the browser host: WebAssembly
loading, host imports, transport attachment, event routing, privileged browser
effects, diagnostics, and fallback/error presentation.

It must not become a second component framework. Component state and semantic
behavior remain in Elixir; DOM lowering belongs to the DOM renderer contract and
its bridge.

Status: experimental BH-01 Phase 4 loader using the pinned package-manager
declaration `npm@11.19.0`. The loader accepts only an exact, same-origin runtime
manifest, verifies every declared byte with SHA-256, and transfers the runtime
and AVM bundle to an isolated same-origin runtime frame. It has no component
logic, renderer, Phoenix authority, or stable public API.

The runtime frame is profile-owned because its URL, response policy, and cleanup
are deployment concerns. The reusable package owns acquisition and transfer,
not the DOM or application state. The frame imports verified in-memory runtime
source, preloads the verified AVM into Emscripten's filesystem, creates the exact
fixed shared memory, and reports typed runtime/readiness events.
