# BH-05 fixed browser conformance fixture

This non-public Mix project packages the Phase 11 public component corpus for
the pinned Popcorn/AtomVM browser runtime. It is a fixed qualification fixture,
not a general build or reachability system. Host transport lives in `Browser`;
the components contain no browser, DOM, Popcorn, Phoenix, LiveView, or runtime
conditional semantics.

Phase 12 adds a private count-measurement module and runner to this pinned
fixture. The 20-sample quantitative series remains the controlled ERTS
reference; Chrome and Firefox each execute one exact-bound AtomVM observation.
