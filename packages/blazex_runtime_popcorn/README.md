# BlazeX Popcorn Runtime

Adapts the Popcorn/AtomVM WebAssembly environment to BlazeX runtime contracts.
It will own runtime boot, process integration, bundle loading, host imports,
failure isolation, restart behavior, and runtime diagnostics.

This adapter must not define the component API or assume that every future host
uses Popcorn. Other Elixir runtimes can implement the same host-neutral
contracts independently.

Status: directory scaffold only; create the Mix project when its implementation
milestone begins.

