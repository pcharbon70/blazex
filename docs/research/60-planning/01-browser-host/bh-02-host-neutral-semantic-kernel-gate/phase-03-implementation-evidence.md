---
title: "BH-02 Phase 3 implementation evidence"
kind: note
created: "2026-09-05"
maturity: stable
tags:
  - bh-02
  - capabilities
  - effects
  - evidence
  - host-neutral
  - resources
  - semantic-events
aliases:
  - "BH-02 Phase 3 evidence"
---

# BH-02 Phase 3 implementation evidence

## Outcome

**Passed.** The [Phase 3 plan](phase-03-events-effects-capabilities-and-resource-ownership.md)
now has executable experimental contracts for semantic event dispatch,
deny-by-default capabilities, typed effects, and generation-scoped opaque
resources. A composed local BEAM test routes a bound semantic action through a
stateful component into a typed effect and verifies exact-owner cleanup.

This evidence does not establish a stable public API, concrete capability
provider, layout, tokens, accessibility, focus, selection, renderer lifecycle,
headless rendering, browser behavior, native controls, performance, or
support. Phase 4 is eligible but remains unauthorized.

## Authorization and base

- Authorization: `BX-BH02-PHASE-03-AUTHORIZATION-0.1`
- Authorized date: 2026-09-05
- Synchronized base: `1380da03a68de7af1d7cc3c1faf2d80ef34ea4f2`
- Base branch and remote: `main` and `origin/main`, equal before branching
- Feature branch: `codex/bh-02-phase-03-events-effects`
- Delivery: four ordered sections, one commit per section, one phase pull request

## Section commits

| Section | Commit | Result |
| --- | --- | --- |
| 3.1 — Authorization and contract envelope | `1072aeb` | Phase 2 completion and accepted architecture inputs bound; exact experimental vocabulary frozen |
| 3.2 — Semantic events, bindings, and dispatch | `218cba9` | versioned intent, document bindings, ordered stateful dispatch, and atomic rerender validation implemented |
| 3.3 — Capabilities, effects, and resources | `0c315ee` | deny-by-default negotiation, typed request/result data, deterministic terminal outcomes, transfer, and owner cleanup implemented |
| 3.4 — Integration gate and evidence | this evidence commit | composed trace, versioned scenarios, fail-closed validation, full gate, and limitations recorded |

## Implemented contract

### Semantic intent

- Version 1 defines exactly thirteen intent-oriented event names and six event
  fields without concrete input callbacks.
- Event owners and source nodes share root and generation, and the source must
  descend from the owner.
- Semantic documents reject missing sources, wrong owners, and duplicate
  source/event bindings.
- Stateful dispatch requires a strictly increasing sequence, updates state and
  revision only after a valid rerender, and leaves prior accepted output intact
  on failure.

### Capabilities and effects

- Exactly four proof capabilities: time, clipboard, file choice, and storage,
  with their bounded operation sets.
- Required/optional negotiation is deny by default and records explicit fail,
  omit, or component fallback outcomes.
- Effect requests contain only versioned provider-neutral data, portable
  payloads, bounded timeouts, and an owning identity.
- Terminal results are exactly ok, denied, cancelled, timeout, unsupported, or
  failed; pending effect identifiers cannot be reused.
- The provider behaviour defines an outward seam without supplying or storing
  any concrete provider object.

### Resource ownership

- Resources expose only opaque portable identity data: owner, capability, ID,
  and generation.
- Allocation follows successful effect completion; ownership transfer is
  explicit and limited to the same generation.
- Cancellation and disposal are tracked, disposal is idempotent, and prior
  resource identities become stale after transfer.
- Owner teardown cancels pending effects and disposes resources for the exact
  owner generation while retaining other generations.

## Conformance evidence

The Phase 3 [event/effect/resource fixture set](../../../../../integration/conformance/event-effect-resource-fixtures-v0.1.0.json)
contains twelve scenarios covering bound dispatch, unbound and stale events,
grant and denial, component fallback, completion, cancellation, timeout,
transfer, stale resources, and owner-generation cleanup. The local contract
result passed. Concrete provider and renderer result arrays remain empty.

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
| `mix test` in each of seven activated Mix projects | passed; 42 tests total |
| `python3 validate_bh02_effects.py` | passed |
| `python3 -m unittest test_validate_bh02_effects.py` | passed; ten tests |
| `python3 validate_bh02_semantics.py` | passed |
| `python3 -m unittest test_validate_bh02_semantics.py` | passed; eight tests |
| `python3 validate_bh02_activation.py` | passed |
| `python3 -m unittest test_validate_bh02_activation.py` | passed; seven tests |
| `python3 validate_archive.py` | passed; 175 documents, 22 directories, 1,259 local links, 50 source notes |
| `python3 -m unittest test_validate_archive.py` | passed; eight tests |
| `python3 validate_bh01_activation.py` | passed |
| `python3 -m unittest test_validate_bh01_activation.py` | passed; thirteen tests |
| `python3 validate_bh00_governance.py` | passed |
| `python3 -m unittest test_validate_bh00_governance.py` | passed; twenty-five tests |
| `python3 generate_bh00_release.py --check` | passed; generated baseline unchanged |
| JSON parsing, no-lock, and `git diff --check` gates | passed |

The normalized command record is retained in
[`blazex-bh-02-phase-03-validation-log-v0.1.0.txt`](../../../assets/bh-02-baseline/blazex-bh-02-phase-03-validation-log-v0.1.0.txt).

## Fail-closed cases

The Phase 3 Python validator rejects stale or missing authorization, expanded
event names or capability operations, relaxed resource ownership, concrete
provider/platform leakage, missing lifecycle fixtures, premature provider or
renderer results, stable API or support claims, and premature Phase 4
authorization. The Elixir suites additionally reject invalid event lineage,
sequences, payloads, bindings, rerenders, unknown capabilities and operations,
duplicate authority declarations and effect IDs, late terminal outcomes,
cross-generation transfer, and stale resource operations.

## Bound artifact hashes

| Artifact | SHA-256 |
| --- | --- |
| Phase 3 authorization | `5805884e7c8729f7cd00fc70c6e0ac47fcf040124eeb8b99bd5e2ccd1148d9a3` |
| Phase 3 contract | `3602b414973e57e05da1e107f68097c63c47a4373d2da2689064cd28939a018d` |
| Phase 3 output ledger | `a4120d81b40812489a5da70cd10846c72bf153234b80be3bc542024b7d009ba0` |
| Event/effect/resource fixture set | `e5372f49136fdf3b049c478fedcdc4c0171d1e7331a386b8d7ff6e3e85b4982d` |
| Phase 3 conformance index | `6f085d0daca76b99b3b915d4b3979cadf997f9577218a37536a91bb6cd60c35c` |

## Deferred and unproven work

- Phase 4 owns layout, tokens, accessibility, focus, and selection intent.
- Phase 5 owns renderer lifecycle and the deterministic headless oracle.
- Phase 6 owns standalone DOM lowering.
- Phase 7 owns direct Win32/AppKit/GTK experiments; Windows and macOS execution
  remain `[DEFERRED]`, and Qt/wxWidgets remain excluded.
- Phase 8 owns cross-backend acceptance and any decision about stabilizing the
  experimental contracts.

## Decision

The Phase 3 gate passes with no exception. Phase 4 may begin only after a new
explicit repository-owner authorization. No concrete provider, renderer,
public API, product, or support claim is implied.
