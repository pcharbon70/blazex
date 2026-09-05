---
title: "BH-02 Phase 5 implementation evidence"
kind: note
created: "2026-09-05"
maturity: stable
tags:
  - bh-02
  - capabilities
  - conformance
  - evidence
  - headless
  - renderer
aliases:
  - "BH-02 Phase 5 evidence"
---

# BH-02 Phase 5 implementation evidence

## Outcome

**Passed.** The [Phase 5 plan](phase-05-renderer-lifecycle-and-deterministic-headless-oracle.md)
now has executable experimental contracts for renderer capability negotiation,
immutable mount/update/replace/dispose sessions, deterministic nonvisual
snapshots, SHA-256 digests, and ordered lifecycle traces. The local headless
profile exercises presentation intent plus event, effect, resource, and
renderer disposal coordination.

This evidence establishes a deterministic local oracle, not a visual renderer.
It does not establish geometry, measurement, hit testing, pixels, DOM lowering,
browser behavior, native controls, platform accessibility mapping, host focus
or selection execution, performance, a stable API, or support. Phase 6 is
eligible but remains unauthorized.

## Authorization and base

- Authorization: `BX-BH02-PHASE-05-AUTHORIZATION-0.1`
- Authorized date: 2026-09-05
- Synchronized base: `c50e8849649987ebe770e5e568b4c38528a1abbc`
- Base branch and remote: `main` and `origin/main`, equal before branching
- Feature branch: `codex/bh-02-phase-05-headless-renderer`
- Delivery: four ordered sections, one commit per section, one phase pull request

## Section commits

| Section | Commit | Result |
| --- | --- | --- |
| 5.1 — Authorization and contract envelope | `337484f` | Phase 4 completion and accepted renderer decisions bound; exact capability, lifecycle, snapshot, and trace surfaces frozen |
| 5.2 — Renderer negotiation and lifecycle | `ab1c3b3` | derived requirements, deny-by-default negotiation, stable diagnostics, backend behavior, and immutable sessions implemented |
| 5.3 — Deterministic headless oracle | `4d92ac3` | canonical normalization, SHA-256 snapshots, lifecycle traces, and backend-neutral render scripts implemented |
| 5.4 — Integration gate and evidence | this evidence commit | composed headless profile, versioned scenarios, fail-closed validation, full gate, and limitations recorded |

## Implemented contract

### Renderer negotiation and lifecycle

- Renderer capabilities declare versioned tree versions, node kinds, logical
  layout modes, accessibility roles, and the five current semantic features.
- Complete validated semantic output derives renderer requirements; every
  requirement must be explicitly supported before a backend callback runs.
- A renderer session retains backend module, accepted capabilities and
  requirements, exact owner/generation/revision, lifecycle state, opaque
  backend state, and a validated artifact envelope.
- Mount starts at revision zero; update requires the same owner and generation
  and advances revision; replacement requires the next generation and resets
  revision; disposal is idempotent.
- Malformed output, missing capabilities, stale ownership, callback errors,
  exceptions, and malformed artifacts produce stable diagnostics without
  accepting partial state or exposing private backend reasons.

### Deterministic headless oracle

- Semantic nodes, bindings, logical layout and token references,
  accessibility, focus, and selection normalize to fixed tagged tuple/list
  sections.
- Unordered bindings, annotations, and map entries are sorted canonically;
  meaningful tree-child and selection-value order is preserved.
- Deterministic Erlang term encoding feeds a lowercase SHA-256 digest over the
  complete snapshot context and semantic sections.
- Mount, update, replacement, and disposal append contiguous trace entries
  carrying transition, owner, generation, revision, and digest. Repeated
  disposal does not append another entry.
- `blazex_test` can execute backend-neutral lifecycle scripts and assert exact
  artifact equality without depending on a concrete backend.

## Conformance evidence

The Phase 5 [renderer/headless fixture set](../../../../../integration/conformance/renderer-headless-fixtures-v0.1.0.json)
contains sixteen scenarios covering capability negotiation, pre-callback
rejection, mount/update/replace/dispose behavior, repeatability, canonical
ordering, meaningful child order, event/effect/resource coordination, focus,
selection, invalid semantic output, and callback atomicity. Its canonical
trace covers all four lifecycle transitions. Visual, geometry, DOM, browser,
native, and platform-accessibility result arrays remain empty.

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
| `mix test` in each of seven activated Mix projects | passed; 68 tests total |
| `python3 validate_bh02_renderer.py` | passed |
| `python3 -m unittest test_validate_bh02_renderer.py` | passed; fourteen tests |
| Phase 1–4 BH-02 validators and focused tests | passed; 35 tests |
| `python3 validate_archive.py` and focused tests | passed; eight validator tests |
| BH-00 and BH-01 validators, focused tests, and generated-release check | passed |
| JSON parsing, no-lock, and `git diff --check` gates | passed |

The normalized command record is retained in
[`blazex-bh-02-phase-05-validation-log-v0.1.0.txt`](../../../assets/bh-02-baseline/blazex-bh-02-phase-05-validation-log-v0.1.0.txt).

## Fail-closed cases

The Phase 5 Python validator rejects stale authority, expanded renderer
capabilities, changed lifecycle or snapshot surfaces, concrete-backend
leakage, missing scenario or trace coverage, premature visual/backend results,
stable API or support claims, and premature Phase 6 authorization. The Elixir
suites additionally reject malformed capabilities and output, missing
requirements, wrong or stale ownership, nonconsecutive replacement,
post-disposal updates, callback rejection or failure, invalid artifacts, and
malformed render scripts.

## Bound artifact hashes

| Artifact | SHA-256 |
| --- | --- |
| Phase 5 authorization | `5e2925494bd42d73492f2ccb01babe1e5297685c0c90c0ff543c3254a6148b9e` |
| Phase 5 contract | `c7da238f2f9b98fe0be5ae53552c1b1e15019b88a8cb3ed2fb666603b437c89e` |
| Phase 5 output ledger | `cecec48c1dee26f8f8763c52cbe90ce7597d3e50f06808bf56c46e3ec9b2b81b` |
| Renderer/headless fixture set | `56c5ef67550d9a5adee03e37e34a507046d1990cf4caf4ee32c36e25b2fdf1d3` |
| Phase 5 conformance index | `ffeb44a5a4d7d349d9f580ce75c976b64e008fb8bee14d9a19bf299c3f3d073f` |

## Deferred and unproven work

- Phase 6 owns standalone DOM lowering and browser conformance.
- Phase 7 owns direct Win32/AppKit/GTK experiments; Windows and macOS execution
  remain `[DEFERRED]`, and Qt/wxWidgets remain excluded.
- Phase 8 owns cross-backend acceptance and any decision about stabilizing the
  experimental contracts.
- Geometry, platform accessibility, host focus/selection execution, pixels,
  performance, production component families, and every support claim remain
  unimplemented or unproven.

## Decision

The Phase 5 gate passes with no exception. Phase 6 may begin only after a new
explicit repository-owner authorization. No visual, browser, native,
platform-accessibility, public-API, product, or support claim is implied.
