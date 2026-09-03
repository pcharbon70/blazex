# Benchmarks

Contains repeatable benchmarks and recorded baselines for WebAssembly and asset
payloads, startup latency, memory, event-to-paint latency, server round trips,
tree updates, and representative component workloads.

Benchmarks should name the runtime, host, renderer, profile, build mode, and
environment so results remain comparable over time.

Phase 1 activation adds governed empty indexes, environment/sample schemas,
and reserved raw-evidence/report locations. No benchmark has run and no budget
has passed.

## Phase 1 index

- `environment-fingerprint.schema.json` — build/test environment identity.
- `sample.schema.json` — immutable raw measurement sample contract.
- `benchmark-index.json` — canonical empty environment/sample/report index.
- `environments/`, `samples/`, `raw-evidence/`, and `reports/` — future evidence locations.
