# BlazeX UI Tree

Defines the versioned semantic UI tree exchanged between component evaluation
and renderer backends. Its vocabulary will cover semantic nodes, layout,
styling tokens, accessibility, resources, identity, and incremental changes.

The representation must describe intent without embedding HTML, CSS, DOM, or
native-toolkit objects. Renderer-specific lowering belongs in renderer
packages. The tree may refer to opaque resource identities, but effect and
resource lifecycle belongs to `blazex_effects`.

Status: experimental BH-02 implementation. Version-1 nodes, structural
identity checks, sibling uniqueness, ancestry validation, and deterministic
preorder traversal are implemented. Component output is accepted atomically
only when the complete tree is valid and its root identity matches the Core
evaluation. BH-02 Phase 3 adds semantic documents and validated event bindings
without adding concrete input callbacks. BH-02 Phase 4 adds renderer-independent
token references, logical layout, accessibility roles/states/relationships,
focus participation/restoration, controlled selection, and a composed intent
set without calculating geometry or invoking a platform API. Stable public
APIs remain deferred.

## BH-05 Phase 1 activation

Governance only: existing experimental behavior is preserved, with no new
BH-05 callbacks, facade, process or support claim. Package ownership and API
migration decisions are recorded in `docs/research/assets/bh-05-baseline`.
Runtime/host profiles consume neutral contracts; LiveView and LocalLiveView
integration remain explicitly deferred.

## BH-05 Phase 4 pure composition

`BlazeX.UITree.Composition.evaluate(root, generation, reference, graph, boundary,
capabilities)` accepts trusted build-authored graphs of schema-aware pure
components. It plans the whole bounded graph before invoking callbacks, then
accepts one complete `IntentSet` through existing constructors. A failure returns
only a redacted diagnostic. Graph keys, lexical slots, ordering and traces are
deterministic; no state, effects or renderer execution is introduced.

See the [contract](../../docs/research/60-planning/01-browser-host/bh-05-component-programming-model-and-lifecycle/composition-contract.md)
and [public example](../../integration/bh-05/composition-fixtures.exs).
The implementation does not sandbox arbitrary Elixir or claim Wasm parity.
