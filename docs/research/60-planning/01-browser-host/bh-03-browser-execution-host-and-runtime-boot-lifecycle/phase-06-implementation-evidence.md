---
title: "BH-03 Phase 6 Implementation Evidence"
kind: note
created: "2026-09-06"
maturity: stable
tags:
  - active-browser-matrix
  - bh-03
  - browser-profile
  - implementation-evidence
aliases:
  - "BH-03 phase 6 evidence"
---

# BH-03 Phase 6 Implementation Evidence

Back to phase: [Phase 6 plan](phase-06-browser-profile-integration-and-active-matrix-conformance.md)

## Decision

BH-03 Phase 6 passes its active gate. A separate Phoenix-served `/bh03/`
profile composes strict manifest discovery and compatibility, all-or-nothing
artifact acquisition, isolated AtomVM/Elixir startup, the shared runtime
registry, independent root handles, intentional fallback decisions, and
registry-owned shutdown. The historical generated `/bh01/` profile was hashed
before and after the Phase 6 build and remained byte-identical.

The identical governed scenario set passed in active Linux Chrome
140.0.7339.80 and Firefox 153.0. Each row executed the actual Wasm runtime and
AVM bundle: two compatible opens caused one runtime start; two roots registered,
mounted, updated, moved, disposed, and remounted independently; eight root
operations were acknowledged by the Elixir fixture before shutdown; and three
more acknowledgements disposed both roots and stopped the runtime with matching
scope and generation.

## Active browser result

| Browser | Version | Scenarios | Result |
| --- | --- | ---: | --- |
| Linux Chrome | 140.0.7339.80 | 5 | passed |
| Linux Firefox | 153.0 | 5 | passed |

Both rows verified the 29-file governed profile inventory, isolation headers,
range and ETag behavior, one shared runtime, two ready roots, mismatch fallback,
unsupported-prerequisite fallback, and acknowledged release. The retained
[raw browser evidence](../../../../../integration/fixtures/raw-evidence/bh03-phase6-browser-matrix.json)
records exact executables, versions, scenario identity, observations, and empty
failure arrays.

## Implementation boundary

- `assets/phase6/` owns the deterministic profile source, builder, and
  fail-closed inventory verifier. Generated `/bh03/` assets remain ignored
  build output.
- `AssetPlug` serves `/bh01/` and `/bh03/` as separate roots with the same
  isolation, MIME, cache, ETag, and range guarantees.
- `js/blazex_runtime` owns discovery, verified startup, sharing, roots,
  fallback, and shutdown. Actual browser execution exposed and fixed a missing
  host binding on the default `fetch` capability; a regression test preserves
  the fix.
- The disposable browser-host AVM fixture implements only the already-frozen
  root acknowledgement and shutdown envelope required to exercise BH-03. It is
  not a component model, renderer, or public API.
- Profile-owned diagnostic HTML reflects acknowledged lifecycle state. It is
  not the BH-04 reference DOM interaction transport.

## Active validation gate

| Gate | Result |
| --- | --- |
| Pinned Elixir format/tests | passed; 4 projects, 39 tests, 0 failures |
| JavaScript build and unit tests | passed; 19 test files, 0 failures |
| Active browser profile suite | passed; 2 browsers × 5 scenarios |
| Runtime build contract and tests | passed; contract PASS and 9 tests |
| Complete research Python suite | passed; 279 tests |
| Research validators/generators | passed; 21 validators and 4 generator checks |
| JSON, archive, tracked-file, and patch hygiene | passed; exact counts in the validation log |

## Evidence boundary

This phase establishes active development-browser conformance, not production
support. Safari, mobile, physical devices, a second host, and manual
assistive-technology pairings remain `deferred-unavailable` under policy and
receive no pass credit. Phase 7 owns resource, reliability, startup, memory,
and repetition measurements; none are claimed here. BH-03 acceptance, BH-04
eligibility, public stability, publication, and support remain unclaimed.

Phase 7 is eligible but requires separate repository-owner authorization.

## Connections

- [Phase 6 plan](phase-06-browser-profile-integration-and-active-matrix-conformance.md)
- [BH-03 plan](README.md)
- [Development environment and deferred qualification policy](../../development-environment-and-deferred-qualification-policy.md)
- [BH-03 Phase 6 completion decision](../../../assets/bh-03-baseline/blazex-bh-03-phase-06-completion-v0.1.0.json)
