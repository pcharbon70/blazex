---
title: "BH-03 Phase 1 implementation evidence"
kind: note
created: "2026-09-06"
maturity: stable
tags:
  - bh-03
  - browser-host
  - evidence
  - runtime-lifecycle
aliases:
  - "BH-03 Phase 1 evidence"
---

# BH-03 Phase 1 implementation evidence

## Outcome

**Passed.** BH-03 Phase 1 binds the accepted BH-02 handoff, freezes the
eight-phase milestone plan and lifecycle vocabulary, activates five existing
repository/evidence boundaries, and enforces the activation envelope with a
fail-closed validator. The completed work follows the
[Phase 1 activation plan](phase-01-authorization-handoff-reconciliation-and-boundary-activation.md).
Phase 2 is eligible but remains unauthorized.

This is an activation result, not a runtime-lifecycle proof. Discovery,
manifest validation, artifact acquisition, startup, readiness, shared-runtime
registration, root lifecycle, shutdown, recovery, browser conformance, and
resource measurements all remain unimplemented or unexecuted. Public APIs are
experimental and support remains unsupported.

## Authority and delivery

- Authorization: `BX-BH03-PHASE-01-AUTHORIZATION-0.1`
- Synchronized base: `65797d7ea05cc112e45cab1a091baea621ba6b6e`
- Feature branch: `codex/bh-03-phase-01-activation`
- Delivery: four ordered section commits, one pull request, merge, synchronized
  `main` return, and local/remote branch cleanup

| Section | Commit | Result |
| --- | --- | --- |
| 1.1 — Authority and milestone entry | `fa68b22` | authorization, immutable handoff ledger, and eight-phase plan recorded |
| 1.2 — Vocabulary and repository boundaries | `5252f8b` | planned lifecycle contract and five truthful activation boundaries recorded |
| 1.3 — Fail-closed validation | `334f047` | activation validator and negative tests added |
| 1.4 — Inherited gate and evidence | this evidence commit | full gate, immutable decision, limits, and next-phase state recorded |

## Activated boundaries

| Boundary | Phase 1 role | Evidence state |
| --- | --- | --- |
| `packages/blazex_runtime_popcorn` | runtime owner | existing adapter activated; lifecycle behavior unimplemented |
| `packages/blazex_host_browser` | browser-host owner | existing host boundary activated; lifecycle behavior unimplemented |
| `js/blazex_runtime` | browser loader owner | existing loader activated; no BH-03 behavior added |
| `profiles/browser_phoenix` | executable composition owner | existing profile activated; no BH-03 scenario added |
| `integration/bh-03` | quality owner | empty governed index; no fixture, result, or acceptance evidence |

The existing BH-01 origins remain intact. Phase 1 added no production runtime
dependency, support claim, stable public API, browser result, or canonical
acceptance-registry mutation.

## Reproducible gate

The pinned Elixir gate used Elixir 1.17.3 / OTP 26 in the immutable container
`docker.io/hexpm/elixir@sha256:8d03cfb52e3fa3f5d83d749942b7c45c966dda48a7c4ba4f069390379b59fc39`
(image ID `sha256:a2386c21edd5c612b4ed6e2731daba806177dba55baf977ee456c6e194f60d9f`).
The remaining tools were Node 24.3.0, npm 11.4.2, Python 3.12.12, Git 2.49.0,
and jq 1.7 on the Linux x86-64 development host.

| Gate | Result |
| --- | --- |
| Mix format/tests in runtime adapter, browser host, and browser profile | passed; 3 projects, 15 tests, 0 failures |
| JavaScript build and unit tests | passed; 10 tests, 0 failures |
| Runtime build verifier and Python unit tests | passed; contract PASS and 9 tests |
| Complete research Python test suite | passed; 228 tests |
| Research validators | passed; 16 validators including all BH-02 phases and BH-03 activation |
| Deterministic generators | passed; 4 generated outputs unchanged |
| Repository JSON parsing | passed |
| Archive validation | passed; final counts are retained in the normalized validation log |
| Patch hygiene | passed |

The normalized commands, exact counts, and negative cases are retained in the
[Phase 1 validation log](../../../assets/bh-03-baseline/blazex-bh-03-phase-01-validation-log-v0.1.0.txt).

## Fail-closed behavior

The focused validator suite rejects missing authority, stale bound inputs,
changed output sets, duplicated boundaries, prematurely implemented lifecycle
contracts, nonempty execution evidence, support promotion, later-phase
authorization, and a completion record whose artifact hashes or outcome state
diverge.

## Bound artifacts

| Artifact | SHA-256 |
| --- | --- |
| Phase 1 authorization | `f12f41d50d7d43892bb266e675f0aa1494e91f3738e99c5a1bfc583ac6ba7574` |
| BH-03 entry ledger | `b9c41a106e1a041c89d2c0a38716d432f1388ea8e27ea915baa042e2240225a8` |
| Phase 1 lifecycle contract | `44cd9dc05a528e7847c09868566b365d34d087f57116a44d8a23ff907ea562eb` |
| Repository activation | `75471a39821710cea0e5f16d63633985f9f61c6ce5809349be5443e44a1c69a6` |
| Empty integration index | `3fc0947fec76cfa24c3bc023f564458c5dc0c73ee42ca54769c022eb6879b0b1` |

## Limits and decision

- No BH-03 acceptance condition has executed evidence.
- No browser, platform, runtime, accessibility, security, performance, or
  release qualification is claimed by this activation gate.
- Windows, macOS, Safari, physical devices, second-host work, and manual
  assistive-technology qualification retain their governed deferrals.
- The accepted BH-02 contract and disposable BH-01 proof remain immutable
  inputs; neither becomes a BH-03 lifecycle implementation by inheritance.

Phase 1 passes without exception. Phase 2 may begin only after new explicit
repository-owner authorization.
