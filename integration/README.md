# Integration

This directory holds repository-wide validation that crosses independent
package boundaries. Package-local unit tests remain with their package; suites
here exercise supported compositions and compare implementations against shared
contracts.

- [BH-05](bh-05/README.md) activates fourteen empty, schema-bound component-model
  evidence classes. Phase 1 is governance-only, not component conformance.
- [BH-06](bh-06/README.md) owns the first entrypoint-to-browser-Wasm build slice
  and its manifest, integrity, lifecycle, payload, delivery-metadata, and
  active-browser evidence through accepted Phase 11 and the final declared
  entrypoint attestation.

- `fixtures` contains deterministic shared applications, trees, events, and
  expected outcomes.
- `conformance` verifies behavioral contracts across runtimes, renderers, and
  profiles.
- `benchmarks` tracks performance and payload budgets against recorded
  baselines.
- `bh-03` owns browser-host/runtime lifecycle fixtures and evidence; Phase 2
  currently contains pure pre-acquisition contract fixtures.

BH-01 activates governed fixture and benchmark evidence. BH-02 owns accepted
internal cross-renderer conformance. BH-03 Phase 2 implements compatibility,
discovery, prerequisite, and strict-manifest fixtures while browser, runtime,
root, failure-execution, measurement, and acceptance result sets remain empty.
# BH-04 activation status

[BH-04](bh-04/README.md) activates an empty, versioned renderer evidence index
in Phase 1; all result classes remain empty. Historical statements below
describe earlier activations. The current BH-03 handoff is its accepted Phase 9
[decision](../docs/research/assets/bh-03-baseline/blazex-bh-03-phase-09-acceptance-v0.1.0.json),
with bounded limitations and no support promotion.
# BH-04 Phase 2 protocol status

[BH-04 protocol fixtures](bh-04/README.md) now compare canonical bytes, hashes
and rejection classes across Elixir and JavaScript. Browser and performance
results remain empty; earlier activation descriptions below are historical.
