# Benchmarks

Contains repeatable benchmarks and recorded baselines for WebAssembly and asset
payloads, startup latency, memory, event-to-paint latency, server round trips,
tree updates, and representative component workloads.

Benchmarks should name the runtime, host, renderer, profile, build mode, and
environment so results remain comparable over time.

Phase 1 activation added governed indexes, environment/sample schemas, and
reserved raw-evidence/report locations. Phase 8 added one local environment
fingerprint and the exact browser inventory used to govern its compatibility
matrix. Phase 9 Section 9.1 adds exact metric boundaries, sampling/statistical
policy, a schema for browser runs, deterministic aggregation helpers, and an
instrumented Chrome/Firefox runner. No Phase 9 sample has run at this section
boundary and no budget has passed.

## Index

- `environment-fingerprint.schema.json` — build/test environment identity.
- `sample.schema.json` — immutable raw measurement sample contract.
- `artifact-run.schema.json` — manifest-derived payload accounting evidence contract.
- `build-run.schema.json` — isolated profile-packaging timing evidence contract.
- `measurement-run.schema.json` — raw active-browser run contract.
- `phase9-metric-definitions.json` — clocks, boundaries, sample policy, budget
  links, and deferred qualification boundary.
- `phase9_metrics.py` — deterministic nearest-rank statistics and raw sample
  validation.
- `run_phase9_build.py` — isolated dependency-cached profile packaging timer.
- `run_phase9_artifacts.mjs` — manifest-driven decoded and deterministic Brotli
  payload accounting.
- `benchmark-index.json` — canonical environment/measurement/sample/report index.
- `environments/`, `samples/`, `raw-evidence/`, and `reports/` — future evidence locations.
- `environments/bh01-phase8-local-linux.json` — exact local Linux/Chrome
  fingerprint for the available Phase 8 required row.
- `raw-evidence/bh01-phase8-environment-inventory.json` — browser binary,
  automation, host, and unavailable-environment inventory.
- `tests/test_phase9_metrics.py` — positive and fail-closed metric tests.
