# Integration Fixtures

Contains deterministic fixture components, semantic trees, event streams,
resources, test applications, and expected results shared by conformance tests
and benchmarks.

Fixtures should be small, versioned, and independent of one test runner wherever
possible so multiple hosts can consume the same behavioral evidence.

The BH-02 headless, DOM, and native-spike implementations must consume the same
portable interaction traces from this directory.

Phase 1 activation added a governed scenario index, a scenario schema,
and reserved scenario/raw-evidence locations. Phase 3 adds only the disposable
`runtime_smoke` project used to package and probe the pinned VM. Phases 4-6 add
the disposable `browser_host` AVM, local browser behavior contracts, retained
browser evidence, and a machine-checked standalone dependency boundary. Phase
8 adds the governed `browser_matrix` without treating emulation as a device.
Production projects remain forbidden from importing this directory.

## Phase 1 index

- `scenario.schema.json` — deterministic scenario identity and expected-result contract.
- `fixture-index.json` — canonical empty scenario/raw-evidence index.
- `scenarios/` — future disposable representative behavior records.
- `raw-evidence/` — future immutable fixture execution evidence.
- `runtime_smoke/` — non-public Elixir/AVM packaging and runtime-semantics fixture.
- `browser_host/` — non-public local behavior AVM and standalone-boundary manifest.
- `browser_matrix/` — non-public Phase 8 environment, scenario, fallback, and
  compatibility matrix contracts and verifiers.
