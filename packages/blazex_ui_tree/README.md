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

## BH-05 Phase 5 nested state

`BlazeX.UITree.Nested` owns in-memory mount, reconcile and local event candidates.
Its opaque session couples a Core `NestedTable` with complete accepted semantic
output. Keyed reorder retains state; explicit incompatible replacement starts
fresh state; removals dispose deepest-first. Every rejection preserves the exact
prior session. Typed parent notifications are data only, not delivered messages.

The [nested contract](../../docs/research/60-planning/01-browser-host/bh-05-component-programming-model-and-lifecycle/nested-contract.md)
and [public fixtures](../../integration/bh-05/nested-fixtures.exs) define the bounded
API and deterministic examples. No root processes, effects or renderer commit
are introduced. Default Phase 4 pure-only composition remains unchanged.
# Phase 6 root evaluator

`BlazeX.UITree.RootEvaluator` implements the Core evaluator port for a trusted
static graph with a root-role entry and pure/stateful descendants. It returns
semantically accepted candidates without disposing prior state; cleanup is a
separate post-renderer-commit operation. Phase 4/5 defaults remain unchanged.

## Phase 7 scheduled evaluator

The same evaluator implements the outward `SchedulingPort`: committed event
bindings determine the nearest stateful owner, typed messages invoke only
declared `handle_info/1` callbacks, and candidate actions remain inert data until
Core validates and commits them. Removed instances are cleaned up only after
renderer acceptance. No process, renderer, LiveView or LocalLiveView ownership
is added to the evaluator.

Phase 8 adds `admit_action/3`: effect requests must match the actual component's
capability declarations and expose a declared result callback. Typed outcomes
use root `effect_result/1` or nested `handle_info/1`; provider execution stays
behind Core's outward action port and after renderer commit.

Phase 8 action-enabled roots require an actual component capability declaration
and a result callback: root `effect_result/1`, nested stateful `handle_info/1`.
Public manifests cannot substitute for either. Typed actions validate with the
whole candidate before provider submission; semantic and renderer commit remain separate.
