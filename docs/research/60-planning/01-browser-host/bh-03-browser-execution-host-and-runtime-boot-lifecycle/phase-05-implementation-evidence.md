---
title: "BH-03 Phase 5 Implementation Evidence"
kind: note
created: "2026-09-06"
maturity: stable
tags:
  - bh-03
  - fallback
  - implementation-evidence
  - runtime-recovery
  - shutdown
aliases:
  - "BH-03 phase 5 evidence"
---

# BH-03 Phase 5 Implementation Evidence

Back to phase: [Phase 5 plan](phase-05-shutdown-runtime-loss-mismatch-and-fallback.md)

## Decision

BH-03 Phase 5 passes its active gate. The shared runtime registry now owns a
bounded, idempotent shutdown sequence: it stops accepting roots, drains and
disposes each retained root, requires a matching scope/generation runtime
acknowledgement, releases the runtime exactly once on every terminal path, and
retains a stopped tombstone.

An exact active-generation loss report quiesces the old runtime and roots before
making at most one delayed replacement. Registered, ready, and disposed roots
replay through the same scope, registry, and root handles. The registry returns
to ready only after every replay succeeds. A stale report is rejected without
mutation; a non-retryable loss, replacement failure, replay failure, or second
loss converges to a bounded fallback decision with no partial ready state.

## Executable behavior

- `runtime-registry.js` implements the registry-only shutdown capability,
  correlated shutdown acknowledgements, exact-generation loss reports, one
  100 ms replacement delay, recovery publication, and stopped/fallback records.
- `root-lifecycle.js` retains the last acknowledged root intent, stops bridges
  on loss, and replays registered, ready, and disposed states through the same
  handles without granting those handles runtime release ownership.
- `BlazeX.Host.Browser.Lifecycle` publishes matching dependency-free shutdown,
  loss, replay, and fallback vocabulary.
- Versioned Phase 5 fixtures name sixteen positive and negative conformance
  cases. JavaScript tests exercise them through deterministic injected
  transports; no browser-profile composition is present.

## Active validation gate

| Gate | Result |
| --- | --- |
| Pinned Elixir format/tests in runtime adapter, browser host, and Phoenix profile | passed; 3 projects, 21 tests, 0 failures |
| JavaScript build and unit/conformance tests | passed; 19 test files, 0 failures |
| Runtime build-contract verifier and tests | passed; contract PASS and 9 tests |
| Complete research Python suite | passed; 268 tests |
| Research validators and deterministic generators | passed; 20 validators and 4 generator checks |
| JSON parsing, archive validation, tracked completion paths, and patch hygiene | passed; exact archive counts recorded in the validation log |

The pinned Mix image is Elixir 1.17.3 / OTP 26 at
`docker.io/hexpm/elixir@sha256:8d03cfb52e3fa3f5d83d749942b7c45c966dda48a7c4ba4f069390379b59fc39`.
The remaining tools are recorded by exact version in the normalized
[Phase 5 validation log](../../../assets/bh-03-baseline/blazex-bh-03-phase-05-validation-log-v0.1.0.txt).

## Evidence boundary

Shutdown, loss, replacement, replay, and fallback are injected-transport or
pure-decision unit conformance. The retained runtime module, WebAssembly module,
and application bundle remain declaration-bound inputs; this phase does not
claim a browser executed them. The Phoenix profile is regression-tested only;
it does not compose the new reusable lifecycle in Phase 5.

Fallback is a redacted record, not DOM or HTML presentation. Browser results,
resource/reliability measurements, and BH-03 acceptance evidence remain empty.
Public APIs remain experimental and all browser/platform support remains
unsupported. Phase 6 is eligible but requires separate repository-owner
authorization.
