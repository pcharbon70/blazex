# BH-06 browser-Wasm vertical slice

This private fixture packages `BlazeX.BH06.VerticalSlice.Counter`, authored
through the public experimental `BlazeX.Component` facade, into an AVM bundle.
The BH-06 build package combines it with the governed AtomVM WebAssembly runtime,
content-addressed reachability, client-safety, and exact compatibility reports,
plus a redacted secret audit, complete license/provenance inventory, and browser assets.
Phase 7 packages the counter as a separate content-addressed feature AVM; the
host verifies it and loads it into the already-running AtomVM before mount.
The reports root the counter explicitly, prove the inventoried `Unused` sentinel
is not silently bundled, and classify every bounded reachable/external dependency
before AVM assembly. The runtime identity, AVM ABI, protocol versions, and
required features must also match the runtime-owned profile before assembly.
Every audited input must then resolve to one shipped component, exact license
records, and verified notice content before the AVM can be created.
Every BEAM also has exactly one base/feature owner, and the startup bridge proves
the counter is absent before its one permitted dynamic load.
Phase 8 marks reports as private build evidence, Brotli-compresses every public
artifact three times, and truthfully rejects the unreduced runtime payload.
Phase 9 excludes the build-only Mix task, graph-prunes the 692-module base,
function-prunes compiler-metadata-bearing BEAMs, carries opaque BEAMs unchanged,
and records opaque-to-analyzable bridge roots before normal promotion. The
unchanged Phase 8 numeric budgets now accept the reduced candidate. Chrome and
Firefox then execute mount,
semantic render, browser click, Elixir state transition, DOM update, and disposal.
Phase 10 binds a closed delivery policy, verifies SHA-384 SRI before runtime
startup, and proves exact no-store/immutable Cache-Control responses. This is
adapter-consumable metadata rather than a production serving claim.
Phase 11 emits one deterministic attestation that accounts for the complete
declared browser entrypoint set and binds it into both active-browser replays.

It is an early executable build gate, not a supported component or release.
LiveView, LocalLiveView, Phoenix transport, production cache/CDN qualification,
and production deployment remain outside this slice.

From this directory, build and run with:

```bash
# Expected to accept and promote /tmp/bh06-build:
mix bh06.package --out-dir /tmp/bh06-build --payload-report /tmp/bh06-payload.json --attestation-report /tmp/bh06-attestation.json

node run-browser.mjs /tmp/bh06-build /tmp/bh06-browser.json /tmp/bh06-payload.json /tmp/bh06-attestation.json
```
