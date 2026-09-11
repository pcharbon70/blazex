# BH-06 build-pipeline evidence

Phase 1 owns the first continuous browser-Wasm vertical slice. The index is
activated before executable evidence is recorded; it cannot claim a pass until
the same packaged Elixir component completes the lifecycle in Chrome and Firefox.

- [`vertical_slice`](vertical_slice/README.md) contains the public Elixir
  counter, candidate package task, integrity-verifying host, and browser matrix.
- [`candidate-build-manifest-v0.1.0.json`](candidate-build-manifest-v0.1.0.json)
  records five governed outputs and their exact content identities.
- [`browser-slice-v0.1.0.json`](browser-slice-v0.1.0.json) records matching
  Chrome/Firefox lifecycle results and the fail-closed integrity case.
