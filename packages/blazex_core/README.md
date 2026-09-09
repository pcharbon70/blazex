# BlazeX Core

BH-05 Phase 5 adds `BlazeX.Component.NestedTable`, the immutable accepted
root/revision/sequence and instance-record contract. It validates portable state,
identity/parent ownership and integrity digests without depending on UI Tree or
a renderer. Semantic acceptance and in-memory candidate orchestration belong to
`BlazeX.UITree.Nested`. There is no process startup, mailbox or effect execution.

Defines the host-neutral component programming model: component behaviours,
lifecycle, stable identity, state transitions, semantic events, commands, and
the contracts used to evaluate a component tree.

This package must not depend on Phoenix, Plug, DOM or JavaScript types,
Popcorn/AtomVM, or any native UI toolkit. It is the innermost dependency of the
framework.

Status: experimental BH-02 Phase 2 implementation. Structural identity,
bounded portable props/state, evaluation context, pure/stateful mount and
update, replacement generations, and stable diagnostics are implemented.
BH-02 Phase 3 adds semantic events and stateful dispatch. Effects remain in
their dedicated package; process lifecycle, messages, commands, disposal, and
stable public APIs remain deferred.

## BH-05 Phase 1 activation

Governance only: existing experimental behavior is preserved, with no new
BH-05 callbacks, facade, process or support claim. Package ownership and API
migration decisions are recorded in `docs/research/assets/bh-05-baseline`.
Runtime/host profiles consume neutral contracts; LiveView and LocalLiveView
integration remain explicitly deferred.

## BH-05 Phase 2 candidate facade

`use BlazeX.Component, role: :pure | :stateful | :root` declares a candidate
behaviour and literal metadata. `BlazeX.Component.Input` and `.Result` validate
closed portable envelopes without invoking callbacks or committing state.
`BlazeX.Core.Authoring` is private build-time machinery; no new dependencies.
The inherited evaluator is unchanged. Schema execution, state retention,
processes, effects, context resolution, runtime parity and stable APIs remain
deferred. See the authoring contract in the BH-05 planning directory.

## BH-05 Phase 3 schema candidate

Opt into `schema: [props: [...], slots: [...]]` in the facade declaration to
emit version `0.2.0-bh05-schema-candidate`; legacy declarations are unchanged.
`BlazeX.Component.Schema`, `.Props`, `.Slots` and `.Invocation` supply bounded
schema validation, JSON-compatible wire terms, caller-owned slot descriptors
and atomic invocation updates. No component/slot body is executed. Local-only
callables never cross host/persistence/command/renderer boundaries. Custom
schemas are versioned declarative aliases, not executable validators.
Schema normalization does not retrofit the BH-02 evaluator: Phase 4 owns
evaluation admission. Process execution and runtime parity remain deferred.
# Phase 6 candidate root ports

`BlazeX.Component.RootPort` validates schema-normalized root start records,
identity-only handles, complete renderer correlations and integrity-bound
candidate summaries. Its Evaluator, Renderer and Host behaviours are outward
implementation seams; private tokens/configuration never reach components.
Root action execution and support claims remain deferred.

`BlazeX.Component.LocalView` starts independently supervised roots through
`LocalView.Supervisor`, admits one candidate at a time, and exposes identity-only
handles for update, replacement, acknowledgement, stop and redacted inspection.
Temporary guardians retain terminal metadata without replaying crashed work.
