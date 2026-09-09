---
title: "BH-05 Phase 2 authoring implementation evidence"
kind: note
created: "2026-09-09"
maturity: developing
tags: [bh-05, authoring, implementation-evidence]
aliases: []
---

# BH-05 Phase 2 authoring implementation evidence

Implements the [Phase 2 plan](phase-02-component-roles-authoring-facade-and-callback-algebra.md)
and [candidate authoring contract](authoring-contract.md).

Decision: **Phase 2 complete — candidate authoring contracts only**. Phase 3
is eligible but unauthorized; BH-06 remains ineligible. No runtime parity or
support status is granted by this evidence.

The [source-frozen gate record](../../../assets/bh-05-baseline/authoring-gates-v0.1.0.json)
and [completion](../../../assets/bh-05-baseline/authoring-completion-v0.1.0.json)
record all 13 passing gates and unchanged before/after/current source hashes:

- 244 package/conformance tests across eight suites;
- 31 JavaScript test files plus DOM driver checks;
- two facade compile-integration tests, three warning-free valid modules with
  every callback, and 15 invalid integration declarations;
- 11 compiler/analyzer runtime/fixture modules with printed import inventories;
- ten frozen Phase 1 mutation-test groups and accepted BH-04 replay;
- full historical sweep, including 438 tests, validators and generated checks;
- seven current evidence-mutation groups, candidate authority generation,
  boundary validation, archive validation, 430 JSON files and patch hygiene.

The command/output log is authoritative for tool versions, counts, warnings
and exact commands. The final archive/JSON checks are repeated after adding
these completion records; those records do not alter the tested source closure.

## Section delivery

| Section | Commit | Scope |
| --- | --- | --- |
| 2.1 | `2d3877a` | Hash-bound authority and candidate compatibility envelope |
| 2.2 | `1dd6eb2` | Pure, nested-stateful and process-root behaviours/vocabulary |
| 2.3 | `11dfde5` | Facade, literal metadata, immutable inputs, closed results and rejection tests |
| 2.4 | this delivery commit | Compile fixtures, subset check, boundary mutations and source-frozen gates |

The branch starts at synchronized Phase 1 merge
`968013b9794664fc454619ee08788c3d0c39551f`. Delivery is four section commits,
one PR, merge, checkout main, sync origin, then local/remote feature branch
deletion. Unrelated README/demo changes are preserved in stash
`30e06e8de057465f2ab6067a99336567723dd136` and restored after synchronization.

## Candidate surface and evidence method

The [inventory](../../../../../integration/bh-05/authoring-index-v0.1.0.json)
binds source and fixture hashes and enumerates public/private APIs, all three
roles and required/optional callbacks. Compilation prints exact deterministic
metadata and checks exports. Invalid declarations exercise host, renderer,
server, private implementation, dynamic invocation, process references,
Razor/DI/render-mode options, duplicate roles, missing/wrong-arity callbacks,
unsupported metadata and malformed results. Valid fixtures must emit no warnings.

Seven package suites plus shared conformance preserve the existing kernel.
The compile gate exercises all three roles without starting a component root.
Portable result validation is not schema execution or semantic tree validation.
Only typed action intent is admitted; inherited generic evaluator emissions
remain unchanged until Phase 8. No renderer or runtime adapter is changed and
no package dependency is added.

The subset gate authenticates the cached Popcorn 0.3.3 Hex tar against the
accepted SHA-256 pin before extracting its reader, analyzer and Core Erlang
compiler helper. It parses, analyzes and recompiles six facade runtime modules,
two inherited value/identity modules and three fixtures with Elixir 1.17.3 /
OTP 26.0.2. Macro expansion and BEAM dependency/opcode audits are build-time only.
This is compiler/analyzer compatibility, not application AOT Wasm, WebAssembly
Component Model output, AtomVM execution, transitive runtime reachability proof
or cross-runtime parity. The printed import inventory retains inherited Elixir
helper calls; Phase 11 must exercise actual supported runtime paths.

Historical guards are replayed at accepted snapshots: Phase 1 at `968013b`,
BH-04 corrective acceptance at `506c254`, and the full sealed tooling sweep at
`d61e103`. Current Phase 2 has its own immutable-input and source-closure
validator; no old guard, migration exception or historical evidence is rewritten.
The runner hashes tested sources before and after execution and compares them
again before publishing. Gate outputs are first written to fresh temporary
directories; failed, incomplete or changed-source runs cannot be published.

## Corrections and limitations

Pre-gate checks caught a missing archive conceptual link, an overly strict
standard integer-formatting import, compiler-generated dynamic helpers from
unguarded dotted access, a diagnostic expectation mismatch, and temporary-file
ownership in the subset runner. These were corrected and tests rerun. Integration
review also tightened dynamic-call opcodes, explicit semantic-builder imports
(not every UI-tree implementation module), and public diagnostic redaction.

Authoring is trusted Elixir build code, not a macro sandbox. The import audit
cannot prove pure termination or recognize secrets hidden in otherwise portable
application data. Context names and schema/registry declarations do not resolve
values or grant authority. Semantic output is explicitly a candidate requiring
later UI-tree validation. All stable API, production support, native qualification,
runtime parity, process execution and reliability acceptance claims remain open.
LiveView and LocalLiveView remain explicitly deferred outside this host work.
