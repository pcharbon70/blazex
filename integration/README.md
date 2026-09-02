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

