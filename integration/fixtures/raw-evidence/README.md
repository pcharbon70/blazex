# BH-01 Fixture Raw Evidence

Immutable logs, traces, and observations from governed fixture execution are
retained here or referenced through content-addressed records. The Phase 3
Node runtime-semantics record preserves the normalized trace, exact runtime and
bundle identities, bounded-resource observations, and compatibility limits. It
is not browser evidence.

- `bh01-phase3-runtime-semantics.json` — passed pinned-Node AtomVM/AVM probe.
- `bh01-phase3-artifact-reproducibility.json` — 21 byte-identical runtime,
  fixture, metadata, compressed-output, and normalized-build-log comparisons
  across two clean equivalent builds.
- `bh01-phase3-negative-paths.json` — eight fail-closed actual-runtime,
  WebAssembly-host-contract, bundle, and evidence-validation probes.
- `bh01-phase4-browser.json` — normalized actual-browser loader, bridge,
  lifecycle, fallback, deployment, artifact, and network observations.
- `bh01-phase5-local-browser.json` — two complete actual-browser local-
  behavior runs, one canonical 29-checkpoint semantic trace, negative paths,
  preliminary timings/accessibility observations, and terminal resource state.
