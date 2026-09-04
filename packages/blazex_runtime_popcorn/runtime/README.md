# BH-01 pinned runtime build

This directory is the reproducible build and inspection boundary for the
Phase 3 FissionVM/Popcorn candidate. It produces two deployable web variants
(`debug-web` and `release-web`) plus a `release-node-probe` harness used only
to exercise the same Wasm VM before browser-loader work begins.

The recipe accepts only checksum-qualified archives. It extracts each source
into a fixed container path, copies the sysroot from the digest-pinned
Emscripten image, seeds the exact Emscripten zlib port, and configures and
builds with Docker networking disabled. `gperf` and the zlib port are explicit
inputs because the first clean Phase 3 build correctly failed when they were
not present in the Phase 2 inventory.

Example:

```console
python3 packages/blazex_runtime_popcorn/runtime/build_runtime.py \
  --fissionvm /inputs/fissionvm-6c3208c7.tar.gz \
  --mbedtls /inputs/mbedtls-v3.6.3.1.tar.gz \
  --ninja /inputs/ninja-linux-v1.12.1.zip \
  --gperf /inputs/gperf_3.1-1build1_amd64.deb \
  --zlib /inputs/zlib-1.3.1.tar.gz \
  --output packages/blazex_runtime_popcorn/runtime/generated
```

The command rejects wrong hashes, undeclared modes, dirty output directories,
missing Docker, implicit network access, and missing generated outputs. It
uses canonical source-prefix maps and deterministic gzip headers. Generated
binaries and logs are ignored. Ninja progress indices and transcript lines are
normalized to remove parallel completion order; their hashes, sizes, binary contract, input
lineage, source-map policy, and limitations are retained in
`runtime-binary-manifest.json`.

`THIRD_PARTY_NOTICES.md` assigns stable license records to every direct build
input. The unified Phase 3 artifact manifest also records the empty BlazeX
source-patch set, embedded debug-section carrier, external source-map omission,
output reachability, and clean-repeat identities.

`adapter-classification.json` separates upstream VM behavior, FissionVM's
Emscripten platform, Popcorn packaging/bridges, BlazeX's Phase 3 adaptation,
the empty source-patch set, and responsibilities deferred to the browser host.

`wasi_snapshot_preview1` function imports in these modules are Emscripten JS
ABI shims. They do not make this a WASI target: the module also depends on
`env`, imported fixed shared memory, Emscripten pthreads, browser facilities,
and generated JavaScript glue. The WebAssembly Component Model is not used.
