---
title: "Phase 2 Browser Product and Support Envelope Evidence"
kind: note
created: "2026-09-02"
maturity: stable
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

## Section 2.4 — Integration and phase completion evidence

### Reproducible verification

| Check | Command or method | Result |
| --- | --- | --- |
| Complete product-envelope matrix | `python3 validate_browser_product_envelope.py` | Passed: 5 browser configurations, 10 evidence classes, 11 toolchain inputs, 6 BH-01 records, 6 modes, 3 profiles, 12 capabilities, 9 trust boundaries, 12 deployment prerequisites, 7 fallbacks, 8 paper scenarios, and 5 forbidden claims. |
| Envelope negative-path tests | `python3 -m unittest test_validate_browser_product_envelope.py` | Passed: 17 tests. |
| Corpus structure and links | `python3 validate_archive.py` | Passed: 80 completed documents, 14 directories, 513 local links, and 28 source notes. |
| Archive validator tests | `python3 -m unittest test_validate_archive.py` | Passed: 8 tests. |
| Patch hygiene | `git diff --check` | Passed with no whitespace errors. |
| Evidence-state audit | `jq` queries over every browser, toolchain, profile, scenario, forbidden claim, and non-evidence flag | Zero premature states or true evidence flags. |
| Project/runtime absence | Search package, profile, JavaScript, integration, and experiment trees for Mix/JavaScript manifests, Elixir/JavaScript/TypeScript sources, Wasm modules, and BEAM files | Zero matches. |

### Paper scenario review

| Scenario | Expected outcome | Review result |
| --- | --- | --- |
| Phoenix browser-local | Browser owns execution; standalone DOM owns the surface; Phoenix revalidates remote commands. | Consistent with profile, mode, trust, and capability records; still unproven. |
| Plug baseline | Standalone DOM plus Plug HTTP/security hooks; no Phoenix/LiveView closure or Phoenix-only capability. | Consistent; transitive dependency audit remains a BH-20 executable gate. |
| Headless conformance | Deterministic semantic/event/effect/accessibility/disposal traces without browser/server dependencies. | Consistent; no visual or production support implied. |
| Unsupported browser | `FB-UNSUPPORTED-BROWSER`; no runtime start, bounded output, honest alternatives, cleanup. | Consistent with unsupported status and fallback obligations. |
| Missing cross-origin isolation | When the selected build requires it, `FB-CAPABILITY-UNAVAILABLE`; no policy bypass. | Consistent while isolation remains conditional pending BH-01. |
| Network loss | Safe local behavior may continue; authoritative mutations fail closed or use idempotency-approved policy. | Consistent with command trust and retry boundaries. |
| Incompatible deployment | `FB-INCOMPATIBLE-BUILD`; never attach mixed output, preserve safe content, bounded coherent reload. | Consistent with integrity, identity, replacement, and cleanup rules. |
| No JavaScript | `FB-NO-JAVASCRIPT`; static/server output and ordinary host actions remain when declared. | Consistent; no empty mount or browser-local claim. |

All eight scenarios are labeled `paper-reviewed-no-execution`; none is runtime
or browser evidence.

### Compatibility non-claim audit

The validator requires five records to remain `forbidden`: automatic
native-host support, full OTP support, general Elixir-to-Wasm AOT, WebAssembly
Component Model delivery as the UI contract, and .NET compatibility. Text
searches found these terms only in explicit non-claims, forbidden-claim rows,
or the integration audit requirement. No matrix status implies them.

### Security and deployment review

The review confirms that all client state and execution remain untrusted at the
server, every command follows authentication through audit/redacted result,
and every fallback fails closed for authority and integrity. Every deployment
prerequisite has one cell for each rendering mode. Cross-origin isolation,
COOP/COEP, worker, and storage requirements remain conditional until BH-01
selects and proves a runtime composition.

### Evidence-state and scope audit

Machine queries report:

```text
non_unsupported_browsers=0
non_candidate_toolchains=0
non_unproven_profiles=0
non_paper_scenarios=0
non_forbidden_claims=0
phase_scope_true_values=0
project_or_runtime_files=0
```

Phase 2 introduced policy documents, a JSON contract, and validation tooling
only. No dependency is pinned/tested/supported; no Mix or JavaScript project,
runtime artifact, component implementation, browser demonstration, or Phase 3
catalog inventory exists.

### Revision and review record

- Section 2.1 browser/toolchain policy revision: `ce0ecc1`.
- Section 2.2 rendering/profile revision: `f5c7b33`.
- Section 2.3 trust/deployment/fallback revision: `e39bdba`.
- Phase delivery: [PR #5](https://github.com/pcharbon70/blazex/pull/5), containing
  one final commit for each of Sections 2.1 through 2.4.
- Implementation, matrix, security, and deployment review: Codex under the
  repository owner's instruction; the owner authorized one PR and immediate
  merge for this phase.
- Independent second-party review remains the Phase 6 BH-00 gate.

### Risks and assumptions assigned to BH-01 or later gates

- Resolve exact Popcorn, AtomVM, Elixir, OTP, Phoenix, LiveView,
  LocalLiveView, Mix, JavaScript tooling, browser, and OS identities.
- Determine whether the candidate build can reproduce and boot on the browser
  rows, including mobile and constrained environments.
- Inventory and decide every private API dependency and maintenance burden.
- Resolve whether cross-origin isolation is required and compatible with
  application assets, embedding, OAuth/payment, and third-party services.
- Record artifacts, provenance, clean rebuild, security update, runtime subset,
  payload, startup, memory, event, accessibility, and failure evidence.
- Defer prerender/activation proof to BH-18 and Plug closure proof to BH-20.

### Section result

All local integration checks and paper scenarios pass. The records form one
bounded browser-product envelope while preserving every feasibility unknown,
and the single Phase 2 PR is open without Phase 3 catalog work. Section 2.4 and
Phase 2 are complete.

## Phase 2 delivery status

- Complete in PR #5; later executable evidence remains assigned to the named
  BH-01, BH-18, BH-20, and Phase 6 gates.

## Connections

- [Phase 2 plan](phase-02-browser-product-and-support-envelope.md)
- [BH-00 plan](README.md)

## Sources

- [Browser host implementation milestones](../../../20-notes/browser-host-implementation-milestones.md)
- [Canonical vocabulary](../../../20-notes/blazex-canonical-vocabulary.md)
