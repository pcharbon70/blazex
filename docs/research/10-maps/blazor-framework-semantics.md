---
title: "Blazor framework semantics"
kind: map
created: "2026-09-02"
tags:
  - blazor
  - design-analysis
  - components
  - phoenix
aliases:
  - "BlazeX component design map"
---

# Blazor framework semantics

## Scope

This map uses Blazor's built-in Razor component APIs as a catalog of solved
framework and runtime problems, then routes to native Phoenix/LiveView and
BlazeX designs. It does not define .NET compatibility, a Blazor API layer,
WebAssembly Component Model binaries, or the target visual-control catalog.
That product-level role belongs to the [MudBlazor-inspired component-system
map](mudblazor-inspired-component-system.md).

## Start here

- [Blazor framework semantics beneath BlazeX](../20-notes/blazor-framework-semantics-beneath-blazex.md) — complete component-by-component framework matrix,
  native API decisions, proposed package boundaries, P0/P1/P2 priorities, and
  contract-testing plan.
- [Which foundational component semantics does BlazeX
  need?](../40-inquiries/which-foundational-component-semantics-does-blazex-need.md) — converts provisional design choices into executable acceptance
  questions.
- [2026-09-02 component semantics deep
  dive](../50-journal/2026-09-02-blazor-component-semantics-deep-dive.md) — records source baselines, LocalLiveView package inspection, negative
  findings, and limits.

## Central decisions

- Keep MudBlazor v9.9.0 as the separate product-level catalog and UX
  reference; this map concerns only its underlying framework substrate.
- Define native Elixir/Phoenix semantics. Blazor is research input, never a
  compatibility target or public API namespace.
- Treat Phoenix as route, authentication, upload, and trusted-command
  authority; treat browser state as untrusted.
- Use semantic function components for portable composition, nested stateful
  components for shared-root state, and local views for process/failure
  boundaries. Function components/LiveComponents are the first web adapter.
- Own a client-safe form state rather than shipping arbitrary Ecto changesets
  into AtomVM.
- Bound dynamic dispatch in a build manifest.
- Express DOM/browser work as capability-scoped effects.
- Ship process-root error containment before claiming subtree boundaries.
- Build virtualization before the optional QuickGrid-like package.

## Evidence trails

### Blazor component kernel

- [Component contracts, composition, styling, and
  interop](../30-sources/microsoft-2026-blazor-component-contracts-styling-and-interop.md) — parameters, events, fragments, dynamic components, cascades,
  lifecycle, keys, binding, CSS, and JavaScript.
- [Blazor render modes and
  components](../30-sources/microsoft-2026-blazor-render-modes-and-components.md) — common model across static, server, WebAssembly, and Auto hosts.
- [ASP.NET Core renderer
  source](../30-sources/dotnet-project-2025-aspnetcore-component-renderer-source.md) — render tree, component state, diffs, and batches.

### Concrete built-ins

- [Forms, routing, and authorization
  components](../30-sources/microsoft-2026-blazor-forms-routing-and-authorization-components.md) — concrete form inputs, form state, router/navigation, auth views,
  and remote auth.
- [Layouts, sections, errors, virtualization, and
  QuickGrid](../30-sources/microsoft-2026-blazor-layout-sections-errors-virtualization-and-quickgrid.md) — cross-tree content, head updates, failure containment, virtual
  ranges, and first-party grid primitives.

### Phoenix foundations

- [Phoenix LiveView UI foundation
  surfaces](../30-sources/phoenix-framework-2026-liveview-ui-foundation-surfaces.md) — attrs, slots, forms, uploads, navigation, layouts, viewport events,
  hooks, and security.
- [Phoenix LiveView lifecycle and
  renderer](../30-sources/phoenix-framework-2026-liveview-1-2-documentation-and-source.md) — server process and DOM protocol architecture.

### Browser-local evidence

- [LocalLiveView first release and
  implementation](../30-sources/software-mansion-2026-local-live-view-first-release.md) — local processes, events, nested components, renderer reuse, host
  bridge, and present private-API/SSR limits.
- [Popcorn architecture and
  limitations](../30-sources/software-mansion-2026-popcorn-documentation-and-source.md) — AtomVM-in-Wasm execution, bundle and JavaScript boundary, exact pins,
  and unsupported runtime facilities.

## BlazeX design priorities by family

- **P0 reuse/adapt:** attrs/props, required inputs, slots, contextual slots,
  event maps, global attributes, keys, layouts, patch navigation, basic forms,
  validation display, and hooks/effects.
- **P0 new framework work:** host-boundary prop schema, dynamic registry,
  lifecycle/disposal facade, secure commands, client-safe form state, and
  process-root fallback.
- **P1:** context, sections/head manager, navigation focus/locks, date/file
  inputs, uploads, advisory auth view, persistence, package assets, and
  virtualization.
- **P2/P3:** QuickGrid-like package, editor registry, CSS isolation, remote
  authentication UI, and SSR/activation state transfer.
- **Intentional divergence:** class inheritance, C# generic components,
  dependency-injection scopes, mutable child references, arbitrary reflection,
  and client-side security decisions.

## Open questions

- Which current LiveView component features pass unchanged under the pinned
  LocalLiveView/AtomVM runtime?
- What cleanup callbacks reliably run on DOM removal, navigation, process
  crash, and VM restart?
- Can Phoenix's upload client be adapted to a local root without private
  coupling?
- How should colocated hooks and package assets cross the separate local Mix
  project boundary?
- Does page-title propagation work in hosted and standalone local modes?
- What is the fixed payload and startup cost of each BlazeX package?
- Which P1 facilities can remain useful under plain Plug?

## Host-neutral amendment

- [Host-neutral and native-renderer
  architecture](host-neutral-and-native-renderer-architecture.md) supersedes
  any implication that HEEx, DOM, browser effects, or LocalLiveView define the
  portable BlazeX renderer contract.
