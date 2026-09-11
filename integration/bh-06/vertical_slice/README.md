# BH-06 Phase 1 browser-Wasm vertical slice

This private fixture packages `BlazeX.BH06.VerticalSlice.Counter`, authored
through the public experimental `BlazeX.Component` facade, into an AVM bundle.
The BH-06 build package combines it with the governed AtomVM WebAssembly runtime
and content-addressed browser assets. Chrome and Firefox then execute mount,
semantic render, browser click, Elixir state transition, DOM update, and disposal.

It is an early executable build gate, not a supported component or release.
LiveView, LocalLiveView, Phoenix transport, general reachability, and production
deployment are outside Phase 1.

From this directory, build and run with:

```bash
mix bh06.package --out-dir /tmp/bh06-build
node run-browser.mjs /tmp/bh06-build /tmp/bh06-browser.json
```
