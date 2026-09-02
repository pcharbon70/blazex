# BlazeX Browser Runtime

Provides the small JavaScript companion for the browser host: WebAssembly
loading, host imports, transport attachment, event routing, privileged browser
effects, diagnostics, and fallback/error presentation.

It must not become a second component framework. Component state and semantic
behavior remain in Elixir; DOM lowering belongs to the DOM renderer contract and
its bridge.

Status: directory scaffold only; initialize the JavaScript package when its
implementation milestone begins.

