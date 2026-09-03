# BlazeX Popcorn Runtime

Adapts the Popcorn/AtomVM WebAssembly environment to BlazeX runtime contracts.
It will own runtime boot, process integration, bundle loading, host imports,
failure isolation, restart behavior, and runtime diagnostics.

This adapter must not define the component API or assume that every future host
uses Popcorn. Other Elixir runtimes can implement the same host-neutral
contracts independently.

Status: experimental BH-01 Mix skeleton. The project has no dependencies and
contains no runtime implementation; toolchain and candidate-runtime
qualification begins in Phase 2. Its module root is not a stable public API.
