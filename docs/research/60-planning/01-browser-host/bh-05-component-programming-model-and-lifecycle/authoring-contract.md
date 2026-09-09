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

## Callback inputs and result algebra

`Input.validate/1` checks an exact plain-map envelope: `role`, `transition`,
`props`, `slots`, `state`, `payload`, `root`, `identity`, `generation`, `revision`,
`sequence`, sorted unique `capabilities` and `context_keys`. Root and component
identities are `{root, path, generation}` maps, never PIDs. Counters are safe
nonnegative integers; generations are positive. Root paths are empty, nested
stateful paths are not. Pure/init/mount state is `:absent`; other state is
`{:present, prior_state}`, including explicit nil. Payload is `{:present, data}`
only for event/info, acknowledgements, effect results, failure/retry and
disposal/termination; otherwise `:absent`. This bounds portable shape, not
prop/slot/event schema semantics. Context lookup and capability authority are
not implemented. Callers must not put secrets in application data; the guard
rejects reserved host/renderer/secret fields but cannot recognize secret content.

`Result.validate/3` checks the following closed candidate forms:

| Callback | Admitted returns (all also admit `{:rejected, reason}`) |
| --- | --- |
| render | `{:output, {:semantic, 1, portable_map}}` |
| init, mount | `{:state, candidate_state}` |
| dispose, terminate | `:ok` |
| failure, retry (root only) | update forms plus `{:retry_request, reason}` |
| other declared callbacks | `:no_change`, `{:state, state}`, `{:actions, state, actions}`, `{:stop, reason}` |

The semantic tag identifies a candidate for version-1 UI-tree lowering; it is
not itself an accepted `Node`/`Document`, and does not bypass their validators.
The Core package cannot depend on UI-tree. Phase 4 owns candidate-to-tree
composition/validation, so a Phase 2 output pass is not a renderable-tree claim.
State and output never share a result tuple. Actions are 1–128 portable
`{kind, id, payload}` tuples; kind is effect/command/message/timer/release and
id is a nonempty bounded binary. This is closed typed intent, not provider,
resource or command validation or execution. Phase 8 replaces inherited generic
emissions in the executing evaluator. Retry/stop/rejection reasons are fixed
atoms in `Result`, never raw exceptions, state, messages or opaque resources.
Malformed results receive only `{code, contract}` diagnostics.

Metadata exposes contract version, role, exact exported callbacks, required and
optional sets, public-candidate/private-implementation status, and sorted unique
names declaring props/slots/capabilities/registry/context. Names are references,
not schemas or dynamic registrations. Unknown/duplicate options, missing or
extra callbacks, wrong arities, private implementation imports and dynamic
invocations fail compilation with fixed diagnostic codes. Build-only BEAM
import/opcode inspection audits compiled callback dependencies, including
aliases/imports. It is not an Elixir compile-time sandbox: trusted authors can
run macros at build time. Pattern-match maps in callbacks (unguarded dotted
access can emit Elixir dynamic remote-call helpers and is rejected). Pure
determinism remains a caller contract; this phase does not prove termination.

## Evidence status

Sections 2.1–2.4 are separate commits. Completion and exact gate evidence will
be indexed here after execution. Phase 3 remains unauthorized until requested.
