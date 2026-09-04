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
- `prerequisite-matrix.json` — required-row and non-substituting engine-probe
  prerequisite/lifecycle outcomes.
- `verify_prerequisites.py` and `tests/test_prerequisites.py` — retained raw-
  evidence, no-partial-activation, and mutation checks for Section 8.2.
- `behavior-trust-matrix.json` — normalized behavior, server trust, optional-
  adapter, resilience, diagnostic, and cleanup outcomes for Section 8.3.
- `verify_behavior_trust.py` and `tests/test_behavior_trust.py` — semantic-
  equivalence, authority, no-substitution, and resource-convergence checks.
