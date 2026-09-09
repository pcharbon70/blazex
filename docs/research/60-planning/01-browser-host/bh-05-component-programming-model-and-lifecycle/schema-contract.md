---
title: "BH-05 prop and slot schema contract"
kind: note
created: "2026-09-09"
maturity: developing
tags: [bh-05, props, slots, component-model]
aliases: []
---

# BH-05 prop and slot schema contract

Implements the [Phase 3 plan](phase-03-prop-slot-and-host-boundary-contracts.md)
under [ADR-0001](../../../20-notes/architecture-decisions/adr-0001-host-neutral-semantic-component-kernel.md).

## Authority and delivery

The owner requested the next phase, separate section commits and one PR,
followed by merge, checkout main, origin synchronization and branch deletion.
Base is synchronized Phase 2 merge `5cd382c23c5589404efc8dd7121432dd24c4cd96`;
branch is `codex/bh05-phase3-schemas`. The
[authority record](../../../assets/bh-05-baseline/schema-authorization-v0.1.0.json)
binds the inherited facade, portable values, identity, redaction, runtime pin
and neutral security boundary. Existing Phase 2 declarations remain compatible.

Schema-aware declarations opt into `schema: [props: [...], slots: [...]]` in
`use BlazeX.Component`. They emit version `0.2.0-bh05-schema-candidate`; the
old declaration form retains `0.1.0-bh05-candidate` unchanged. No implicit
conversion of legacy name lists is allowed. Changing schema semantics requires
a new version, migration note and compiler/boundary evidence. Custom schemas
are versioned declarative aliases, never user-supplied validator callbacks.

## Closed vocabulary

Schema forms are boolean, integer, float, string, opaque ID, bounded integer
range/string, enum, tuple, bounded list, string-keyed map, closed record,
nullable, semantic value version 1, local-only callable, and
`{:custom, binary_id, positive_version, schema}`. Custom schemas contain their
complete declarative definition; they perform no registry lookup or execution.
Depth is at most 8; declarations at most 64; collections at most 256; binaries
at most 4096 bytes. Host numbers must fit the safe integer range and values must
be recursively JSON-compatible; no atom creation, term decoding or coercion.
Semantic values are tagged text/number/boolean data, not HTML or renderer handles.

Props are ordered `{binary_name, keyword_options}` declarations, with type,
required/default, boundary (host or local), documentation, deprecation and
schema version. Duplicate/reserved names, invalid defaults, required-with-default,
unknown options and executable validators are errors. Required/unknown/type and
default processing is deterministic; no partial result is returned. Unknown
keys fail, including in closed records. Extensibility uses an explicitly declared
bounded semantic map, never global HTML attributes. Diagnostics contain only
fixed codes and declared field paths; unknown names and rejected data are redacted.

Local-only callables are uncaptured external function references of declared
arity, and only within a validated same-root local boundary. They are never
invoked here and never accepted in host, persistence, command or renderer data.
Captured closures, PIDs, ports, references, structs and opaque resources are
rejected. A local boundary is an internal caller assertion, not server authority;
host adapters must use host mode and cannot promote untrusted input to local.
Portable shape checks cannot recognize secrets hidden in arbitrary text; reserved
secret/host/framework keys are rejected recursively, and producers must avoid
placing credentials in component data.

## Slots and invocation ownership

Default slot name is `default`; named slots use the same reserved-name rules.
Each declares required/min/max, ordered entry props, context schema, key policy,
boundary and documentation. Entries are ordered, keyed immutable maps. Required
keys are explicit; optional keys receive stable ordinal keys. Duplicate keys,
unknown entry fields and cross-root ownership fail. Local content is a lexical
caller-owned descriptor (root, caller, content ID), not a closure or mutable
instance. Host content is semantic data only; local content cannot cross hosts.
Context is explicit validated data, not an ambient socket or context lookup.

Props and all slots normalize together. Update accepts a prior immutable
invocation and returns either a complete replacement or an error plus that exact
prior value. It never mutates prior data or invokes component bodies. Actual
evaluation/admission of normalized invocations is Phase 4; schema normalization
does not retrofit the inherited BH-02 evaluator or start processes.

## Exclusions

Nested evaluation, state retention, processes, events/effects, dynamic registry,
forms, renderer changes, execution parity and support remain out of scope.
LiveView and LocalLiveView integration remain explicitly deferred. A schema
pass is not a security authorization or a rendered component result.
