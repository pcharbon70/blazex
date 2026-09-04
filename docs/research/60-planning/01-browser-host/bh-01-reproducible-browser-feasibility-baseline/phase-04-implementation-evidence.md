---
title: "BH-01 Phase 4 Browser Host, Lifecycle, and Deployment Evidence"
kind: note
created: "2026-09-04"
maturity: stable
tags:
  - bh-01
  - browser-host
  - implementation-evidence
  - phoenix
  - webassembly
aliases:
  - "BH-01 phase 4 evidence"
---

# BH-01 Phase 4 Browser Host, Lifecycle, and Deployment Evidence

## Decision

BH-01 Phase 4 is complete with a narrow `go` result for continuing to the local
browser behavior and DOM feasibility phase. The pinned Chrome for Testing
152.0.7977.75 loaded the governed profile through the Phoenix endpoint,
verified the Emscripten JavaScript, AtomVM Wasm, and AVM bundle, reached the
Elixir application's readiness event, completed a bounded Elixir echo bridge
round trip, restarted twice, survived a warm navigation, and released every
lifecycle-owned resource after each stop.

Missing cross-origin isolation selected the explicit unsupported fallback.
Manifest network failure and runtime-Wasm integrity drift failed closed and
converged to `stopped`. The deterministic loader, bridge, lifecycle, and
deployment test matrices cover the remaining declared cache, schema,
instantiate, startup, timeout, cancellation, stale-generation, crash, retry,
navigation, and disposal cases.

This is feasibility evidence for one exact headless Chromium/Linux profile;
all browsers remain unsupported. Phase 5 is eligible but not authorized. No DOM
renderer, component behavior, Phoenix authority command, LiveView integration,
mobile result, performance budget, or production deployment is established.

Machine-readable results are retained in the [normalized browser
capture](../../../../../integration/fixtures/raw-evidence/bh01-phase4-browser.json)
and [Phase 4 completion
record](../../../assets/bh-01-baseline/blazex-bh-01-phase-04-completion-v0.1.0.json).
Exact command outcomes are retained in the [Phase 4 validation
log](../../../assets/bh-01-baseline/blazex-bh-01-phase-04-validation-log-v0.1.0.txt).

## Section 4.1 — Manifest-driven browser loading

The experimental JavaScript package now validates the manifest protocol,
generation, startup contract, artifact roles, relative same-origin URLs,
redirect behavior, byte counts, SHA-256 identities, MIME types, Wasm magic,
declared import/export contract, timeout, cancellation, and aggregate payload
bounds. Runtime loading transfers only verified module, Wasm, AVM, and startup
values to a sandboxed runtime frame. Static guards reject DOM mutation,
Phoenix/LiveView authority, unbounded fetch, dynamic code surfaces, and product
state in the loader package. Section revision: `0e99efe`.

## Section 4.2 — Explicit browser-host bridge

The bridge uses versioned request, response, error, cancel, readiness,
shutdown, diagnostic, and trace envelopes. It bounds operation names, payload
size/depth, pending concurrency, sequence, correlation, generation, timeout,
queueing, cancellation, and retained diagnostics. Values containing functions,
browser objects, DOM handles, credentials, arbitrary URLs, code, or unknown
operations fail before crossing the boundary. Stale and post-disposal messages
cannot complete a current request. Section revision: `95854d1`.

## Section 4.3 — Lifecycle and teardown

One monotonic state machine owns checking, fetching, instantiating, loading,
starting, ready, failed, stopping, and stopped transitions. Every activation
gets a new generation, exactly one terminal outcome, bounded retry policy, and
reverse-order disposal of abort controller, pagehide listener, runtime frame,
and host bridge. Repeated stop is idempotent; late traffic increments the stale
drop observation and cannot reanimate a stopped generation. Section revision:
`91de0e4`.

## Section 4.4 — Prerequisites and deployment

The browser host checks WebAssembly, workers, modules, shared memory, Atomics,
fetch, SubtleCrypto, secure context, cross-origin isolation, and streaming
before activation. Outcomes are explicit `proceed`, `alternate-loading`,
`server-fallback`, or `unsupported` decisions with user-facing text.

The Phoenix profile serves 18 governed files from `/bh01/` with exact MIME,
cross-origin isolation, no-sniff, referrer, CSP, immutable/no-store cache,
strong ETag, and single-range behavior. The profile builder rejects unexplained
files and manifest drift. Same-origin identity artifacts are canonical;
precompression, reverse proxies, CDNs, service workers, and non-local HTTP
remain unverified. Popcorn 0.3.3 currently needs CSP `unsafe-eval`, retained as
explicit security debt. Section revision: `6924c2d`.

## Section 4.5 — Actual-browser integration gate

### Controlled environment

- Elixir/Phoenix tests: digest-pinned `hexpm/elixir` image, Elixir 1.17.3,
  Erlang/OTP 26.2.5.13, Phoenix 1.8.13, Bandit 1.12.5.
- Browser harness: Node 26.8.1, npm 11.19.0, Playwright Core 1.62.1.
- Browser: Chrome for Testing 152.0.7977.75 from archive SHA-256
  `a16d36890636bd72251133b27f05825f7f9269c2425b3408fa3a76e10dccd8f1`.
- Captured host: Linux 6.8.0-51-generic x86-64, localhost port 4197.
- Runtime/application: Phase 3 Emscripten/AtomVM runtime and disposable Elixir
  browser-host AVM behind the Phase 4 Phoenix static endpoint.

### Positive observations

The cold activation reached generation 1 and emitted the ordered boundaries
`checking`, `fetching`, `instantiating`, `loading`, `starting`, and `ready`,
including manifest verification, artifact verification, frame attachment,
runtime readiness, application readiness, and root readiness. The fixture then
echoed `bh01-browser-roundtrip` through the actual runtime bridge.

Two same-page starts reached generations 2 and 3. A full page reload reached a
new generation 1 under a warm browser/cache context. All three same-page stops
and the warm-navigation stop reported `stopped`, one remaining top-level frame,
no lifecycle failure, no stale drop, no cleanup failure, and an empty owned-
resource map. The browser observed the declared cross-origin-isolated secure
localhost environment.

### Negative and fallback observations

- Removing `Cross-Origin-Embedder-Policy` prevented activation and selected
  the explicit `unsupported` fallback before runtime fetch or instantiation.
- Aborting `runtime-manifest.json` produced `fetch-failed`; activation failed
  and lifecycle cleanup converged to `stopped` with no owned resources.
- Replacing the declared Wasm SHA-256 with zeros produced
  `artifact-integrity-mismatch`; no unverified runtime started and cleanup
  converged to `stopped`.
- Unit/integration mutation matrices additionally reject stale cache identity,
  redirect/origin drift, unsupported manifests, malformed Wasm contracts,
  frame/startup failure, duplicate readiness, bridge timeout/cancel/overflow,
  stale generation traffic, retry exhaustion, runtime crash, pagehide, and
  repeated disposal.

### Network and artifact accounting

All 18 deployed files returned the declared byte count, SHA-256, MIME type, and
cache class. The Wasm endpoint returned `206` for an eight-byte range and `304`
for a matching ETag. No source map was emitted. After normalization, the actual
page network contained only `/bh01/`, the 18 declared profile paths used by the
scenario, and the browser-created runtime worker blob. There was no unexplained
same-origin or cross-origin fetch.

The retained evidence replaces random blob UUIDs, deduplicates repeated
requests, removes only nondeterministic cleanup duration, and condenses repeated
cumulative event histories. It preserves source-capture hash/size, toolchain,
scenario outcomes, generations, errors, resource counts, artifact hashes,
headers, canonical event sequences, and normalized network identities.

### Integration defects found and fixed

The first actual-browser boot showed that Emscripten could not derive a Wasm
URL from the generated blob module. The runtime-frame host now provides a
same-origin `locateFile` while still supplying the already verified
`wasmBinary`. The next run showed that raw Emscripten module startup did not
install Popcorn's JavaScript bridge before the AVM entrypoint. The frame now
configures Popcorn serialization, tracked-object handling, call/cast wrapping,
script callback, and readiness event hooks in `onRuntimeInitialized`. The
browser shell also keeps one observable state object and exposes an explicit
restart operation, allowing stopped snapshots and generation checks to remain
truthful.

### Risk and proof disposition

- `BX-BH01-PROOF-RUNTIME-BOOT` receives a provisional passing result for one
  exact controlled browser. Cross-browser closure remains Phase 8 work.
- `BX-BH01-PROOF-BROWSER-FALLBACK` receives its first observed pass for one
  missing-policy case. Accessible and complete browser fallback closure remains
  Phase 8 work.
- `BX-BH01-PROOF-ARTIFACT-ACCOUNTING` now includes browser loader, frame,
  module, Wasm, AVM, manifest, source-map absence, response, and network paths.
  Payload economics and independent clean rebuild remain open.
- Browser prerequisite, runtime semantics, artifact-accounting, and toolchain
  risks remain open but bounded by the recorded profile. No stop condition was
  triggered.
- Popcorn's evaluated JavaScript bridge is accepted only as Phase 4 feasibility
  debt; it is not a production security disposition or a portable component
  capability.

### Delivery record

- Section 4.1 revision: `0e99efe`.
- Section 4.2 revision: `95854d1`.
- Section 4.3 revision: `91de0e4`.
- Section 4.4 revision: `6924c2d`.
- Section 4.5 is the final coherent commit in the single Phase 4 PR.

## Limitations carried into Phase 5

- Only one headless Chromium/Linux environment was executed; Firefox, WebKit,
  desktop variants, mobile browsers, constrained devices, and assistive
  technology remain untested, and all browsers remain unsupported.
- No DOM, component state, identity, form, event, timer-to-DOM, accessibility,
  or renderer behavior has been implemented.
- Phoenix only serves governed static artifacts here. No authentication,
  authorization, command, LiveView, LocalLiveView, Plug-only composition, or
  server-authority result can be inferred.
- CSP requires `unsafe-eval` for the selected Popcorn bridge. A production-safe
  replacement or tightly reviewed mitigation is unresolved.
- The AVM is intentionally unpruned and no startup, payload, memory, CPU,
  interaction, reliability, or mobile budget has passed.
- Reverse proxy, CDN, precompression, service worker, deployment rollback, and
  production HTTPS behavior are specified but not exercised.
- Browser-process termination cannot emit a final in-page cleanup observation;
  lifecycle evidence covers explicit stop, pagehide/reload, failures, and test
  context closure.
- The bridge remains an experimental profile boundary and does not establish a
  public BlazeX component, renderer, capability, or host API.

## Connections

- [Phase 4 plan](phase-04-browser-host-loader-lifecycle-and-deployment.md)
- [BH-01 plan](README.md)
- [Phase 3 evidence](phase-03-implementation-evidence.md)
- [Phase 4 deployment contract](../../../../../profiles/browser_phoenix/assets/phase4/deployment-contract.json)
- [BH-01 entry manifest](../../../assets/bh-00-release/blazex-bh-01-entry-manifest-v0-1-0.md)
