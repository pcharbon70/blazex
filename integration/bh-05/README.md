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
