# BH-01 Phase 4 Browser Loader Assets

This directory owns the feasibility-only browser runtime frame and its governed
manifest template. `build_profile.py` copies only the three declared artifacts,
computes their byte counts and SHA-256 digests, and writes a no-store runtime
manifest. It performs no network acquisition.

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

The loader does not own component state, DOM rendering, Phoenix authorization,
LiveView data, arbitrary script execution, or general browser fetch. The frame's
only Phase 4 purpose is to host the declared Popcorn runtime, transfer the
verified AVM, and emit typed lifecycle observations. Product DOM behavior starts
in a later phase.

The bridge allows only `runtime.echo` and `runtime.shutdown`. Every envelope is
versioned and carries scenario, generation, correlation, and sequence identity.
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
