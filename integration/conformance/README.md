# Conformance

Contains cross-runtime, cross-renderer, and cross-profile contract suites. These
tests will verify that supported implementations agree on lifecycle, tree
updates, event ordering, capability negotiation, errors, and disposal.

The headless implementation provides a deterministic oracle where appropriate;
host-specific behavior is tested against explicit capability contracts rather
than assumed equivalence.

During BH-02, the bounded `experiments/native_renderer_spike` participates in
the same semantic traces as the headless and DOM renderers. Its presence in the
matrix supplies portability evidence without turning the experiment into a
supported backend.

Status: BH-02 Phase 3 contains versioned semantic-kernel and
event/effect/resource fixture sets with local BEAM evaluation outcomes. No
concrete provider or renderer backend has executed these fixtures, so provider
and renderer conformance and all support claims remain absent.

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
