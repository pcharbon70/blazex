# Integration

This directory holds repository-wide validation that crosses independent
package boundaries. Package-local unit tests remain with their package; suites
here exercise supported compositions and compare implementations against shared
contracts.

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
