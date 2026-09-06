# BH-03 Browser Host Integration

This directory owns cross-boundary fixtures and evidence for browser runtime
discovery, startup, shared runtime ownership, independent roots, shutdown,
failure, fallback, and resource behavior.

Phase 2 adds pure pre-acquisition contract fixtures for compatibility,
discovery, prerequisites, and manifest validation. Phase 3 adds verified-byte
and injected-transport startup conformance fixtures. Phase 4 adds
injected-transport conformance fixtures for exact-compatible runtime sharing
and independent root queues. Browser, shutdown, recovery, measurement, and
acceptance result sets remain empty. Later content requires separate phase
authorization.

Versioned records:

- `integration-index-v0.1.0.json` — immutable Phase 1 activation index.
- `integration-index-v0.2.0.json` — Phase 2 fixture index with empty execution
  result sets.
- `phase-02/` — Phase 2 pre-acquisition contract fixtures.
- `integration-index-v0.3.0.json` — Phase 3 acquisition and isolated-startup
  conformance index with later result sets empty.
- `phase-03/` — Phase 3 verified-byte and startup protocol fixtures.
- `integration-index-v0.4.0.json` — Phase 4 shared-runtime and independent-root
  conformance index with later result sets empty.
- `phase-04/` — Phase 4 runtime registry and root lifecycle fixtures.
