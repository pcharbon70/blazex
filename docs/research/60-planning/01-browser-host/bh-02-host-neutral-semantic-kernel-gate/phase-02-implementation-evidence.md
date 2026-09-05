---
title: "BH-02 Phase 2 implementation evidence"
kind: note
created: "2026-09-05"
maturity: stable
tags:
  - bh-02
  - component-model
  - evidence
  - host-neutral
  - semantic-ui
aliases:
  - "BH-02 Phase 2 evidence"
---

# BH-02 Phase 2 implementation evidence

## Outcome

**Passed.** The [Phase 2 plan](phase-02-semantic-nodes-identity-and-component-evaluation.md)
now has an executable experimental contract for version-1 semantic nodes,
structural identity, and pure/stateful component evaluation. The contract is
host-neutral and contains no concrete browser, server-framework, runtime, or
native-platform object.

This evidence establishes local BEAM semantics only. It does not establish a
stable public API, semantic events, effects, resources, layout, accessibility,
focus, renderer lifecycle, headless rendering, browser behavior, native
controls, performance, or support. Phase 3 is eligible but remains
unauthorized.

## Authorization and base

- Authorization: `BX-BH02-PHASE-02-AUTHORIZATION-0.1`
- Authorized date: 2026-09-05
- Synchronized base: `1e92ac866d8472f693214fe700f5c006b68c0f5e`
- Base branch and remote: `main` and `origin/main`, equal before branching
- Feature branch: `codex/bh-02-phase-02-semantic-kernel`
- Delivery: four ordered sections, one commit per section, one phase pull request

## Section commits

| Section | Commit | Result |
| --- | --- | --- |
| 2.1 — Authorization and contract envelope | `e22fbd4` | Phase 1 completion and accepted ADRs bound; exact experimental vocabulary frozen |
| 2.2 — Semantic nodes and identity | `9b8ac52` | structural identity, version-1 nodes, tree validation, and traversal implemented |
| 2.3 — Portable component evaluation | `42d66ec` | pure/stateful mount, update, replacement, diagnostics, and atomic semantic-output validation implemented |
| 2.4 — Integration gate and evidence | this evidence commit | conformance scenarios, fail-closed validation, full gate, and limitations recorded |

## Implemented contract

### Identity

- Structural `root`, ordered `path`, and positive `generation` fields.
- Bounded atom, binary, integer, proper-list, and tuple key material.
- Explicit rejection of PIDs, references, functions, ports, maps, structs,
  floats, improper lists, empty/nil keys, excessive depth, and excessive size.
- Stable identity across update and keyed move; replacement increments only
  the generation and restarts the evaluation revision.

### Semantic tree

- Version 1 with exactly `text`, `group`, `action`, `field`, `selection`,
  `collection`, and `surface` node kinds.
- Exactly `version`, `kind`, `identity`, `key`, `content`, and `children`
  fields.
- Complete-tree validation for node shape, version, kind, identity, key/path
  agreement, content rules, child ancestry, and duplicate sibling identity or
  key.
- Deterministic preorder traversal after successful validation.

### Component evaluation

- Explicit `pure` and `stateful` modes.
- Immutable mount, update, and replace transitions with map props, bounded
  portable state, stable identity, and monotonic update revisions.
- A host-neutral context containing identity, revision, and transition only.
- Deterministic diagnostics that omit raw callback error terms and exception
  messages.
- Atomic UI-tree acceptance: malformed output or wrong root identity rejects
  the candidate without changing the previously accepted evaluation.

## Conformance evidence

The Phase 2 [semantic fixture set](../../../../../integration/conformance/semantic-kernel-fixtures-v0.1.0.json)
contains eight scenarios: semantic text/tree traversal, pure mount/update,
stateful mount/update, keyed reorder, replacement generation, duplicate
sibling rejection, opaque-term rejection, and invalid-output rejection. The
local semantic-kernel result passed. Renderer-result arrays remain empty.

## Tool and execution environment

- Linux x86-64 development host
- Erlang/OTP 27, ERTS 15.2.3
- Elixir 1.18.4 and Mix 1.18.4
- Python 3.12.12
- Git 2.49.0
- jq 1.7

## Validation results

| Command | Result |
| --- | --- |
| `mix format --check-formatted` in each of seven activated Mix projects | passed |
| `mix test` in each of seven activated Mix projects | passed; 27 tests total |
| `python3 validate_bh02_semantics.py` | passed |
| `python3 -m unittest test_validate_bh02_semantics.py` | passed; eight tests |
| `python3 validate_bh02_activation.py` | passed |
| `python3 -m unittest test_validate_bh02_activation.py` | passed; seven tests |
| `python3 validate_archive.py` | passed; 173 documents, 22 directories, 1,237 local links, 50 source notes |
| `python3 -m unittest test_validate_archive.py` | passed; eight tests |
| `python3 validate_bh01_activation.py` | passed |
| `python3 -m unittest test_validate_bh01_activation.py` | passed; thirteen tests |
| `python3 validate_bh00_governance.py` | passed |
| `python3 -m unittest test_validate_bh00_governance.py` | passed; twenty-five tests |
| `python3 generate_bh00_release.py --check` | passed; generated baseline unchanged |
| `git diff --check` | passed |

The normalized command record is retained in
[`blazex-bh-02-phase-02-validation-log-v0.1.0.txt`](../../../assets/bh-02-baseline/blazex-bh-02-phase-02-validation-log-v0.1.0.txt).

## Fail-closed cases

The Phase 2 Python validator rejects stale or missing authorization, expanded
node kinds or fields, relaxed opaque identity rules, concrete adapter/platform
leakage, missing fixture coverage, renderer results, stable API claims, and
support claims. The Elixir suites additionally reject malformed identity
terms, ancestry/key errors, duplicates, invalid callback modes/results/state,
raised or rejected callbacks, malformed semantic output, and wrong root
identity.

## Bound artifact hashes

| Artifact | SHA-256 |
| --- | --- |
| Phase 2 authorization | `6fbbcfeed1bc4b1da9d0c970f9a73fdba2d6b7afdf4876bfff7bdba4355775b4` |
| Phase 2 contract | `b7e98bf1fcbd6c4c6dead077cd4ddb4203fee957e944674e7642db458fc2ce04` |
| Phase 2 output ledger | `fd5d3772e2ab900f24fa5a9438b70902c1eb367696732778abd83a781b0dd657` |
| Semantic fixture set | `74e7db1e0194cb97f7d1c3b37b815d3cd0139050b75382078138570a58e04b78` |
| Phase 2 conformance index | `e74da6a416631edecd345bf0e843ae79fade8a68ca325aec37c02476efa9d552` |

## Deferred and unproven work

- Phase 3 owns semantic events, effects, capabilities, and resource ownership.
- Phase 4 owns layout, tokens, accessibility, focus, and selection intent.
- Phase 5 owns renderer lifecycle and the deterministic headless oracle.
- Phase 6 owns standalone DOM lowering.
- Phase 7 owns direct Win32/AppKit/GTK experiments; Windows and macOS execution
  remain `[DEFERRED]`, and Qt/wxWidgets remain excluded.
- Phase 8 owns cross-backend acceptance and any decision about stabilizing the
  experimental contracts.

## Decision

The Phase 2 gate passes with no exception. Phase 3 may begin only after a new
explicit repository-owner authorization. No public API or product/support
claim is implied.
