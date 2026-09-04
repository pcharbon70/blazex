# BH-01 Browser Matrix Fixtures

This directory owns disposable Phase 8 browser-environment, scheduling,
prerequisite, behavior, fallback, and compatibility matrix contracts. Required
browser rows remain present when unavailable and use `environment-blocked`;
engine emulation and non-vendor builds never substitute for a required row.

- `environment-catalog.json` — five required browser rows and bounded local
  engine probes.
- `matrix-policy.json` — scheduling, retry, quarantine, evidence, and result
  governance.
- `verify_environments.py` and `tests/test_environments.py` — static and
  mutation validation for Section 8.1.
