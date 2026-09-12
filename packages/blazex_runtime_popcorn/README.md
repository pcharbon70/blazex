# BlazeX Popcorn Runtime

Adapts the Popcorn/AtomVM WebAssembly environment to BlazeX runtime contracts.
It will own runtime boot, process integration, bundle loading, host imports,
failure isolation, restart behavior, and runtime diagnostics.

This adapter must not define the component API or assume that every future host
uses Popcorn. Other Elixir runtimes can implement the same host-neutral
contracts independently.

Status: experimental BH-03 Phase 2 runtime adapter. It publishes the exact
`blazex.popcorn-runtime-adapter/1` compatibility descriptor without acquiring
artifacts or starting a runtime. The historical BH-01 pinned build recipe,
Wasm inspection, and three disposable fixture hooks remain available only as
feasibility evidence. Generated runtime binaries remain rebuildable outputs
under `runtime/generated/`; their stable identities live in the checked-in
runtime binary manifest. Neither surface is a stable public API.

BH-06 Phase 4 adds the data-only
[`compatibility-profile-v0.1.0.json`](compatibility-profile-v0.1.0.json), owned
by this adapter and consumed by `blazex_build`. It declares the exact runtime,
AVM ABI, protocol versions, and supported or unsupported features evidenced by
the current browser artifact family. It is not a support claim or a version range.

Run the static contract tests with `python3 runtime/verify_runtime_build.py`
and `python3 -m unittest discover -s runtime/tests -p 'test_*.py'`. The full
build command is documented in `runtime/README.md` and requires the exact
input archives named by `runtime/build-contract.json`.
