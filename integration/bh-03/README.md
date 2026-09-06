# BH-03 Browser Host Integration

This directory owns cross-boundary fixtures and evidence for browser runtime
discovery, startup, shared runtime ownership, independent roots, shutdown,
failure, fallback, and resource behavior.

Phase 2 adds pure pre-acquisition contract fixtures for compatibility,
discovery, prerequisites, and manifest validation. They contain no browser
result, artifact bytes, runtime result, root result, failure-execution result,
measurement, or acceptance evidence. Later content requires separate phase
authorization.

Versioned records:

- `integration-index-v0.1.0.json` — immutable Phase 1 activation index.
- `integration-index-v0.2.0.json` — Phase 2 fixture index with empty execution
  result sets.
- `phase-02/` — Phase 2 pre-acquisition contract fixtures.
