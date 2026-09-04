# BH-01 Current Browser Profile Assets

This directory owns the feasibility-only browser runtime frame and its governed
manifest template. `build_profile.py` copies the declared runtime artifacts,
runtime loader, and replaceable Phase 5 DOM fixture adapter; computes byte counts
and SHA-256 digests; and writes a no-store runtime manifest. It performs no
network acquisition. The historical `phase4` path remains in place so Phase 5
extends the already-proven profile rather than creating a second host.

## Ownership and replacement boundaries

| Resource or operation | Browser API | Owner and cleanup | Capability prerequisite | Future replacement boundary |
| --- | --- | --- | --- | --- |
| Manifest/artifact fetch | `fetch`, `AbortController`, `SubtleCrypto` | `BrowserRuntimeLoader`; abort on stop/failure | Fetch and secure-context integrity APIs | Host-neutral artifact provider |
| Runtime isolation | Same-origin sandboxed `iframe` | `BrowserRuntimeFrame`; remove frame/listener on stop | Modules, frames, structured clone | Browser host adapter |
| Runtime module load | Blob URL plus dynamic `import()` | Runtime frame; revoke URL after import | Blob-backed ES modules | Versioned runtime adapter |
| Wasm instantiation | `WebAssembly`, `SharedArrayBuffer`, worker support | Popcorn/Emscripten runtime; frame disposal owns termination | Wasm threads and cross-origin isolation | Runtime backend adapter |
| Bundle preload/start | Emscripten preload plus fixed entrypoint | Runtime frame; frame disposal releases bundle | Governed AVM and startup contract | Portable application launcher |
| Parent/frame events | `postMessage` with random channel and exact origin | Frame port; detach listener on stop | Structured clone and same origin | Versioned host bridge |
| Elixir requests | Popcorn `call`/`cast` carrying JSON values | `BrowserHostBridge`; timeout, cancel, or stop settles ownership | Ready runtime and `blazex.host-bridge/1` | Portable host command port |

The loader does not own component semantics, Phoenix authorization, LiveView
data, arbitrary script execution, or general browser fetch. The frame hosts the
declared Popcorn runtime, transfers the verified AVM, and emits typed lifecycle
observations. Phase 5 adds only a closed, test-only DOM operation adapter; it is
not a public renderer contract.

The bridge allows only `runtime.echo`, `runtime.shutdown`, `fixture.command`,
`fixture.event`, and `fixture.snapshot`. Every envelope is versioned and carries
scenario, generation, correlation, and sequence identity.
Both JavaScript and Elixir enforce finite JSON values, an 8 KiB envelope, depth
and item limits, bounded timeout/concurrency, no retry, and rejection of
sensitive keys. Browser objects, functions, credentials, arbitrary URLs, and
arbitrary operations are not representable through this boundary.

Activation uses a ten-state monotonic lifecycle with a distinct activation
generation. Every abort controller, page listener, runtime frame, bridge,
request timer, and correlation is owned by one activation. Explicit stop,
startup failure, runtime failure, and `pagehide` converge through the same
idempotent reverse-order cleanup path. Integrity and contract failures require
operator/deployment action; transient startup failures allow at most one retry
after reset, backoff, and a new generation.
