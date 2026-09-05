---
title: "BH-02 Phase 6 implementation evidence"
kind: note
created: "2026-09-05"
maturity: stable
tags:
  - bh-02
  - browser
  - conformance
  - dom
  - evidence
  - renderer
aliases:
  - "BH-02 Phase 6 evidence"
---

# BH-02 Phase 6 implementation evidence

## Outcome

**Passed.** The [Phase 6 plan](phase-06-standalone-dom-lowering-and-browser-conformance.md)
now has an experimental standalone DOM backend over the Phase 5 contracts, a
closed versioned full-projection wire format, and a dependency-free browser
driver. The same semantic slice passes headless/DOM integration tests and an
automated real-page run in the active local Linux Google Chrome and Firefox
development matrix.

This is bounded development evidence, not browser support. It does not prove
incremental reconciliation, hydration, server transport, geometry, pixels,
visual equivalence, performance, manual accessibility conformance, native
controls, a stable API, or production readiness. Phase 7 remains unauthorized.

## Authorization and delivery

- Authorization: `BX-BH02-PHASE-06-AUTHORIZATION-0.1`
- Authorized date: 2026-09-05
- Synchronized base: `4ae389f55de15f71d33628c994d17e9a6556ea06`
- Feature branch: `codex/bh-02-phase-06-dom-lowering`
- Delivery: four ordered sections, one commit per section, one pull request

| Section | Commit | Result |
| --- | --- | --- |
| 6.1 — Authorization and contract envelope | `9161542` | Phase 5 and architecture inputs bound; exact DOM, driver, browser, and evidence boundary frozen |
| 6.2 — Standalone DOM lowering | `a265ad1` | complete semantic output lowers to deterministic versioned full-root projections through the neutral renderer lifecycle |
| 6.3 — Browser driver and matrix | `7150b1d` | strict wire validation, atomic application, events, focus, selection, disposal, Node tests, Chrome, and Firefox implemented |
| 6.4 — Integration gate and evidence | this evidence commit | headless/DOM parity suite, versioned scenarios, fail-closed validation, complete gate, and limitations recorded |

## Implemented boundary

- `blazex_renderer_dom` depends only on `blazex_core`, `blazex_effects`,
  `blazex_ui_tree`, and `blazex_renderer`; it has no external or server
  framework dependency.
- All seven semantic node kinds, current event bindings, logical layout and
  portable token references, accessibility intent, focus, and selection lower
  through one closed seven-tag DOM vocabulary.
- Mount, update, and replacement yield deterministic full-root batches with
  owner, generation, revision, transition, and SHA-256 digest. Disposal uses a
  rootless batch and is idempotent.
- The JavaScript protocol rejects unknown fields, tags, attributes, event
  mappings, relationships, stale lifecycle coordinates, and configured size
  limits before accepted-root mutation.
- The driver builds detached projections, replaces one owned root atomically,
  emits plain bounded semantic-event records, applies autofocus and controlled
  selection, restores same-ID update focus, and removes listeners on disposal.

## Conformance evidence

The [DOM fixture set](../../../../../integration/conformance/dom-renderer-fixtures-v0.1.0.json)
contains twenty scenarios spanning exact capabilities, all semantic kinds,
determinism, lifecycle, stale rejection, accessibility, logical presentation,
focus, selection, events, framework isolation, headless parity, and both active
browsers. The executable integration suite compares headless and DOM semantic
kinds, bindings, focus, selection, deterministic output, and lifecycle.

The [browser matrix](../../../../../integration/conformance/dom-browser-matrix-v0.1.0.json)
records successful automated local runs for Google Chrome 140.0.7339.80 and
Mozilla Firefox 134.0. Each browser passed mount, semantic accessibility,
autofocus/selection, event normalization, focus restoration, atomic stale
rejection, and disposal checks. Visual, pixel, manual-accessibility, native,
and performance result sets remain empty.

## Tool and validation environment

- Linux x86-64 development host
- Erlang/OTP 27, ERTS 15.2.3
- Elixir and Mix 1.18.4
- Node.js 24.3.0 and npm 11.4.2
- Python 3.12.12, Git 2.49.0, jq 1.7
- Google Chrome 140.0.7339.80 and Mozilla Firefox 134.0

| Gate | Result |
| --- | --- |
| `mix format --check-formatted` and `mix test` in nine activated Mix projects | passed; 79 tests |
| DOM JavaScript syntax/build and Node driver suite | passed; 7 tests |
| Real-page active Linux Chrome and Firefox matrix | passed; 7 checks per browser |
| Phase 1–6 BH-02 validators and focused negative tests | passed |
| Archive, BH-00, BH-01, generated-record, JSON, no-lock, and patch-hygiene gates | passed |

The normalized command record is retained in
[the Phase 6 validation log](../../../assets/bh-02-baseline/blazex-bh-02-phase-06-validation-log-v0.1.0.txt).

## Bound artifact hashes

| Artifact | SHA-256 |
| --- | --- |
| Phase 6 authorization | `8f58a205e6637409d2e70cac0466d7a53002876ca1c5492292a71ea897967493` |
| Phase 6 contract | `bff23f61d7e6ac468d847df7618ecbc9e78aeef1cc454543da36ed9fdd442e89` |
| Phase 6 output ledger | `285c3bff7435b1afe3fa4d3859a6efceda568e8e732f17d7bd5adf58707ec590` |
| DOM renderer fixture set | `c2ea66f720dbfdc7325dc15596e3f431cb0d85c4a2df1852cb27891c1e5a6124` |
| Browser matrix | `610e744e2931745201aca645b6299c9ebefebdc3a79c5484d890d56ba745497a` |
| Phase 6 conformance index | `c03b7e975afd5e275c469672696c4f2129ca8d88ea074f13e58e50fde1383392` |

## Decision

The Phase 6 gate passes with no exception. Phase 7 may begin only after a new
explicit repository-owner authorization. No browser support, visual/pixel,
manual-accessibility, native-control, performance, stable-API, product, or
release claim is implied.
