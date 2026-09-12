# BH-06 build-pipeline evidence

Phase 1 owns the first continuous browser-Wasm vertical slice. Phase 2 adds an
explicit, deterministic entrypoint-rooted BEAM inventory to that candidate build.

- [`vertical_slice`](vertical_slice/README.md) contains the public Elixir
  counter, candidate package task, integrity-verifying host, and browser matrix.
- [`candidate-build-manifest-v0.1.0.json`](candidate-build-manifest-v0.1.0.json)
  records five governed outputs and their exact content identities.
- [`browser-slice-v0.1.0.json`](browser-slice-v0.1.0.json) records matching
  Chrome/Firefox lifecycle results and the fail-closed integrity case.
- [`reachability-v0.1.0.json`](reachability-v0.1.0.json) records the Phase 2
  entrypoint-rooted module inventory, external references, and deliberately
  excluded unused sentinel; its schema is
  [`reachability.schema.json`](reachability.schema.json).
