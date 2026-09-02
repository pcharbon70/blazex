---
title: "ADR-0007 — Native-control portability gate"
kind: note
created: "2026-09-02"
maturity: stable
tags:
  - architecture-decision
  - bh-00
  - native-controls
  - portability
aliases:
  - "ADR-0007"
---

# ADR-0007 — Native-control portability gate

## Decision metadata

| Field | Value |
| --- | --- |
| Status | accepted |
| Date | 2026-09-02 |
| Owners | architecture, product, renderer, accessibility, and test stewards |
| Scope | F0 portable contracts, `experiments/native_renderer_spike`, and headless/DOM/native conformance evidence |
| Supersedes | None |
| Superseded by | None |
| Review triggers | F0 APIs approach stability without native evidence; the spike requires browser types in portable code; or the selected toolkit cannot exercise required semantics |

## Context

Browser delivery comes first, but the ultimate architecture must permit real
native controls rather than defining portability as a WebView alone. Paper
abstractions can hide DOM assumptions until APIs are already expensive to
change.

## Decision

Before public F0 component and semantic contracts are declared stable, the same
representative vertical slice must pass three proofs: deterministic headless
execution, standalone DOM rendering, and creation/interaction of actual native
toolkit controls. The bounded native proof lives in
`experiments/native_renderer_spike`.

The experiment selects neither a production toolkit nor a supported native
profile. Only accepted reusable contracts, fixtures, traces, and findings move
into packages or integration suites; experimental toolkit code is retired or
remains explicitly experimental.

## Rationale

An early native-control proof is the cheapest credible test that semantic UI,
events, effects, resources, layout, and accessibility are not browser-shaped.
Keeping it bounded avoids making a desktop product commitment during browser
delivery.

## Consequences

### Enables

- Evidence-based portability before API lock-in.
- Direct comparison of DOM and native materialization from one semantic slice.
- Extraction of toolkit-neutral contracts without prematurely supporting a
  native backend.

### Constrains

- F0 stability is blocked until all three proofs and findings are reviewed.
- The spike cannot become a production dependency or support claim.
- WebView success alone does not satisfy the native-control gate.

## Alternatives considered

- **Defer native proof until after browser API stability:** rejected because
  discovered DOM coupling would force breaking changes.
- **Treat WebView as sufficient:** rejected because it tests packaging, not
  mapping to actual native controls.
- **Build a complete desktop host now:** rejected because it expands scope far
  beyond the portability question.

## Impact review

### Compatibility

The gate may require pre-stability changes to BlazeX-owned contracts. It creates
no native support or toolkit compatibility promise.

### Security and trust

The experiment uses minimal capabilities and no production secrets. Any native
resource/OS authority remains behind the same capability boundary.

### Accessibility

The native proof must inspect actual toolkit accessibility role, state,
relationship, focus, and input mappings—not merely visual output.

### Packaging and dependencies

Experimental toolkit dependencies remain under the experiment and outside
profiles/packages. Promoting code requires a later ADR, package owner,
dependency review, and profile decision.

### Cross-backend portability

The same semantic fixtures, event/effect traces, and expected state transitions
are compared across headless, DOM, and native materializations.

## Evidence basis

- [Host-neutral architecture synthesis](../host-neutral-blazex-architecture-and-native-control-backends.md)
- [Repository ownership and dependency map](../../10-maps/blazex-repository-ownership-and-dependency-map.md)
- [Browser host milestones](../browser-host-implementation-milestones.md)

## Unresolved evidence

BH-02 must select the smallest toolkit and slice, define comparison tolerances,
run accessibility inspection, and record which abstractions survived or changed.

## Change control

Architecture, renderer, accessibility, and test stewards review gate changes
with product and experiment owners. The roadmap, F0 acceptance contract,
experiment README, conformance fixtures, package map, and API stability status
must change atomically.

## Connections

- [ADR-0001 — Host-neutral semantic component kernel](adr-0001-host-neutral-semantic-component-kernel.md)
- [ADR-0002 — Versioned semantic UI tree](adr-0002-versioned-semantic-ui-tree.md)
- [ADR-0004 — Renderer backend separation](adr-0004-renderer-backend-separation.md)
- [BH-00 Phase 1 plan](../../60-planning/01-browser-host/bh-00-product-boundary-catalog-and-acceptance-contract/phase-01-terminology-and-architecture-decision-baseline.md)

## Sources

- [Tauri desktop WebView architecture notes](../../30-sources/tauri-2026-desktop-webview-architecture.md)
- [WASI WebGPU and windowing status](../../30-sources/webassembly-wasi-2026-webgpu-and-windowing-status.md)
- [AtomVM WebAssembly runtime notes](../../30-sources/atomvm-project-2026-webassembly-runtime.md)
