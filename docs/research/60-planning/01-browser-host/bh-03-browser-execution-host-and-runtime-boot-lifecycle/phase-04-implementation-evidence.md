---
title: "BH-03 Phase 4 Implementation Evidence"
kind: note
created: "2026-09-06"
maturity: stable
tags:
  - bh-03
  - implementation-evidence
  - root-lifecycle
  - runtime-registry
aliases:
  - "BH-03 phase 4 evidence"
---

# BH-03 Phase 4 Implementation Evidence

Back to phase: [Phase 4 plan](phase-04-shared-runtime-registry-and-independent-root-lifecycle.md)

## Decision

BH-03 Phase 4 passes its active gate. Concurrent callers with the same bounded
scope and complete exact compatibility identity now share one in-flight or
ready runtime scope. Different scopes start independently, incompatible reuse
fails before another startup, and a failed scope remains a deterministic
tombstone without retry or fallback.

Each ready scope owns one bounded root registry. Root identifiers are reserved
before asynchronous registration and remain unique through disposal and
remount. Each root serializes register, mount, update, move, dispose, and
remount operations through its own FIFO queue; a blocked or failed root does
not block or mutate another. State commits require acknowledgements matching
both root identity and positive operation generation.

## Executable behavior

- `runtime-registry.js` validates the complete Phase 2 identity table, bounds
  scope count, coalesces startup, reuses one ready scope, isolates different
  scopes, and retains failed scope records without retry.
- `root-lifecycle.js` reserves at most 64 roots per scope, executes only the
  five allowlisted root operations, validates bounded payloads and target
  identities, serializes per root, checks acknowledgements atomically, and
  exposes snapshots without runtime ownership.
- `BlazeX.Host.Browser.Lifecycle` publishes the same closed lifecycle
  vocabulary from the dependency-free browser host package.
- Versioned Phase 4 fixtures name twelve positive and negative conformance
  cases. JavaScript tests exercise them through an injected transport.

## Active validation gate

| Gate | Result |
| --- | --- |
| Pinned Elixir format/tests in runtime adapter, browser host, and Phoenix profile | passed; 3 projects, 21 tests, 0 failures |
| JavaScript build and unit/conformance tests | passed; 17 test files, 0 failures |
| Runtime build-contract verifier and tests | passed; contract PASS and 9 tests |
| Complete research Python suite | passed; 258 tests |
| Research validators and deterministic generators | passed; 19 validators and 4 generator checks |
| JSON parsing, archive validation, tracked completion paths, and patch hygiene | passed; exact archive counts recorded in the validation log |

The pinned Mix image is Elixir 1.17.3 / OTP 26 at
`docker.io/hexpm/elixir@sha256:8d03cfb52e3fa3f5d83d749942b7c45c966dda48a7c4ba4f069390379b59fc39`.
The remaining tools are Node 24.3.0, npm 11.4.2, Python 3.12.12, Git 2.49.0,
and jq 1.7 on the Linux x86-64 development host. The normalized command record
is the [Phase 4 validation log](../../../assets/bh-03-baseline/blazex-bh-03-phase-04-validation-log-v0.1.0.txt).

## Evidence boundary

Runtime sharing and root lifecycle are exercised with a deterministic injected
transport. The retained runtime module, WebAssembly module, and application
bundle remain declaration-bound inputs from Phase 3; this phase does not claim
that a browser executed them or that the demo controls are WebAssembly-backed.

No root owns runtime transport or runtime release. Runtime shutdown,
runtime-loss detection, retry, restart, recovery, and fallback remain Phase 5.
Browser-profile composition remains Phase 6. Browser results, resource and
reliability measurements, and BH-03 acceptance evidence remain empty.

Public APIs remain experimental, all browser/platform support remains
unsupported, and deferred platform, device, Safari, second-host, and manual
accessibility qualification is unchanged. Phase 5 is eligible but requires
new explicit repository-owner authorization.
