# BlazeX Build

Owns framework build concerns such as component entry points, reachability,
client-safety checks, WebAssembly bundles, asset manifests, reproducibility,
and actionable compiler diagnostics.

Build output may target a particular profile, but this package must not acquire
execution-host behavior or contain server-framework behavior.

BH-06 Phase 1 activates the package with a deliberately narrow candidate
pipeline: one explicit public Elixir entrypoint and a prebuilt application AVM
bundle are assembled with the governed AtomVM WebAssembly runtime and static
host files. Every immutable asset receives a SHA-256-addressed filename and a
versioned manifest record. `BlazeX.Build.Pipeline.verify!/1` re-hashes the
finished output and fails on missing, changed, duplicate, or escaping paths.

This phase is not general reachability analysis or a production release tool.
The package has no dependency on a host, renderer, Phoenix, Plug, LiveView,
LocalLiveView, Popcorn, or AtomVM implementation package.

Run `mix format --check-formatted && mix test` from this directory.
