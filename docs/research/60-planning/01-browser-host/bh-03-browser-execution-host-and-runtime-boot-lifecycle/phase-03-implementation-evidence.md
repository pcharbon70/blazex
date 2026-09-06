---
title: "BH-03 Phase 3 Implementation Evidence"
kind: note
created: "2026-09-06"
maturity: stable
tags:
  - artifact-integrity
  - bh-03
  - implementation-evidence
  - runtime-startup
aliases:
  - "BH-03 phase 3 evidence"
---

# BH-03 Phase 3 Implementation Evidence

Back to phase: [Phase 3 plan](phase-03-artifact-acquisition-runtime-startup-and-readiness.md)

## Decision

BH-03 Phase 3 passes its active gate. A successful Phase 2 pre-acquisition
result can now acquire exactly the declared runtime module, WebAssembly module,
and application bundle under fixed per-role and aggregate limits. Bytes are
published only after response, size, digest, and WebAssembly checks all pass.

The browser loader can hand those verified bytes to one isolated runtime
transport, bind the Popcorn startup descriptor, transfer the application
bundle at `/bundle.avm`, and resolve an attempt-scoped handle only after the
exact readiness event matches both attempt and manifest generations. Every
failure releases attempt-owned resources.

## Executable behavior

- `artifact-acquisition.js` requires the Phase 2 gate protocol and eligible
  decision, preserves the three-role order, uses no-store same-origin fetches,
  rejects redirects and transformed responses, bounds streams before
  allocation, verifies SHA-256, validates WebAssembly structure, and publishes
  the complete set atomically.
- `runtime-startup.js` owns a single attempt, adapter descriptor, abort path,
  transport, timer, event correlation, readiness resolution, and failure
  cleanup. Its ready handle is deliberately not a shared-runtime registry.
- `BlazeX.Runtime.Popcorn.Startup` publishes the cross-language descriptor for
  the retained FissionVM/Popcorn artifact, 256 memory pages, `/bundle.avm`, the
  inherited boot entrypoint, and `popcorn_app_ready`.
- The versioned Phase 3 fixture set covers ten positive and negative cases;
  JavaScript tests execute these boundaries with an injected transport.

## Active validation gate

| Gate | Result |
| --- | --- |
| Pinned Elixir format/tests in runtime adapter, browser host, and Phoenix profile | passed; 3 projects, 20 tests, 0 failures |
| JavaScript build and unit/conformance tests | passed; 15 test files, 0 failures |
| Runtime build-contract verifier and tests | passed; contract PASS and 9 tests |
| Complete research Python suite | passed; 248 tests |
| Research validators and deterministic generators | passed; 18 validators and 4 generator checks |
| JSON parsing, archive validation, tracked completion paths, and patch hygiene | passed; exact archive counts recorded in the validation log |

The pinned Mix image is Elixir 1.17.3 / OTP 26 at
`docker.io/hexpm/elixir@sha256:8d03cfb52e3fa3f5d83d749942b7c45c966dda48a7c4ba4f069390379b59fc39`.
The remaining tools are Node 24.3.0, npm 11.4.2, Python 3.12.12, Git 2.49.0,
and jq 1.7 on the Linux x86-64 development host. The normalized command record
is the [Phase 3 validation log](../../../assets/bh-03-baseline/blazex-bh-03-phase-03-validation-log-v0.1.0.txt).

## Evidence boundary

The three retained profile artifact files were checked directly against their
Phase 2 byte counts and SHA-256 declarations and remain within the new limits.
The active Phase 3 startup tests use those same contracts with small governed
payloads and an injected transport. They do not claim that a real browser
executed the retained Popcorn runtime; active browser composition belongs to
Phase 6.

Browser, shared-runtime, root, failure-execution, measurement, and acceptance
result arrays remain empty. The attempt `release` operation is resource
cleanup only; deterministic shared-runtime shutdown, runtime-loss handling,
retry, and fallback remain later work.

Public APIs remain experimental, all browser/platform support remains
unsupported, and deferred platform, device, Safari, second-host, and manual
accessibility qualification is unchanged. Phase 4 is eligible but requires
new explicit repository-owner authorization.
