---
title: "BH-01 Phase 6 Phoenix Trust Boundary and Adapter Isolation Evidence"
kind: note
created: "2026-09-04"
maturity: stable
tags:
  - bh-01
  - browser
  - implementation-evidence
  - liveview
  - phoenix
  - security
aliases:
  - "BH-01 phase 6 evidence"
---

# BH-01 Phase 6 Phoenix Trust Boundary and Adapter Isolation Evidence

## Decision

BH-01 Phase 6 is complete with a narrow `go` result. In the exact pinned
Chrome for Testing 152.0.7977.75/Linux profile, one normalized DOM action
crossed the Elixir runtime, bounded bridge, same-origin browser transport,
Phoenix endpoint, server authority, audit, public result, and DOM update. The
browser proposed a typed counter intent; it did not provide trusted identity,
role, authorization, CSRF, session, or authoritative resource state.

The server re-established every authority-bearing fact from its cookie session
and current state. An allowed command changed the resource exactly once, an
exact replay returned the original result without another effect, and stale,
rate-limited, unauthorized, expired, transaction-failed, server-error,
disconnect, timeout, and disposal paths remained bounded. Diagnostics and
retained evidence contain no session identifier, CSRF value, role rule,
credential, cookie, or stack trace.

LiveView 1.2.11 and LocalLiveView 0.1.0 remain optional, high-risk candidates.
Their private surfaces, exact package artifacts, call-site lines, compatibility
descriptor, patch fixture, and disable behavior are owned by
`blazex_renderer_dom_liveview`. The adapter enables only for the exact
descriptor, requires a full patch after reconnect, drops duplicate/stale data,
and selects standalone DOM explicitly on configuration or compatibility
mismatch. No private renderer structure entered the runtime, standalone DOM,
server authority, Plug boundary, headless boundary, or portable package.

This is feasibility evidence, not product support. The identity store,
counter, transport route, adapter descriptor, and patch protocol are disposable
fixtures. Actual LiveView rendering was not adopted as BlazeX semantics; Plug
and headless remain dependency contracts rather than executable profiles. Phase
7 is eligible but is not authorized by this decision.

## Section results

### Section 6.1 — Minimal Phoenix feasibility profile

The Phoenix profile now composes a path-owned `blazex_phoenix` authority,
encrypted and signed strict-same-site session cookie, readiness route, and
loopback/test-only identity, reset, expiry, and redacted-state controls. The
server package owns deterministic identity roles, opaque sessions, CSRF
digests, current resource state, idempotency, rate, and audit storage without a
Phoenix dependency. Section revision: `b39bdeb`.

### Section 6.2 — Authenticated and authorized command

The closed `blazex.bh01.server-command/0.1` contract allows one
`counter.increment` action with exact fields, bounded identifiers and body,
one-unit payload, correlation, idempotency, and expected resource version. The
Phoenix command plug validates origin, JSON media/body, cookie session, and
CSRF; `blazex_phoenix` then validates schema, loads server-owned identity and
current state, authorizes, rate-checks, applies once, records a redacted audit,
and returns `blazex.bh01.server-result/0.1`.

The runtime holds only a public counter projection and pending correlation.
The host owns the single allowlisted fetch, 1.5-second timeout, abort
controllers, test session bootstrap, and disposal. Unit and profile tests cover
malformed, oversized, unknown, anonymous, expired/revoked, CSRF, cross-origin,
unauthorized, stale, replay, conflict, rate, transaction, server error,
duplicate/stale result, retry, and disposal behavior. Section revision:
`8cc8851`.

### Section 6.3 — LiveView and LocalLiveView isolation

The private-API inventory now binds each candidate surface to the exact Hex
artifact and source/call-site line spans. The adapter package owns a narrow
compatibility probe and disposable patch translator. Exact versions and seven
surface groups can become `eligible`; any version, field, or surface mismatch
returns `disabled` with `standalone-dom`. Enabled fixture tests cover full/diff
translation, malformed envelopes, duplicate/stale generation or sequence,
disconnect, reconnect/full-reset, explicit disable, and disposal. The Phoenix
health record reports candidate eligibility and versions without activating a
hidden fallback. Section revision: `b3281b4`.

### Section 6.4 — Standalone DOM, Plug, and headless separation

The browser AVM fixture and standalone DOM adapter run independently with
dependency sets `{popcorn}` and `{}` respectively. A source and manifest
verifier rejects LiveView adapter imports from the runtime fixture, browser
host, standalone DOM, or server authority. It also checks the Phase 2 qualified
Plug closure contains only Plug, Plug Crypto, MIME, and Telemetry, while the
inactive headless contract depends inward and excludes browser/runtime/server
packages. Those manifests explicitly avoid claiming executable Plug or
headless profiles. Section revision: `1dbcbfd`.

### Section 6.5 — Actual-browser integration and gate

The retained browser run used the digest-pinned Elixir image, Node 26.8.1,
Playwright Core 1.62.1, and Chrome for Testing 152.0.7977.75. The observed
positive path rendered counter value/version `1/1` from a real click, then
accepted one explicit command to `2/2`; an exact replay returned `replayed=true`
with authoritative state still `2/2`. Five correlated audit events recorded
accepted, accepted, replayed, stale, and rate-limited outcomes, with exactly two
effects.

The browser matrix returned `authorization-denied`, `session-invalid`,
`state-stale`, `rate-limited`, `transaction-failed`, `server-unavailable`,
`transport-unavailable`, and `transport-timeout` as expected. Disconnect retry
succeeded once. Disposing during transport prevented runtime result delivery.
Final host state had zero pending bridge and server requests, zero DOM roots,
listeners, and nodes, an empty lifecycle resource map, and cleared browser-side
session configuration.

The first integration attempt found that `Regex.match?/2` reached Erlang's
unavailable `re` NIF in AtomVM. Identifier and error-code validation now use
bounded byte predicates, and the dependency/source verifier rejects a runtime
fixture regression to `Regex` or `~r/`. The complete browser matrix passed
after rebuilding the AVM and governed profile.

## Gate and limitations

No BH-01 stop condition was triggered. Server authority no longer depends on
client presentation, private renderer state, or role hints. Private LiveView
coupling remains isolated and removable; the local DOM slice and its retained
Phase 5 proofs pass without that adapter.

- One exact headless Chromium/Linux environment was exercised; all browsers
  remain unsupported.
- Actual LiveView/LocalLiveView rendering, channel transport, and private diff
  execution were not made BlazeX contracts or product behavior.
- Plug-only and headless profiles remain non-executable boundary manifests.
- Authentication, persistence, multi-node state, production HTTPS/proxy,
  security stress, performance, accessibility, and cross-browser quality remain
  outside this phase.
- Popcorn's existing CSP `unsafe-eval` requirement and unpruned AVM remain open
  feasibility risks.

## Delivery record

- Section 6.1 revision: `b39bdeb`.
- Section 6.2 revision: `8cc8851`.
- Section 6.3 revision: `b3281b4`.
- Section 6.4 revision: `1dbcbfd`.
- Section 6.5 is the final coherent commit in the single Phase 6 PR.

## Connections

- [Phase 6 plan](phase-06-phoenix-trust-boundary-and-liveview-isolation.md)
- [BH-01 plan](README.md)
- [Phase 5 evidence](phase-05-implementation-evidence.md)
- [Phase 6 raw browser evidence](../../../../../integration/fixtures/raw-evidence/bh01-phase6-trust-and-isolation.json)
- [Phase 6 authorization](../../../assets/bh-01-baseline/blazex-bh-01-phase-06-authorization-v0.1.0.json)
- [Phase 6 validation log](../../../assets/bh-01-baseline/blazex-bh-01-phase-06-validation-log-v0.1.0.txt)
- [Phase 6 completion decision](../../../assets/bh-01-baseline/blazex-bh-01-phase-06-completion-v0.1.0.json)
