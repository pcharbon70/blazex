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

BH-01 activates governed fixture and benchmark evidence. BH-02 Phase 1
activates an empty versioned `conformance` index. Empty means no semantic
fixture, canonical trace, backend result, or cross-renderer claim exists yet.
