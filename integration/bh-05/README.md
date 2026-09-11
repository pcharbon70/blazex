# BH-05 component-model evidence

The retained Phase 1 record activates governance only. Its [index](index-v0.1.0.json)
conforms to its closed [schema](index.schema.json); all fourteen evidence
classes are empty. No callbacks, macros, processes, fixtures, measurements or
passing component results are implemented here.

The [ownership record](../../docs/research/assets/bh-05-baseline/ownership-v0.1.0.json)
assigns portable contracts to Core, semantic output to UI Tree, capabilities
and leases to Effects, and shared assertions to Test. Runtime and renderer
adapters are consumers, not component-model owners. LiveView/LocalLiveView
remain deferred; server authority and BH-06 implementation remain out of scope.

Run `python3 docs/research/70-tools/generate_bh05_boundary.py --check` from the
accepted Phase 1 checkout. Activation does not count as runtime conformance or support.

Phase 2 adds a separate [candidate authoring index](authoring-index-v0.1.0.json),
preserving the empty historical record. Only facade contract evidence is active;
schemas, processes, scheduling, effects, runtime parity and acceptance remain
unimplemented here.

- [Three valid declarations](authoring-fixtures.exs): all required/optional callbacks.
- [Compile integration gate](authoring-check.exs): exact metadata, warning-free valid
  fixtures and rejected host/private/server/compatibility declarations.
- [Pinned subset gate](authoring-subset.exs): Core Erlang reader/analyzer and
  compiler roundtrip using authenticated Popcorn 0.3.3 sources. No execution parity.

Current command: `python3 docs/research/70-tools/validate_bh05_authoring.py --final`.
The source-frozen runner and individual checks are indexed under research tools.

Phase 3 adds the [schema inventory](schema-index-v0.1.0.json),
[public schema fixtures](schema-fixtures.exs),
[schema/codec integration checks](schema-check.exs) and
[compiler-roundtrip comparison](schema-subset.exs). Earlier indexes remain
historical. Props/slots normalize without component or slot body execution;
host/local boundaries, redaction, ownership and atomic invalid updates are tested.
Phase 3 completion check at its accepted snapshot: `python3 docs/research/70-tools/validate_bh05_schema.py --final`.

Phase 4 adds [public pure composition fixtures](composition-fixtures.exs) and a
[source/digest inventory](composition-index-v0.1.0.json). The
[conformance test](../conformance/test/bh05_composition_test.exs) executes nested
pure controls and contextual slots and compares complete output with an
independently authored headless oracle using public constructors. Runtime state,
effects, renderer execution by components and Wasm parity remain out of scope.
Phase 4 check at its accepted snapshot: `python3 docs/research/70-tools/validate_bh05_composition.py --final`.

Phase 5 adds [public nested fixtures](nested-fixtures.exs), a
[state/trace inventory](nested-index-v0.1.0.json) and
[nested conformance tests](../conformance/test/bh05_nested_test.exs). Keyed state,
local event candidates, notification/disposal plans and complete semantic output
reconcile atomically under one future root process/failure boundary. No process,
external message, effect or renderer commit occurs. Current check:
`python3 docs/research/70-tools/validate_bh05_nested.py --final`.

- [Root lifecycle fixtures](root-fixtures.exs) — Public root and nested components with an independent semantic oracle.
- [Root lifecycle index](root-index-v0.1.0.json) — Root API, source hashes, normalized trace/state digests and qualification limits.

- [Scheduling fixtures](scheduling-fixtures.exs) — Typed root/child callbacks, test-owned graph snapshots and independent semantic oracle.
- [Scheduling index](scheduling-index-v0.1.0.json) — Phase 7 queue bounds, source hashes, raw samples, outcome digests and limitations.

Current Phase 7 check: `python3 docs/research/70-tools/validate_bh05_scheduling.py --final`.
Earlier phase checks run at their accepted frozen snapshots.

- [Action fixtures](action-fixtures.exs) — Portable typed-action components, deterministic abstract providers and independent semantic oracle.
- [Action index](action-index-v0.1.0.json) — Phase 8 inventory, raw pending/lease samples, hashes and limits.

Phase 8 successor check: `python3 docs/research/70-tools/validate_bh05_actions.py --final`.

- [Scope fixtures](scope-fixtures.exs) — Public scoped root, stateful/pure registry targets, contextual slot and independent headless oracle.
- [Scope index](scope-index-v0.1.0.json) — Phase 9 source inventory, bounds and twelve retained/new normalized digests.

Phase 9 successor check: `python3 docs/research/70-tools/validate_bh05_scopes.py --final`.
Earlier phase validators replay their frozen accepted revisions; they do not
grant current-source evidence for authorized successor changes.
Phase 7 and earlier validators remain frozen and run at accepted snapshots.

- [Recovery fixtures](recovery-fixtures.exs) — Public failure injection, independent headless fallback and provider cleanup.
- [Recovery index](recovery-index-v0.1.0.json) — Phase 10 source inventory, bounds and fifteen normalized digests.

Current successor check: `python3 docs/research/70-tools/validate_bh05_recovery.py --final`.
- [Conformance corpus](conformance-corpus-v0.1.0.json) — Phase 11 public application sources, scenario coverage and normalization model.
- [Local conformance](local-conformance-v0.1.0.json) — Reproducible ERTS/headless, Chrome/Firefox DOM and GTK portability observations.
- [Browser conformance](browser-conformance-v0.1.0.json) — Fixed AVM bundle results, exact Chrome/Firefox trace comparison and runtime identities.
- [Fixed browser fixture](browser_conformance/README.md) — Phase 11-only packaging and browser host adapter; not a general build system.
- [Phase 12 count measurement report](acceptance-counts-v0.1.0.json) — Backlog, pending-effect, lease and restart outcomes.
- [Phase 12 raw count evidence](acceptance-counts-raw-v0.1.0.json) — ERTS samples, browser observations and retained failed trials.
- [Phase 12 cleanup report](acceptance-cleanup-v0.1.0.json) — Passing ERTS cleanup/process budgets and failure gates, plus the active Firefox revise decision.
- [Phase 12 raw cleanup evidence](acceptance-cleanup-raw-v0.1.0.json) — 100 cleanup samples, ten 100-cycle process samples, browser terminal inventories and retained failures.
- [Phase 12 acceptance reconciliation](../../docs/research/assets/bh-05-baseline/acceptance-reconciliation-v0.1.0.json) — Nine outcomes and nine review lenses retaining the active Firefox blocker.
- [Phase 13 cleanup scaling schema](cleanup-scaling.schema.json) — Closed execution/acceptance, terminal-identity, amplification, timing, runtime and raw-hash evidence shape.
- [Phase 13 append-only attempt ledger](cleanup-scaling-attempts-v0.1.0.json) — Every aborted, failed, and passing corrective probe retained without relabeling or deletion.
- [Phase 14 compact cleanup schema](compact-cleanup.schema.json) — Closed page-proportional outcome-summary shape with exact identity count and zero timed-path diagnostic expansion.
- [Phase 14 append-only attempt ledger](compact-cleanup-attempts-v0.1.0.json) — Canonical corrections, bounded full-matrix stall, and isolated maximum-payload results without relabelling Phase 13 evidence.
- [Phase 15 runtime-owned resource inventory schema](resource-inventory.schema.json) — Bounded acquisition-time registration, compact disposal requests, inventory convergence, and explicit byte-instrumentation availability.
