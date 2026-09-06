# BlazeX Browser Runtime

Provides the small JavaScript companion for the browser host: WebAssembly
loading, host imports, transport attachment, event routing, privileged browser
effects, diagnostics, and fallback/error presentation.

It must not become a second component framework. Component state and semantic
behavior remain in Elixir; DOM lowering belongs to the DOM renderer contract and
its bridge.

Status: experimental BH-03 Phase 5 browser runtime using the pinned
package-manager declaration `npm@11.19.0`. It publishes the same eight exact
compatibility identities as the Elixir browser host and fails closed on missing,
unknown, duplicate, malformed, or mismatched inputs before acquisition. It also
resolves one same-origin manifest declaration, fetches only bounded no-store
JSON, validates the strict profile envelope, and returns explicit prerequisite
decisions without acquiring any declared artifact. Compatible scopes share one
runtime while independent roots retain their own ordered queues. The registry
now rejects new roots, drains and disposes existing roots, verifies a bounded
generation-bound shutdown acknowledgement, and releases the runtime exactly
once. The
historical BH-01 loader accepts and verifies its disposable fixture manifest;
that evidence is not the BH-03 profile-manifest contract. The package has no
component logic, renderer, Phoenix authority, or stable public API.

The runtime frame is profile-owned because its URL, response policy, and cleanup
are deployment concerns. The reusable package owns acquisition and transfer,
not the DOM or application state. The frame imports verified in-memory runtime
source, preloads the verified AVM into Emscripten's filesystem, creates the exact
fixed shared memory, and reports typed runtime/readiness events.
