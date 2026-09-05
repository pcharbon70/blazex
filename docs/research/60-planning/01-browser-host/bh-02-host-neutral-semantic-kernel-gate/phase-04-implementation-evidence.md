---
title: "BH-02 Phase 4 implementation evidence"
kind: note
created: "2026-09-05"
maturity: stable
tags:
  - accessibility
  - bh-02
  - evidence
  - focus
  - host-neutral
  - layout
  - selection
  - tokens
aliases:
  - "BH-02 Phase 4 evidence"
---

# BH-02 Phase 4 implementation evidence

## Outcome

**Passed.** The [Phase 4 plan](phase-04-layout-tokens-accessibility-focus-and-selection-intent.md)
now has executable experimental contracts for token references, logical layout,
accessibility, focus, controlled selection, and composed presentation intent. A
local BEAM profile validates a dialog relationship and focus scope without
calculating geometry or invoking a renderer or platform accessibility API.

This evidence does not establish a stable public API, geometry or measurement
engine, renderer lifecycle, headless renderer, platform accessibility mapping,
host focus/selection execution, browser behavior, native controls,
performance, accessibility conformance, or support. Phase 5 is eligible but
remains unauthorized.

## Authorization and base

- Authorization: `BX-BH02-PHASE-04-AUTHORIZATION-0.1`
- Authorized date: 2026-09-05
- Synchronized base: `313dfe578b354e81b12b204b299060f90808d4e6`
- Base branch and remote: `main` and `origin/main`, equal before branching
- Feature branch: `codex/bh-02-phase-04-semantic-intent`
- Delivery: four ordered sections, one commit per section, one phase pull request

## Section commits

| Section | Commit | Result |
| --- | --- | --- |
| 4.1 — Authorization and contract envelope | `beeac9e` | Phase 3 completion and accepted architecture inputs bound; exact experimental vocabulary frozen |
| 4.2 — Tokens and logical layout | `9f61ea0` | categorized token references, logical metrics, layout modes, constraints, overflow, and virtualization hints implemented |
| 4.3 — Accessibility, focus, selection, and composition | `b300845` | roles, states, relationships, focus scopes/targets, controlled selection, intent-set validation, and atomic component acceptance implemented |
| 4.4 — Integration gate and evidence | this evidence commit | composed profile trace, versioned scenarios, fail-closed validation, full gate, and limitations recorded |

## Implemented contract

### Tokens and logical layout

- Token references contain only version, exact category, and a bounded portable
  name; resolved visual values remain renderer-owned.
- Metrics are auto, content, fill, bounded non-negative logical units, or space/
  size token references.
- Per-node layout intent covers none, stack, grid, and overlay modes; row/column
  direction; alignment; gap and padding; size bounds; growth; overflow; and
  bounded virtualization hints.
- Validation rejects bad ownership, opaque values, invalid modes or metrics,
  contradictory numeric bounds, and malformed virtualization without producing
  calculated bounds.

### Accessibility and focus

- Ten bounded semantic roles, eight typed state keys, five in-tree relationship
  kinds, and off/polite/assertive live intent.
- Relationships resolve only to exact accepted document identities and
  generations; roles are checked against semantic node kinds.
- Focus annotations distinguish none, ordered targets, and group/surface
  scopes, with at most one autofocus target and explicit previous-focus
  restoration or wrapping for scopes.
- No ARIA, OS accessibility object, input callback, or focus API enters the
  portable data.

### Selection and composed intent

- Controlled none, single, multiple, and directional text-range selection;
  values and offsets are bounded and multiple values are unique.
- A version-1 intent set preserves the Phase 3 semantic document and separately
  attaches layout, accessibility, focus, and selection annotations.
- Every annotation owner and relationship target must be an exact document
  node; duplicate per-kind owners, duplicate focus order, incompatible roles,
  incompatible focus behavior, and incompatible selection kinds fail closed.
- Component mount, update, event dispatch, and replacement accept the complete
  intent set atomically and retain prior accepted evaluation on failure.

## Conformance evidence

The Phase 4 [presentation-intent fixture set](../../../../../integration/conformance/presentation-intent-fixtures-v0.1.0.json)
contains fourteen scenarios covering token references, stack/grid layout,
virtualization, invalid bounds, accessibility relationships, missing targets,
focus order/scope/restoration, controlled selection, stale owners, and atomic
output. Geometry, platform mapping, and renderer result arrays remain empty.

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
| `mix test` in each of seven activated Mix projects | passed; 52 tests total |
| `python3 validate_bh02_intent.py` | passed |
| `python3 -m unittest test_validate_bh02_intent.py` | passed; ten tests |
| `python3 validate_bh02_effects.py` and focused tests | passed; ten tests |
| `python3 validate_bh02_semantics.py` and focused tests | passed; eight tests |
| `python3 validate_bh02_activation.py` and focused tests | passed; seven tests |
| `python3 validate_archive.py` | passed; 177 documents, 22 directories, 1,282 local links, 50 source notes |
| `python3 -m unittest test_validate_archive.py` | passed; eight tests |
| `python3 validate_bh01_activation.py` and focused tests | passed; thirteen tests |
| `python3 validate_bh00_governance.py` and focused tests | passed; twenty-five tests |
| `python3 generate_bh00_release.py --check` | passed; generated baseline unchanged |
| JSON parsing, no-lock, and `git diff --check` gates | passed |

The normalized command record is retained in
[`blazex-bh-02-phase-04-validation-log-v0.1.0.txt`](../../../assets/bh-02-baseline/blazex-bh-02-phase-04-validation-log-v0.1.0.txt).

## Fail-closed cases

The Phase 4 Python validator rejects stale or missing authorization, expanded
token/layout/accessibility vocabularies, relaxed annotation ownership,
concrete layout/accessibility/platform leakage, missing intent fixtures,
premature geometry/platform/renderer results, stable API or support claims,
and premature Phase 5 authorization. The Elixir suites additionally reject
opaque token names, invalid metrics and bounds, malformed virtualization,
unknown owners/targets, duplicate annotations or focus order, multiple
autofocus targets, incompatible node roles/focus/selection, invalid ranges,
and invalid intent-set rerenders.

## Bound artifact hashes

| Artifact | SHA-256 |
| --- | --- |
| Phase 4 authorization | `0dd5e9c7cc519550b16e902a2cfdd10fa98f5cc1f62cc55a124347e90b451922` |
| Phase 4 contract | `037a42b96fda568d3787fbda9d27c6d133a86899c7c4ce12da7fc626ac397bcf` |
| Phase 4 output ledger | `7cb21fee7f42f2ee8e14840f5a60bbffc87b8b5655151733891103cac48e87e1` |
| Presentation-intent fixture set | `86998ccbd9be44100e0be87a4249540022eaab6784433b4600ad4ca423c36665` |
| Phase 4 conformance index | `a6d33e9f31c5925c9bd8334549b7a58679b0990934d1f099aad08fe3d8811714` |

## Deferred and unproven work

- Phase 5 owns renderer lifecycle, capability negotiation, calculated output,
  and the deterministic headless oracle.
- Phase 6 owns standalone DOM lowering.
- Phase 7 owns direct Win32/AppKit/GTK experiments; Windows and macOS execution
  remain `[DEFERRED]`, and Qt/wxWidgets remain excluded.
- Phase 8 owns cross-backend acceptance and any decision about stabilizing the
  experimental contracts.

## Decision

The Phase 4 gate passes with no exception. Phase 5 may begin only after a new
explicit repository-owner authorization. No geometry, platform accessibility,
renderer, public API, product, or support claim is implied.
