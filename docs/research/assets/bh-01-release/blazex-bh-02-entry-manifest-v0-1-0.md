---
title: "BH-02 Conditional Entry Manifest v0.1.0"
kind: note
created: "2026-09-05"
maturity: stable
tags:
  - bh-02
  - entry-manifest
  - host-neutral
---

# BH-02 Conditional Entry Manifest v0.1.0

- Status: `ready-pending-final-integration-and-explicit-authorization`
- Authorized: `false`
- May start: `false`

## Goal

Define the first host-neutral semantic kernel and prove that one interaction set can target headless, DOM, and a limited native-control spike without browser or toolkit objects in portable component code.

## Proven host facts

- A checksum-governed Wasm runtime can boot a packaged Elixir application and expose bounded process, message, timer, failure, and cleanup observations.
- A worker-owned browser host can validate a manifest, detect prerequisites, report readiness, reject stale generations, recover, and dispose owned resources.
- A bounded renderer adapter can validate operations, preserve keyed identity, normalize events, reject malformed input before partial mutation, and converge on cleanup.
- Server-owned authentication, authorization, resource version, idempotency, rate, audit, and side effects remain independent of untrusted client presentation.
- Standalone DOM behavior does not require Phoenix, Plug, LiveView, or LocalLiveView; the private LiveView adapter is optional and exact-pins-only.
- Active Chrome and Firefox development executions agree on normalized semantics while remaining unsupported products.
- Immutable source and tools can reproduce runtime, AVM, profile, and report identities in two clean contexts on one Linux host.

## Neutral contract constraints

- Represent semantic nodes independently of any concrete renderer.
- Make identity explicit and deterministic across update, move, replacement, and disposal.
- Represent events as validated semantic input rather than host callback objects.
- Represent effects as requested capabilities with explicit ownership and cancellation.
- Keep resources generation-scoped, bounded, observable, and idempotently disposable.
- Separate presentation state from authority-bearing decisions and side effects.
- Make fallback and unsupported capability outcomes explicit semantic states.
- Require deterministic headless traces before backend-specific conformance credit.
- Keep layout intent, accessibility intent, tokens, and focus/selection semantics host neutral.

## Disposable BH-01 lessons

- BH-01 Elixir fixture modules and message tuples are examples, not public component APIs.
- BH-01 DOM operation names and JSON wire shapes are renderer experiments, not the neutral tree protocol.
- BH-01 Phoenix routes, session fixtures, command names, and audit shapes are not server-adapter contracts.
- BH-01 lifecycle state names and JavaScript callback shapes are not portable host contracts.
- BH-01 benchmark workloads and timing boundaries remain experimental methods.
- Popcorn, AtomVM, Phoenix, LiveView, browser, and toolkit implementation objects stay behind adapters.

## Forbidden leakage

- HTML or DOM node types in portable packages
- browser event or JavaScript callback objects in semantic APIs
- Phoenix, Plug, LiveView, or LocalLiveView dependencies in portable packages
- Popcorn or AtomVM types in semantic packages
- BH-01 fixture message tuples, route paths, command strings, or JSON shapes as public contracts
- private LiveView renderer data outside its optional adapter
- native toolkit handles or widget classes in portable component code

## Required outputs

- versioned semantic UI node and identity contract
- host-neutral event and action contract
- effect, capability, and resource ownership contract
- layout, token, accessibility, focus, selection, and file-choice intent
- renderer lifecycle and capability negotiation contract
- deterministic headless renderer and canonical traces
- minimal DOM lowering conforming to the same traces
- limited native-control portability spike conforming to the same interaction set
- automated forbidden-dependency and leakage checks

BH-02 requires explicit owner authorization after Phase 10 integration. This manifest grants no browser, native, mobile, accessibility, security, performance, or release support.
