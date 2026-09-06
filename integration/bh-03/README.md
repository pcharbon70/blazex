# BH-03 Browser Host Integration

This directory owns cross-boundary fixtures and evidence for browser runtime
discovery, startup, shared runtime ownership, independent roots, shutdown,
failure, fallback, and resource behavior.

Phase 2 adds pure pre-acquisition contract fixtures for compatibility,
discovery, prerequisites, and manifest validation. Phase 3 adds verified-byte
and injected-transport startup conformance fixtures. Phase 4 adds
injected-transport conformance fixtures for exact-compatible runtime sharing
and independent root queues. Phase 5 adds injected-transport shutdown,
generation-loss, same-handle replay, and non-DOM fallback conformance. Phase 6
adds the separate Phoenix `/bh03/` profile, one cross-browser scenario fixture,
and observed active Linux Chrome/Firefox results. Measurement and acceptance
result sets remain empty. Later content requires separate phase authorization.

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
- `integration-index-v0.5.0.json` — Phase 5 shutdown, recovery, and fallback
  unit-conformance index with browser and measurement result sets empty.
- `phase-05/` — Phase 5 injected-transport resilience fixtures.
- `integration-index-v0.6.0.json` — Phase 6 active Chrome/Firefox browser-
  profile conformance index with measurement and acceptance results empty.
- `phase-06/` — Phase 6 browser-profile and active-matrix fixtures.
