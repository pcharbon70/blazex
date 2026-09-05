# BH-01 Reproducibility Evidence

This directory owns Phase 10 clean-rebuild execution records, comparison
reports, schemas, and validators. The two required clean executions begin from
the same exact Git archive in distinct source trees with distinct empty Hex,
Mix, npm, build, and generated-output state. They use immutable container,
Node, and browser identities.

Both executions currently share one physical Linux host. They establish
independent clean execution contexts and detect hidden checkout/cache state;
they do not establish cross-machine, cross-operating-system, mobile, or
browser-product support. Those unavailable qualifications remain deferred to
BH-22.

Run one environment with `run_clean_rebuild.py`, then compare both retained
records with `compare_clean_rebuilds.py`. The runner performs locked network
acquisition first and uses network-disabled build/test steps afterward. It
rebuilds all three Wasm runtime modes, the browser fixture AVM, and the static
profile; runs package and browser suites; regenerates the seven Phase 9 reports;
and proves stale-artifact rejection followed by a clean restore.

The browser fixture is always mounted at `/workspace` inside the immutable BEAM
container. The first Phase 10 attempt proved that a checkout-relative mount
leaks a dependency source path into one Jason macro module even after BEAM line
chunks are removed. `raw-evidence/bh01-phase10-clean-a-attempt-1.json` preserves
that stopped attempt. Attempts 2 and 3 record independent server-log
finalization and command-hash assignment defects found only after all browser
scenarios completed. The authoritative A/B records prove all corrections under
fresh execution contexts.

`close_phase10_ledgers.py` derives the canonical closure record from the
original BH-01 milestone ledger and retained Phase 4–10 evidence. It preserves
all identities, owners, proof requirement links, conditions, deferrals,
findings, and zero exceptions. `--check` rejects a stale or edited view.

`conduct_phase10_reviews.py` materializes eleven discipline-separated review
lenses, nine owned conditions, and six candidate-stack alternatives. It binds
the review to the exact closure-ledger hash and rejects missing challenges,
unknown conditions, stale evidence, support promotion, or implicit BH-02
authorization.

`version_phase10_baseline.py` freezes the reviewed candidate, validates every
source and dependency hash, and generates the eight navigable indexes under
`docs/research/assets/bh-01-release`. Its supersession policy preserves prior
evidence and invalidates affected proofs on any governed identity change.
