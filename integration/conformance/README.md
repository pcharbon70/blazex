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

Status: BH-02 Phase 5 adds a versioned renderer/headless fixture set with local
BEAM lifecycle, canonical snapshot, and trace outcomes. This is a deterministic
nonvisual oracle only. No geometry engine, visual backend, platform
accessibility mapping, browser, or native-control result exists, and all
support claims remain absent.

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
