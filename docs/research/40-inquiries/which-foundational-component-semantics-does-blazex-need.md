---
title: "Which foundational component semantics does BlazeX need?"
kind: inquiry
created: "2026-09-02"
status: open
tags:
  - blazor
  - design-analysis
  - components
  - phoenix
  - research-program
aliases:
  - "BlazeX component semantics inquiry"
---

# Which foundational component semantics does BlazeX need?

## Why this matters

Blazor provides useful evidence about the problems a mature interactive UI
framework must solve, but its contracts must not become BlazeX's contracts by
accident. BlazeX needs an explicit, native Elixir/Phoenix design for forms,
identity, cleanup, uploads, authorization, focus, and failure recovery—not a
translation of C# APIs or a promise about Razor components.

The foundational runtime contract also determines package reachability,
browser capabilities, payload, and security. An overly broad surface would expose
unstable LiveView internals and unsupported AtomVM behavior; an overly narrow
one would offer little beyond raw HEEx.

MudBlazor v9.9.0 is now the target visual catalog, tracked in a [separate
inquiry](which-mudblazor-component-families-should-blazex-build.md). This
inquiry asks only which renderer, lifecycle, form, navigation, effect, and host
semantics are needed beneath that catalog.

Those semantics must now support the [host-neutral renderer
boundary](../20-notes/host-neutral-blazex-architecture-and-native-control-backends.md):
browser DOM is the first adapter, while actual native controls are a future
renderer target.

## Operational question

For each P0/P1 row in the [component semantics design
study](../20-notes/blazor-framework-semantics-beneath-blazex.md), can BlazeX:

1. state the underlying UI problem independently of Blazor terminology;
2. name a stable Elixir/HEEx contract and supported host set;
3. satisfy its documented semantic output and event contracts under claimed
   runtime, renderer, capability, and remote profiles;
4. preserve identity, focus, form values, accessibility, and cleanup across
   updates/removal;
5. reject unsupported props, runtime calls, dynamic modules, and host crossings
   at build or mount time rather than silently degrading;
6. define offline, disconnect, retry, and crash behavior;
7. keep authorization, persistence, uploads, and privileged commands
   server-authoritative;
8. measure the incremental payload, startup, memory, and event-to-paint cost;
9. depend on public/versioned renderer surfaces or isolate private dependencies
   behind tested adapters; and
10. publish the capability from a machine-readable BlazeX row tied to tests?

A row is “supported” only when all applicable dimensions have evidence. A
similar component name or static HTML demo is insufficient.

## Working hypotheses

- **H1 — native semantics are the product:** Elixir developers need an
  idiomatic behavior and composition model, not translated C# classes, Razor
  syntax, or Blazor API names.
- **H2 — P0 web composition is reusable behind an adapter:** attrs, slots,
  LiveComponents, HEEx keys, forms, and renderer diffs can implement the first
  DOM backend, but portable composition requires semantic nodes/regions.
- **H3 — forms are the decisive P0 library:** a portable form state and input
  model will expose more real framework-design failures than another counter or
  button example.
- **H4 — process boundaries define honest error boundaries:** a local root can
  be isolated now; nested LiveComponents cannot claim independent containment.
- **H5 — host services should stay host-owned:** Phoenix should continue to own
  routes, auth, antiforgery, uploads, and trusted work.
- **H6 — browser capabilities require lifecycle ownership:** focus,
  measurement, files, observers, storage, and JavaScript handles need an
  effect contract with disposal and stale-generation rejection.
- **H7 — dynamic dispatch must be bounded:** tree shaking and security require
  a manifest of public component/provider IDs.
- **H8 — QuickGrid is only a substrate workload:** it can validate generic
  provider and virtualization contracts, but the MudBlazor DataGrid family is
  the product-level target and is tracked separately.

## Paths to explore

### P0 contract application

- Build one reference app with nested function/live components, contextual
  slots, dynamic components, keyed reorder, and component removal.
- Add a multi-step form with raw invalid numeric state, local pure validation,
  server rejection, reconnect recovery, and accessibility assertions.
- Run it as ordinary LiveView and LocalLiveView under exact pins.
- Run the same semantic trace through a headless renderer and the early native
  control adapter before freezing public APIs.
- Preserve callback traces, diffs, DOM snapshots, console errors, bundle
  manifests, and browser timings.

### Browser capability lifecycle

- Implement focus, measurement/resize observation, clipboard, and one opaque
  JavaScript handle.
- Remove/restart roots through every path and prove deterministic cleanup.
- Inject delayed replies from an old generation and verify rejection.

### Host boundaries

- Exercise hosted and standalone patch navigation, browser back/forward,
  route focus, navigation blocking, and full reload.
- Implement an advisory authorization view and prove direct forged events
  still fail at the server command handler.
- Prototype file selection without upload, then compare Phoenix upload reuse,
  direct-to-cloud, and Plug HTTP transports.

### P1/P2 feasibility

- Test page-title and colocated-hook behavior in both LocalLiveView modes.
- Compare LiveView streams/viewport bindings with an observer-based local
  virtualizer.
- Use a bounded QuickGrid-like fixture only after the provider and virtualizer
  APIs are independently tested; design the actual grid package from the
  MudBlazor DataGrid study.
- Prototype deterministic scoped CSS IDs across server and local render before
  committing to CSS isolation.

## Findings

- The [component semantics synthesis](../20-notes/blazor-framework-semantics-beneath-blazex.md)
  recommends P0/P1/P2 BlazeX priorities and identifies ideas to reshape or
  omit.
- The [MudBlazor component-system
  synthesis](../20-notes/mudblazor-inspired-component-system-for-blazex.md)
  now owns the visual catalog, public component families, and delivery tiers.
- The [host-neutral architecture
  synthesis](../20-notes/host-neutral-blazex-architecture-and-native-control-backends.md)
  makes semantic rendering and the native-control vertical slice part of F0.
- [Blazor's API catalog](../30-sources/microsoft-2026-blazor-component-contracts-styling-and-interop.md)
  shows that its built-ins are primarily infrastructure, forms, navigation,
  and renderer contracts rather than a broad visual widget suite.
- [Phoenix's UI foundations](../30-sources/phoenix-framework-2026-liveview-ui-foundation-surfaces.md)
  already cover attrs, slots, stateful components, forms, navigation,
  uploads, title updates, viewport events, hooks, and server security.
- The locally inspected LocalLiveView package implements local process
  lifecycle, form event decoding, nested LiveComponent diff state, component
  deletion bookkeeping, server event pushes, and hosted/standalone patch
  navigation.
- No LocalLiveView-specific upload integration, general head/section outlet,
  browser-side authorization provider, or subtree error-boundary contract was
  found in the inspected package.

## Outcome

Open. The architecture-level direction is sufficiently clear to begin an
executable P0 matrix, but most browser-local BlazeX facilities still need
contract tests. The first resolution milestone is a pinned P0 reference
application proving composition, identity, forms, effects, secure commands,
process-root recovery, hosted/standalone navigation, and cross-renderer
semantics with measured costs. It is explicitly not an implementation
milestone for any Blazor API.
