# Benchmarks

Contains repeatable benchmarks and recorded baselines for WebAssembly and asset
payloads, startup latency, memory, event-to-paint latency, server round trips,
tree updates, and representative component workloads.

Benchmarks should name the runtime, host, renderer, profile, build mode, and
environment so results remain comparable over time.

Phase 1 activation added governed indexes, environment/sample schemas, and
reserved raw-evidence/report locations. Phase 8 adds one local environment
fingerprint and the exact browser inventory used to govern its compatibility
matrix. No performance benchmark has run and no budget has passed.

## Index

- `environment-fingerprint.schema.json` — build/test environment identity.
- `sample.schema.json` — immutable raw measurement sample contract.
- `benchmark-index.json` — canonical empty environment/sample/report index.
- `environments/`, `samples/`, `raw-evidence/`, and `reports/` — future evidence locations.
- `environments/bh01-phase8-local-linux.json` — exact local Linux/Chrome
  fingerprint for the available Phase 8 required row.
- `raw-evidence/bh01-phase8-environment-inventory.json` — browser binary,
  automation, host, and unavailable-environment inventory.
