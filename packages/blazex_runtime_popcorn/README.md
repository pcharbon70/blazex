# BlazeX Popcorn Runtime

Adapts the Popcorn/AtomVM WebAssembly environment to BlazeX runtime contracts.
It will own runtime boot, process integration, bundle loading, host imports,
failure isolation, restart behavior, and runtime diagnostics.

This adapter must not define the component API or assume that every future host
uses Popcorn. Other Elixir runtimes can implement the same host-neutral
contracts independently.

Status: experimental BH-01 runtime adapter. Phase 3 owns a pinned,
network-disabled build recipe, Wasm inspection, and three disposable fixture
hooks. Generated runtime binaries remain rebuildable outputs under
`runtime/generated/`; their stable identities live in the checked-in runtime
binary manifest. The module root and hooks are not a stable public API.

Run the static contract tests with `python3 runtime/verify_runtime_build.py`
and `python3 -m unittest discover -s runtime/tests -p 'test_*.py'`. The full
build command is documented in `runtime/README.md` and requires the exact
input archives named by `runtime/build-contract.json`.
