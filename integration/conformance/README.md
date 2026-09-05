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

Status: BH-02 Phase 2 contains a versioned semantic-kernel fixture set and
local evaluation outcomes. No renderer backend has executed these fixtures,
so renderer conformance and all support claims remain absent.

Versioned records:

- `conformance-index-v0.1.0.json` — immutable Phase 1 empty activation index.
- `semantic-kernel-fixtures-v0.1.0.json` — Phase 2 semantic-tree, identity,
  and evaluation scenarios with expected outcomes.
- `conformance-index-v0.2.0.json` — Phase 2 fixture/result index; renderer
  results remain empty.
