# BlazeX Browser Runtime

Provides the small JavaScript companion for the browser host: WebAssembly
loading, host imports, transport attachment, event routing, privileged browser
effects, diagnostics, and fallback/error presentation.

It must not become a second component framework. Component state and semantic
behavior remain in Elixir; DOM lowering belongs to the DOM renderer contract and
its bridge.

Status: experimental BH-01 JavaScript skeleton using the pinned package-manager
declaration `npm@11.4.2`. It has no dependencies, lockfile, Wasm loader, browser
bridge implementation, component logic, or stable public API.
