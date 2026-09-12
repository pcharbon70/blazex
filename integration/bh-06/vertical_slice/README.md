# BH-06 browser-Wasm vertical slice

This private fixture packages `BlazeX.BH06.VerticalSlice.Counter`, authored
through the public experimental `BlazeX.Component` facade, into an AVM bundle.
The BH-06 build package combines it with the governed AtomVM WebAssembly runtime,
content-addressed reachability, client-safety, and exact compatibility reports,
plus a redacted secret audit, complete license/provenance inventory, and browser assets.
The reports root the counter explicitly, prove the inventoried `Unused` sentinel
is not silently bundled, and classify every bounded reachable/external dependency
before AVM assembly. The runtime identity, AVM ABI, protocol versions, and
required features must also match the runtime-owned profile before assembly.
Every audited input must then resolve to one shipped component, exact license
records, and verified notice content before the AVM can be created.
Chrome and Firefox then execute mount,
semantic render, browser click, Elixir state transition, DOM update, and disposal.

It is an early executable build gate, not a supported component or release.
LiveView, LocalLiveView, Phoenix transport, server/native safety classification,
and production deployment remain outside this slice.

From this directory, build and run with:

```bash
mix bh06.package --out-dir /tmp/bh06-build
node run-browser.mjs /tmp/bh06-build /tmp/bh06-browser.json
```
