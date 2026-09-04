---
title: "BH-01 Phase 5 Local Browser Behavior and DOM Evidence"
kind: note
created: "2026-09-04"
maturity: stable
tags:
  - bh-01
  - browser
  - dom
  - implementation-evidence
  - runtime-semantics
aliases:
  - "BH-01 phase 5 evidence"
---

# BH-01 Phase 5 Local Browser Behavior and DOM Evidence

## Decision

BH-01 Phase 5 is complete with a narrow `go` result for continuing to the
Phoenix trust-boundary and LiveView-adapter isolation phase. In the exact
pinned Chrome for Testing 152.0.7977.75/Linux profile, Elixir-authored local
state, keyed nested identity, field validation, timers, and process messages
crossed the bounded bridge as fixture effects and produced renderer-owned DOM
updates. Two independent browser contexts produced byte-identical normalized
29-checkpoint traces, with no local-behavior network request after readiness.

Negative behavior and renderer cases failed closed. Parent and child crashes,
stale generations, duplicate or missing identities, disabled/read-only input,
malformed and oversized values, timer cancellation, duplicate and late
messages, missing DOM targets, duplicate listeners, partial batches, and post-
disposal traffic did not acquire unbounded authority. Both original and
replacement activations converged runtime, bridge, lifecycle, listener, node,
and root ownership at explicit stop.

This is feasibility evidence for one exact headless Chromium environment; all
browsers remain unsupported. The fixture records and closed DOM operations are
not public BlazeX contracts. No authenticated command, LiveView integration,
server validation, assistive-technology result, performance budget, or
production deployment is established. Phase 6 is eligible but not authorized.

Machine-readable observations are retained in the [Phase 5 browser
evidence](../../../../../integration/fixtures/raw-evidence/bh01-phase5-local-browser.json),
the [Phase 5 completion
record](../../../assets/bh-01-baseline/blazex-bh-01-phase-05-completion-v0.1.0.json),
and the [Phase 5 validation
log](../../../assets/bh-01-baseline/blazex-bh-01-phase-05-validation-log-v0.1.0.txt).

## Section 5.1 — Fixture behavior and observation contracts

The local-browser fixture defines four named scenario families, a versioned
record schema, and a reviewed normalization policy. Records preserve sequence,
causality, generation, semantic identity, state, failures, and unexplained
output while permitting only documented timing and opaque-runtime identity
normalization. Production/profile leakage guards keep these definitions under
`integration/fixtures`; their experimental status and public-import
prohibition are explicit. Section revision: `cd550a9`.

## Section 5.2 — Bounded DOM fixture operations

The standalone DOM package owns a closed nine-operation protocol for mounting
one root, creating known fixture node kinds, updating text/state/allowlisted
properties and relationships, binding five event types, observing focus, and
removing owned nodes. It rejects arbitrary HTML, scripts, selectors, styles,
global mutation, unknown tags/properties/events, code values, stale generation,
oversized input, duplicate listeners, missing targets, and post-disposal use.
Operations are preflighted so a failed batch cannot partially mutate the DOM.
Browser events become bounded scalar records before runtime delivery. Section
revision: `7fc7782`.

## Section 5.3 — Local and nested state identity

The disposable Elixir fixture owns a parent and independent keyed children,
with explicit generation, instance, restart, sequence, and stale-drop state.
The browser scenario exercises parent/child updates, insertion, reorder,
removal, replacement, child crash, parent crash, late output, duplicate and
missing keys, and generation replacement. Keyed reorder preserves child
identity; replacement creates a new identity; child crash is isolated; parent
restart resets only the parent subtree and preserves sibling form/async
ownership. Section revision: `e78113a`.

## Section 5.4 — Form input and validation

One representative field normalizes input, change, focus, blur, reset, and
composition-like observations without retaining browser event objects.
Deterministic local validation covers empty, too-short, valid, rapid, repeated,
disabled, read-only, stale-validation, malformed, oversized, reset, disposal,
and remount cases. Label, help, and error relationships remain correlated with
the DOM value, invalid state, and runtime snapshot. Phoenix changesets and
server authority stay outside this fixture. Section revision: `f5f0ee1`.

## Section 5.5 — Timers, messages, DOM effects, and observations

Bounded one-shot and repeated timers, cancellation, controlled crash/retry,
duplicate messages, late messages, stale generations, and disposal update
visible state through the same effect boundary. The host records command,
event, effect-to-DOM, next-paint, bridge, lifecycle, memory-page, listener,
root, node, timer, pending-message, process, and mailbox observations. These
are preliminary samples only and do not pass a budget. Section revision:
`7332b2e`.

## Section 5.6 — Complete actual-browser integration gate

### Controlled environment

- Runtime/server build: digest-pinned `hexpm/elixir`, Elixir 1.17.3,
  Erlang/OTP 26.2.5.13, Phoenix 1.8.13, Bandit 1.12.5, Popcorn 0.3.3, and the
  retained AtomVM-in-Wasm runtime.
- Browser harness: Node 26.8.1, npm 11.19.0, Playwright Core 1.62.1.
- Browser: Chrome for Testing 152.0.7977.75 from archive SHA-256
  `a16d36890636bd72251133b27f05825f7f9269c2425b3408fa3a76e10dccd8f1`.
- Captured host: Linux 6.8.0-51-generic x86-64, localhost Phoenix endpoint on
  port 4198.
- Implementation parent: `7332b2e2ec6933eadd424f2948f2297767b06b79`.

### Repeatable positive behavior

Both complete runs passed and produced normalized trace SHA-256
`f1a45a5c94e07551892194c1481657f10e4932edab25ad4dda3f3d4304e78cf6`
over the same 29 semantic checkpoints. Those checkpoints retain runtime and
DOM generation/sequence, parent state, child keys/instances/counts/restarts,
field state, asynchronous state, stale/failure counts, resource counts, and
the complete observed fixture-node state. Timing samples are deliberately
excluded from semantic equivalence but retained separately.

The observed flow covered initial mount, parent/child mutation, keyed insert/
reorder/remove/replace, isolated failure/restart, valid/invalid/composition-
like/rapid/repeated input, focus/blur, stale validation, disabled/read-only
guards, reset, timer completion/cancel/crash/retry, duplicate/late messages,
no-op rendering, parent-restart preservation, explicit disposal, and a clean
generation-2 activation.

### Negative, network, and atomicity results

Behavior errors retained the expected typed outcomes:
`fixture-child-duplicate`, `fixture-child-missing`,
`fixture-field-disabled`, `fixture-field-read-only`,
`fixture-field-event-invalid`, `bridge-payload-string-exceeded`, and
`bridge-stopped`. Direct renderer negatives retained
`fixture-listener-duplicate`, `fixture-target-missing`,
`fixture-value-exceeded`, `fixture-renderer-disposed`, and
`fixture-generation-stale`. A two-operation batch that failed on its second
missing target left the first node text as `before`, proving no partial commit.

Each run observed only `/bh01/`, the 20 governed profile paths used by the
scenario, and the browser-created runtime-worker blob. The request slice from
post-readiness behavior through teardown was empty, demonstrating that these
local interactions did not require a Phoenix round trip. No page error or
undeclared source map was observed.

### Cleanup and preliminary accessibility/resource observations

The first and replacement stops in both runs reached `stopped` with zero DOM
roots, listeners, and nodes; zero bridge requests pending; an empty lifecycle
resource map; and zero fixture processes, timers, and pending messages. The
replacement activation reached generation 2 and completed its timer without
accepting generation-1 ownership. The fixed runtime memory observation was 256
Wasm pages. Parent-frame worker count and a runtime-wide process inventory are
not exposed and therefore remain explicit unknowns rather than inferred zeros.

The browser found one textbox named `Name`, one alert role, the expected help
and error relationships, and keyboard reachability for the field and reset
action. Focus visibility is not styled, no assistive technology was exercised,
and no accessibility compliance claim follows from these observations.

### Integration defects found and fixed

The complete run found that a simulated parent crash reconstructed the whole
fixture and therefore erased independently owned form/timer state. Restart now
reconstructs only the parent subtree, and an Elixir regression test preserves
the sibling state. It also found that host-dispatched asynchronous messages
used a compile-time generation and could replace the active generation after a
browser restart. Async dispatch now reads active process-owned state and drops
stale generation traffic; a regression test fixes that boundary. Finally,
cancelled timers were moved away from their due-time edge so repeatability
tests measure cancellation semantics instead of scheduler races.

### Abstraction-leakage and proof disposition

Dependency, source, fixture, profile, schema, and documentation checks found no
Phoenix/LiveView coupling in the standalone DOM package, no browser/DOM object
in Elixir fixture state, and no production import of the local fixture
contracts. The operation set remains closed and replaceable; no semantic tree,
component lifecycle, capability/effect model, forms API, or stable renderer
contract was introduced.

- `BX-BH01-PROOF-NESTED-STATE` receives a provisional pass; failure/resource
  stress and cross-browser closure remain Phases 7 and 8.
- `BX-BH01-PROOF-FORM-EVENT` receives a provisional pass; server authority and
  cross-browser closure remain Phases 6 and 8.
- `BX-BH01-PROOF-TIMER-MESSAGE` receives a provisional pass; stress and cross-
  browser closure remain Phases 7 and 8.
- `BX-BH01-PROOF-DOM-UPDATE` receives a provisional pass; cross-browser and
  measured-update closure remain Phases 8 and 9.

No BH-01 stop condition was triggered. The result does not weaken BH-00 or
authorize stabilization of the fixtures.

### Delivery record

- Section 5.1 revision: `cd550a9`.
- Section 5.2 revision: `7fc7782`.
- Section 5.3 revision: `e78113a`.
- Section 5.4 revision: `f5f0ee1`.
- Section 5.5 revision: `7332b2e`.
- Section 5.6 is the final coherent commit in the single Phase 5 PR.

## Limitations carried into Phase 6

- Only one headless Chromium/Linux environment ran; Firefox, WebKit, desktop
  variants, mobile browsers, constrained devices, and assistive technology
  remain untested, and all browsers remain unsupported.
- Fixture protocols and DOM operations are disposable and are not public BlazeX
  contracts or accepted BH-02 component/renderer design.
- No authenticated command, Phoenix changeset, LiveView, LocalLiveView, Plug-
  only composition, server validation, or authority boundary has been tested.
- Popcorn 0.3.3 still requires CSP `unsafe-eval`; adversarial security and
  production-safe bridge disposition remain open.
- The AVM remains unpruned. No payload, startup, interaction, memory, CPU,
  reliability, cleanup, accessibility, or mobile budget has passed.
- Worker count and runtime-wide process inventory are unavailable at the
  parent-frame boundary; later resource work must instrument or bound them.
- Reverse proxy, CDN, precompression, service worker, non-local HTTP,
  production HTTPS, deployment rollback, and browser crash recovery remain
  unverified.
- Timings are raw observations with scheduler/browser noise and cannot be used
  as performance claims.

## Connections

- [Phase 5 plan](phase-05-local-browser-behavior-and-dom-vertical-slice.md)
- [BH-01 plan](README.md)
- [Phase 4 evidence](phase-04-implementation-evidence.md)
- [Local-browser scenario catalog](../../../../../integration/fixtures/local_browser/scenario-catalog.json)
- [Phase 5 authorization](../../../assets/bh-01-baseline/blazex-bh-01-phase-05-authorization-v0.1.0.json)
