---
title: "BH-05 Phase 4 pure composition implementation evidence"
kind: note
created: "2026-09-09"
maturity: developing
tags: [bh-05, composition, implementation-evidence, semantic-ui]
aliases: []
---

# BH-05 Phase 4 pure composition implementation evidence

Implements the [Phase 4 plan](phase-04-pure-composition-and-atomic-semantic-evaluation.md)
and [pure composition contract](composition-contract.md).

Decision: **Phase 4 complete — bounded pure composition on ERTS**.
Phase 5 is eligible but unauthorized; BH-06 remains ineligible. Retained state,
effects execution, AtomVM parity and support are not granted.

The [source-frozen gates](../../../assets/bh-05-baseline/composition-gates-v0.1.0.json)
and [completion record](../../../assets/bh-05-baseline/composition-completion-v0.1.0.json)
bind all 14 passing gates to identical before/after/current source hashes:

- 267 package/conformance tests: Core 31, Effects 9, UI Tree 34, Renderer 8,
  Headless 6, DOM 116, Test 3, cross-package conformance 60;
- 213 JavaScript runtime tests and seven DOM driver tests;
- five inherited authoring/schema compile integration tests;
- seven current evidence mutation groups, seven Phase 3 groups, seven Phase 2
  groups, ten Phase 1 groups and the accepted BH-04 corrective replay;
- complete historical tooling sweep, including 438 Python tests, all applicable
  validators and generator checks at its accepted frozen source;
- current ownership/evidence validator, authority generator, archive links,
  438 JSON files before publication and patch hygiene.

Archive, JSON and final boundary checks are repeated after publication of the
gate/completion records and this note. Those additions do not alter the tested
executable/contract source closure. The log records exact commands, outputs,
versions and elapsed times; no failed result is waived.

## Section delivery

| Section | Commit | Scope |
| --- | --- | --- |
| 4.1 | `7023fef` | Authority, inherited validator bindings, identity and atomicity rules |
| 4.2 | `6995cf8` | Whole-graph planning, derived identities, pure callbacks and lexical slots |
| 4.3 | `ec82465` | Complete semantic acceptance and deterministic redacted traces |
| 4.4 | this delivery commit | Public fixtures, independent headless oracle, gates and evidence |

Synchronized base is Phase 3 merge `fc5048d4db7cc80fd21b492e0638182abceda1af`.
Branch `codex/bh05-phase4-composition` is delivered as one PR after four section
commits, followed by merge, checkout main, sync origin and branch deletion.
Unrelated README/demo work is preserved in stash
`e0fd6e042a732fa19bc2a0908842d5a00487ec78` for exact restoration after delivery.

## Implemented behavior

The [fixture inventory](../../../../../integration/bh-05/composition-index-v0.1.0.json)
binds four UI-tree-owned implementation modules, package tests,
[public examples](../../../../../integration/bh-05/composition-fixtures.exs) and
[conformance tests](../../../../../integration/conformance/test/bh05_composition_test.exs).
`BlazeX.UITree.Composition.evaluate/6` takes a finite, trusted build-authored
graph. The existing Core/schema/identity/evaluator contracts and package
dependencies are unchanged. Private planning and acceptance modules are not
application imports; there is no Core-to-UI-tree dependency.

All records normalize before render callbacks. Planning rejects malformed roles,
schemas, props, slots, ownership, unavailable capabilities, cycles, unreachable
records, duplicate identities and overflow. Identity uses root, generation,
parent path, public component ID, call site, child/slot discriminator and key.
Traversal follows explicit child order, then declared slot order and entry order.
Local content resolves caller props and declared contextual data; host content
remains inert text/number/boolean data. Reused graph records execute each time.

Callbacks contribute one neutral semantic candidate per invocation. Acceptance
builds the complete Node/Document/IntentSet with root-owned bindings and closed
layout, accessibility, focus and selection constructors. Accessibility paths
resolve against the complete derived identity set. Selection values retain the
existing controlled-key/text-range semantics, not an invented node-reference
contract. Unknown capabilities, effects/resources, state/actions, explicit
identities, callback-supplied children and host fields reject. Invalid descendants
or global intent return only a fixed redacted diagnostic, never partial output.

Success traces contain public enter/exit, slot expansion, accepted-node and final
digest observations. Failure discards candidate traces and returns one canonical
rejection/failure event. Raw props, state, module-private names, stack traces,
PIDs and clocks are absent. Twenty repeated integration evaluations per main
fixture match exactly. Output/trace hashes for controls and slots, and the
independent headless snapshot digest, are in the inventory and gate stdout.

## Verification and corrections

The independent oracle constructs all seven semantic kinds, bindings and complete
presentation intent through public builders, then compares the entire accepted
output and headless snapshot. Exact 12-child-level, 128-invocation and 256-node
boundaries pass; each overflow rejects. Adversarial cases cover wrong roots and
relationships, missing props/slots, duplicate keys, cycles, callback rejection,
exception/throw/exit redaction, prohibited returns, and compile-time rejection
of process, message, renderer and dynamic callback dependencies.

Early local checks exposed an empty-string child discriminator rejected by
Identity, a helper name conflicting with Kernel.node/1, and a test that treated
Node.preorder/1 as a bare list. These were corrected before the frozen passing
run. Ordinary children use the `:child` discriminator; slot depth uses semantic
identity depth. Throw/exit fixtures use the already-admitted `:erlang.raise/3`
operation, preserving the existing authoring dependency audit unchanged.

Frozen replays use Phase 3 `fc5048d`, Phase 2 `5cd382c`, Phase 1 `968013b`,
corrective BH-04 `506c254`, and complete historical tooling `d61e103`. Old
validators intentionally reject new current surfaces; no sealed tool or prior
evidence hash was rewritten to bypass that boundary. The current successor
validator rejects inherited drift, unknown surfaces, private application imports,
premature phase completion, false runtime credit and stale/failed gate evidence.

## Limits and next phase

Modules and compile-time facade use are trusted build code, not an adversarial
Elixir sandbox. Import/opcode checks are not a transitive proof of purity or
termination. No process isolation, timeout, callback side-effect rollback or
independent child failure boundary is claimed. Root/caller strings are internal
assertions, not authentication. Text can contain sensitive content; field
rejection is not secret-content detection.

Deterministic SHA-256 uses ERTS term encoding. Browser AtomVM execution and
cross-runtime encoding parity remain Phase 11 work; no Wasm execution claim is
derived from the headless oracle. Retained state/reconciliation is Phase 5,
process roots and scheduling are later phases, and typed effects/resources remain
Phase 8. LiveView and LocalLiveView integration stay explicitly deferred.
