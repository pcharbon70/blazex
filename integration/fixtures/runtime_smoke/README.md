# BH-01 runtime smoke fixture

This is a disposable, non-public feasibility fixture. It packages a small
Elixir program as deterministic debug and release AVM bundles for execution by
the pinned Phase 3 AtomVM-in-WebAssembly runtime. Its names, trace tuples, and
message shapes are test-only contracts and must not be imported by product
packages.

The fixture starts a real OTP supervisor, exchanges a bounded message with its
worker, observes a controlled worker crash and restart, fires and cancels
timers, emits a readiness record, and shuts the process tree down. Every trace
contains generation, scenario, process, sequence, result, error, and cleanup
fields.

The fixed boot module performs Popcorn-equivalent OTP/application startup but
omits Popcorn's browser readiness event. The Node probe has no browser window,
and the upstream generated glue currently rejects that event's function-valued
JavaScript expression. The limitation is retained as probe evidence rather
than hidden in product code.

Build and validate from the exact Phase 2 BEAM environment:

```console
MIX_ENV=prod mix deps.get --check-locked
MIX_ENV=prod mix compile
MIX_ENV=prod mix bh01.package --mode debug --out-dir generated/debug
MIX_ENV=prod mix bh01.package --mode release --out-dir generated/release
python3 verify_fixture.py
```

Generated bundles are ignored. `bundle-manifest.json` retains their identities,
module inventories, sizes, source policy, and package lineage.
