# Conformance

Contains cross-runtime, cross-renderer, and cross-profile contract suites. These
tests will verify that supported implementations agree on lifecycle, tree
updates, event ordering, capability negotiation, errors, and disposal.

The headless implementation provides a deterministic oracle where appropriate;
host-specific behavior is tested against explicit capability contracts rather
than assumed equivalence.

BH-05 Phase 4 adds [pure composition conformance](test/bh05_composition_test.exs),
using [public fixtures](../bh-05/composition-fixtures.exs). Its independent oracle
covers all seven semantic kinds, complete presentation intent and bindings;
contextual slots and exact graph bounds have deterministic replay tests. This
is ERTS/headless evidence only, not browser AtomVM execution parity.

BH-05 Phase 5 [nested-state conformance](test/bh05_nested_test.exs) uses
[public fixtures](../bh-05/nested-fixtures.exs) for retained state, local events,
keyed permutations, parent-scope removal/insertion, disposal, overflow and an
independent headless oracle. Repeated script and final-state digests are bound
in the [nested inventory](../bh-05/nested-index-v0.1.0.json).

During BH-02, the bounded `experiments/native_renderer_spike` participates in
the same semantic traces as the headless and DOM renderers. Its presence in the
matrix supplies portability evidence without turning the experiment into a
supported backend.

Status: BH-02 Phase 8 accepts the bounded headless/DOM/native semantic matrix
as an internal versioned contract baseline and reproduces the direct GTK 4 run
on local Linux under Xvfb. This remains experimental development evidence only.
Windows and macOS execution, incremental DOM reconciliation, hydration,
geometry, pixels, visual equivalence, manual accessibility conformance, and
support claims remain absent or explicitly deferred.

Versioned records:

- `conformance-index-v0.1.0.json` — immutable Phase 1 empty activation index.
- `semantic-kernel-fixtures-v0.1.0.json` — Phase 2 semantic-tree, identity,
  and evaluation scenarios with expected outcomes.
- `conformance-index-v0.2.0.json` — Phase 2 fixture/result index; renderer
  results remain empty.
- `event-effect-resource-fixtures-v0.1.0.json` — Phase 3 semantic dispatch,
  capability negotiation, effect lifecycle, and resource ownership scenarios.
- `conformance-index-v0.3.0.json` — Phase 3 local contract-result index;
  concrete provider and renderer results remain empty.
- `presentation-intent-fixtures-v0.1.0.json` — Phase 4 token, layout,
  accessibility, focus, selection, and atomic-validation scenarios.
- `conformance-index-v0.4.0.json` — Phase 4 local intent-result index; geometry,
  platform mapping, and renderer results remain empty.
- `renderer-headless-fixtures-v0.1.0.json` — Phase 5 negotiation, lifecycle,
  normalization, trace, coordination, and rejection scenarios.
- `conformance-index-v0.5.0.json` — Phase 5 local deterministic-headless result
  index; visual, geometry, browser, and native results remain empty.
- `mix.exs` and `test/` — Phase 6 executable headless/DOM semantic parity and
  lifecycle conformance suite.
- `dom-renderer-fixtures-v0.1.0.json` — Phase 6 lowering, browser behavior,
  lifecycle, rejection, isolation, and parity scenarios.
- `dom-browser-matrix-v0.1.0.json` — exact local Linux Chrome and Firefox
  executable versions and automated page-conformance outcomes.
- `conformance-index-v0.6.0.json` — Phase 6 local standalone-DOM result index;
  visual, pixel, manual-accessibility, and native results remain empty.
- `native-control-fixtures-v0.1.0.json` — Phase 7 native projection,
  headless/DOM/native parity, direct GTK execution, and governed platform
  deferral scenarios.
- `conformance-index-v0.7.0.json` — Phase 7 local native-spike index with one
  passing GTK development row and explicit Windows/macOS deferrals.
- `conformance-index-v0.8.0.json` — Phase 8 accepted internal experimental
  baseline with final reproduction counts, declared exceptions, and BH-03
  eligibility without authorization.

- [BH-05 root lifecycle tests](test/bh05_root_test.exs) — Supervised final-state commit correlation, independent headless parity, rollback and cleanup failure.
- [BH-05 scheduling tests](test/bh05_scheduling_test.exs) — Typed local messages/events, multi-root fairness, nested timer removal and retained 256-work overload traces.

- [BH-05 action integration](test/bh05_actions_test.exs) exercises real portable
  callbacks, capability adapters and headless sessions, including 128 pending
  requests, 512 leases, nested ownership, stale results and untrusted command denial.
