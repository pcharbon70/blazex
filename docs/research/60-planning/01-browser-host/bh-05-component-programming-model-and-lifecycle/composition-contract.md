---
title: "BH-05 pure composition contract"
kind: note
created: "2026-09-09"
maturity: developing
tags: [bh-05, composition, semantic-ui]
aliases: []
---

# BH-05 pure composition contract

Implements the [Phase 4 plan](phase-04-pure-composition-and-atomic-semantic-evaluation.md)
under [ADR-0002](../../../20-notes/architecture-decisions/adr-0002-versioned-semantic-ui-tree.md).

## Authority and boundary

Synchronized base is `fc5048d4db7cc80fd21b492e0638182abceda1af` (Phase 3).
The owner requested four verified section commits, one PR, merge, checkout main,
sync origin, then deletion of `codex/bh05-phase4-composition`. The
[authority record](../../../assets/bh-05-baseline/composition-authorization-v0.1.0.json)
binds pure role, schema normalization, identity and semantic validators. No old
contract or historical record is rewritten. Composition is UI-tree-owned;
Core does not gain a renderer or UI-tree dependency.

## Explicit invocation graph

`BlazeX.UITree.Composition` consumes a trusted, build-authored finite graph of
static module references, not a host-supplied dynamic component registry. Each
record names a public ID, call-site ID, explicit sibling key, props, slots and
ordered child graph references. All component records must use the schema-aware
pure facade. The graph is normalized in full before any render callback runs.
Unreachable records, cycles, unknown references and duplicate derived identities
are errors. A graph record may be reused in different branches; no memoization
or callback skipping occurs.

Every invocation contributes exactly one semantic node. Nested semantic nodes
use child invocations, keeping child identity known before execution. Callbacks
return the existing `{:output, {:semantic, 1, map}}` candidate with node kind,
optional text and declarative binding/presentation intent. Callback-supplied
children, explicit identities, resources, commands or host fields are rejected.
Graph children are followed by slots in declaration order and entries in input
order. A local slot content ID references a static graph record; its caller must
match the receiving record's public lexical owner and its root must match the
validated boundary. Host slots expand inert semantic data, never executable IDs.
Slot entry props and a declared `context` prop bind contextual data to local
content records; their complete invocation is schema-validated before execution.

Root identity is the supplied root/generation with empty path. Child identity
adds one composite key containing public ID, call site, slot name and explicit
key. This preserves strict semantic parent ancestry. Inline host slot data adds
one slot/key segment. Ordinal keys are stable by position only. Root generation
is never assigned randomly. Limits are 12 levels, 128 callback invocations and
256 semantic nodes; limits are checked in planning, before callbacks.

## Evaluation and acceptance

Callbacks run parent-first in deterministic graph/slot order with normalized
props, slots and portable identity/context metadata. No state or effects are
admitted. Callback exceptions, throws and exits become fixed redacted failures.
Pure modules remain trusted build code subject to the existing dependency audit,
not an adversarial Elixir sandbox or a proof of termination. No process-based
isolation, callback timeout or side-effect rollback is claimed in this phase.

Node, Document, Binding and IntentSet constructors own semantic acceptance.
Bindings belong to the shared root; there is no independent pure-child event or
failure boundary. Layout, accessibility, focus and selection use closed neutral
constructors. Relationship references are derived identity paths, resolved only
against the complete tree. Unknown capabilities and opaque/effect resource
references are rejected; there is no effect execution. A failed descendant or
whole-tree validation returns no candidate tree or invocation records.

Canonical traces contain public enter/exit, slot expansion, node acceptance,
callback rejection/failure and final digest observations only. No raw props,
state, module-private names, exceptions, clocks, PIDs or renderer data appear.
SHA-256 uses deterministic term encoding of accepted semantic output/trace on
ERTS; cross-runtime encoding/parity remains Phase 11. A headless oracle is used
only in conformance tests, never by the composition implementation.

## Deferrals

State retention, root processes, scheduling, messages, effects, dynamic registry,
renderer execution, HEEx/DOM and stable/support claims remain out of scope.
LiveView and LocalLiveView integration remain explicitly deferred. Any future
optimization or broader output/composition form requires versioned change control
and identical acceptance/trace evidence or a separately authorized successor.
