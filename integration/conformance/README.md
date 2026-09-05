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

Status: activated as a BH-02 Phase 1 evidence boundary. The versioned index is
empty: no semantic fixture, canonical trace, backend result, or support claim
exists yet.
