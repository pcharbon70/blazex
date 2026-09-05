---
title: "BH-02 Phase 1 implementation evidence"
kind: note
created: "2026-09-05"
maturity: stable
tags:
  - bh-02
  - evidence
  - host-neutral
  - implementation-planning
aliases:
  - "BH-02 Phase 1 evidence"
---

# BH-02 Phase 1 implementation evidence

## Outcome

**Passed.** BH-02 Phase 1 records explicit owner authorization, preserves the
immutable BH-01 handoff, activates exactly nine approved host-neutral and
evidence boundaries, and enforces their dependency and leakage constraints.
The completed work follows the
[Phase 1 activation plan](phase-01-authorization-input-reconciliation-and-foundation-activation.md).
BH-02 Phase 2 is eligible but remains unauthorized.

This result proves repository structure, compilation, ownership, local path
dependency direction, and fail-closed validation only. It does not prove a
semantic component API, renderer output, browser behavior, native control,
accessibility conformance, performance budget, or support state.

## Authorization and base

- Authorization: `BX-BH02-AUTHORIZATION-0.1`
- Authorized date: 2026-09-05
- Synchronized base: `8b732641910ebbdf28dd1c8a4b4a9fc435c820ce`
- Base branch and remote: `main` and `origin/main`, equal before branching
- Feature branch: `codex/bh-02-phase-01-activation`
- Delivery: sections in order, one commit per section, one phase pull request

The Phase 1 plan was derived from the owner-authorized BH-02 milestone outcome
and the immutable conditional entry manifest because no earlier BH-02 phase
decomposition existed.

## Section commits

| Section | Commit | Result |
| --- | --- | --- |
| 1.1 — Authority and governing inputs | `5d9736b` | authorization, handoff ledger, planning boundary, and direct-native research reconciliation recorded |
| 1.2 — Host-neutral project activation | `e4f7498` | seven Mix projects compile with approved inward-only local dependencies |
| 1.3 — Repository and evidence governance | `228d760` | activation/conformance/experiment indexes and fail-closed validation added |
| 1.4 — Integration gate and evidence | this evidence commit | full gate, limitations, and Phase 2 authorization state recorded |

## Activated boundaries

| Boundary | State | Dependencies |
| --- | --- | --- |
| `packages/blazex_core` | experimental skeleton | none |
| `packages/blazex_effects` | experimental skeleton | `blazex_core` |
| `packages/blazex_ui_tree` | experimental skeleton | `blazex_core` |
| `packages/blazex_renderer` | experimental skeleton | core, effects, UI tree |
| `packages/blazex_renderer_headless` | experimental skeleton | renderer and neutral contracts |
| `packages/blazex_test` | experimental skeleton | renderer and neutral contracts |
| `profiles/headless` | experimental composition | all six activated packages |
| `integration/conformance` | empty governed evidence index | none |
| `experiments/native_renderer_spike` | empty governed experiment index | none |

All Mix dependencies are local path dependencies. No activated project has a
`mix.lock`, Git/Hex dependency source, semantic implementation, or stable API.

## Tool and execution environment

- Linux x86-64 development host
- Erlang/OTP 27, ERTS 15.2.3
- Elixir 1.18.4
- Mix 1.18.4
- Python 3.12.12
- Git 2.49.0
- jq 1.7

These are Phase 1 validation tools, not new runtime/toolchain support claims.
The browser runtime baseline and its invalidation conditions remain unchanged.

## Validation results

| Command | Result |
| --- | --- |
| `mix format --check-formatted` in each of seven Mix projects | passed |
| `mix test` in each of seven Mix projects | passed; seven tests total |
| `python3 validate_bh02_activation.py` | passed |
| `python3 -m unittest test_validate_bh02_activation.py` | passed; seven tests |
| `python3 validate_archive.py` | passed; 171 documents, 22 directories, 1,216 local links, 50 source notes |
| `python3 -m unittest test_validate_archive.py` | passed; eight tests |
| `python3 validate_bh01_activation.py` | passed after successor-activation reconciliation |
| `python3 -m unittest test_validate_bh01_activation.py` | passed; thirteen tests |
| `python3 validate_bh00_governance.py` | passed after successor-activation reconciliation |
| `python3 -m unittest test_validate_bh00_governance.py` | passed; twenty-five tests |
| `python3 generate_bh00_release.py --check` | passed; generated baseline unchanged |
| `git diff --check` | passed |

The normalized command record is retained in
[`blazex-bh-02-phase-01-validation-log-v0.1.0.txt`](../../../assets/bh-02-baseline/blazex-bh-02-phase-01-validation-log-v0.1.0.txt).

## Fail-closed cases

The BH-02 validator tests reject:

- missing repository-owner authorization;
- incomplete inherited condition handoff;
- an extra or duplicate activation boundary;
- a forbidden browser/server/runtime token in portable source;
- an external or unapproved Mix dependency source; and
- a native-support overclaim.

The validator also checks the approved input hashes, exact metadata/dependency
agreement, absence of lockfiles, empty conformance/native evidence, and direct
or transitive exclusion of Qt and wxWidgets.

## Inherited-validator reconciliation

The first full-gate run correctly failed because the BH-00 and BH-01 validators
treated their historical activation slices as permanent limits. The bound
repository map and root README were restored byte-for-byte rather than changing
the accepted BH-00 source hashes. The validators were then made successor-aware:
later packages are accepted only when both BH-02 authorization and activation
records exist, agree, and name the boundary. Missing, partial, or unapproved
successor records still fail closed. The BH-00 generated release remains
unchanged.

## Bound artifact hashes

| Artifact | SHA-256 |
| --- | --- |
| BH-02 authorization | `f83f7d84eb817a93e22eff679426bca9bbceb0e90d78010869920507a8c4fbd2` |
| BH-02 entry ledger | `761514204143b8685a7ce58df1aa24fb5333f91bcb8f9bb762b0251006923717` |
| BH-02 repository activation | `ea4261130fc20526bbc8a9c4f191db3d9fe58e417d23b27bf39087ac7065b8fd` |
| Conformance index | `e49350965835b0f2e71a34389577794f9cfbfbab762a475f1bb4f69338d84524` |
| Native experiment index | `94890d383045d777d2d256d948ae6106923b66ef6e4e445452d800649b74bf52` |

## Deferred and unproven work

- `[DEFERRED]` Windows direct-control execution until a governed Windows
  environment is available.
- `[DEFERRED]` macOS direct-control execution until a governed macOS
  environment is available.
- `[DEFERRED]` Manual assistive-technology and unavailable browser/device
  qualification under the existing BH-22 policy.
- Linux GTK execution is planned but unexecuted and unauthorized until BH-02
  Phase 7.
- Semantic nodes, component evaluation, events, effects, resources, layout,
  accessibility intent, renderer behavior, headless traces, and DOM lowering
  remain unimplemented.

## Decision

The Phase 1 gate passes with no exception. Phase 2 may be planned or started
only after a new explicit repository-owner authorization. No later phase,
public API, product component, or support claim is implied by this decision.
