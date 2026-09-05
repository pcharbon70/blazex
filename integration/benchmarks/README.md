# Benchmarks

Contains repeatable benchmarks and recorded baselines for WebAssembly and asset
payloads, startup latency, memory, event-to-paint latency, server round trips,
tree updates, and representative component workloads.

Benchmarks should name the runtime, host, renderer, profile, build mode, and
environment so results remain comparable over time.

Phase 1 activation added governed indexes, environment/sample schemas, and
reserved raw-evidence/report locations. Phase 8 added one local environment
fingerprint and the exact browser inventory used to govern its compatibility
matrix. Phase 9 Section 9.1 added exact metric boundaries, sampling/statistical
policy, evidence schemas, deterministic aggregation helpers, and an
instrumented Chrome/Firefox runner. Section 9.2 retains 1,303 Chrome and 1,301
Firefox browser samples, ten build samples, manifest-derived payload evidence,
three exact environment fingerprints, and a reproducible 41-distribution
summary. These are Linux development observations; no budget or browser support
claim is made at this section boundary.

## Index

- `environment-fingerprint.schema.json` — build/test environment identity.
- `sample.schema.json` — immutable raw measurement sample contract.
- `artifact-run.schema.json` — manifest-derived payload accounting evidence contract.
- `build-run.schema.json` — isolated profile-packaging timing evidence contract.
- `measurement-run.schema.json` — raw active-browser run contract.
- `desktop-summary.schema.json` — derived Linux desktop distribution contract.
- `phase9-metric-definitions.json` — clocks, boundaries, sample policy, budget
  links, and deferred qualification boundary.
- `phase9_metrics.py` — deterministic nearest-rank statistics and raw sample
  validation.
- `run_phase9_build.py` — isolated dependency-cached profile packaging timer.
- `run_phase9_artifacts.mjs` — manifest-driven decoded and deterministic Brotli
  payload accounting.
- `summarize_phase9.py` — fail-closed raw-evidence validator and deterministic
  nearest-rank desktop summary generator.
- `benchmark-index.json` — canonical environment/measurement/sample/report index.
- `environments/`, `samples/`, `raw-evidence/`, and `reports/` — future evidence locations.
- `environments/bh01-phase8-local-linux.json` — exact local Linux/Chrome
  fingerprint for the available Phase 8 required row.
- `raw-evidence/bh01-phase8-environment-inventory.json` — browser binary,
  automation, host, and unavailable-environment inventory.
- `tests/test_phase9_metrics.py` — positive and fail-closed metric tests.
- `environments/bh01-phase9-linux-*.json` — exact build, Chrome, and Firefox
  development fingerprints.
- `raw-evidence/bh01-phase9-*.json` — retained browser, build, and artifact
  distributions.
- `samples/bh01-phase9-linux-desktop-summary.json` — generated active-matrix
  statistics, adequacy, variance flags, and deferred second-machine comparison.
