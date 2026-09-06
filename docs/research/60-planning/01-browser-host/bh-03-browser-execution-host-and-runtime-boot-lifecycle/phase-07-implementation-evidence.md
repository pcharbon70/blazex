---
title: "BH-03 Phase 7 Implementation Evidence"
kind: note
created: "2026-09-06"
maturity: stable
tags:
  - bh-03
  - browser-host
  - implementation-evidence
  - measurement
  - reliability
aliases:
  - "BH-03 phase 7 evidence"
---

# BH-03 Phase 7 Implementation Evidence

Back to phase: [Phase 7 plan](phase-07-resource-reliability-and-startup-measurements.md)

## Decision

BH-03 Phase 7 passes its active observational gate. The separate `/bh03/`
profile now exposes bounded diagnostic clocks, the observed 256-page Wasm
memory allocation, and one single-use measurement-root operation. The active
runner discards one warm-up, retains five complete lifecycle samples per
browser, exercises eight measurement roots in addition to the two profile
roots, closes the registry, and verifies all ten roots are disposed and the
runtime iframe is removed.

The identical plan passed in Linux Chrome 140.0.7339.80 and Firefox 153.0.
Across the ten retained samples, every profile used one shared runtime, reached
ten roots, received 43 Elixir acknowledgements by shutdown, disposed all roots,
released the runtime, and retained zero runtime iframes. Identity mismatch,
unsupported prerequisites, and unavailable runtime artifacts also converged to
their exact closed fallback in both browsers, for six declared-failure passes.

## Descriptive timing observations

| Browser | Retained samples | Startup-to-ready median | Eight-root cycle median | Shutdown median |
| --- | ---: | ---: | ---: | ---: |
| Linux Chrome 140.0.7339.80 | 5 | 218.090 ms | 115.990 ms | 13.640 ms |
| Linux Firefox 153.0 | 5 | 377.800 ms | 685.760 ms | 55.700 ms |

These values describe one run on one active Linux host. They are not budgets,
performance requirements, qualification thresholds, or comparative browser
claims. The retained [raw measurement evidence](../../../../../integration/fixtures/raw-evidence/bh03-phase7-measurements.json)
contains every sample and its minimum, median, maximum, and mean.

## Memory and resource observations

- The actual runtime frame observed a fixed 256-page shared WebAssembly memory
  allocation in every retained sample (16 MiB at 64 KiB per page).
- Chrome exposed `performance.memory.usedJSHeapSize`. The ready sample was the
  largest of the three observation points in all five repetitions, producing
  zero observed positive peak growth. This coarse API and run shape do not
  prove heap reclamation or establish a leak budget.
- Firefox exposed no governed browser heap API, so all five heap observations
  are explicitly `browser-memory-api-unavailable`. No value was fabricated and
  no pass credit follows from unavailability.
- Every retained repetition and both discarded warm-ups ended with ten disposed
  roots, an acknowledged released shutdown, and zero retained runtime iframes.

## Implementation boundary

- The Phase 6 `/bh03/` source owns profile-only measurement diagnostics and a
  dedicated measurement-aware runtime frame. The older Phase 4 frame source
  that feeds `/bh01/` remains byte-identical to the Phase 7 base.
- `BrowserRuntimeStartup` carries the frame-observed page count into its
  experimental ready state. It does not add a stable public API.
- Measurement normalization and the active runner remain test-owned code. They
  reject malformed samples, root or frame leakage, acknowledgement drift,
  inconsistent memory capability, release budgets, and support promotion.
- No reference DOM transport, Phoenix command authority, component model, or
  native host behavior is introduced.

## Evidence boundary

This phase records development observations only. Safari, mobile, physical
devices, a second host, and manual assistive-technology pairings remain
`deferred-unavailable` without pass credit. Chrome and Firefox remain
unsupported. Release budgets and BH-03 acceptance evidence remain empty.

Phase 8 is eligible but requires separate repository-owner authorization. It
owns reconciliation, review, the BH-03 acceptance decision, and any BH-04
eligibility decision.

## Connections

- [Phase 7 plan](phase-07-resource-reliability-and-startup-measurements.md)
- [BH-03 plan](README.md)
- [Phase 7 measurement contract](../../../assets/bh-03-baseline/blazex-bh-03-phase-07-contract-v0.1.0.json)
- [Development environment and deferred qualification policy](../../development-environment-and-deferred-qualification-policy.md)
