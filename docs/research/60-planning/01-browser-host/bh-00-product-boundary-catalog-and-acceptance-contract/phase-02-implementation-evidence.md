---
title: "Phase 2 Browser Product and Support Envelope Evidence"
kind: note
created: "2026-09-02"
maturity: developing
tags:
  - bh-00
  - browser
  - implementation-evidence
  - product-contract
aliases:
  - "BH-00 phase 2 evidence"
---

# Phase 2 Browser Product and Support Envelope Evidence

## Section 2.1 — Initial browser and toolchain support policy

### Delivered artifacts

- [BlazeX browser and toolchain support
  policy](../../../20-notes/blazex-browser-and-toolchain-support-policy.md)
  defines four browser support states, five candidate configurations, ten
  evidence classes, six toolchain states, eleven moving toolchain inputs, a
  review cadence, private-API rules, and six mandatory BH-01 records.
- The [machine-readable browser product
  envelope](../../../assets/browser-product-envelope-v0.1.json) carries stable
  IDs and the `policy-only-unproven` evidence state used by later Phase 2
  matrices.
- `validate_browser_product_envelope.py` fails closed on missing/duplicate rows,
  incomplete fields, premature support claims, missing evidence classes, or a
  toolchain input that skips the candidate state. Five focused tests exercise
  the valid contract and principal negative paths.

### Policy result

Chromium desktop/Android, Firefox desktop, Safari macOS, and Safari iOS/iPadOS
have channel-relative candidate windows and explicit qualification cadence.
They all remain `unsupported` because BH-01 has not resolved or tested exact
versions. Every toolchain layer remains `candidate`; no package, browser, or OS
combination is pinned, tested, or supported.

The policy requires desktop, mobile, memory, CPU, network, input, zoom,
contrast, direction, and assistive-technology evidence. Promotion additionally
depends on exact locks, artifacts, provenance, clean rebuild, security update,
and tested support-matrix records. A demonstration alone cannot promote a row.

### Section validation

```text
Browser product envelope validation passed: stage section-2.1; 5 browser configurations, 10 evidence classes, 11 toolchain inputs, and 6 BH-01 records checked.
Ran 5 tests ... OK
```

### Section result

Every Section 2.1 requirement has a stable prose definition and a
machine-validated record. The candidate envelope is bounded enough for BH-01
to resolve, narrow, block, or prove without converting symbolic windows into
unsupported version claims.

## Section 2.2 — Rendering and server-integration modes

### Delivered artifacts

- [BlazeX browser rendering and profile
  modes](../../../20-notes/blazex-browser-rendering-and-profile-modes.md)
  defines static fallback, server-rendered, prerendered, browser-local,
  activated, and headless output with observable identity, state, effect,
  event, focus, accessibility, mismatch, replacement, and disposal behavior.
- The contract separates the browser/Phoenix, browser/Plug, and headless
  compositions from the Phoenix and Plug server adapters and the optional
  LiveView DOM renderer adapter.
- A complete twelve-row capability matrix covers static delivery, bootstrap,
  sessions, CSRF/origin policy, typed commands, pushes, realtime, uploads,
  navigation, prerender, activation, and telemetry for all three profiles.

### Boundary result

Browser-local interaction is a browser execution-host claim, not a Phoenix
claim. Standalone DOM remains reusable without LiveView. Server-rendered output
does not imply activation, and destructive replacement cannot be labeled
activation. The Plug baseline explicitly excludes Phoenix, LiveView,
LocalLiveView, the LiveView DOM adapter, pushes/realtime, uploads, prerender,
and activation; replacement facilities require public hooks or a later named
adapter/profile.

The mode disposition table distinguishes browser 1.0 commitments from
conditional server-rendering claims and headless conformance. Every row remains
planned/unproven until its later milestone and support evidence pass.

### Section validation

```text
Browser product envelope validation passed: stage section-2.2; 5 browser configurations, 10 evidence classes, 11 toolchain inputs, and 6 BH-01 records, 6 rendering modes, 3 profiles, and 12 profile capabilities checked.
Ran 9 tests ... OK
```

Negative tests reject a missing rendering mode, incomplete profile matrix,
realtime inherited by Plug, and any Plug renderer other than standalone DOM.

### Section result

Every Section 2.2 mode, profile, adapter, capability, and exclusion has one
stable prose definition and one machine-validated matrix entry without
claiming executable behavior.

## Section 2.3 — Trust, deployment, and fallback boundaries

### Delivered artifacts

- [BlazeX browser trust, deployment, and fallback
  policy](../../../20-notes/blazex-browser-trust-deployment-and-fallback-policy.md)
  defines nine trust boundaries, the ordered remote-command validation path,
  capability/origin/CSRF and content-integrity rules, secret exclusion,
  diagnostic redaction, and absolute authorization non-equivalences.
- A twelve-row deployment matrix covers HTTPS, MIME, CSP, cross-origin
  isolation, COOP, COEP, caching, compression, integrity, workers, storage,
  and transport across all six rendering modes.
- Seven fallback records cover unavailable capability, incompatible build,
  no JavaScript, unsupported browser, unavailable runtime, network loss, and
  server loss. Every record contains bounded content, accessibility, security,
  diagnostics, retry, cleanup, and truthful-support behavior.

### Security and deployment result

Public bootstrap/authentication projections, local events, local cache,
capability results, and remote commands are explicitly non-authoritative.
Server commands authenticate, enforce origin/CSRF, decode under limits,
allowlist and schema-validate, reload trusted state, authorize, apply
replay/idempotency policy, execute, audit, and return a public result. Local
visibility, disabled state, cached state, optimistic state, or successful
JavaScript/BEAM/Wasm execution can never substitute for that path.

Cross-origin isolation, COOP, COEP, workers, and storage remain conditional
until the selected runtime/modes prove their need. A missing conditional
prerequisite selects a declared fallback rather than an unverified partial boot.

### Section validation

```text
Browser product envelope validation passed: stage section-2.3; 5 browser configurations, 10 evidence classes, 11 toolchain inputs, and 6 BH-01 records, 6 rendering modes, 3 profiles, and 12 profile capabilities, 9 trust boundaries, 12 deployment prerequisites, and 7 fallback categories checked.
Ran 13 tests ... OK
```

Negative tests reject a missing trust boundary, an incomplete per-mode
deployment row, premature conversion of cross-origin isolation from conditional
to required, and a fallback without security behavior.

### Section result

Every Section 2.3 trust, deployment, and fallback obligation is explicit in
both prose and the machine-readable envelope. The policy fails closed without
claiming that any production deployment currently satisfies it.

## Remaining Phase 2 evidence

- Section 2.4 integration and phase completion: pending.

## Connections

- [Phase 2 plan](phase-02-browser-product-and-support-envelope.md)
- [BH-00 plan](README.md)

## Sources

- [Browser host implementation milestones](../../../20-notes/browser-host-implementation-milestones.md)
- [Canonical vocabulary](../../../20-notes/blazex-canonical-vocabulary.md)
