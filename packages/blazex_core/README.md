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

## Phase 7 opt-in scheduling

`BlazeX.Component.ScheduledView` opts a root into typed, capability-bound ingress.
`RootSchedule` owns immutable FIFO admission, explicit tail coalescing and the
256-work ceiling (including active and candidate-reserved work). `SchedulingPort`
keeps semantic binding admission/evaluation outward. Default LocalView behavior
remains unchanged; scheduled roots reject unsequenced legacy update calls.

Typed callback messages and owned timers are commit-bound. Timer cancellation,
replacement, shutdown and `ScheduledView.runtime_loss/2` bypass application work;
late ticks and acknowledgements cannot restore canceled candidates. Inspection
reports bounded queue metrics and a payload-free timer inventory. Effects,
provider results and remote commands remain deferred to their later phase.

`BlazeX.Component.RootPort` validates schema-normalized root start records,
identity-only handles, complete renderer correlations and integrity-bound
candidate summaries. Its Evaluator, Renderer and Host behaviours are outward
implementation seams; private tokens/configuration never reach components.
General effect/command execution and support claims remain deferred.

## Phase 8 explicit typed-action roots

`ActionView.start/6` takes the ordinary root ports/scheduler policy plus a closed
`ActionManifest` and runtime-private `ActionPort`. `Action.new/5` constructs closed
portable records; action-enabled roots reject legacy generic tuples. `Action.result/4`
constructs correlated provider outcomes for runtime delivery through `ActionView.result/3`.
Requests submit only after renderer commit and reserve terminal-result capacity
inside the existing 256-work bound. No concrete provider or server transport is
part of Core. Static manifest metadata is available for future build/command
registration; it grants no server authority.

`BlazeX.Component.LocalView` starts independently supervised roots through
`LocalView.Supervisor`, admits one candidate at a time, and exposes identity-only
handles for update, replacement, acknowledgement, stop and redacted inspection.
Temporary guardians retain terminal metadata without replaying crashed work.

Portable callback code constructs Phase 8 records through `BlazeX.Component.Result.action/5`,
which delegates to `Action.new/5` without expanding the frozen compiler allowlist.
Resource references contain only an opaque ID and acquisition correlation; provider
objects remain private. Leases are limited to 512, requests to 128, and every command
remains untrusted. Cleanup is bounded and must be idempotent across crash uncertainty.

## Phase 9 scoped context and component registry

`ScopedContext` validates explicit public provider/consumer grants, resolves the
nearest same-root/generation provider or declared default, and retains immutable
dependency snapshots. Fixed bindings reject change; tracked consumers invalidate
in tree order only after provider commit. Limits are 16 definitions, 32 providers
and 128 subscriptions. `ScopedView.change/5` submits generation/revision-bound
provider changes; `ScopedView.select/6` submits bounded public-ID selection.
Both use the existing scheduled root queue and reserve follow-up capacity.

`ComponentRegistry.new/2` composes explicit compile/package/root entry lists.
Only already-loaded declared modules qualify; public lookup checks stable ID,
role, schema, allowed targets and registry generation. Exported metadata strips
module names and retains declaration hashes for later BH-06 analysis. There is
no dynamic atom creation, arbitrary module loading, global context, server auth,
bundle generation or Wasm execution claim. See the
[scope contract](../../docs/research/60-planning/01-browser-host/bh-05-component-programming-model-and-lifecycle/scope-contract.md).
