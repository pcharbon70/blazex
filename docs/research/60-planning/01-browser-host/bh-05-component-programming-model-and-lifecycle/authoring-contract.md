---
title: "BH-05 candidate authoring contract"
kind: note
created: "2026-09-09"
maturity: developing
tags: [bh-05, authoring, component-model]
aliases: []
---

# BH-05 candidate authoring contract

Implements the [Phase 2 plan](phase-02-component-roles-authoring-facade-and-callback-algebra.md)
under the [host-neutral kernel decision](../../../20-notes/architecture-decisions/adr-0001-host-neutral-semantic-component-kernel.md).

## Authority and compatibility

Phase 2 follows accepted Phase 1 merge `968013b9794664fc454619ee08788c3d0c39551f`.
The owner explicitly requested the next phase, one commit per section, one PR,
merge, checkout main, sync origin, then branch deletion. The synchronized branch
is `codex/bh05-phase2-authoring`. Unrelated root README/demo work is stashed.
The [authority record](../../../assets/bh-05-baseline/authoring-authorization-v0.1.0.json)
hash-binds the inherited kernel, semantic baseline, ADR-0001 and runtime pins.
The existing BH-02 evaluator and callback API remain unchanged and experimental.

Public candidate namespaces are `BlazeX.Component` (declaration macro),
`BlazeX.Component.Pure`, `.Stateful`, `.Root` (behaviours),
`.Input`, `.Result`, and `.Contract` (portable contract validation/introspection).
`BlazeX.Core.Authoring` is build-time private implementation. Application code
uses the facade and semantic UI-tree builders, not private evaluator modules.
`use BlazeX.Component, role: ...` selects exactly one behaviour and generates
literal `__blazex_component__/0` metadata; it does not start or register anything.
Compilation checks declarations and exports; result validation is explicit,
not a claim that arbitrary Elixir callback code is sandboxed or deterministic.

Version `0.1.0-bh05-candidate` is not stable. Breaking changes require a new
version, migration note and re-run of fixture/subset gates; never silently
reinterpret existing metadata. Runtime reflection is limited to generated
literal metadata. Compiler reflection is build-only; registry resolution is
Phase 9. Runtime and renderer adapters remain replaceable consumers.

Modules, pattern matching, explicit inputs and `mount`, `update`, `handle_event`,
`handle_info`, `render` names are Elixir/Phoenix-familiar vocabulary only.
There is no socket, mutable assigns, mutable instance/reference handle,
arbitrary callback registration, `StateHasChanged`, dependency injection,
Razor, HEEx, or nested render-mode switch. LiveView and LocalLiveView integration
remain explicitly deferred outside this host implementation.

Phase 2 excludes prop/slot schema execution, composition/state retention,
process startup, event/effect execution, renderer changes, forms and support
claims. Declarations and typed intent are not authority to execute effects.
ERTS compilation and pinned Popcorn/AtomVM compiler/analyzer checks are not
runtime execution parity; that gate remains Phase 11.

## Delivery

## Roles and lifecycle ownership

All callbacks are arity one. `Contract.callbacks/1` is the authoritative closed
inventory and records required versus optional callbacks. Pure requires only
`render`; stateful requires `init` and `render`; root requires `mount` and
`render`. There are no generated lifecycle defaults or arbitrary callback hooks.

Pure evaluation is deterministic by contract, caller-owned, without retained
state or mailbox; failures belong to the owning root. A nested stateful unit
initializes, receives prop `update`, local `handle_event`/`handle_info`, renders,
is replaced, and disposes under its root scheduler. Module declaration plus
root/path/generation identifies an instance; keys preserve identity and
replacement advances generation. The nested unit shares its root's process,
transition, failure, effect/resource and renderer commit boundaries. It cannot
hold a PID, mutable reference, independent supervision or renderer root.

Only the root role declares an independent process/mailbox, root identity,
generation, revision, admission sequence, scheduler, renderer ownership,
fallback and supervised retry boundary. Its `mount`, host-prop `update`,
`handle_event`, `handle_info`, `render`, `commit_ack`, `effect_result`, `failure`,
`retry`, `replace` and `terminate` transitions are vocabulary, not execution.
Generation/revision/sequence correlate portable lifecycle messages with host
admission; no host object crosses this boundary. Resources and effects belong
to that root generation. Root termination disposes the entire owned subtree.
No transferred server process, nested render mode or direct browser access is
part of any role. Phase 6 supplies root execution; Phases 7–10 supply scheduling,
effects, context and recovery semantics.

## Delivery status

Sections 2.1–2.4 are separate commits. Completion and exact gate evidence will
be indexed here after execution. Phase 3 remains unauthorized until requested.
