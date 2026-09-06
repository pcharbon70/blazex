---
title: "BH-03 Phase 2 implementation evidence"
kind: note
created: "2026-09-06"
maturity: stable
tags:
  - bh-03
  - browser-host
  - compatibility
  - evidence
  - manifest
aliases:
  - "BH-03 Phase 2 evidence"
---

# BH-03 Phase 2 implementation evidence

## Outcome

**Passed.** BH-03 Phase 2 implements eight exact compatibility identities in
the Elixir browser host and JavaScript loader, a reusable Popcorn adapter
identity, deterministic manifest discovery, browser/deployment prerequisite
evaluation, and strict bounded profile-manifest validation. The work follows
the [Phase 2 plan](phase-02-compatibility-identity-discovery-prerequisites-and-manifest.md).
Phase 3 is eligible but remains unauthorized.

The gate fetches only the JSON manifest. It does not fetch a declared artifact,
verify artifact bytes as Phase 3 evidence, start a runtime, load a bundle,
register a root, execute a browser scenario, or grant support.

## Authority and section commits

- Authorization: `BX-BH03-PHASE-02-AUTHORIZATION-0.1`
- Synchronized base: `0d4d70231ecc2b0f6ca839b72a5ba55bea36e590`
- Feature branch: `codex/bh-03-phase-02-compatibility-manifest`

| Section | Commit | Result |
| --- | --- | --- |
| 2.1 — Authority and executable contract | `b4344e4` | Phase 1 handoff, exact scope, four-section delivery, and Phase 3 exclusions bound |
| 2.2 — Compatibility identity and negotiation | `492c7ca` | Elixir/JavaScript identities and atomic exact-match negotiation implemented |
| 2.3 — Discovery, prerequisites, manifest, fixtures | `85dce00` | browser pre-acquisition gate, profile declaration, 27 conformance cases, and validator implemented |
| 2.4 — Inherited gate and evidence | this evidence commit | complete active gate, limitations, and next-phase state recorded |

## Implemented contract

- Eight opaque identities must match exactly; missing, unknown, duplicate,
  malformed, and mismatched entries fail as `identity-mismatch` before
  acquisition.
- One explicit, link, or meta manifest declaration resolves to an HTTP(S),
  same-origin, credential-free, fragment-free URL. Duplicates and conflicts
  fail as `manifest-invalid`.
- Six browser requirements and three deployment requirements must pass.
  Missing optional Wasm streaming selects `alternate-loading`; missing required
  capability selects `unsupported-prerequisite`.
- The JSON response is no-store, same-origin, redirect-free, and limited to
  65,536 bytes. Unknown fields, incompatible identities, invalid prerequisite
  declarations, and malformed or stale artifact declarations are rejected.
- The Phoenix profile serves a versioned BH-03 manifest with `no-store`. Its
  three declarations match the retained BH-01 artifacts byte-for-byte, but no
  Phase 3 acquisition occurred.

## Active validation gate

| Gate | Result |
| --- | --- |
| Pinned Elixir format/tests in runtime adapter, browser host, and Phoenix profile | passed; 3 projects, 19 tests, 0 failures |
| JavaScript build and unit/conformance tests | passed; 13 tests, 0 failures |
| Runtime build-contract verifier and tests | passed; contract PASS and 9 tests |
| Complete research Python suite | passed; 239 tests |
| Research validators and deterministic generators | passed; 17 validators and 4 generator checks |
| JSON parsing, archive validation, and patch hygiene | passed; exact archive counts retained in the validation log |

The pinned Mix image is Elixir 1.17.3 / OTP 26 at
`docker.io/hexpm/elixir@sha256:8d03cfb52e3fa3f5d83d749942b7c45c966dda48a7c4ba4f069390379b59fc39`.
The remaining tools are Node 24.3.0, npm 11.4.2, Python 3.12.12, Git 2.49.0,
and jq 1.7 on the Linux x86-64 development host. The normalized command record
is the [Phase 2 validation log](../../../assets/bh-03-baseline/blazex-bh-03-phase-02-validation-log-v0.1.0.txt).

## Historical diagnostic outside the active gate

An additional run of the undeclared BH-01 profile toolchain suite passed 96 of
97 tests. Its remaining canonical-boundary assertion predates BH-02 and expects
the standalone DOM package to have zero dependencies plus the old headless
activation label. Accepted BH-02 intentionally replaced those assumptions with
four renderer-neutral dependencies and an experimental activation skeleton.
No Phase 2 source or declared project test fails that assertion, so this legacy
successor-awareness debt is recorded but not rewritten within BH-03 Phase 2.

## Bound artifacts

| Artifact | SHA-256 |
| --- | --- |
| Phase 2 authorization | `6b0602f2d9d73ceb6a713c33c11729198c60943e220a2df0179fad63d76504e3` |
| Phase 2 contract | `72d8afe559f213f48955d4c116c016dac333e295fbc87fb63401a82abc6f434b` |
| JavaScript compatibility negotiation | `1e61fbc4cf2cb1cb726bc517fdec515cd95e063da900dec7e514b7b351275c00` |
| JavaScript manifest discovery | `5a9c764d4d96309a6c45d15e7661c2f6771e7e965e2d4e9259816cba775060d7` |
| JavaScript strict manifest gate | `3e6db892bd505c5aaba9e4ba460420199d8ec17b6c1e2e9ebde91e6b11916710` |
| Phase 2 fixture set | `3d4a46fbd15bfc3c7809f99e615650bd1c0c7c05e6909932242ea284b52f3d25` |
| Phase 2 integration index | `aa754155be5e211fc240622ff4b5d2265a9f770a9054c794a29b4c8dfda480b3` |
| Phoenix profile manifest | `de29c89e0a6e4f0cfd06c4bbedf4804a23384feb39c6ad6cd90096b63a3350cd` |

## Limits and decision

- Browser, runtime, root, failure-execution, measurement, and acceptance result
  arrays remain empty.
- The historical BH-01 artifact files are inputs to declaration validation, not
  new acquisition or integrity-execution evidence.
- Public APIs remain experimental and all browser/platform support remains
  unsupported.
- Deferred platform, device, Safari, second-host, and manual accessibility
  qualification remains unchanged.

Phase 2 passes without exception in its active gate. Phase 3 requires new
explicit repository-owner authorization.
