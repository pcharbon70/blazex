---
title: "BH-05 Phase 3 schema implementation evidence"
kind: note
created: "2026-09-09"
maturity: developing
tags: [bh-05, props, slots, implementation-evidence]
aliases: []
---

# BH-05 Phase 3 schema implementation evidence

Implements the [Phase 3 plan](phase-03-prop-slot-and-host-boundary-contracts.md)
and [prop/slot contract](schema-contract.md).

Decision: **Phase 3 complete — schemas and invocation normalization only**.
Phase 4 is eligible but unauthorized; BH-06 remains ineligible. No component
execution, AtomVM parity or support status is granted.

The [source-frozen gates](../../../assets/bh-05-baseline/schema-gates-v0.1.0.json)
and [completion](../../../assets/bh-05-baseline/schema-completion-v0.1.0.json)
record all 14 passing gates, with matching before/after/current source hashes:

- 254 package/conformance tests across eight suites;
- 31 JavaScript test files plus DOM driver checks;
- five legacy/new compile integration tests, including schema declarations,
  wire rejection, non-executing defaults and deterministic normalized fixtures;
- seven compiler/analyzer modules with identical before/after normalization;
- seven current mutation groups, seven frozen Phase 2 groups and ten Phase 1 groups;
- accepted BH-04 replay and the full historical sweep including 438 tests;
- authority generation, boundary validation, archive checks, 434 JSON files and hygiene.

The log records exact commands, tool versions, outputs and diagnostics. Archive
and JSON checks are repeated after publication of these two completion records;
their addition does not change the tested executable/contract source closure.

## Section delivery

| Section | Commit | Scope |
| --- | --- | --- |
| 3.1 | `bde95ba` | Authority, versioning, schema vocabulary and boundary semantics |
| 3.2 | `338a03a` | Ordered prop declarations, metadata, normalization and wire terms |
| 3.3 | `c6092d1` | Slots, caller ownership and atomic invocation updates |
| 3.4 | this delivery commit | Integration fixtures, compiler roundtrip and source-frozen evidence |

Synchronized base is Phase 2 merge `5cd382c23c5589404efc8dd7121432dd24c4cd96`.
The feature branch is `codex/bh05-phase3-schemas`; delivery is one PR after four
section commits, merge, checkout main, sync origin, then branch deletion.
Unrelated README/demo work is retained in stash
`0c7096001136f329a9a904a88a115f4c8e90bd17` for exact restoration after delivery.

## Implemented contracts

The [schema inventory](../../../../../integration/bh-05/schema-index-v0.1.0.json)
binds the four public modules, changed build helper, tests and integration
fixtures. Legacy facade metadata stays version `0.1.0-bh05-candidate`; the
explicit schema opt-in emits `0.2.0-bh05-schema-candidate`. Inherited evaluators,
runtime/host code, package dependencies and historical evidence are unchanged.

The closed schema algebra covers scalar/range, enum, tuple, bounded collection,
record, nullable, opaque ID, semantic data, local callable and versioned
declarative custom forms. Metadata preserves declaration order, documentation,
deprecation and defaults. Unknown fields and unsupported declarations fail
closed. No executable validator/default is evaluated. Wire codecs return
JSON-compatible terms; byte serialization belongs to the host adapter.

Slot normalization covers default/named, contextual, multiple and empty slots,
required/min/max, entry schemas, key rules and lexical content descriptors.
Declared slot order and input entry order are preserved. Optional ordinal keys
are stable by position, not a promise of state retention across reordering;
explicit keys are the default. Cross-root/local-host content fails. Local
callables must be uncaptured external references in a same-root local boundary;
they are never invoked or accepted in host/persistence/command/renderer data.

Invocation validation returns a complete normalized props/slots pair or one
redacted diagnostic. Invalid updates return the exact previous invocation.
Component fixtures deliberately raise if executed; normalization never calls
them. This proves the validation entry point rejects invalid inputs and performs
no callback execution, not that the inherited evaluator has gained a schema
admission hook. That integration belongs to Phase 4.

## Verification method

Current gates run all package/conformance, JavaScript, legacy/new compile,
schema/codec, ownership and redaction fixtures. Seven evidence mutation groups
reject missing/drifted inputs, authority expansion, altered dependencies,
premature phase completion, false execution credit and stale/failed gate records.

The compiler gate authenticates the cached Popcorn 0.3.3 tar and its reader,
analyzer and Core Erlang serialization helper, then recompiles four runtime
modules and three fixture/helper modules. Normalization before and after the
compiler roundtrip on ERTS must yield the same deterministic SHA-256 as the
independent integration fixture. No AtomVM code is executed. Import inventories
retain Elixir helpers and callable introspection for Phase 11 runtime checking;
compiler success is not runtime parity or transitive runtime support proof.

Predecessors replay in frozen checkouts: Phase 2 at `5cd382c`, Phase 1 at
`968013b`, corrective BH-04 at `506c254`, and the complete historical tooling
sweep at `d61e103`. Sealed tools and old gate records are not rewritten. Current
source hashes are captured before/after execution and checked again before
publishing. Every run uses a fresh temporary log path.

## Corrections and limits

Pre-gate integration checks exposed fixture compilation-order warnings; fixtures
now compile warning-free before their integration test module. Integration review
bounded tuple conversion and wire traversal before normalization, and added an
executable-default non-execution check. No failing gate is waived.

Local root/caller descriptors are internal assertions, not capabilities or
authentication. Generation scheduling, content-ID resolution, retention and
process ownership remain later-phase work. Producers must not hide credentials
inside ordinary text; reserved-field rejection cannot detect secret content.
Macros remain trusted build code and custom schemas cannot execute validators.
LiveView/LocalLiveView, forms, renderer changes, root processes, effects,
cross-runtime parity, BH-06 and stable/public support claims remain deferred.
