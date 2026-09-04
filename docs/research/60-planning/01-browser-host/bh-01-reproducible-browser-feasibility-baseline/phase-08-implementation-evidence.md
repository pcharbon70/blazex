---
title: "BH-01 Phase 8 Browser Compatibility and Accessible Fallback Matrix Evidence"
kind: note
created: "2026-09-04"
maturity: stable
tags:
  - accessibility
  - bh-01
  - browser-compatibility
  - implementation-evidence
aliases:
  - "BH-01 phase 8 evidence"
---

# BH-01 Phase 8 Browser Compatibility and Accessible Fallback Matrix Evidence

## Decision

BH-01 Phase 8 is complete as governed work, but its gate is **blocked**. The
required five-row matrix was not reduced to match available infrastructure.
Only Chrome for Testing 152.0.7977.75 on the pinned Linux environment could run
as a required row. Stable Firefox, Chrome Android, Safari on macOS, and Safari
on iOS/iPadOS could not execute with exact browser, operating-system/device,
driver, and evidence authority. The available Chrome row also lacks required
assistive-technology and physical-input review. Phase 9 is therefore not
eligible and is not authorized.

Two additional probes provide useful but strictly non-substituting evidence.
Playwright's patched Firefox 153 engine and Linux WebKit MiniBrowser 26.5 ran
the same prerequisite, behavior/trust, accessibility/input, and compatibility
suites. Their automated outcomes matched the required Chrome run except for
informational browser-default tab-wrap and focus-outline observations. The
Firefox probe is not stable Firefox evidence, and Linux WebKit is not macOS or
mobile Safari evidence.

All browsers remain unsupported. This decision is not browser support,
accessibility conformance, mobile compatibility, a dependency-version range,
production readiness, or security certification.

## Immutable final execution

Section 8.4 added an accessible, user-controlled capability recheck plus a
stable public diagnostic code and correlation identity to the fallback page.
That intentionally changed the generated profile after the first prerequisite
and behavior runs. The final gate detected the stale profile identity, rejected
those runs for matrix completion, rebuilt the profile, and reran all twelve
locally executable browser/scenario-family combinations. Every final record
contains profile-manifest SHA-256
`818ac7b967db6519c766f9d1fff80455cc92d205e3f188252e6da27258ee4aad`.
No automatic retries or quarantines were used.

The final execution comprises four scenario families in one required browser
and two unqualified engine probes:

- prerequisites, policy failure, alternate loading, and lifecycle changes;
- local behavior, server trust, resilience subset, diagnostics, and cleanup;
- accessible fallback, no-JavaScript, keyboard/focus, form input, reduced
  motion, and forced colors;
- manifest, runtime/bundle, artifact/cache, browser-feature, renderer-data,
  server/client-generation, and adapter compatibility.

Raw JSON traces were the governed evidence form. Screenshots and video were not
required for the machine-semantic scenarios and were not captured. Manual
assistive-technology and physical/mobile interaction evidence remains blocked,
not silently replaced by automation.

## Required matrix result

| Required configuration | Environment | Automated result | Manual result | Overall |
| --- | --- | --- | --- | --- |
| `BR-CHROMIUM-DESKTOP` | Chrome for Testing 152.0.7977.75, Linux x86-64 | Prerequisite, behavior/trust, fallback/input, and exact-pin compatibility suites passed | Screen reader and physical keyboard review unavailable | Blocked manual evidence |
| `BR-FIREFOX-DESKTOP` | Stable Firefox executable exists, but no qualified pinned automation protocol | Not executed | Not executed | Environment-blocked |
| `BR-CHROMIUM-ANDROID` | No exact Android device/emulator, browser build, or automation endpoint | Not executed | Not executed | Environment-blocked |
| `BR-WEBKIT-DESKTOP` | No macOS Safari host or `safaridriver` | Not executed | Not executed | Environment-blocked |
| `BR-WEBKIT-MOBILE` | No iPhone/iPad simulator or device, Xcode host, or Mobile Safari build | Not executed | Not executed | Environment-blocked |

Environment-blocked is neither a product pass nor a product failure. It does
block the Phase 8 gate because the support envelope requires all five rows.

## Section results

### Section 8.1 — Browser environments and matrix governance

The environment catalog materializes every required row, including unavailable
ones, with exact missing controls and evidence requirements. Scheduling forbids
silent omission, automatic retries, probe substitution, and support claims.
One qualified Chrome/Linux environment was available; four required rows were
environment-blocked. The Firefox and Linux WebKit executables were admitted
only as experimental probes. Section revision: `24f6958`.

### Section 8.2 — Prerequisite matrix

WebAssembly validation, memory/table behavior, shared memory, workers, modules,
streaming and buffered loading, structured transfer, timers, secure context,
cross-origin isolation, response policy, offline/online transition, restart,
navigation, and cleanup were exercised in all executable environments. Missing
WebAssembly/worker capability chose static fallback, missing streaming chose
alternate loading, and missing isolation chose unsupported fallback. None
partially activated the runtime. Section revision: `e7c5f88`.

### Section 8.3 — Behavior, trust, resilience, and resources

All executed environments produced semantic trace SHA-256
`6933d006d378292a34b542d8fdc8c2a0fa0d10ee48388a0a9b42fc2224b39bbc`.
Nested keyed state, reorder, input/change/blur validation, timer completion,
duplicate-message drain, and disposal matched. Authorized, replayed, stale,
denied, forged, disconnected, and recovered server commands preserved server
authority and applied zero unauthorized effects. Three lifecycle generations
per environment converged DOM, bridge, and server pending resources to zero;
structured diagnostics remained correlated and redacted. The complete Phase 7
failure/resource evidence remains the broader retained stress basis. Section
revision: `083c587`.

### Section 8.4 — Accessible fallback and input

The fallback surface now retains meaningful server-rendered content, a polite
status relationship, a descriptive message, a user-controlled recheck action,
and bounded diagnostic metadata. Missing capability, missing isolation, and
no-JavaScript paths avoid partial activation. Keyboard order and activation,
visible focus, focus retention, rapid/composition-like input, input/change/blur,
validation relationships, and disabled/read-only rejection passed automation.
Reduced-motion and forced-color emulation preserved readiness and visible
focus. Static content and explicit unavailability applied to the fixture; the
other five component fallback values were explicitly not applicable. No screen
reader, physical keyboard, touch, virtual-keyboard, rotation, background, or
memory-pressure evidence was inferred. Section revision: `b14cb8f`.

### Section 8.5 — Compatibility and private APIs

All seven mismatch categories failed before unsafe use or partial mutation.
Manifest schema, application bundle identity, Wasm artifact/cache identity,
browser capability, renderer batch/generation, and bridge generation failures
were explicit and bounded. A fresh exact baseline after the mismatch contexts
matched the original semantic state. The optional LiveView adapter remains
confined to `packages/blazex_renderer_dom_liveview`, rejects a simulated
Phoenix LiveView 1.2.12 descriptor, and falls back to standalone DOM. No
adjacent Phoenix, Phoenix LiveView, or LocalLiveView package was locally
available, installed, or credited. Only Phoenix 1.8.13, Phoenix LiveView
1.2.11, and LocalLiveView 0.1.0 form the authoritative candidate set. Section
revision: `b84aaeb`.

### Section 8.6 — Integration gate and evidence publication

The final gate composes the retained Phase 7 gate, five Phase 8 matrix
verifiers, mutation tests, scenario schema, generated-profile verification,
package/profile tests, JavaScript tests, archive validation, and whitespace
validation. It verifies all twelve raw browser records against one profile
hash and rejects probe substitution, missing rows, manual-evidence overclaim,
partial activation, semantic divergence, unauthorized effects, resource
retention, compatibility-range claims, stale evidence, and accidental Phase 9
authorization.

The implementation work is complete, but the product gate is blocked by
environment and manual-evidence availability. This is a terminal Phase 8
decision under the current authorized scope, not permission to proceed with
Phase 9.

## Proof and risk disposition

- Runtime boot, nested state, form events, timer/message behavior, DOM updates,
  server authority, fallback automation, fail-closed compatibility, diagnostics,
  and bounded cleanup passed in every executable environment.
- Required browser coverage is blocked at one of five available rows.
- Required accessibility evidence is blocked because no browser/assistive-
  technology pairing or physical/mobile review executed.
- Mobile performance and lifecycle risk remains open because no Android or
  iOS/iPadOS device environment exists.
- Private-API risk remains high but confined; exact pins and standalone-DOM
  fallback remain mandatory.
- Popcorn's `unsafe-eval` CSP requirement, performance budgets, payload
  economics, mobile viability, and production deployment/security remain open.

## Delivery record

- Section 8.1 revision: `24f6958`.
- Section 8.2 revision: `e7c5f88`.
- Section 8.3 revision: `083c587`.
- Section 8.4 revision: `b14cb8f`.
- Section 8.5 revision: `b84aaeb`.
- Section 8.6 is the final coherent commit in the single Phase 8 PR.

## Connections

- [Phase 8 plan](phase-08-browser-compatibility-and-fallback-matrix.md)
- [BH-01 plan](README.md)
- [Phase 7 evidence](phase-07-implementation-evidence.md)
- [Browser matrix report](../../../../../integration/fixtures/browser_matrix/matrix-report.json)
- [Aggregate Phase 8 raw evidence](../../../../../integration/fixtures/raw-evidence/bh01-phase8-browser-matrix.json)
- [Phase 8 governed scenario](../../../../../integration/fixtures/scenarios/bh01-phase8-browser-matrix.json)
- [Phase 8 authorization](../../../assets/bh-01-baseline/blazex-bh-01-phase-08-authorization-v0.1.0.json)
- [Phase 8 validation log](../../../assets/bh-01-baseline/blazex-bh-01-phase-08-validation-log-v0.1.0.txt)
- [Phase 8 completion decision](../../../assets/bh-01-baseline/blazex-bh-01-phase-08-completion-v0.1.0.json)
