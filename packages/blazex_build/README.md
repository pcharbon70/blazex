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

BH-06 Phase 2 adds atom-safe `ClientEntryPoint` declarations and
`BeamInventory.scan!/1`. Inventory output is ordered, path-independent, and
limited to module names, content hashes, static imports/exports, and attribute
names. Malformed files and duplicate module definitions fail closed.

`Reachability.analyze!/3` follows known imports from validated client roots,
selects stable shortest reason chains, retains external references and unused
inventory, and rejects undeclared `apply/2,3`. The candidate pipeline can bind
the canonical report as another content-addressed manifest asset.

BH-06 Phase 3 adds exact-match `ClientSafetyPolicy` records and
`ClientSafety.analyze!/3`. Every reachable module and external module must be
classified; server-only, native, unknown, forbidden NIF/port primitives, and
unused candidate-specific declarations fail with deterministic diagnostics.

Run `mix format --check-formatted && mix test` from this directory.
