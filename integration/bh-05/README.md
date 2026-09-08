# BH-05 component-model evidence

Phase 1 activates governance only. The versioned [index](index-v0.1.0.json)
conforms to its closed [schema](index.schema.json); all fourteen evidence
classes are empty. No callbacks, macros, processes, fixtures, measurements or
passing component results are implemented here.

The [ownership record](../../docs/research/assets/bh-05-baseline/ownership-v0.1.0.json)
assigns portable contracts to Core, semantic output to UI Tree, capabilities
and leases to Effects, and shared assertions to Test. Runtime and renderer
adapters are consumers, not component-model owners. LiveView/LocalLiveView
remain deferred; server authority and BH-06 implementation remain out of scope.

Run `python3 docs/research/70-tools/generate_bh05_boundary.py --check` from the
repository root. Activation does not count as runtime conformance or support.
